use super::Call;
use rego::Error;
use uuid::Uuid;

#[async_trait::async_trait]
pub trait CallRepository {
    async fn find_by_id(&self, id: &Uuid) -> Result<Call, Error>;

    async fn create(&self, call: &Call) -> Result<(), Error>;

    async fn update(&self, call: &Call) -> Result<(), Error>;
}
