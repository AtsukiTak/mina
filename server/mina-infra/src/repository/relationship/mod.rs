mod pg;

use self::pg::SnapshotHash;
use super::PgClient;
use mina_domain::{
    relationship::{Relationship, RelationshipId, RelationshipRepository},
    user::UserId,
};
use rego::Error;
use std::{collections::HashMap, ops::DerefMut};
use tokio::sync::Mutex;

pub struct RelationshipRepositoryImpl {
    client: PgClient,
    // 楽観ロックのためsnapshot_hashを保持しておく
    // relationship_idとsnapshot_hashのペア
    hash_store: Mutex<HashMap<RelationshipId, SnapshotHash>>,
}

impl RelationshipRepositoryImpl {
    pub fn new(client: PgClient) -> Self {
        RelationshipRepositoryImpl {
            client,
            hash_store: Mutex::new(HashMap::new()),
        }
    }
}

#[async_trait::async_trait]
impl RelationshipRepository for RelationshipRepositoryImpl {
    async fn find_of_user(&self, user_id: &UserId) -> Result<Vec<Relationship>, Error> {
        let records =
            pg::load_related_to_user(self.client.lock().await.deref_mut(), user_id.as_str())
                .await
                .map_err(Error::internal)?;

        // hash_storeの更新
        for (relationship, snapshot_hash) in records.iter() {
            self.hash_store
                .lock()
                .await
                .insert(*relationship.id(), *snapshot_hash);
        }

        Ok(records
            .into_iter()
            .map(|(relationship, _)| relationship)
            .collect())
    }

    async fn create(&self, relationship: &Relationship) -> Result<(), Error> {
        let snapshot_id = pg::insert(self.client.lock().await.deref_mut(), relationship)
            .await
            .map_err(Error::internal)?;

        self.hash_store
            .lock()
            .await
            .insert(*relationship.id(), snapshot_id);

        Ok(())
    }

    async fn update(&self, relationship: &Relationship) -> Result<(), Error> {
        let snapshot_hash = self
            .hash_store
            .lock()
            .await
            .get(relationship.id())
            .copied()
            .unwrap(); // 必ずhash_storeにあるはず

        let new_snapshot_hash = pg::update(
            self.client.lock().await.deref_mut(),
            relationship,
            &snapshot_hash,
        )
        .await
        .map_err(Error::internal)?;

        self.hash_store
            .lock()
            .await
            .insert(*relationship.id(), new_snapshot_hash);

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repository::test_utils::connect_isolated_db;
    use chrono::{NaiveTime, Weekday};
    use mina_domain::user::User;

    #[tokio::test]
    async fn create_and_find_and_update() {
        pretty_env_logger::init();

        let client = PgClient::new(connect_isolated_db().await);
        let repo = RelationshipRepositoryImpl::new(client);
        let user_a = User::new_anonymous().unwrap().0;
        let user_b = User::new_anonymous().unwrap().0;
        let mut relationship = Relationship::new(user_a.id().clone(), user_b.id().clone()).unwrap();

        // create
        repo.create(&relationship).await.unwrap();

        // find
        let found_a = repo.find_of_user(user_a.id()).await.unwrap();
        assert_eq!(found_a, vec![relationship.clone()]);
        let found_b = repo.find_of_user(user_b.id()).await.unwrap();
        assert_eq!(found_b, vec![relationship.clone()]);

        // update
        relationship.add_call_schedule(vec![Weekday::Sun], NaiveTime::from_hms(10, 0, 0));
        repo.update(&relationship).await.unwrap();

        // find
        let found = repo.find_of_user(user_a.id()).await.unwrap();
        assert_eq!(found, vec![relationship.clone()]);
    }
}
