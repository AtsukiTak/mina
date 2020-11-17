use super::{super::ContextData, GQLUser};
use async_graphql::{Context, Error, Object};
use mina_domain::{partner_request::PartnerRequest, user::UserRepository as _, RepositorySet as _};
use uuid::Uuid;

pub struct GQLPartnerRequest {
    req: PartnerRequest,
}

#[Object(name = "PartnerRequest")]
impl GQLPartnerRequest {
    async fn id(&self) -> &Uuid {
        self.req.id()
    }

    async fn from(&self, context: &Context<'_>) -> Result<GQLUser, Error> {
        let data = context.data::<ContextData>()?;

        let from_user = data
            .repos()
            .user_repo()
            .find_by_id(self.req.from_user())
            .await
            .map_err(Error::from)?;

        Ok(GQLUser::from(from_user))
    }

    async fn to(&self, context: &Context<'_>) -> Result<GQLUser, Error> {
        let data = context.data::<ContextData>()?;

        let from_user = data
            .repos()
            .user_repo()
            .find_by_id(self.req.to_user())
            .await
            .map_err(Error::from)?;

        Ok(GQLUser::from(from_user))
    }

    async fn is_valid(&self) -> bool {
        self.req.is_valid()
    }
}

impl From<PartnerRequest> for GQLPartnerRequest {
    fn from(req: PartnerRequest) -> Self {
        GQLPartnerRequest { req }
    }
}
