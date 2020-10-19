use mina_domain::user::{User, UserRepository};
use rego::Error;

pub struct Params {
    name: String,
}

/// 超絶シンプルな登録プロセス
/// Appは初回起動時に名前をサーバーに登録し、返されたUserId
/// をApp内に保存する。
/// 以降、そのUserIdを使ってAPIリクエストを行う
///
/// ## Production Ready Signup
/// - Signin with Apple Id を利用する
/// - Appは起動時にサーバーと接続し、nonceを取得
/// - サーバーは発効したnonceとSession IDを保存しておく
/// - Appはnonceを付与したSignin with Apple IDリクエストを
///   Appleサーバーに送り、Identity Tokenを取得する
/// - Appは取得したIdentity Tokenをサーバーに送る
/// - サーバーは送られてきたIdentity Tokenを検証する
///   - nonceは合っているか
///   - Signatureは合っているか、etc..
/// - Tokenをパースして得られたUserIdとSessionIdを紐づける
/// - nonceを無効化する
/// - SessionIdを用いてsignupを行う
pub async fn signup<R>(Params { name }: Params, repo: &mut R) -> Result<User, Error>
where
    R: UserRepository,
{
    let user = User::new(name)?;
    repo.save(user).await
}
