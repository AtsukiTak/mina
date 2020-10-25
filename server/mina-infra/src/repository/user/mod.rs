mod pg;

use self::pg::{insert, load, update, UserWithHash};
use dataloader::{cached::Loader, BatchFn};
use mina_domain::user::{User, UserRepository};
use rego::Error;
use std::{collections::HashMap, sync::Arc};
use tokio_postgres::Client;

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
        match load(&self.client, keys).await {
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
