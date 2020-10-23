mod repository;
pub use repository::UserRepository;

use super::id::Id;
use rand::{distributions::Alphanumeric, thread_rng, Rng};
use rego::{domain::Cred, Error};
use std::ops::Deref;

#[derive(Debug, Clone)]
pub struct User {
    id: UserId,
    name: Option<String>,
    /// 匿名ユーザーのためのsecret
    /// 将来、匿名ユーザー以外を導入した時は
    /// secretによるログインをできないようにしたりする
    secret: Cred,
}

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
            secret: Cred::derive(secret.as_str())?,
        };

        Ok((user, secret))
    }

    pub fn id(&self) -> &UserId {
        &self.id
    }

    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    pub fn secret(&self) -> &Cred {
        &self.secret
    }

    pub fn from_raw_parts(id: String, name: Option<String>, secret: String) -> User {
        let id = UserId::from(id);
        let secret = Cred::from(secret);

        User { id, name, secret }
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
