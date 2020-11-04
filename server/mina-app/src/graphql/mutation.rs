use super::{objects::user::GQLUser, ContextData};
use async_graphql::{Context, Error, Object, SimpleObject};

pub struct Mutation;

#[Object]
impl Mutation {
    async fn signup_as_anonymous(&self, context: &Context<'_>) -> Result<UserAndSecret, Error> {
        let repos = context.data::<ContextData>()?.repos();

        mina_usecase::signup_as_anonymous(repos)
            .await
            .map_err(Error::from)
            .map(|res| UserAndSecret {
                user: GQLUser::from(res.user),
                secret: res.secret,
            })
    }

    async fn send_partner_request(
        &self,
        context: &Context<'_>,
        to_user_id: String,
    ) -> Result<&'static str, Error> {
        let data = &context.data::<ContextData>()?;
        let me = data.me_or_err()?;

        let _ = mina_usecase::send_partner_request(to_user_id, me, data.repos())
            .await
            .map_err(Error::from)?;

        Ok("success")
    }
}

#[derive(SimpleObject)]
struct UserAndSecret {
    user: GQLUser,
    secret: String,
}
