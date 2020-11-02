mod pg;
pub use self::pg::UserWithHash;

use self::pg::{insert, load, update};
use super::PgClient;
use dataloader::{non_cached::Loader, BatchFn};
use mina_domain::user::{User, UserRepository};
use rego::Error;
use std::{collections::HashMap, ops::DerefMut as _};
use tokio::sync::Mutex;

/// ## 責務
/// - DBに対する操作（SQL操作）
/// - 内部キャッシュの更新
/// - dataloader
/// - 楽観ロック
pub struct UserRepositoryImpl {
    client: PgClient,
    cache: Mutex<HashMap<String, Result<UserWithHash, Error>>>,
    loader: Loader<String, Result<UserWithHash, Error>, UserLoader>,
}

impl UserRepositoryImpl {
    pub fn new(client: PgClient) -> UserRepositoryImpl {
        UserRepositoryImpl {
            client: client.clone(),
            cache: Mutex::new(HashMap::new()),
            loader: Loader::new(UserLoader::new(client)),
        }
    }
}

#[async_trait::async_trait]
impl UserRepository for UserRepositoryImpl {
    async fn find_by_id(&self, user_id: &str) -> Result<User, Error> {
        let cache = self.cache.lock().await;
        if let Some(cached) = cache.get(user_id).cloned() {
            return cached.map(|u| u.user);
        }
        drop(cache);

        Ok(self.loader.load(user_id.to_string()).await?.user)
    }

    async fn create(&self, user: &User) -> Result<(), Error> {
        // DBへの挿入
        let new_hash = insert(self.client.lock().await.deref_mut(), user).await?;

        // Cacheの更新
        let new_cache = UserWithHash::new(user.clone(), new_hash);
        self.cache
            .lock()
            .await
            .insert(user.id().to_string(), Ok(new_cache));

        Ok(())
    }

    async fn update(&self, user: &User) -> Result<(), Error> {
        // snapshot_idを取得するためCacheを取得する
        // Cacheがヒットしない場合はDBへクエリが行われるが、
        // これは意図した挙動（必要不可欠な挙動）である
        let cached = self.loader.load(user.id().to_string()).await?;

        // DBのupdate
        let new_hash = update(self.client.lock().await.deref_mut(), user, cached.hash).await?;

        // Cacheの更新
        let new_cache = UserWithHash::new(user.clone(), new_hash);
        self.cache
            .lock()
            .await
            .insert(user.id().to_string(), Ok(new_cache));

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
impl BatchFn<String, Result<UserWithHash, Error>> for UserLoader {
    async fn load(&self, keys: &[String]) -> HashMap<String, Result<UserWithHash, Error>> {
        match load(self.client.lock().await.deref_mut(), keys).await {
            Ok(user_with_hash_vec) => {
                // NotFoundの場合は、対応するKeyにErrorを設定する
                // そのため、まずすべてのkeyがNotFoundなHashMapを作る
                let mut map = keys
                    .iter()
                    .map(|id| (id.clone(), Err(Error::not_found("user"))))
                    .collect::<HashMap<_, _>>();

                for user_with_hash in user_with_hash_vec {
                    let key = user_with_hash.user.id().as_str();
                    let val = map.get_mut(key).unwrap();
                    *val = Ok(user_with_hash);
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
