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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repository::test_utils::connect_isolated_db;
    use mina_domain::user::User;

    #[tokio::test]
    async fn create_and_find() {
        pretty_env_logger::init();

        let client = PgClient::new(connect_isolated_db().await);
        let repo = RelationshipRepositoryImpl::new(client);
        let user_a = User::new_anonymous().unwrap().0;
        let user_b = User::new_anonymous().unwrap().0;
        let relationship = Relationship::new(user_a.id().clone(), user_b.id().clone()).unwrap();

        // create
        repo.create(&relationship).await.unwrap();

        // find
        let found_a = repo.find_of_user(user_a.id()).await.unwrap();
        assert_eq!(found_a, vec![relationship.clone()]);
        let found_b = repo.find_of_user(user_b.id()).await.unwrap();
        assert_eq!(found_b, vec![relationship.clone()]);
    }
}
