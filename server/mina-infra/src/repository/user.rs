use dataloader::{cached::Loader, BatchFn};
use mina_domain::user::{User, UserRepository};
use rego::Error;
use std::{collections::HashMap, sync::Arc};
use tokio_postgres::{Client, Row};

/// ## 責務
/// - DBに対する操作（SQL操作）
/// - 内部キャッシュ
/// - dataloader
pub struct UserRepositoryImpl {
    client: Arc<Client>,
    loader: Loader<String, Result<User, Error>, UserLoader>,
}

impl UserRepositoryImpl {
    pub fn new(client: Arc<Client>) -> Self {
        UserRepositoryImpl {
            client: client.clone(),
            loader: Loader::new(UserLoader::new(client)),
        }
    }
}

#[async_trait::async_trait]
impl UserRepository for UserRepositoryImpl {
    async fn find_by_id(&mut self, user_id: String) -> Result<User, Error> {
        self.loader.load(user_id).await
    }

    async fn save(&mut self, user: User) -> Result<User, Error> {
        // DBへの挿入
        insert(&self.client, &user).await?;

        // Cacheの更新
        self.loader
            .prime(user.id().to_string(), Ok(user.clone()))
            .await;

        Ok(user)
    }
}

/*
 * ===============
 * DataLoader
 * ===============
 */
struct UserLoader {
    client: Arc<Client>,
}

impl UserLoader {
    fn new(client: Arc<Client>) -> Self {
        UserLoader { client }
    }
}

#[async_trait::async_trait]
impl BatchFn<String, Result<User, Error>> for UserLoader {
    async fn load(&self, keys: &[String]) -> HashMap<String, Result<User, Error>> {
        load(&self.client, keys).await
    }
}

/*
 * =============
 * DB Load
 * =============
 */
/// 複数IdからUserをクエリするためのStatement
const LOAD_STMT: &str = r#"
SELECT (id, name, secret)
FROM users
WHERE id = ANY $1
"#;

async fn load(client: &Client, user_ids: &[String]) -> HashMap<String, Result<User, Error>> {
    let res = client.query(LOAD_STMT, &[&user_ids]).await;

    if let Err(e) = res {
        let err = Error::internal(e);
        return user_ids
            .iter()
            .map(move |id| (id.clone(), Err(err.clone())))
            .collect();
    }

    let rows = res.unwrap();

    // NotFoundの場合は、対応するkeyにErrorを設定する
    // そのため、まずすべてのkeyがNotFoundなHashMapを作る
    let mut users: HashMap<String, Result<User, Error>> = user_ids
        .iter()
        .map(|id| (id.clone(), Err(Error::not_found("user"))))
        .collect();

    // 見つかったUserを1つずつinsertしていく
    for row in rows {
        let user = to_user(row);
        users.insert(user.id().to_string(), Ok(user));
    }

    users
}

fn to_user(row: Row) -> User {
    let id: String = row.get("id");
    let name: Option<String> = row.get("name");
    let secret: String = row.get("secret");

    User::from_raw_parts(id, name, secret)
}

/*
 * ==============
 * DB Insert
 * ==============
 */
const INSERT_STMT: &str = r#"
INSERT INTO users (id, name, secret)
VALUES ($1, $2, $3)
"#;

async fn insert(client: &Client, user: &User) -> Result<(), Error> {
    client
        .execute(
            INSERT_STMT,
            &[&user.id().as_str(), &user.name(), &user.secret().as_str()],
        )
        .await
        .map_err(Error::internal)?;

    Ok(())
}
