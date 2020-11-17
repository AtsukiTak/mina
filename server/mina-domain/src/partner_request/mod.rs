mod repository;
pub use repository::PartnerRequestRepository;

use crate::user::{User, UserId};
use chrono::{DateTime, Duration, Utc};
use rego::Error;
use std::convert::TryFrom;
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PartnerRequest {
    id: Uuid,
    from: UserId,
    to: UserId,
    created_at: DateTime<Utc>,
}

/*
 * ===========
 * Query系
 * ===========
 */
impl PartnerRequest {
    pub fn id(&self) -> &Uuid {
        &self.id
    }

    pub fn from_user(&self) -> &UserId {
        &self.from
    }

    pub fn to_user(&self) -> &UserId {
        &self.to
    }

    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }

    /// 期限が切れていないかチェックする
    /// 有効期限は24時間
    pub fn is_valid(&self) -> bool {
        self.is_valid_at(Utc::now())
    }

    /// for test
    pub(crate) fn is_valid_at(&self, at: DateTime<Utc>) -> bool {
        const VALID_HOURS: i64 = 24;

        let valid_dur = Duration::hours(VALID_HOURS);
        at < self.created_at + valid_dur
    }
}

/*
 * ===========
 * Command系
 * ===========
 */
impl PartnerRequest {
    /// `from` から `to` への `PartnerRequest` を生成する.
    /// `from` と `to` が同一人物の場合はエラー.
    /// `from` と `to` が（少なくともこのときは）存在する
    /// ことを満たすために `User` を要求する.
    pub fn new(from: &User, to: &User) -> Result<Self, Error> {
        Self::new_at(from, to, Utc::now())
    }

    /// for test
    pub(crate) fn new_at(from: &User, to: &User, at: DateTime<Utc>) -> Result<Self, Error> {
        if from.id() == to.id() {
            return Err(Error::bad_input("PartnerRequest to myself is invalid"));
        }

        Ok(PartnerRequest {
            id: Uuid::new_v4(),
            from: from.id().clone(),
            to: to.id().clone(),
            created_at: at,
        })
    }

    pub fn from_raw_parts(id: Uuid, from: String, to: String, created_at: DateTime<Utc>) -> Self {
        PartnerRequest {
            id,
            from: UserId::try_from(from).unwrap(),
            to: UserId::try_from(to).unwrap(),
            created_at,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_before_24h() {
        let now = Utc::now();
        let req = new_partner_request_at(now);

        let after_2h = now + Duration::hours(2);
        assert!(req.is_valid_at(after_2h));

        // 24hより少し前
        let after_24h_minus = now + Duration::hours(24) - Duration::seconds(1);
        assert!(req.is_valid_at(after_24h_minus));

        // 24hより少しあと
        let after_24h_plus = now + Duration::hours(24) + Duration::seconds(1);
        assert!(!req.is_valid_at(after_24h_plus));
    }

    fn new_partner_request_at(at: DateTime<Utc>) -> PartnerRequest {
        PartnerRequest::new_at(
            &User::new_anonymous().unwrap().0,
            &User::new_anonymous().unwrap().0,
            at,
        )
        .unwrap()
    }
}
