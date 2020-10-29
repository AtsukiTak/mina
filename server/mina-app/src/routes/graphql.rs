use crate::{
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
        .and(async_graphql_warp::graphql(schema))
        .and_then(move |(schema, req): (MySchema, Request)| {
            let graphql = graphql.clone();
            async move {
                let res = graphql.query(&schema, req).await;
                Ok::<_, Infallible>(Response(res))
            }
        })
}
