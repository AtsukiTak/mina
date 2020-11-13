use chrono::Utc;
use mina_domain::{
    relationship::{Call, RelationshipRepository as _},
    RepositorySet,
};
use rego::Error;

pub async fn invoke_ready_calls<R>(repos: &R) -> Result<Vec<Call>, Error>
where
    R: RepositorySet,
{
    let now = Utc::now();

    // readyなcallがあるrelationshipの一覧
    let mut relationships = repos
        .relationship_repo()
        .find_all()
        .await?
        .into_iter()
        .filter(|rel| rel.is_call_process_startable_at(now))
        .collect::<Vec<_>>();

    let calls = relationships
        .iter_mut()
        .map(|rel| rel.start_call_process_at(now).unwrap().clone())
        .collect::<Vec<_>>();

    repos
        .relationship_repo()
        .update_many(&relationships)
        .await?;

    Ok(calls)
}
