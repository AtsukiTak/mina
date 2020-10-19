mod repository;
pub use repository::UserRepository;

use super::id::Id;
use rego::Error;
use std::ops::Deref;

#[derive(PartialEq, Eq, Debug, Clone)]
pub struct User {
    id: UserId,
    name: String,
    partners: Vec<Partner>,
}

impl User {
    pub fn new(name: String) -> Result<User, Error> {
        if name.is_empty() {
            return Err(Error::bad_input("name must not be empty"));
        }

        Ok(User {
            id: UserId::new(),
            name,
            partners: Vec::new(),
        })
    }

    pub fn id(&self) -> &UserId {
        &self.id
    }

    pub fn name(&self) -> &str {
        self.name.as_str()
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
