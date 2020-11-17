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
struct PushPayload {
    call_id: Uuid,
}

async fn handler(config: Config) -> Result<Json, Error> {
    let repos = config.repos().await?;
    let push_client = config.push_client();
    let res = invoke_ready_calls(&repos).await?;

    let futures = FuturesUnordered::new();

    // push通知を送る
    for call in res.calls {
        let payload = PushPayload {
            call_id: *call.id().as_ref(),
        };

        for call_user in call.users() {
            let user = res.users.get(call_user.user_id()).unwrap();

            if let Some(device_token) = user.apple_push_token() {
                let fut = push_client.req(Some(Uuid::new_v4()), device_token, Utc::now(), payload);
                futures.push(fut);
            }
        }
    }

    futures.for_each(futures::future::ready).await;

    Ok(json(&"ok"))
}
