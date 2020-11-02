use super::User;
use rego::Error;

#[async_trait::async_trait]
pub trait UserRepository {
    async fn find_by_id(&self, user_id: &str) -> Result<User, Error>;

    async fn create(&self, user: &User) -> Result<(), Error>;

    async fn update(&self, user: &User) -> Result<(), Error>;
}
