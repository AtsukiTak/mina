use mina_domain::{
    user::{User, UserRepository as _},
    RepositorySet,
};
use rego::Error;

pub struct AuthItem {
    user_id: String,
    try_secret: String,
}

pub struct AuthenticatedUser(User);

impl AsRef<User> for AuthenticatedUser {
    fn as_ref(&self) -> &User {
        &self.0
    }
}

impl AsMut<User> for AuthenticatedUser {
    fn as_mut(&mut self) -> &mut User {
        &mut self.0
    }
}

impl Into<User> for AuthenticatedUser {
    fn into(self) -> User {
        self.0
    }
}

pub async fn authenticate<R>(item: &AuthItem, repos: &R) -> Result<AuthenticatedUser, Error>
where
    R: RepositorySet,
{
    let user = repos
        .user_repo()
        .find_by_id(item.user_id.as_str())
        .await
        .map_err(|e| match e {
            Error::NotFound { .. } => Error::AuthFailed,
            e => e,
        })?;

    user.secret_cred().verify(item.try_secret.as_str())?;

    Ok(AuthenticatedUser(user))
}
