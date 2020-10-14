//! # Resources
//! - https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns

use chrono::{DateTime, Duration, Utc};
use jsonwebtoken::{encode, errors::Error as JwtError, Algorithm, EncodingKey, Header};
use serde::Serialize;

pub struct Authorizer {
    iss: String,

    key: EncodingKey,

    /// `kid` から予め計算された `Header`
    header: Header,

    cache: Option<Cache>,
}

struct Cache {
    token: String,
    iat: DateTime<Utc>,
}

impl Authorizer {
    /// # Params
    ///
    /// ## iss
    /// The issuer key, the value for which is the 10-character Team ID you use for developing
    /// your company’s apps. Obtain this value from your developer account.
    ///
    /// ## kid
    /// The 10-character Key ID you obtained from your developer account;
    /// [see Obtain an Encryption Key and Key ID from
    /// Apple](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns#2943371).
    ///
    /// ## key_secret
    /// Usually, this value is obtained by `include_bytes!("private.pem")`.
    pub fn new(iss: String, kid: String, key_secret: &[u8]) -> Result<Authorizer, JwtError> {
        let key = EncodingKey::from_ec_pem(key_secret)?;
        let mut header = Header::new(Algorithm::ES256);
        header.kid = Some(kid);

        Ok(Authorizer {
            iss,
            key,
            header,
            cache: None,
        })
    }

    /// 新しいTokenを取得する
    /// 30分以内に導出したTokenがある場合、それを返す
    /// それがない場合は新たに導出したものを返す
    pub fn get_token(&mut self, iat: DateTime<Utc>) -> Result<String, JwtError> {
        if let Some(cache) = self.cache.as_ref() {
            // 30分以内に作られたcacheならそれを再利用する
            if iat - cache.iat < Duration::minutes(30) {
                return Ok(cache.token.clone());
            }
        }

        let token = self.derive_token(iat)?;

        self.cache = Some(Cache {
            token: token.clone(),
            iat,
        });

        Ok(token)
    }

    /// 単純に新しいTokenを導出する
    /// `get_token` 関数と異なり、cacheから読み込むこともしない
    /// 前回使用したTokenから20分以内に導出されたTokenを使用
    /// するとAppleから警告が出るので注意
    pub fn derive_token(&self, iat: DateTime<Utc>) -> Result<String, JwtError> {
        let claim = TokenClaim::new(self.iss.as_str(), iat);

        encode(&self.header, &claim, &self.key)
    }
}

#[derive(Serialize, Debug)]
struct TokenClaim<'a> {
    iss: &'a str,
    iat: usize,
}

impl<'a> TokenClaim<'a> {
    fn new(iss: &'a str, iat: DateTime<Utc>) -> Self {
        let iat = iat.timestamp() as usize;

        TokenClaim { iss, iat }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const SECRET: &str = r#"-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQggsxbZG38UqQPT0ci
O93QBk0doWeRZr6odmzjLtUnt5yhRANCAAQCpm9FfjaDOfAQNB7s3kAtY5t4nNWU
n+y72I7T0/9JOW4kVQrc443CqXVt+ahKZWUtLxSOewvIHItUTOMDdsMw
-----END PRIVATE KEY-----"#;

    #[test]
    fn use_cache_if_within_30min() {
        let iss = "TEST_ISS".to_string();
        let kid = "TEST_KID".to_string();
        let mut authorizer = Authorizer::new(iss, kid, SECRET.as_bytes()).unwrap();

        let iat1 = Utc::now();
        let token1 = authorizer.get_token(iat1).unwrap();

        let iat2 = iat1 + Duration::minutes(29);
        let token2 = authorizer.get_token(iat2).unwrap();

        assert_eq!(token1, token2);
    }

    #[test]
    fn not_use_cache_if_without_30min() {
        let iss = "TEST_ISS".to_string();
        let kid = "TEST_KID".to_string();
        let mut authorizer = Authorizer::new(iss, kid, SECRET.as_bytes()).unwrap();

        let iat1 = Utc::now();
        let token1 = authorizer.get_token(iat1).unwrap();

        let iat2 = iat1 + Duration::minutes(31);
        let token2 = authorizer.get_token(iat2).unwrap();

        assert_ne!(token1, token2);
    }
}
