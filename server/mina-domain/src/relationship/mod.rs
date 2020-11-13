mod repository;
pub use repository::RelationshipRepository;

use crate::user::UserId;
use chrono::{DateTime, Datelike as _, NaiveDate, NaiveDateTime, NaiveTime, Utc, Weekday};
use rego::Error;
use std::{fmt, iter::FromIterator};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Relationship {
    id: RelationshipId,
    user_a: UserId,
    user_b: UserId,

    schedules: Vec<CallSchedule>,
    next_call_time: Option<DateTime<Utc>>,
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

    pub fn users(&self) -> [&UserId; 2] {
        [&self.user_a, &self.user_b]
    }

    pub fn schedules(&self) -> &[CallSchedule] {
        self.schedules.as_slice()
    }

    pub fn next_call_time(&self) -> Option<&DateTime<Utc>> {
        self.next_call_time.as_ref()
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
            next_call_time: None,
        })
    }

    /// 新しいスケジュールを追加する
    ///
    /// # Note
    /// 現在の時間を `now` パラメータとして渡す
    /// これは `next_call_time` フィールドの更新のために必要
    pub fn add_call_schedule_at<W>(&mut self, weekdays: W, time: NaiveTime, now: DateTime<Utc>)
    where
        W: IntoIterator<Item = Weekday>,
    {
        // schedules の更新
        let schedule = CallSchedule {
            id: CallScheduleId(Uuid::new_v4()),
            time,
            weekdays: weekdays.into_iter().collect(),
        };
        self.schedules.push(schedule);

        // next_call_time の更新
        self.next_call_time = self.schedules.iter().map(|s| s.next_call_time(now)).min();
    }

    /// 指定したスケジュールを削除する
    ///
    /// # Note
    /// 現在の時間を `now` パラメータとして渡す
    /// これは `next_call_time` フィールドの更新のために必要
    pub fn remove_call_schedule_at(
        &mut self,
        schedule_id: &CallScheduleId,
        now: DateTime<Utc>,
    ) -> Result<(), Error> {
        // schedules の更新
        if let Some((i, _)) = self
            .schedules
            .iter()
            .enumerate()
            .find(|(_, schedule)| schedule.id() == schedule_id)
        {
            self.schedules.swap_remove(i);
        } else {
            return Err(Error::bad_input("specified schedule not found"));
        }

        // next_call_time の更新
        self.next_call_time = self.schedules.iter().map(|s| s.next_call_time(now)).min();

        Ok(())
    }

    /// `next_call_time` フィールドを次の時間に更新する
    pub fn update_next_call_time(&mut self) {
        if let Some(last_call_time) = self.next_call_time {
            self.next_call_time = self
                .schedules
                .iter()
                .map(|s| s.next_call_time(last_call_time))
                .min();
        }
    }

    pub fn from_raw_parts(
        id: Uuid,
        user_a: String,
        user_b: String,
        schedules: Vec<(Uuid, NaiveTime, u8)>,
        next_call_time: Option<DateTime<Utc>>,
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
            next_call_time,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
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
/// 曜日と時間はともにUTCタイムゾーンで扱われる
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

    /// `at` 以降の最初のschedule
    /// ただし`at` は含まない
    fn next_call_time(&self, at: DateTime<Utc>) -> DateTime<Utc> {
        let naive = at.naive_utc();

        // 次に有効になるDateを計算
        let next_date = if naive.time() < self.time {
            self.next_active_date(naive.date())
        } else {
            self.next_active_date(naive.date().succ())
        };

        let next_naive = NaiveDateTime::new(next_date, self.time);
        DateTime::from_utc(next_naive, Utc)
    }

    fn next_active_date(&self, date: NaiveDate) -> NaiveDate {
        let date_weekday = date.weekday();
        if self.weekdays.iter().find(|w| *w == date_weekday).is_some() {
            date
        } else {
            self.next_active_date(date.succ())
        }
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
    fn new() -> Weekdays {
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

    /// for DB use
    pub fn into_raw_value(&self) -> u8 {
        self.0
    }

    /// for DB use
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
