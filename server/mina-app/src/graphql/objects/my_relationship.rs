use super::{super::ContextData, GQLUser};
use async_graphql::{Context, Error, Object};
use mina_domain::{
    relationship::{CallSchedule, Relationship},
    user::UserRepository as _,
    RepositorySet as _,
};
use mina_usecase::user::auth::AuthenticatedUser;
use uuid::Uuid;

pub struct GQLMyRelationship {
    me: AuthenticatedUser,
    relationship: Relationship,
}

pub struct GQLCallSchedule<'a> {
    schedule: &'a CallSchedule,
}

#[Object(name = "MyRelationship")]
impl GQLMyRelationship {
    async fn id(&self) -> &Uuid {
        self.relationship.id().as_ref()
    }

    async fn partner(&self, context: &Context<'_>) -> Result<GQLUser, Error> {
        let data = context.data::<ContextData>()?;

        let users = self.relationship.users();
        let partner_id = users
            .iter()
            .find(|id| *id != &self.me.as_ref().id())
            .unwrap();

        let partner = data
            .repos()
            .user_repo()
            .find_by_id(partner_id.as_str())
            .await?;

        Ok(GQLUser::from(partner))
    }

    async fn call_schedules<'a>(&'a self) -> Vec<GQLCallSchedule<'a>> {
        self.relationship
            .schedules()
            .iter()
            .map(|schedule| GQLCallSchedule { schedule })
            .collect()
    }
}

impl From<(AuthenticatedUser, Relationship)> for GQLMyRelationship {
    fn from((me, relationship): (AuthenticatedUser, Relationship)) -> Self {
        GQLMyRelationship { me, relationship }
    }
}

#[Object(name = "CallSchedule")]
impl<'a> GQLCallSchedule<'a> {
    async fn id(&self) -> &Uuid {
        self.schedule.id().as_ref()
    }

    /// "21:45" のようなフォーマットの文字列
    async fn time(&self) -> String {
        self.schedule.time().format("%H:%M").to_string()
    }

    /// "Mon,The,Thu,Fri" のようなコンマ区切りの文字列
    async fn weekdays(&self) -> String {
        self.schedule
            .weekdays()
            .iter()
            .map(|weekday| weekday.to_string())
            .collect::<Vec<_>>()
            .join(",")
    }
}
