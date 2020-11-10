use crate::auth::AuthenticatedUser;
use mina_domain::{
    partner_request::PartnerRequestRepository as _,
    relationship::{Relationship, RelationshipRepository as _},
    RepositorySet,
};
use rego::Error;
use uuid::Uuid;

pub async fn accept_partner_request<R>(
    partner_request_id: Uuid,
    me: &AuthenticatedUser,
    repos: &R,
) -> Result<(), Error>
where
    R: RepositorySet,
{
    // idからpartner_requestを検索
    let partner_req = repos
        .partner_request_repo()
        .find_by_id(&partner_request_id)
        .await?;

    // 正当性チェック
    if !partner_req.is_valid() {
        return Err(Error::bad_input("Specified partner request is expired"));
    } else if partner_req.to_user() != me.as_ref().id() {
        return Err(Error::bad_input("Specified partner request is not for you"));
    }

    // Relationshipの生成
    let relationship =
        Relationship::new(me.as_ref().id().clone(), partner_req.from_user().clone())?;
    repos.relationship_repo().create(&relationship).await?;

    Ok(())
}
