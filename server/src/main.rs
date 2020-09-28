mod apns;

use apns::ApnsAuthorizer;
use chrono::Utc;

fn main() {
    let iss = "BN74D86Y99".to_string();
    let kid = "6637Y96KAX".to_string();
    let key_bytes = include_bytes!("../AuthKey_6637Y96KAX.p8");
    let mut apns_authorizer = ApnsAuthorizer::new(iss, kid, key_bytes).unwrap();

    let iat = Utc::now();
    let token = apns_authorizer.get_token(iat).unwrap();

    println!("{}", token);
}
