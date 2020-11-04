pub mod playground;

use crate::{
    auth::basic_opt,
    graphql::{GraphQL, MySchema},
    server::Config,
};
use async_graphql::Request;
use async_graphql_warp::Response;
use std::convert::Infallible;
use warp::{Filter, Rejection};

/// GET or POST
pub fn route(config: Config) -> impl Filter<Extract = (Response,), Error = Rejection> + Clone {
    let graphql = GraphQL::new(config.repository_factory.clone());
    let schema = GraphQL::schema();

    warp::path!("graphql")
        .and(basic_opt())
        .and(async_graphql_warp::graphql(schema))
        .and_then(move |auth_opt, (schema, req): (MySchema, Request)| {
            let graphql = graphql.clone();
            async move {
                let res = graphql.query(&schema, req, auth_opt).await;
                Ok::<_, Infallible>(Response(res))
            }
        })
}
