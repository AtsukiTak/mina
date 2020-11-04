use crate::auth::AuthenticatedUser;
use mina_domain::{
    partner_request::{PartnerRequest, PartnerRequestRepository as _},
    user::UserRepository as _,
    RepositorySet,
};
use rego::Error;

pub struct Params {
    to_user_id: String,
    me: AuthenticatedUser,
}

pub async fn publish_partner_request<R>(
    Params { to_user_id, me }: Params,
    repos: &R,
) -> Result<PartnerRequest, Error>
where
    R: RepositorySet,
{
    let to_user = repos.user_repo().find_by_id(to_user_id.as_str()).await?;

    let req = PartnerRequest::new(me.as_ref(), &to_user)?;
    repos.partner_request_repo().create(&req).await?;
    Ok(req)
}
