mod repository;
pub use repository::UserRepository;

use crate::Cred;
use rand::{distributions::Alphanumeric, thread_rng, Rng};
use rego::Error;
use std::ops::Deref;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct User {
    id: UserId,
    name: Option<String>,

    /// 匿名ユーザーのためのsecret
    /// 将来、匿名ユーザー以外を導入した時は
    /// secretによるログインをできないようにしたりする
    secret_cred: Cred,

    /// Push通知に使うためのToken
    /// 初期状態はNoneだが、一度Someになった後は常にSome
    apple_push_token: Option<String>,

    /// 自分のPartnerのID一覧
    partners: Vec<UserId>,
}

/*
 * ==============
 * Query系
 * ==============
 */
impl User {
    pub fn id(&self) -> &UserId {
        &self.id
    }

    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    pub fn secret_cred(&self) -> &Cred {
        &self.secret_cred
    }

    pub fn apple_push_token(&self) -> Option<&str> {
        self.apple_push_token.as_deref()
    }
}

/*
 * ===============
 * Command系
 * ===============
 */
impl User {
    /// 匿名ユーザーを新しく生成する
    /// UserIdはランダムに生成されるので、既存ユーザーと
    /// 重複してしまう可能性がある。
    /// そのためユースケース層で重複がないことを必ずチェックする必要がある
    ///
    /// 生成したUserとsecretを返す
    pub fn new_anonymous() -> Result<(User, String), Error> {
        let secret = thread_rng()
            .sample_iter(Alphanumeric)
            .take(16)
            .collect::<String>();

        let user = User {
            id: UserId::new(),
            name: None,
            secret_cred: Cred::derive(secret.as_str())?,
            apple_push_token: None,
            partners: Vec::new(),
        };

        Ok((user, secret))
    }

    /// apple_push_tokenの値を更新する
    /// tokenは更新されうるので、既に登録されている場合でも上書きする
    pub fn set_apple_push_token(&mut self, token: String) {
        self.apple_push_token = Some(token);
    }

    /// DBなどに保存されている生の値から
    /// `User` を再構築するときのメソッド
    ///
    /// TODO
    /// partnersをDBから再構築する
    pub fn from_raw_parts(
        id: String,
        name: Option<String>,
        secret_cred: String,
        apple_push_token: Option<String>,
    ) -> User {
        let id = UserId::from(id);
        let secret_cred = Cred::from(secret_cred);

        User {
            id,
            name,
            secret_cred,
            apple_push_token,
            partners: Vec::new(),
        }
    }
}

/*
 * ===============
 * UserId
 * ===============
 */
#[derive(PartialEq, Eq, Debug, Clone)]
pub struct UserId(String);

impl UserId {
    /// `PREFIX` を含めない文字数
    /// つまり、ユニークな部分の文字数
    pub const LEN: usize = 12;

    /// すべての `UserId` に付与されるprefix
    pub const PREFIX: &'static str = "usr_";

    /// ランダムにUserIdを生成する
    pub fn new() -> UserId {
        let uniq = thread_rng().sample_iter(Alphanumeric).take(Self::LEN);
        let s = Self::PREFIX.chars().chain(uniq).collect::<String>();

        UserId(s)
    }

    pub fn to_string(&self) -> String {
        self.0.clone()
    }

    pub fn as_str(&self) -> &str {
        self.0.as_str()
    }
}

impl AsRef<str> for UserId {
    fn as_ref(&self) -> &str {
        self.0.as_ref()
    }
}

impl Deref for UserId {
    type Target = str;

    fn deref(&self) -> &str {
        self.as_ref()
    }
}

impl From<String> for UserId {
    fn from(s: String) -> UserId {
        if !s.starts_with(Self::PREFIX) {
            panic!("UserId (${}) starts with invalid prefix.", s);
        }

        // 将来的に文字数を増やす可能性があるため、
        // 文字数に対するチェックは行わない

        UserId(s)
    }
}
