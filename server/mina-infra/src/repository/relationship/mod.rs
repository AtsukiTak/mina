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
use uuid::Uuid;

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

    async fn find_by_ids(&self, ids: &[Uuid]) -> Result<Vec<Relationship>, Error> {
        let records = pg::load_many(self.client.lock().await.deref_mut(), ids)
            .await
            .map_err(Error::internal)?;

        // hash_storeの更新
        let mut hash_store = self.hash_store.lock().await;
        for (relationship, snapshot_hash) in records.iter() {
            hash_store.insert(*relationship.id(), *snapshot_hash);
        }
        drop(hash_store);

        Ok(records
            .into_iter()
            .map(|(relationship, _)| relationship)
            .collect())
    }
}

#[async_trait::async_trait]
impl RelationshipRepository for RelationshipRepositoryImpl {
    async fn find_of_user(&self, user_id: &UserId) -> Result<Vec<Relationship>, Error> {
        let ids =
            pg::load_ids_related_to_user(self.client.lock().await.deref_mut(), user_id.as_str())
                .await?;
        self.find_by_ids(ids.as_slice()).await
    }

    async fn find_all(&self) -> Result<Vec<Relationship>, Error> {
        let ids = pg::load_ids_of_all(self.client.lock().await.deref_mut()).await?;
        self.find_by_ids(ids.as_slice()).await
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

    async fn update_many(&self, relationships: &[Relationship]) -> Result<(), Error> {
        // snapshot_hashの取得
        let hash_store = self.hash_store.lock().await;
        let relationships = relationships
            .iter()
            .map(|rel| (rel, hash_store.get(rel.id()).copied().expect("このRepositoryからloadしていないRelationshipの更新処理を行うことはできません")))
            .collect::<Vec<_>>();
        drop(hash_store);

        // DBのupdate
        let updated_list = pg::update_many(
            self.client.lock().await.deref_mut(),
            relationships.as_slice(),
        )
        .await
        .map_err(Error::internal)?;

        // hash_storeの更新
        let mut hash_store = self.hash_store.lock().await;
        for (rel_id, new_snap_hash) in updated_list {
            hash_store.insert(rel_id, new_snap_hash);
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repository::test_utils::connect_isolated_db;
    use chrono::{NaiveTime, Utc, Weekday};
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
        relationship.add_call_schedule_at(
            vec![Weekday::Sun],
            NaiveTime::from_hms(10, 0, 0),
            Utc::now(),
        );
        repo.update(&relationship).await.unwrap();

        // find
        let found = repo.find_of_user(user_a.id()).await.unwrap();
        assert_eq!(found, vec![relationship.clone()]);
    }
}
