use chrono::Utc;
use mina_domain::{
    relationship::{Call, RelationshipRepository as _},
    user::{User, UserId, UserRepository as _},
    RepositorySet,
};
use rego::Error;
use std::collections::HashMap;

pub struct Res {
    pub calls: Vec<Call>,
    pub users: HashMap<UserId, User>,
}

pub async fn invoke_ready_calls<R>(repos: &R) -> Result<Res, Error>
where
    R: RepositorySet,
{
    let now = Utc::now();

    // readyなcallがあるrelationshipの一覧を取得
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

    // 関連するUser一覧を取得
    let mut user_ids = Vec::with_capacity(relationships.len() * 2);
    for relationship in relationships.iter() {
        let [u1, u2] = relationship.users();
        user_ids.push(u1.clone());
        user_ids.push(u2.clone());
    }
    let users = repos
        .user_repo()
        .find_by_ids(user_ids.as_slice())
        .await
        .into_iter()
        .filter_map(|(id, res)| res.ok().map(|user| (id, user)))
        .collect();

    // 更新したrelationshipの保存
    repos
        .relationship_repo()
        .update_many(relationships.as_slice())
        .await?;

    Ok(Res { calls, users })
}
