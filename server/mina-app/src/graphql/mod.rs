pub mod mutation;
pub mod objects;
pub mod query;

use self::{mutation::Mutation, query::Query};
use async_graphql::{EmptySubscription, Request, Response, Schema, ServerError};
use headers::{authorization::Basic, Authorization};
use mina_infra::repository::{RepositoryFactory, RepositorySetImpl};
use mina_usecase::auth::{authenticate, AuthenticatedUser};

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

    pub async fn query(
        &self,
        schema: &MySchema,
        req: Request,
        auth: Option<Authorization<Basic>>,
    ) -> Response {
        // RepositorySetの作成
        let repos = match self.factory.create().await {
            Ok(repos) => repos,
            Err(_) => {
                let err = ServerError::new("Unable to connect to DB");
                return Response::from_errors(vec![err]);
            }
        };

        // Userの認証
        let me_opt = match auth {
            Some(Authorization(basic)) => {
                match authenticate(basic.username(), basic.password(), &repos).await {
                    Ok(me) => Some(me),
                    Err(_) => {
                        let err = ServerError::new("Unauthorized");
                        return Response::from_errors(vec![err]);
                    }
                }
            }
            None => None,
        };

        // 実行
        let data = ContextData::new(repos, me_opt);
        schema.execute(req.data(data)).await
    }
}

pub struct ContextData {
    pub repos: RepositorySetImpl,
    pub me: Option<AuthenticatedUser>,
}

impl ContextData {
    fn new(repos: RepositorySetImpl, me: Option<AuthenticatedUser>) -> Self {
        ContextData { repos, me }
    }
}
