use super::auth::AuthenticatedUser;
use mina_domain::{
    partner_request::{PartnerRequest, PartnerRequestRepository as _},
    user::{UserId, UserRepository as _},
    RepositorySet,
};
use rego::Error;
use std::convert::TryFrom as _;

pub async fn send_partner_request<R>(
    to_user_id: String,
    me: &AuthenticatedUser,
    repos: &R,
) -> Result<PartnerRequest, Error>
where
    R: RepositorySet,
{
    let to_user = repos
        .user_repo()
        .find_by_id(&UserId::try_from(to_user_id)?)
        .await?;

    let req = PartnerRequest::new(me.as_ref(), &to_user)?;
    repos.partner_request_repo().create(&req).await?;
    Ok(req)
}
