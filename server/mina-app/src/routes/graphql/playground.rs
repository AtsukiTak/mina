use crate::server::Config;
use async_graphql::http::{playground_source, GraphQLPlaygroundConfig};
use warp::{reply::Html, Filter, Rejection};

pub fn route(_config: Config) -> impl Filter<Extract = (Html<String>,), Error = Rejection> + Clone {
    warp::path!("graphql" / "playground")
        .and(warp::get())
        .map(|| {
            let html_str = playground_source(GraphQLPlaygroundConfig::new("/graphql"));
            warp::reply::html(html_str)
        })
}
