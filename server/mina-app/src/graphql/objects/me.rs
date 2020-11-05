use super::{super::ContextData, GQLUser};
use async_graphql::{Context, Error, Object};
use futures::stream::{FuturesUnordered, TryStreamExt};
use mina_domain::{user::UserRepository as _, RepositorySet as _};
use mina_usecase::auth::AuthenticatedUser;

pub struct GQLMe {
    me: AuthenticatedUser,
}

#[Object(name = "Me")]
impl GQLMe {
    async fn id(&self) -> &str {
        self.me.as_ref().id().as_str()
    }

    async fn name(&self) -> Option<&str> {
        self.me.as_ref().name()
    }

    async fn partners(&self, context: &Context<'_>) -> Result<Vec<GQLUser>, Error> {
        let data = context.data::<ContextData>()?;
        let user_repo = data.repos().user_repo();

        self.me
            .as_ref()
            .partners()
            .iter()
            .map(|id| user_repo.find_by_id(id))
            .collect::<FuturesUnordered<_>>()
            .map_ok(GQLUser::from)
            .try_collect::<Vec<GQLUser>>()
            .await
            .map_err(Error::from)
    }
}

impl From<AuthenticatedUser> for GQLMe {
    fn from(me: AuthenticatedUser) -> Self {
        GQLMe { me }
    }
}
