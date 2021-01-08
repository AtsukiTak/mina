mod cron;
mod graphql;

use crate::server::Config;
use warp::{Filter, Rejection, Reply};

pub fn routes(config: Config) -> impl Filter<Extract = (impl Reply,), Error = Rejection> + Clone {
    let cors_wrapper = warp::cors()
        .allow_any_origin()
        .allow_methods(vec!["GET", "POST", "OPTIONS"])
        .allow_headers(vec!["Content-Type", "Authorization"]);

    let log_wrapper = warp::log("mina-app::routes");

    let routes = graphql::route(config.clone())
        .or(cron::invoke_ready_calls::route(config.clone()))
        .or(graphql::playground::route(config));

    routes.with(cors_wrapper).with(log_wrapper)
}
