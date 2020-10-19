use super::{User, UserId};
use rego::Error;
use std::collections::HashMap;

#[async_trait::async_trait]
pub trait UserRepository {
    async fn find_by_ids(&mut self, user_id: Vec<String>) -> Result<HashMap<UserId, User>, Error>;

    async fn save(&mut self, user: User) -> Result<User, Error>;
}
