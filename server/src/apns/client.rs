use super::Authorizer;
use chrono::{DateTime, Utc};
use reqwest::Url;
use serde::Serialize;
use std::sync::{Arc, Mutex};
use uuid::Uuid;

#[derive(Clone)]
pub struct Client {
    client: reqwest::Client,
    for_dev: bool,
    bundle_id: String,
    authorizer: Arc<Mutex<Authorizer>>,
}

impl Client {
    pub fn new_for_dev(bundle_id: String, authorizer: Authorizer) -> Self {
        let client = reqwest::ClientBuilder::new()
            .http2_prior_knowledge()
            .build()
            .unwrap();
        Client {
            client,
            for_dev: true,
            bundle_id,
            authorizer: Arc::new(Mutex::new(authorizer)),
        }
    }

    pub async fn req<D: Serialize>(
        &self,
        req_id: Option<Uuid>,
        device_token: &str,
        iat: DateTime<Utc>,
        payload: &D,
    ) {
        let host = if self.for_dev {
            "api.sandbox.push.apple.com"
        } else {
            "api.push.apple.com"
        };
        let url_str = format!("https://{}/3/device/{}", host, device_token);
        let url = Url::parse(url_str.as_str()).unwrap();
        let req = self.client.post(url);

        // Authorize ヘッダーの設定
        let mut authorizer = self.authorizer.lock().unwrap();
        let token = authorizer.get_token(iat).unwrap();
        let mut req = req.bearer_auth(token);

        // apns-push-type ヘッダーの設定
        req = req.header("apns-push-type", "voip");

        // apns-id ヘッダーの設定
        if let Some(req_id) = req_id {
            let mut buf = Uuid::encode_buffer();
            let req_id_str = req_id.to_hyphenated().encode_lower(&mut buf);
            req = req.header("apns-id", &*req_id_str);
        }

        // apns-topic ヘッダーの設定
        let topic = format!("{}.voip", self.bundle_id);
        req = req.header("apns-topic", topic);

        // Payload の設定
        req = req.json(payload);

        match req.send().await {
            Ok(res) => log::debug!("{:?}", res),
            Err(e) => log::warn!("{:?}", e),
        };
    }
}
