use super::Relationship;
use crate::user::UserId;
use rego::Error;

#[async_trait::async_trait]
pub trait RelationshipRepository {
    async fn find_of_user(&self, user_id: &UserId) -> Result<Vec<Relationship>, Error>;

    async fn find_all(&self) -> Result<Vec<Relationship>, Error>;

    async fn create(&self, relationship: &Relationship) -> Result<(), Error>;

    async fn update(&self, relationship: &Relationship) -> Result<(), Error>;

    async fn update_many(&self, relationships: &[Relationship]) -> Result<(), Error>;
}
