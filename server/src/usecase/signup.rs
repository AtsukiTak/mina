use crate::domain::user::{User, UserRepository};
use rego::Error;

pub struct Params {
    name: String,
}

pub async fn signup<R>(Params { name }: Params, repo: &mut R) -> Result<User, Error>
where
    R: UserRepository,
{
    let user = User::new(name)?;
    repo.save(user).await
}
