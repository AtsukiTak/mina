use crate::server::Config;
use chrono::Utc;
use futures::stream::{FuturesUnordered, StreamExt as _};
use mina_usecase::admin::invoke_ready_calls;
use rego::Error;
use serde::Serialize;
use uuid::Uuid;
use warp::{
    reply::{json, Json},
    Filter, Rejection,
};

pub fn route(config: Config) -> impl Filter<Extract = (Json,), Error = Rejection> + Clone {
    // GCPのCronでHeaderを設定したりするのが若干面倒なので
    // とりあえずエンドポイント名に乱数を入れることで
    // 最低限の認証を行っている
    warp::path!("cron" / "ULwEonqs" / "invoke_ready_calls")
        .and(warp::post())
        .and(config.to_filter())
        .and_then(move |config| async {
            Ok::<_, Rejection>(
                handler(config)
                    .await
                    .unwrap_or_else(|e| json(&format!("{:?}", e).as_str())),
            )
        })
}

#[derive(Serialize, Clone, Copy)]
struct PushPayload<'a> {
    call_id: Uuid,
    caller_id: &'a str,
    caller_name: &'a str,
}

async fn handler(config: Config) -> Result<Json, Error> {
    let repos = config.repos().await?;
    let push_client = config.push_client();
    let res = invoke_ready_calls(&repos).await?;

    let futures = FuturesUnordered::new();

    // push通知を送る
    for call in res.calls {
        let user1 = res.users.get(call.users()[0].user_id()).unwrap();
        let user2 = res.users.get(call.users()[1].user_id()).unwrap();

        let payload_for_user1 = PushPayload {
            call_id: *call.id().as_ref(),
            caller_id: user2.id().as_str(),
            caller_name: user2.name().unwrap_or(user2.id().as_str()),
        };

        let payload_for_user2 = PushPayload {
            call_id: *call.id().as_ref(),
            caller_id: user1.id().as_str(),
            caller_name: user1.name().unwrap_or(user1.id().as_str()),
        };

        let (u1_device_token, u2_device_token) =
            match (user1.apple_push_token(), user2.apple_push_token()) {
                (Some(token1), Some(token2)) => (token1, token2),
                _ => break,
            };

        let now = Utc::now();
        let fut1 = push_client.req(None, u1_device_token, now, payload_for_user1);
        let fut2 = push_client.req(None, u2_device_token, now, payload_for_user2);
        futures.push(fut1);
        futures.push(fut2);
    }

    futures.for_each(futures::future::ready).await;

    Ok(json(&"ok"))
}
