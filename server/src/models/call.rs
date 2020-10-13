use super::{id::Id, user::UserId};
use chrono::{DateTime, Utc};

pub struct Call {
    id: CallId,
    users: (CallUser, CallUser),
    created_at: DateTime<Utc>,
}

pub enum CallUser {
    Inprogress(UserId),
    Ready { user_id: UserId, skw_id: String },
}

pub struct CallId(Id);

impl CallId {
    fn new() -> Self {
        CallId(Id::new())
    }
}
