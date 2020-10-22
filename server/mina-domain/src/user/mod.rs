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
    partners: Vec<Partner>,
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
            partners: Vec::new(),
        };

        Ok((user, secret))
    }

    pub fn id(&self) -> &UserId {
        &self.id
    }

    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    pub fn partners(&self) -> &[Partner] {
        self.partners.as_slice()
    }
}

/*
 * ===============
 * UserId
 * ===============
 */
#[derive(PartialEq, Eq, Debug, Clone)]
pub struct UserId(Id);

impl UserId {
    pub fn new() -> UserId {
        UserId(Id::new())
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

/*
 * ============
 * Partner
 * ============
 */
#[derive(PartialEq, Eq, Debug, Clone)]
pub struct Partner {
    user_id: UserId,
    nickname: String,
}
