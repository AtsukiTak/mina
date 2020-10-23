mod user;

use mina_domain::user::{User, UserRepository};
use native_tls::TlsConnector;
use postgres_native_tls::MakeTlsConnector;
use rego::Error;
use std::sync::Arc;
use tokio_postgres::Client;

pub struct RepositoryFactory {
    params: String,
    tls: MakeTlsConnector,
}

impl RepositoryFactory {
    /// 新しいRepositoryFactoryを生成し、初期化を行う
    /// 現在のところ、DBのマイグレーションを行うだけ
    pub async fn new_with_initialize(params: &str) -> Self {
        let tls = MakeTlsConnector::new(TlsConnector::new().unwrap());
        let this = RepositoryFactory {
            params: params.to_string(),
            tls,
        };

        // initialize
        this.run_migrations().await;

        this
    }

    async fn run_migrations(&self) {
        refinery::embed_migrations!();

        let mut client = self.spawn_client().await.unwrap();
        let report = migrations::runner().run_async(&mut client).await.unwrap();

        eprintln!("{:?}", report);
    }

    /// 新しい `RepositoryImpl` を生成する
    pub async fn create(&self) -> Result<RepositoryImpl, Error> {
        let client = self.spawn_client().await?;
        Ok(RepositoryImpl::new(client))
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

pub struct RepositoryImpl {
    pg: Arc<Client>,
    user_repo: Option<user::UserRepositoryImpl>,
}

impl RepositoryImpl {
    fn new(client: Client) -> Self {
        RepositoryImpl {
            pg: Arc::new(client),
            user_repo: None,
        }
    }

    fn user_repo_mut(&mut self) -> &mut user::UserRepositoryImpl {
        if self.user_repo.is_none() {
            let repo = user::UserRepositoryImpl::new(self.pg.clone());
            self.user_repo = Some(repo);
        }

        self.user_repo.as_mut().unwrap()
    }
}

#[async_trait::async_trait]
impl UserRepository for RepositoryImpl {
    async fn find_by_id(&mut self, user_id: String) -> Result<User, Error> {
        self.user_repo_mut().find_by_id(user_id).await
    }

    async fn create(&mut self, user: User) -> Result<User, Error> {
        self.user_repo_mut().create(user).await
    }
}
