use mina_domain::user::{User, UserRepository};
use rego::Error;

pub struct Res {
    pub user: User,
    pub secret: String,
}

/// 超絶シンプルな登録プロセス
/// Appは初回起動時に名前をサーバーに登録し、返されたUserId
/// とパスワードをApp内に保存する。
/// 以降、それらを使ってAPIリクエストを行う
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
pub async fn signup_as_anonymous<R>(repo: &mut R) -> Result<Res, Error>
where
    R: UserRepository,
{
    // 新規匿名ユーザーを生成する
    // UserIdが重複してしまった場合はリトライする
    let (user, secret) = loop {
        let (user, secret) = User::new_anonymous()?;
        match repo.find_by_id(user.id().as_ref().into()).await {
            Ok(_) => {
                // UserIdが重複してしまった場合、リトライする
            }
            Err(Error::NotFound { .. }) => {
                break (user, secret);
            }
            Err(e) => return Err(e),
        }
    };

    let user = repo.save(user).await?;

    Ok(Res { user, secret })
}
