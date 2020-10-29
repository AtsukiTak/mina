use super::query::Query;
use async_graphql::{EmptyMutation, EmptySubscription, Request, Response};
use mina_infra::repository::RepositorySetImpl;

pub struct Schema {
    inner: async_graphql::Schema<Query, EmptyMutation, EmptySubscription>,
}

impl Schema {
    pub async fn query(&self, req: Request, params: Params) -> Response {
        self.inner.execute(req.data(params)).await
    }
}

pub struct Params {
    pub repos: RepositorySetImpl,
}
