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
    // ただしその他の理由によるエラーの可能性もあるので、
    // 規定回数リトライした後はエラーを返す
    let mut last_err: Option<Error> = None;

    const RETRY_NUM: u8 = 3;

    for _ in 0..RETRY_NUM {
        let (user, secret) = User::new_anonymous()?;
        match repo.create(user).await {
            Ok(user) => {
                return Ok(Res { user, secret });
            }
            Err(e) => {
                // エラーの場合、UserIdの重複によるエラーの可能性がある
                // ためリトライする
                last_err = Some(e);
            }
        }
    }

    Err(last_err.unwrap())
}
