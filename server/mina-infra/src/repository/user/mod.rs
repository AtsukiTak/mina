mod pg;
pub use self::pg::SnapshotHash;

use self::pg::{insert, load, update};
use super::PgClient;
use dataloader::{cached::Loader, BatchFn};
use mina_domain::user::{User, UserId, UserRepository};
use rego::Error;
use std::{collections::HashMap, ops::DerefMut as _};

/// ## 責務
/// - DBに対する操作（SQL操作）
/// - 内部キャッシュの更新
/// - dataloader
/// - 楽観ロック
pub struct UserRepositoryImpl {
    client: PgClient,
    loader: Loader<UserId, Result<(User, SnapshotHash), Error>, UserLoader>,
}

impl UserRepositoryImpl {
    pub fn new(client: PgClient) -> UserRepositoryImpl {
        UserRepositoryImpl {
            client: client.clone(),
            loader: Loader::new(UserLoader::new(client)),
        }
    }
}

#[async_trait::async_trait]
impl UserRepository for UserRepositoryImpl {
    async fn find_by_ids(&self, user_ids: &[UserId]) -> HashMap<UserId, Result<User, Error>> {
        self.loader
            .load_many(user_ids.to_vec())
            .await
            .into_iter()
            .map(|(id, val)| (id, val.map(|(user, _)| user)))
            .collect()
    }

    async fn find_by_id(&self, user_id: &UserId) -> Result<User, Error> {
        self.loader
            .load(user_id.clone())
            .await
            .map(|(user, _)| user)
    }

    async fn create(&self, user: &User) -> Result<(), Error> {
        // DBへの挿入
        let new_hash = insert(self.client.lock().await.deref_mut(), user).await?;

        self.loader
            .prime(user.id().clone(), Ok((user.clone(), new_hash)))
            .await;

        Ok(())
    }

    async fn update(&self, user: &User) -> Result<(), Error> {
        // snapshot_idを取得するためCacheを取得する
        // Cacheがヒットしない場合はDBへクエリが行われるが、
        // これは意図した挙動（必要不可欠な挙動）である
        let cached = self.loader.load(user.id().clone()).await?;

        // DBのupdate
        let new_hash = update(self.client.lock().await.deref_mut(), user, cached.1).await?;

        self.loader
            .prime(user.id().clone(), Ok((user.clone(), new_hash)))
            .await;

        Ok(())
    }
}

/*
 * ===============
 * DataLoader
 * ===============
 */
struct UserLoader {
    client: PgClient,
}

impl UserLoader {
    fn new(client: PgClient) -> Self {
        UserLoader { client }
    }
}

#[async_trait::async_trait]
impl BatchFn<UserId, Result<(User, SnapshotHash), Error>> for UserLoader {
    async fn load(&self, keys: &[UserId]) -> HashMap<UserId, Result<(User, SnapshotHash), Error>> {
        match load(self.client.lock().await.deref_mut(), keys).await {
            Ok(records) => {
                // NotFoundの場合は、対応するKeyにErrorを設定する
                // そのため、まずすべてのkeyがNotFoundなHashMapを作る
                let mut map = keys
                    .iter()
                    .map(|id| (id.clone(), Err(Error::not_found("user"))))
                    .collect::<HashMap<_, _>>();

                for (user, hash) in records {
                    let key = user.id().clone();
                    *map.get_mut(&key).unwrap() = Ok((user, hash));
                }

                map
            }
            Err(err) => {
                let err = Error::internal(err);
                keys.iter()
                    .map(|id| (id.clone(), Err(err.clone())))
                    .collect()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repository::test_utils::connect_isolated_db;

    #[tokio::test]
    async fn properly_create() {
        // pretty_env_logger::init();

        let client = PgClient::new(connect_isolated_db().await);

        let repo = UserRepositoryImpl::new(client.clone());

        let (user, _) = User::new_anonymous().unwrap();
        repo.create(&user).await.unwrap();

        // with cache
        let found = repo.find_by_id(user.id().as_str()).await.unwrap();
        assert_eq!(found, user);

        // without cache
        let repo = UserRepositoryImpl::new(client);
        let found = repo.find_by_id(user.id().as_str()).await.unwrap();
        assert_eq!(found, user);
    }

    #[tokio::test]
    async fn update_apple_push_token() {
        // pretty_env_logger::init();

        let client = PgClient::new(connect_isolated_db().await);

        let repo = UserRepositoryImpl::new(client.clone());

        let (mut user, _) = User::new_anonymous().unwrap();
        repo.create(&user).await.unwrap();

        // set_apple_push_token
        user.set_apple_push_token("new_token".to_string());
        repo.update(&user).await.unwrap();

        // test without cache
        // updateした内容がちゃんと反映されているかテストする
        let repo = UserRepositoryImpl::new(client);
        let found = repo.find_by_id(user.id().as_str()).await.unwrap();
        assert_eq!(found, user);
    }
}
