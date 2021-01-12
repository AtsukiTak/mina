use super::auth::AuthenticatedUser;
use mina_domain::{
    user::{User, UserRepository as _},
    RepositorySet,
};
use rego::Error;

pub async fn set_apple_push_token<R>(
    apple_push_token: String,
    me: &AuthenticatedUser,
    repos: &R,
) -> Result<User, Error>
where
    R: RepositorySet,
{
    let mut user = me.as_ref().clone();

    user.set_apple_push_token(apple_push_token);

    // Relationshipの更新
    repos.user_repo().update(&user).await?;

    Ok(user)
}
