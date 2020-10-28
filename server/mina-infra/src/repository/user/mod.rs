mod pg;
pub use self::pg::UserWithHash;

use self::pg::{insert, load, update};
use super::PgClient;
use dataloader::{non_cached::Loader, BatchFn};
use mina_domain::user::{User, UserRepository};
use rego::Error;
use std::{collections::HashMap, ops::DerefMut as _};

/// ## 責務
/// - DBに対する操作（SQL操作）
/// - 内部キャッシュの更新
/// - dataloader
/// - 楽観ロック
pub struct UserRepositoryImpl {
    client: PgClient,
    cache: HashMap<String, Result<UserWithHash, Error>>,
    loader: Loader<String, Result<UserWithHash, Error>, UserLoader>,
}

impl UserRepositoryImpl {
    pub fn new(client: PgClient) -> UserRepositoryImpl {
        UserRepositoryImpl {
            client: client.clone(),
            cache: HashMap::new(),
            loader: Loader::new(UserLoader::new(client)),
        }
    }
}

#[async_trait::async_trait]
impl UserRepository for UserRepositoryImpl {
    async fn find_by_id(&mut self, user_id: String) -> Result<User, Error> {
        if let Some(cached) = self.cache.get(&user_id).cloned() {
            return cached.map(|u| u.user);
        }

        Ok(self.loader.load(user_id).await?.user)
    }

    async fn create(&mut self, user: User) -> Result<User, Error> {
        // DBへの挿入
        let new_user_with_hash = insert(self.client.lock().await.deref_mut(), user).await?;
        let new_user = new_user_with_hash.user.clone();

        // Cacheの更新
        self.cache
            .insert(new_user.id().to_string(), Ok(new_user_with_hash));

        Ok(new_user)
    }

    async fn update(&mut self, user: User) -> Result<User, Error> {
        // snapshot_idを取得するためCacheを取得する
        // Cacheがヒットしない場合はDBへクエリが行われるが、
        // これは意図した挙動（必要不可欠な挙動）である
        let mut cache = self.loader.load(user.id().to_string()).await?;
        cache.user = user;

        // DBのupdate
        let new_user_with_hash = update(self.client.lock().await.deref_mut(), cache).await?;
        let new_user = new_user_with_hash.user.clone();

        // Cacheの更新
        self.cache
            .insert(new_user.id().to_string(), Ok(new_user_with_hash));

        Ok(new_user)
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
