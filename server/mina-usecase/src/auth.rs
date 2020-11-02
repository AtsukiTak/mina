use mina_domain::{
    user::{UserId, UserRepository as _},
    RepositorySet,
};
use rego::Error;

pub struct AuthItem {
    user_id: String,
    try_secret: String,
}

pub async fn authenticate<R>(item: &AuthItem, repos: &R) -> Result<UserId, Error>
where
    R: RepositorySet,
{
    let user = repos
        .user_repo()
        .find_by_id(item.user_id.clone())
        .await
        .map_err(|e| match e {
            Error::NotFound { .. } => Error::AuthFailed,
            e => e,
        })?;

    user.secret_cred().verify(item.try_secret.as_str())?;

    Ok(user.id().clone())
}
