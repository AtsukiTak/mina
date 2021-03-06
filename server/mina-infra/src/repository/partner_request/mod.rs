mod pg;

use self::pg::{insert, load, load_user_received};
use super::PgClient;
use mina_domain::partner_request::{PartnerRequest, PartnerRequestRepository};
use rego::Error;
use std::ops::DerefMut;
use uuid::Uuid;

/// # 以下の非機能要件は必要ない
/// - 楽観ロック
/// - dataloader
/// - cache
///
/// # Note
/// - `update` メソッドが導入されたら、楽観ロックを導入する
/// - 同じidのモデルが複数回queryされるならcacheを導入する
/// - 複数回repositoryメソッドが呼び出されるなら、dataloaderを導入する
pub struct PartnerRequestRepositoryImpl {
    client: PgClient,
}

impl PartnerRequestRepositoryImpl {
    pub fn new(client: PgClient) -> PartnerRequestRepositoryImpl {
        PartnerRequestRepositoryImpl { client }
    }
}

#[async_trait::async_trait]
impl PartnerRequestRepository for PartnerRequestRepositoryImpl {
    async fn find_by_id(&self, id: &Uuid) -> Result<PartnerRequest, Error> {
        load(self.client.lock().await.deref_mut(), id).await
    }

    async fn find_user_received(&self, user_id: &str) -> Result<Vec<PartnerRequest>, Error> {
        load_user_received(self.client.lock().await.deref_mut(), user_id).await
    }

    async fn create(&self, req: &PartnerRequest) -> Result<(), Error> {
        insert(self.client.lock().await.deref_mut(), req).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repository::test_utils::connect_isolated_db;
    use mina_domain::user::User;

    #[tokio::test]
    async fn create_and_find() {
        let client = PgClient::new(connect_isolated_db().await);

        let repo1 = PartnerRequestRepositoryImpl::new(client.clone());
        let user1 = User::new_anonymous().unwrap().0;
        let user2 = User::new_anonymous().unwrap().0;
        let req = PartnerRequest::new(&user1, &user2).unwrap();
        repo1.create(&req).await.unwrap();

        let repo2 = PartnerRequestRepositoryImpl::new(client.clone());
        let found = repo2.find_by_id(req.id()).await.unwrap();
        assert_eq!(found, req);
    }
}
