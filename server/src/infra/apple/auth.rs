use rego::Error;
use serde::Deserialize;

#[derive(Deserialize)]
struct Res {
    pub keys: Vec<PubKey>,
}

/// https://developer.apple.com/documentation/sign_in_with_apple/jwkset/keys
#[derive(Deserialize)]
pub struct PubKey {
    pub alg: String,
    pub e: String,
    pub kid: String,
    pub kty: String,
    pub n: String,
    #[serde(rename = "use")]
    pub use_: String,
}

pub async fn fetch_apple_pub_key() -> Result<Vec<PubKey>, Error> {
    reqwest::get("https://appleid.apple.com/auth/keys")
        .await
        .map_err(Error::internal)?
        .json::<Res>()
        .await
        .map_err(Error::internal)
        .map(|res| res.keys)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fetch_apple_pub_key() {
        let keys = tokio_test::block_on(fetch_apple_pub_key()).unwrap();

        assert!(keys.len() > 0);
        for key in keys {
            assert_eq!(key.kty, "RSA");
        }
    }
}
