use crate::auth::{authenticate, AuthItem};
use mina_domain::{
    partner_request::{PartnerRequest, PartnerRequestRepository as _},
    user::UserRepository as _,
    RepositorySet,
};
use rego::Error;

pub struct Params {
    to_user_id: String,
    auth: AuthItem,
}

pub async fn publish_partner_request<R>(params: Params, repos: &R) -> Result<PartnerRequest, Error>
where
    R: RepositorySet,
{
    let me = authenticate(&params.auth, repos).await?;

    let to_user = repos
        .user_repo()
        .find_by_id(params.to_user_id.as_str())
        .await?;

    let req = PartnerRequest::new(&me, &to_user)?;
    repos.partner_request_repo().create(&req).await?;
    Ok(req)
}
