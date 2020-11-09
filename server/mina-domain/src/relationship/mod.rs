mod repository;
pub use repository::RelationshipRepository;

use crate::user::UserId;
use chrono::{NaiveTime, Weekday};
use rego::Error;
use std::{fmt, iter::FromIterator};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Relationship {
    id: RelationshipId,
    user_a: UserId,
    user_b: UserId,

    schedules: Vec<CallSchedule>,
}

/*
 * ==========
 * Query系
 * ==========
 */
impl Relationship {
    pub fn id(&self) -> &RelationshipId {
        &self.id
    }

    pub fn users(&self) -> (&UserId, &UserId) {
        (&self.user_a, &self.user_b)
    }

    pub fn schedules(&self) -> &[CallSchedule] {
        self.schedules.as_slice()
    }
}

/*
 * ==========
 * Command系
 * ==========
 */
impl Relationship {
    pub fn new(user_a: UserId, user_b: UserId) -> Result<Self, Error> {
        if user_a == user_b {
            return Err(Error::bad_input(
                "cannot establish relationship between a same person",
            ));
        }

        Ok(Relationship {
            id: RelationshipId(Uuid::new_v4()),
            user_a,
            user_b,
            schedules: Vec::new(),
        })
    }

    pub fn from_raw_parts(
        id: Uuid,
        user_a: String,
        user_b: String,
        schedules: Vec<(Uuid, NaiveTime, u8)>,
    ) -> Self {
        Relationship {
            id: RelationshipId(id),
            user_a: UserId::from(user_a),
            user_b: UserId::from(user_b),
            schedules: schedules
                .into_iter()
                .map(|(id, time, weekdays)| CallSchedule {
                    id: CallScheduleId(id),
                    time,
                    weekdays: Weekdays(weekdays),
                })
                .collect(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RelationshipId(Uuid);

impl AsRef<Uuid> for RelationshipId {
    fn as_ref(&self) -> &Uuid {
        &self.0
    }
}

/*
 * ========
 * CallSchedule
 * ========
 */
/// 曜日（複数選択可能）と時間によって指定されたSchedule
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CallSchedule {
    id: CallScheduleId,

    /// 指定された時間
    time: NaiveTime,

    /// ここで指定された曜日にscheduleされる（複数指定可能）
    weekdays: Weekdays,
}

impl CallSchedule {
    pub fn id(&self) -> &CallScheduleId {
        &self.id
    }

    pub fn time(&self) -> &NaiveTime {
        &self.time
    }

    pub fn weekdays(&self) -> &Weekdays {
        &self.weekdays
    }
}

/*
 * ===============
 * CallScheduleId
 * ===============
 */
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CallScheduleId(Uuid);

impl AsRef<Uuid> for CallScheduleId {
    fn as_ref(&self) -> &Uuid {
        &self.0
    }
}

/*
 * =============
 * Weekdays
 * =============
 */
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Weekdays(u8);

impl Weekdays {
    /// create a new empty `Weekdays` struct.
    pub fn new() -> Weekdays {
        Weekdays(0)
    }

    pub fn iter(&self) -> impl Iterator<Item = Weekday> {
        let this = *self;

        [
            Weekday::Sun,
            Weekday::Mon,
            Weekday::Tue,
            Weekday::Wed,
            Weekday::Thu,
            Weekday::Fri,
            Weekday::Sat,
        ]
        .iter()
        .filter(move |weekday| {
            let bit_mask = weekday_to_bit_mask(**weekday);
            (this.0 & bit_mask).count_ones() == 1
        })
        .copied()
    }

    fn activate(&self, weekday: Weekday) -> Self {
        Weekdays(self.0 | weekday_to_bit_mask(weekday))
    }

    pub fn into_raw_value(&self) -> u8 {
        self.0
    }

    pub fn from_raw_value(v: u8) -> Self {
        Weekdays(v)
    }
}

fn weekday_to_bit_mask(weekday: Weekday) -> u8 {
    0b10000000 >> weekday.num_days_from_sunday()
}

impl FromIterator<Weekday> for Weekdays {
    fn from_iter<T>(iter: T) -> Self
    where
        T: IntoIterator<Item = Weekday>,
    {
        iter.into_iter().fold(Weekdays::new(), |weekdays, weekday| {
            weekdays.activate(weekday)
        })
    }
}

impl fmt::Debug for Weekdays {
    fn fmt(&self, fmt: &mut fmt::Formatter) -> fmt::Result {
        fmt.debug_list().entries(self.iter()).finish()
    }
}
