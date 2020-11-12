use mina_app::server::{bind, Config};
use std::net::Ipv4Addr;

#[tokio::main]
async fn main() {
    pretty_env_logger::init();

    let db_url = get_env_var_or_panic("DATABASE_URL");

    let bind_ip_str = std::env::var("BIND").unwrap_or("0.0.0.0".to_string());
    let bind_ip: Ipv4Addr = bind_ip_str.parse().unwrap();

    let port = get_env_var_u16("PORT").unwrap_or(8080);

    let config = Config::new(db_url.as_str()).await;

    bind((bind_ip, port), config).await
}

fn get_env_var_or_panic(key: &'static str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!(format!("{} is not specified", key)))
}

fn get_env_var_u16(key: &'static str) -> Option<u16> {
    std::env::var(key)
        .ok()
        .map(|s| u16::from_str_radix(s.as_str(), 10).unwrap())
}
