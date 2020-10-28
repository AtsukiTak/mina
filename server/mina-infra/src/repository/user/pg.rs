use mina_domain::user::User;
use rego::Error;
use tokio_postgres::{Client, Row};
use uuid::Uuid;

#[derive(Clone, Debug)]
pub struct UserWithHash {
    pub user: User,
    pub hash: Uuid,
}

impl UserWithHash {
    pub fn new(user: User, hash: Uuid) -> UserWithHash {
        UserWithHash { user, hash }
    }
}

/*
 * =============
 * Load
 * =============
 */
/// 複数IdからUserをクエリするためのStatement
const LOAD_STMT: &str = r#"
SELECT (id, name, secret, snapshot_hash)
FROM users
WHERE id = ANY $1
"#;

pub async fn load(client: &mut Client, user_ids: &[String]) -> Result<Vec<UserWithHash>, Error> {
    // 1操作しかしないため、transactionを発行していない
    // 複数操作になったときはtransactionを発行する
    Ok(client
        .query(LOAD_STMT, &[&user_ids])
        .await
        .map_err(Error::internal)?
        .into_iter()
        .map(to_user_with_hash)
        .collect())
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
pub async fn insert(client: &mut Client, user: User) -> Result<UserWithHash, Error> {
    let new_hash = Uuid::new_v4();

    // 1操作しかしないため、transactionを発行していない
    // 複数操作になったときはtransactionを発行する
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

pub async fn update(client: &mut Client, update: UserWithHash) -> Result<UserWithHash, Error> {
    let user = update.user;
    let old_hash = update.hash;
    let new_hash = Uuid::new_v4();

    // 1操作しかしないため、transactionを発行していない
    // 複数操作になったときはtransactionを発行する
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
