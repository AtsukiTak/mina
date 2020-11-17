use super::{User, UserId};
use rego::Error;
use std::{collections::HashMap, slice};

#[async_trait::async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_ids(&self, user_ids: &[UserId]) -> HashMap<UserId, Result<User, Error>>;

    async fn find_by_id(&self, user_id: &UserId) -> Result<User, Error> {
        self.find_by_ids(slice::from_ref(user_id))
            .await
            .get(user_id)
            .unwrap()
            .clone()
    }

    async fn create(&self, user: &User) -> Result<(), Error>;

    async fn update(&self, user: &User) -> Result<(), Error>;
}
