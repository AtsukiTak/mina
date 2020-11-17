use crate::{infra::apple::push::Client as PushClient, routes::routes};
use mina_infra::repository::{RepositoryFactory, RepositorySetImpl};
use rego::Error;
use std::{convert::Infallible, net::SocketAddr, sync::Arc};
use warp::Filter;

pub async fn bind(socket: impl Into<SocketAddr> + 'static, config: Config) {
    let server = warp::serve(routes(config));
    server.bind(socket).await
}

#[derive(Clone)]
pub struct Config {
    pub repository_factory: RepositoryFactory,
    push_client: Arc<PushClient>,
}

impl Config {
    pub async fn new(pg_url: &str, push_client: PushClient) -> Self {
        Config {
            repository_factory: RepositoryFactory::new(pg_url).await,
            push_client: Arc::new(push_client),
        }
    }

    pub async fn repos(&self) -> Result<RepositorySetImpl, Error> {
        self.repository_factory.create().await
    }

    pub fn push_client(&self) -> Arc<PushClient> {
        self.push_client.clone()
    }

    pub fn to_filter(&self) -> impl Filter<Extract = (Config,), Error = Infallible> + Clone {
        let config = self.clone();
        warp::any().map(move || config.clone())
    }
}
