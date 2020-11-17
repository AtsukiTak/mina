use super::{
    objects::{GQLMe, GQLUser},
    ContextData,
};
use async_graphql::{Context, Error, Object};
use mina_domain::{
    user::{UserId, UserRepository as _},
    RepositorySet as _,
};
use std::{convert::TryFrom as _, ops::Deref};

pub struct Query;

#[Object]
impl Query {
    async fn me(&self, context: &Context<'_>) -> Result<GQLMe, Error> {
        let data = context.data::<ContextData>()?;
        let me = data.me_or_err()?;

        Ok(GQLMe::from(me.deref().clone()))
    }

    /// ユーザーをIDで検索する
    async fn user(&self, context: &Context<'_>, id: String) -> Result<GQLUser, Error> {
        context
            .data::<ContextData>()?
            .repos()
            .user_repo()
            .find_by_id(&UserId::try_from(id).map_err(Error::from)?)
            .await
            .map_err(Error::from)
            .map(GQLUser::from)
    }
}
