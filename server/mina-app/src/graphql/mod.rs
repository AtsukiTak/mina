pub mod mutation;
pub mod objects;
pub mod query;

use self::{mutation::Mutation, query::Query};
use async_graphql::{EmptySubscription, Request, Response, Schema, ServerError};
use mina_infra::repository::{RepositoryFactory, RepositorySetImpl};
use mina_usecase::auth::AuthenticatedUser;

pub type MySchema = Schema<Query, Mutation, EmptySubscription>;

#[derive(Clone)]
pub struct GraphQL {
    factory: RepositoryFactory,
}

impl GraphQL {
    pub fn sdl() -> String {
        MySchema::sdl()
    }

    pub fn schema() -> MySchema {
        Schema::new(Query, Mutation, EmptySubscription)
    }

    pub fn new(factory: RepositoryFactory) -> Self {
        GraphQL { factory }
    }

    pub async fn query(&self, schema: &MySchema, req: Request) -> Response {
        let repos = match self.factory.create().await {
            Ok(repos) => repos,
            Err(_) => {
                let err = ServerError::new("Unable to connect to DB");
                return Response::from_errors(vec![err]);
            }
        };

        let data = ContextData::new(repos);
        schema.execute(req.data(data)).await
    }
}

pub struct ContextData {
    pub repos: RepositorySetImpl,
    pub me: Option<AuthenticatedUser>,
}

impl ContextData {
    fn new(repos: RepositorySetImpl) -> Self {
        ContextData { repos, me: None }
    }
}
