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
    apns_topic: String,
    authorizer: Arc<Mutex<Authorizer>>,
}

impl Client {
    pub fn new_for_dev(bundle_id: &str, authorizer: Authorizer) -> Self {
        let client = reqwest::ClientBuilder::new()
            .http2_prior_knowledge()
            .build()
            .unwrap();
        Client {
            client,
            for_dev: true,
            apns_topic: format!("{}.voip", bundle_id),
            authorizer: Arc::new(Mutex::new(authorizer)),
        }
    }

    pub async fn req<D: Serialize>(
        &self,
        req_id: Option<Uuid>,
        device_token: &str,
        iat: DateTime<Utc>,
        payload: D,
    ) {
        let url = self.gen_url(device_token);
        let mut req = self.client.post(url);

        // Authorize ヘッダーの設定
        let token = self.authorizer.lock().unwrap().get_token(iat).unwrap();
        req = req.bearer_auth(token);

        // apns-push-type ヘッダーの設定
        req = req.header("apns-push-type", "voip");

        // apns-id ヘッダーの設定
        if let Some(req_id) = req_id {
            let mut buf = Uuid::encode_buffer();
            let req_id_str = req_id.to_hyphenated().encode_lower(&mut buf);
            req = req.header("apns-id", &*req_id_str);
        }

        // apns-topic ヘッダーの設定
        req = req.header("apns-topic", self.apns_topic.as_str());

        // Payload の設定
        req = req.json(&payload);

        match req.send().await {
            Ok(res) => log::debug!("{:?}", res),
            Err(e) => log::warn!("{:?}", e),
        };
    }

    fn gen_url(&self, device_token: &str) -> Url {
        let host = if self.for_dev {
            "api.sandbox.push.apple.com"
        } else {
            "api.push.apple.com"
        };
        let url_str = format!("https://{}/3/device/{}", host, device_token);
        Url::parse(url_str.as_str()).unwrap()
    }
}
