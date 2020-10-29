pub mod mutation;
pub mod objects;
pub mod query;

use self::{mutation::Mutation, query::Query};
use async_graphql::{EmptySubscription, Request, Response, Schema, ServerError};
use mina_infra::repository::{RepositoryFactory, RepositorySetImpl};

pub struct GraphQL {
    schema: Schema<Query, Mutation, EmptySubscription>,
    factory: RepositoryFactory,
}

impl GraphQL {
    pub fn sdl() -> String {
        Schema::<Query, Mutation, EmptySubscription>::sdl()
    }

    pub async fn new(db_uri: &str) -> Self {
        GraphQL {
            schema: Schema::new(Query, Mutation, EmptySubscription),
            factory: RepositoryFactory::new(db_uri).await,
        }
    }

    pub async fn query(&self, req: Request) -> Response {
        let repos = match self.factory.create().await {
            Ok(repos) => repos,
            Err(_) => {
                let err = ServerError::new("Unable to connect to DB");
                return Response::from_errors(vec![err]);
            }
        };
        let params = Params::new(repos);
        self.schema.execute(req.data(params)).await
    }
}

pub struct Params {
    pub repos: RepositorySetImpl,
}

impl Params {
    fn new(repos: RepositorySetImpl) -> Self {
        Params { repos }
    }
}
