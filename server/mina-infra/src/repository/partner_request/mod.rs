mod pg;

use self::pg::{insert, load};
use super::PgClient;
use mina_domain::partner_request::{PartnerRequest, PartnerRequestRepository};
use rego::Error;
use std::ops::DerefMut;
use uuid::Uuid;

/// # 以下の非機能要件は必要ない
/// - 楽観ロック
/// - dataloader
/// - cache
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

    async fn create(&self, req: &PartnerRequest) -> Result<(), Error> {
        insert(self.client.lock().await.deref_mut(), req).await
    }
}
