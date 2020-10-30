mod graphql;

use crate::server::Config;
use warp::{Filter, Rejection, Reply};

pub fn routes(config: Config) -> impl Filter<Extract = (impl Reply,), Error = Rejection> + Clone {
    let cors_wrapper = warp::cors()
        .allow_any_origin()
        .allow_methods(vec!["GET", "POST", "OPTIONS"])
        .allow_headers(vec!["Content-Type", "Authorization"]);

    let routes = graphql::route(config.clone()).or(graphql::playground::route(config));

    routes.with(cors_wrapper)
}
