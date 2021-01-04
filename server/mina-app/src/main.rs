use mina_app::{
    infra::apple::push::{Authorizer, Client},
    server::{bind, Config},
};
use serde::Deserialize;
use std::net::Ipv4Addr;

#[derive(Deserialize, Debug)]
struct EnvVars {
    database_url: String,
    #[serde(default = "default_bind")]
    bind: String,
    #[serde(default = "default_port")]
    port: u16,
    apple_auth_iss: String,
    apple_auth_kid: String,
    apple_bundle_id: String,
}

#[tokio::main]
async fn main() {
    pretty_env_logger::init();

    let env = envy::from_env::<EnvVars>().unwrap();

    // Authorizerの生成
    let iss = env.apple_auth_iss;
    let kid = env.apple_auth_kid;
    let key_bytes = include_bytes!("../../AuthKey.p8");
    let apple_auth = Authorizer::new(iss, kid, key_bytes).unwrap();

    // Clientの生成
    let apple_push_client = Client::new_for_dev(env.apple_bundle_id.as_str(), apple_auth);

    // Configの生成
    let config = Config::new(env.database_url.as_str(), apple_push_client).await;

    // bind
    let bind_ip: Ipv4Addr = env.bind.parse().unwrap();
    bind((bind_ip, env.port), config).await
}

fn default_bind() -> String {
    "0.0.0.0".to_string()
}

fn default_port() -> u16 {
    8080
}
