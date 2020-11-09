mod pg;

use super::PgClient;
use mina_domain::{
    relationship::{Relationship, RelationshipRepository},
    user::UserId,
};
use rego::Error;
use std::ops::DerefMut;

pub struct RelationshipRepositoryImpl {
    client: PgClient,
}

impl RelationshipRepositoryImpl {
    pub fn new(client: PgClient) -> Self {
        RelationshipRepositoryImpl { client }
    }
}

#[async_trait::async_trait]
impl RelationshipRepository for RelationshipRepositoryImpl {
    async fn find_of_user(&self, user_id: &UserId) -> Result<Vec<Relationship>, Error> {
        pg::load_related_to_user(self.client.lock().await.deref_mut(), user_id.as_str()).await
    }

    async fn create(&self, relationship: &Relationship) -> Result<(), Error> {
        pg::insert(self.client.lock().await.deref_mut(), relationship).await
    }
}
