use mina_domain::user::{User, UserId};
use rego::Error;
use tokio_postgres::{Client, Row};
use uuid::Uuid;

#[derive(Clone, Copy, Debug)]
pub struct SnapshotHash(Uuid);

/*
 * =============
 * Load
 * =============
 */
/// 複数IdからUserをクエリするためのStatement
const LOAD_STMT: &str = r#"
SELECT
    id,
    name,
    secret_cred,
    apple_push_token,
    snapshot_hash
FROM users
WHERE id = ANY( $1 )
"#;

pub async fn load(
    client: &mut Client,
    user_ids: &[UserId],
) -> Result<Vec<(User, SnapshotHash)>, Error> {
    let user_ids = user_ids.iter().map(|id| id.as_str()).collect::<Vec<_>>();
    // 1操作しかしないため、transactionを発行していない
    // 複数操作になったときはtransactionを発行する
    let rows = client
        .query(LOAD_STMT, &[&user_ids])
        .await
        .map_err(Error::internal)?;

    Ok(rows.into_iter().map(to_user_with_hash).collect())
}

fn to_user_with_hash(row: Row) -> (User, SnapshotHash) {
    let id: String = row.get("id");
    let name: Option<String> = row.get("name");
    let secret_cred: String = row.get("secret_cred");
    let apple_push_token: Option<String> = row.get("apple_push_token");
    let hash: Uuid = row.get("snapshot_hash");

    let user = User::from_raw_parts(id, name, secret_cred, apple_push_token);
    (user, SnapshotHash(hash))
}

/*
 * ==============
 * DB Insert
 * ==============
 */
const INSERT_STMT: &str = r#"
INSERT INTO users
(
    id,
    name,
    secret_cred,
    apple_push_token,
    snapshot_hash
)
VALUES ($1, $2, $3, $4, $5)
"#;

/// 新規UserをDBに登録する
pub async fn insert(client: &mut Client, user: &User) -> Result<SnapshotHash, Error> {
    let new_hash = Uuid::new_v4();

    // 1操作しかしないため、transactionを発行していない
    // 複数操作になったときはtransactionを発行する
    client
        .execute(
            INSERT_STMT,
            &[
                &user.id().as_str(),
                &user.name(),
                &user.secret_cred().as_str(),
                &user.apple_push_token(),
                &new_hash,
            ],
        )
        .await
        .map_err(Error::internal)?;

    Ok(SnapshotHash(new_hash))
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
  secret_cred = $2,
  apple_push_token = $3,
  snapshot_hash = $4
WHERE
  id = $5
  AND
  snapshot_hash = $6
"#;

/// 楽観ロック
pub async fn update(
    client: &mut Client,
    user: &User,
    old_hash: SnapshotHash,
) -> Result<SnapshotHash, Error> {
    let new_hash = Uuid::new_v4();

    // 1操作しかしないため、transactionを発行していない
    // 複数操作になったときはtransactionを発行する
    client
        .execute(
            UPDATE_STMT,
            &[
                &user.name(),
                &user.secret_cred().as_str(),
                &user.apple_push_token(),
                &new_hash,
                &user.id().as_str(),
                &old_hash.0,
            ],
        )
        .await
        .map_err(Error::internal)?;

    Ok(SnapshotHash(new_hash))
}
