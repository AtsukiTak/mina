mod infra;

use chrono::Utc;
use infra::apple::push::{Authorizer, Client};
use serde::Serialize;

#[tokio::main]
async fn main() {
    // Authorizer の生成
    let iss = "BN74D86Y99".to_string();
    let kid = "6637Y96KAX".to_string();
    let key_bytes = include_bytes!("../../AuthKey_6637Y96KAX.p8");
    let authorizer = Authorizer::new(iss, kid, key_bytes).unwrap();

    // Client の生成
    let bundle_id = "me.atsuki.mina";
    let client = Client::new_for_dev(bundle_id, authorizer);

    // request の発行
    let device_token = "TODO";
    let payload = Payload {
        msg: "Hello PushKit",
    };
    client.req(None, device_token, Utc::now(), &payload).await;
}

#[derive(Serialize)]
struct Payload {
    msg: &'static str,
}
