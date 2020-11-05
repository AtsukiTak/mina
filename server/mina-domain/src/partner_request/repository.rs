use super::PartnerRequest;
use rego::Error;
use uuid::Uuid;

#[async_trait::async_trait]
pub trait PartnerRequestRepository {
    async fn find_by_id(&self, id: &Uuid) -> Result<PartnerRequest, Error>;

    async fn find_user_received(&self, user_id: &str) -> Result<Vec<PartnerRequest>, Error>;

    async fn create(&self, req: &PartnerRequest) -> Result<(), Error>;
}
