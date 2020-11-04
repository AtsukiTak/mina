use crate::auth::AuthenticatedUser;
use mina_domain::{
    partner_request::PartnerRequestRepository as _,
    user::{User, UserRepository as _},
    RepositorySet,
};
use rego::Error;
use uuid::Uuid;

pub struct Params {
    pub partner_request_id: Uuid,
    pub me: AuthenticatedUser,
}

pub async fn accept_partner_request<R>(
    Params {
        partner_request_id,
        mut me,
    }: Params,
    repos: &R,
) -> Result<(), Error>
where
    R: RepositorySet,
{
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

    let mut other = repos
        .user_repo()
        .find_by_id(partner_req.from_user().as_str())
        .await?;

    // Userの更新
    User::become_partner_each_other(me.as_mut(), &mut other)?;

    repos.user_repo().update(me.as_ref()).await?;
    repos.user_repo().update(&other).await?;

    Ok(())
}
