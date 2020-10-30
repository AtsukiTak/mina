use crate::routes::routes;
use mina_infra::repository::RepositoryFactory;
use std::convert::Infallible;
use std::net::SocketAddr;
use warp::Filter;

pub async fn bind(socket: impl Into<SocketAddr> + 'static, config: Config) {
    let server = warp::serve(routes(config));
    server.bind(socket).await
}

#[derive(Clone)]
pub struct Config {
    pub repository_factory: RepositoryFactory,
}

impl Config {
    pub async fn new(pg_url: &str) -> Self {
        Config {
            repository_factory: RepositoryFactory::new(pg_url).await,
        }
    }

    pub fn to_filter(&self) -> impl Filter<Extract = (Config,), Error = Infallible> + Clone {
        let config = self.clone();
        warp::any().map(move || config.clone())
    }
}
