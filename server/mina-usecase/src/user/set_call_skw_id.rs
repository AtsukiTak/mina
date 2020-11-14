use super::auth::AuthenticatedUser;
use mina_domain::{relationship::RelationshipRepository as _, RepositorySet};
use rego::Error;
use uuid::Uuid;

pub async fn set_call_skw_id<R>(
    relationship_id: Uuid,
    skw_id: String,
    me: &AuthenticatedUser,
    repos: &R,
) -> Result<Option<String>, Error>
where
    R: RepositorySet,
{
    // `find_by_id` メソッドを用意するのが面倒
    // （メンテコスト上がりそう）なので
    // `find_of_user` メソッドを再利用している
    let mut relationship = repos
        .relationship_repo()
        .find_of_user(me.as_ref().id())
        .await?
        .into_iter()
        .find(|rel| *rel.id().as_ref() == relationship_id)
        .ok_or_else(|| Error::bad_input("specified relationship is not found"))?;

    let partner_skw_id = relationship
        .set_call_skw_id(me.as_ref().id(), skw_id)?
        .map(String::from);

    // Relationshipの更新
    repos.relationship_repo().update(&relationship).await?;

    Ok(partner_skw_id)
}
