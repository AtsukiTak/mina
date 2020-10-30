use mina_app::server::{bind, Config};

#[tokio::main]
async fn main() {
    let db_url = get_env_var_or_panic("DATABASE_URL");

    let port = get_env_var_u16("PORT").unwrap_or(8080);

    let config = Config::new(db_url.as_str()).await;

    bind(([0, 0, 0, 0], port), config).await
}

fn get_env_var_or_panic(key: &'static str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!(format!("{} is not specified", key)))
}

fn get_env_var_u16(key: &'static str) -> Option<u16> {
    std::env::var(key)
        .ok()
        .map(|s| u16::from_str_radix(s.as_str(), 10).unwrap())
}
