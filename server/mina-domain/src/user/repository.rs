use super::User;
use rego::Error;

#[async_trait::async_trait]
pub trait UserRepository {
    async fn find_by_id(&mut self, user_id: String) -> Result<User, Error>;

    async fn create(&mut self, user: User) -> Result<User, Error>;

    // async fn update(&mut self, user: User) -> Result<User, Error>;
}
