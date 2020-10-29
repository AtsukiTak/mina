use super::{objects::user::GQLUser, schema::Params};
use async_graphql::{Context, Error, Object};
use mina_domain::{user::UserRepository as _, RepositorySet as _};

pub struct Query;

#[Object]
impl Query {
    async fn user(&self, context: &Context<'_>, id: String) -> Result<GQLUser, Error> {
        let mut repos = context.data::<Params>()?.lock_repos().await;
        repos
            .user_repo()
            .find_by_id(id)
            .await
            .map_err(Error::from)
            .map(GQLUser::from)
    }
}
