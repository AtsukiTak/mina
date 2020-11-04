use mina_domain::{
    user::{User, UserRepository as _},
    RepositorySet,
};
use rego::Error;

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

pub async fn authenticate<R>(
    user_id: &str,
    password: &str,
    repos: &R,
) -> Result<AuthenticatedUser, Error>
where
    R: RepositorySet,
{
    let user = repos
        .user_repo()
        .find_by_id(user_id)
        .await
        .map_err(|e| match e {
            Error::NotFound { .. } => Error::AuthFailed,
            e => e,
        })?;

    user.secret_cred().verify(password)?;

    Ok(AuthenticatedUser(user))
}
