use super::{objects::user::GQLUser, ContextData};
use async_graphql::{Context, Error, Object};
use mina_domain::{user::UserRepository as _, RepositorySet as _};

pub struct Query;

#[Object]
impl Query {
    /// ユーザーをIDで検索する
    async fn user(&self, context: &Context<'_>, id: String) -> Result<GQLUser, Error> {
        context
            .data::<ContextData>()?
            .repos()
            .user_repo()
            .find_by_id(id.as_str())
            .await
            .map_err(Error::from)
            .map(GQLUser::from)
    }
}
