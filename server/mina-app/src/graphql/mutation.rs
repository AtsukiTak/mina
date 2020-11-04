use super::{objects::user::GQLUser, ContextData};
use async_graphql::{Context, Error, Object, SimpleObject};

pub struct Mutation;

#[Object]
impl Mutation {
    async fn signup_as_anonymous(&self, context: &Context<'_>) -> Result<UserAndSecret, Error> {
        let repos = &context.data::<ContextData>()?.repos;

        mina_usecase::signup::signup_as_anonymous(repos)
            .await
            .map_err(Error::from)
            .map(|res| UserAndSecret {
                user: GQLUser::from(res.user),
                secret: res.secret,
            })
    }
}

#[derive(SimpleObject)]
struct UserAndSecret {
    user: GQLUser,
    secret: String,
}
