use chrono::Utc;
use mina_app::infra::apple::push::{Authorizer, Client};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Debug)]
struct EnvVars {
    apple_auth_iss: String,
    apple_auth_kid: String,
    apple_bundle_id: String,
}

#[tokio::main]
async fn main() {
    let env = envy::from_env::<EnvVars>().unwrap();

    // Authorizer の生成
    let iss = env.apple_auth_iss;
    let kid = env.apple_auth_kid;
    let key_bytes = include_bytes!("../../AuthKey.p8");
    let authorizer = Authorizer::new(iss, kid, key_bytes).unwrap();

    // Client の生成
    let bundle_id = env.apple_bundle_id;
    let client = Client::new_for_dev(bundle_id.as_str(), authorizer);

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
