use super::{super::ContextData, GQLMyRelationship, GQLPartnerRequest};
use async_graphql::{Context, Error, Object};
use mina_domain::{
    partner_request::PartnerRequestRepository as _, relationship::RelationshipRepository as _,
    RepositorySet as _,
};
use mina_usecase::user::auth::AuthenticatedUser;

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

    async fn relationships(&self, context: &Context<'_>) -> Result<Vec<GQLMyRelationship>, Error> {
        let data = context.data::<ContextData>()?;

        Ok(data
            .repos()
            .relationship_repo()
            .find_of_user(self.me.as_ref().id())
            .await
            .map_err(Error::from)?
            .into_iter()
            .map(|relationship| GQLMyRelationship::from((self.me.clone(), relationship)))
            .collect())
    }

    async fn received_partner_requests(
        &self,
        context: &Context<'_>,
    ) -> Result<Vec<GQLPartnerRequest>, Error> {
        let data = context.data::<ContextData>()?;

        Ok(data
            .repos()
            .partner_request_repo()
            .find_user_received(self.me.as_ref().id().as_str())
            .await
            .map_err(Error::from)?
            .into_iter()
            .map(GQLPartnerRequest::from)
            .collect())
    }
}

impl From<AuthenticatedUser> for GQLMe {
    fn from(me: AuthenticatedUser) -> Self {
        GQLMe { me }
    }
}
