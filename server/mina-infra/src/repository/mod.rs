#[cfg(test)]
pub mod test_utils;
mod user;

use self::user::UserRepositoryImpl;
use mina_domain::RepositorySet;
use native_tls::TlsConnector;
use postgres_native_tls::MakeTlsConnector;
use rego::Error;
use std::sync::Arc;
use tokio::sync::{Mutex, MutexGuard};
use tokio_postgres::Client;

#[derive(Clone)]
pub struct RepositoryFactory {
    params: String,
    tls: MakeTlsConnector,
}

impl RepositoryFactory {
    pub async fn new(params: &str) -> Self {
        let tls = MakeTlsConnector::new(TlsConnector::new().unwrap());
        RepositoryFactory {
            params: params.to_string(),
            tls,
        }
    }

    /// 現在のところ、DBのマイグレーションを行うだけ
    pub async fn initialize(&self) {
        self.run_migrations().await;
    }

    async fn run_migrations(&self) {
        refinery::embed_migrations!();

        let mut client = self.spawn_client().await.unwrap();
        let report = migrations::runner().run_async(&mut client).await.unwrap();

        eprintln!("{:?}", report);
    }

    /// 新しい接続を確立し `RepositorySetImpl` を生成する
    pub async fn create(&self) -> Result<RepositorySetImpl, Error> {
        let client = self.spawn_client().await?;
        Ok(RepositorySetImpl::new(client))
    }

    async fn spawn_client(&self) -> Result<Client, Error> {
        let (client, conn) = tokio_postgres::connect(self.params.as_str(), self.tls.clone())
            .await
            .map_err(Error::internal)?;

        tokio::spawn(async move {
            if let Err(e) = conn.await {
                log::warn!("postgres connection error: {}", e);
            }
        });

        Ok(client)
    }
}

#[derive(Debug, Clone)]
pub struct PgClient(Arc<Mutex<Client>>);

impl PgClient {
    fn new(client: Client) -> Self {
        PgClient(Arc::new(Mutex::new(client)))
    }

    pub async fn lock(&self) -> MutexGuard<'_, Client> {
        self.0.lock().await
    }
}

/// すべてのRepositoryをまとめる構造体
pub struct RepositorySetImpl {
    client: PgClient,
    user_repo: Option<UserRepositoryImpl>,
}

impl RepositorySetImpl {
    fn new(client: Client) -> Self {
        RepositorySetImpl {
            client: PgClient::new(client),
            user_repo: None,
        }
    }
}

impl RepositorySet for RepositorySetImpl {
    type UserRepo = UserRepositoryImpl;

    fn user_repo(&mut self) -> &mut UserRepositoryImpl {
        if self.user_repo.is_none() {
            let repo = UserRepositoryImpl::new(self.client.clone());
            self.user_repo = Some(repo);
        }

        self.user_repo.as_mut().unwrap()
    }
}
