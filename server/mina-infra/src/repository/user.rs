use dataloader::{cached::Loader, BatchFn};
use mina_domain::user::{User, UserRepository};
use rego::Error;
use std::{collections::HashMap, sync::Arc};
use tokio_postgres::{Client, Row};
use uuid::Uuid;

/// ## 責務
/// - DBに対する操作（SQL操作）
/// - 内部キャッシュ
/// - dataloader
/// - 楽観ロック
pub struct UserRepositoryImpl {
    client: Arc<Client>,
    loader: Loader<String, Result<UserWithHash, Error>, UserLoader>,
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
        Ok(self.loader.load(user_id).await?.user)
    }

    async fn create(&mut self, user: User) -> Result<User, Error> {
        // DBへの挿入
        let new_user_with_hash = insert(&self.client, user).await?;
        let new_user = new_user_with_hash.user.clone();

        // Cacheの更新
        self.loader
            .prime(new_user.id().to_string(), Ok(new_user_with_hash))
            .await;

        Ok(new_user)
    }

    async fn update(&mut self, user: User) -> Result<User, Error> {
        // snapshot_idを取得するためCacheを取得する
        // Cacheがヒットしない場合はDBへクエリが行われるが、
        // これは意図した挙動（必要不可欠な挙動）である
        let mut cache = self.loader.load(user.id().to_string()).await?;
        cache.user = user;

        // DBのupdate
        let new_user_with_hash = update(&self.client, cache).await?;
        let new_user = new_user_with_hash.user.clone();

        // Cacheの更新
        self.loader
            .prime(new_user.id().to_string(), Ok(new_user_with_hash))
            .await;

        Ok(new_user)
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
impl BatchFn<String, Result<UserWithHash, Error>> for UserLoader {
    async fn load(&self, keys: &[String]) -> HashMap<String, Result<UserWithHash, Error>> {
        load(&self.client, keys).await
    }
}

#[derive(Clone, Debug)]
struct UserWithHash {
    user: User,
    hash: Uuid,
}

impl UserWithHash {
    fn new(user: User, hash: Uuid) -> Self {
        UserWithHash { user, hash }
    }
}

/*
 * =============
 * DB Load
 * =============
 */
/// 複数IdからUserをクエリするためのStatement
const LOAD_STMT: &str = r#"
SELECT (id, name, secret, snapshot_hash)
FROM users
WHERE id = ANY $1
"#;

async fn load(
    client: &Client,
    user_ids: &[String],
) -> HashMap<String, Result<UserWithHash, Error>> {
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
    let mut users: HashMap<String, Result<UserWithHash, Error>> = user_ids
        .iter()
        .map(|id| (id.clone(), Err(Error::not_found("user"))))
        .collect();

    // 見つかったUserを1つずつinsertしていく
    for row in rows {
        let user_with_hash = to_user_with_hash(row);
        users.insert(user_with_hash.user.id().to_string(), Ok(user_with_hash));
    }

    users
}

fn to_user_with_hash(row: Row) -> UserWithHash {
    let id: String = row.get("id");
    let name: Option<String> = row.get("name");
    let secret: String = row.get("secret");
    let hash: Uuid = row.get("snapshot_hash");

    let user = User::from_raw_parts(id, name, secret);
    UserWithHash::new(user, hash)
}

/*
 * ==============
 * DB Insert
 * ==============
 */
const INSERT_STMT: &str = r#"
INSERT INTO users (id, name, secret, snapshot_hash)
VALUES ($1, $2, $3, $4)
"#;

/// 新規UserをDBに登録する
async fn insert(client: &Client, user: User) -> Result<UserWithHash, Error> {
    let new_hash = Uuid::new_v4();

    client
        .execute(
            INSERT_STMT,
            &[
                &user.id().as_str(),
                &user.name(),
                &user.secret().as_str(),
                &new_hash,
            ],
        )
        .await
        .map_err(Error::internal)?;

    Ok(UserWithHash::new(user, new_hash))
}

/*
 * ===========
 * DB Update
 * ===========
 */
const UPDATE_STMT: &str = r#"
UPDATE users
SET
  name = $1,
  secret = $2,
  snapshot_hash = $3
WHERE
  id = $4,
  snapshot_hash = $5
"#;

async fn update(client: &Client, update: UserWithHash) -> Result<UserWithHash, Error> {
    let user = update.user;
    let old_hash = update.hash;
    let new_hash = Uuid::new_v4();

    client
        .execute(
            UPDATE_STMT,
            &[
                &user.name(),
                &user.secret().as_str(),
                &new_hash,
                &user.id().as_str(),
                &old_hash,
            ],
        )
        .await
        .map_err(Error::internal)?;

    Ok(UserWithHash::new(user, new_hash))
}
