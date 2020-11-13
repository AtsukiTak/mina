mod repository;
pub use self::repository::CallRepository;

use super::user::UserId;
use chrono::{DateTime, Utc};
use rego::Error;
use uuid::Uuid;

pub struct Call {
    id: CallId,
    users: [CallUser; 2],
    created_at: DateTime<Utc>,
}

impl Call {
    pub fn id(&self) -> &CallId {
        &self.id
    }

    pub fn users(&self) -> [&CallUser; 2] {
        [&self.users[0], &self.users[1]]
    }

    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }
}

impl Call {
    pub fn new_at(users: [&UserId; 2], created_at: DateTime<Utc>) -> Call {
        Call {
            id: CallId(Uuid::new_v4()),
            users: [
                CallUser::new(users[0].clone()),
                CallUser::new(users[1].clone()),
            ],
            created_at,
        }
    }

    /// 自分のskw_idをセットする
    /// すでに相手のskw_idがセットされていればそれを返す
    pub fn set_user_skw_id(
        &mut self,
        user_id: &UserId,
        skw_id: String,
    ) -> Result<Option<&str>, Error> {
        let [user, counterpart] = {
            let [u1, u2] = &mut self.users;
            if u1.id() == user_id {
                [u1, u2]
            } else {
                [u2, u1]
            }
        };

        if user.skw_id.is_some() {
            return Err(Error::bad_input("skw_id is already set"));
        }

        user.skw_id = Some(skw_id);

        Ok(counterpart.skw_id.as_deref())
    }
}

pub struct CallUser {
    id: UserId,
    skw_id: Option<String>,
}

impl CallUser {
    fn new(id: UserId) -> Self {
        CallUser { id, skw_id: None }
    }

    pub fn id(&self) -> &UserId {
        &self.id
    }
}

pub struct CallId(Uuid);

impl AsRef<Uuid> for CallId {
    fn as_ref(&self) -> &Uuid {
        &self.0
    }
}
