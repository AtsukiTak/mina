pub mod mutation;
pub mod objects;
pub mod query;

use self::{mutation::Mutation, query::Query};
use async_graphql::{EmptySubscription, Error, Request, Response, Schema, ServerError};
use headers::{authorization::Basic, Authorization};
use mina_infra::repository::{RepositoryFactory, RepositorySetImpl};
use mina_usecase::user::auth::{authenticate, AuthenticatedUser};

pub type MySchema = Schema<Query, Mutation, EmptySubscription>;

#[derive(Clone)]
pub struct GraphQL {
    factory: RepositoryFactory,
}

impl GraphQL {
    pub fn sdl() -> String {
        Self::schema().sdl()
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
    repos: RepositorySetImpl,
    me: Option<AuthenticatedUser>,
}

impl ContextData {
    fn new(repos: RepositorySetImpl, me: Option<AuthenticatedUser>) -> Self {
        ContextData { repos, me: me }
    }

    pub fn repos(&self) -> &RepositorySetImpl {
        &self.repos
    }

    pub fn me(&self) -> Option<&AuthenticatedUser> {
        self.me.as_ref()
    }

    pub fn me_or_err(&self) -> Result<&AuthenticatedUser, Error> {
        self.me().ok_or_else(|| Error::new("Unauthorized"))
    }
}
