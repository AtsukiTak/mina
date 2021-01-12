use super::auth::AuthenticatedUser;
use mina_domain::{user::UserRepository as _, RepositorySet};
use rego::Error;

pub async fn set_apple_push_token<R>(
    apple_push_token: String,
    mut me: AuthenticatedUser,
    repos: &R,
) -> Result<AuthenticatedUser, Error>
where
    R: RepositorySet,
{
    me.as_mut().set_apple_push_token(apple_push_token);

    // Relationshipの更新
    repos.user_repo().update(me.as_ref()).await?;

    Ok(me)
}
