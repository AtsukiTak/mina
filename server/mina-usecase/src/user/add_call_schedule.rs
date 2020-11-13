use super::auth::AuthenticatedUser;
use chrono::{NaiveTime, Weekday};
use mina_domain::{
    relationship::{Relationship, RelationshipRepository as _},
    RepositorySet,
};
use rego::Error;
use uuid::Uuid;

pub async fn add_call_schedule<R>(
    relationship_id: Uuid,
    weekdays: impl IntoIterator<Item = Weekday>,
    time: NaiveTime,
    me: &AuthenticatedUser,
    repos: &R,
) -> Result<Relationship, Error>
where
    R: RepositorySet,
{
    // `find_by_id` メソッドを用意するのが面倒なので
    // `find_of_user` メソッドを再利用している
    let mut relationship = repos
        .relationship_repo()
        .find_of_user(me.as_ref().id())
        .await?
        .into_iter()
        .find(|rel| *rel.id().as_ref() == relationship_id)
        .ok_or_else(|| Error::bad_input("specified relationship not found"))?;

    relationship.add_call_schedule(weekdays, time);

    repos.relationship_repo().update(&relationship).await?;

    Ok(relationship)
}
