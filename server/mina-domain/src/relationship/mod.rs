mod repository;
pub use repository::RelationshipRepository;

use crate::user::UserId;
use chrono::{DateTime, Datelike as _, NaiveDate, NaiveDateTime, NaiveTime, Utc, Weekday};
use rego::Error;
use std::{fmt, iter::FromIterator, sync::Arc};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Relationship {
    id: RelationshipId,
    user_a: UserId,
    user_b: UserId,

    schedules: Vec<CallSchedule>,
    next_call_time: Option<DateTime<Utc>>,
    processing_call: Option<Call>,
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

    pub fn processing_call(&self) -> Option<&Call> {
        self.processing_call.as_ref()
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
            processing_call: None,
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

    pub fn is_call_process_startable_at(&self, at: DateTime<Utc>) -> bool {
        self.processing_call.is_none() && matches!(self.next_call_time(), Some(t) if *t < at)
    }

    /// 通話プロセスを開始する
    /// このメソッドを呼び出す前に必ず `is_call_process_startable_at` メソッドを用いて
    /// 通話プロセスを開始できるかチェックする。
    /// 通話プロセスを開始するには、未解決の過去のスケジュール
    /// がある必要がある。つまり、next_call_time が at 引数の
    /// 時間よりも過去である必要がある
    /// このメソッドの呼び出し後には、next_call_timeが次の
    /// 値に設定される
    pub fn start_call_process_at(&mut self, at: DateTime<Utc>) -> Result<&Call, Error> {
        if self.is_call_process_startable_at(at) {
            return Err(Error::Internal(Arc::new(anyhow::anyhow!(
                "call process is not startable"
            ))));
        }

        let call = Call {
            id: CallId(Uuid::new_v4()),
            users: [
                CallUser::new(self.users()[0].clone()),
                CallUser::new(self.users()[1].clone()),
            ],
            created_at: at,
        };

        self.processing_call = Some(call);
        self.next_call_time = self.schedules.iter().map(|s| s.next_call_time(at)).min();

        Ok(self.processing_call.as_ref().unwrap())
    }

    /// 通話プロセスの一環として、ユーザーのSkyWayIDを登録する
    /// すでに相手がSkyWayIDを登録済みであればそれを返す
    pub fn set_call_skw_id(
        &mut self,
        user_id: &UserId,
        skw_id: String,
    ) -> Result<Option<&str>, Error> {
        if let Some(call) = self.processing_call.as_mut() {
            call.set_call_skw_id(user_id, skw_id)
        } else {
            Err(Error::bad_input("call process is not started"))
        }
    }

    pub fn from_raw_parts(
        id: Uuid,
        user_a: String,
        user_b: String,
        schedules: Vec<(Uuid, NaiveTime, u8)>,
        next_call_time: Option<DateTime<Utc>>,
        processing_call: Option<(Uuid, [Option<String>; 2], DateTime<Utc>)>,
    ) -> Self {
        Relationship {
            id: RelationshipId(id),
            user_a: UserId::from(user_a.clone()),
            user_b: UserId::from(user_b.clone()),
            schedules: schedules
                .into_iter()
                .map(|(id, time, weekdays)| CallSchedule {
                    id: CallScheduleId(id),
                    time,
                    weekdays: Weekdays(weekdays),
                })
                .collect(),
            next_call_time,
            processing_call: processing_call.map(|(id, users, created_at)| {
                let [u1_skw_id, u2_skw_id] = users;
                Call {
                    id: CallId(id),
                    users: [
                        CallUser {
                            user_id: UserId::from(user_a.clone()),
                            skw_id: u1_skw_id,
                        },
                        CallUser {
                            user_id: UserId::from(user_b.clone()),
                            skw_id: u2_skw_id,
                        },
                    ],
                    created_at,
                }
            }),
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

/*
 * =============
 * Call
 * =============
 */
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Call {
    id: CallId,
    users: [CallUser; 2],
    created_at: DateTime<Utc>,
}

impl Call {
    pub fn id(&self) -> &CallId {
        &self.id
    }

    pub fn users(&self) -> &[CallUser; 2] {
        &self.users
    }

    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }

    pub fn set_call_skw_id(
        &mut self,
        user_id: &UserId,
        skw_id: String,
    ) -> Result<Option<&str>, Error> {
        let [user, counterpart] = {
            let [u1, u2] = &mut self.users;
            if u1.user_id() == user_id {
                [u1, u2]
            } else if u2.user_id() == user_id {
                [u2, u1]
            } else {
                return Err(Error::bad_input(
                    "given user is not a member of this relationship",
                ));
            }
        };

        if user.skw_id.is_some() {
            return Err(Error::bad_input("skw_id is already set"));
        }

        user.skw_id = Some(skw_id);

        Ok(counterpart.skw_id.as_deref())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CallId(Uuid);

impl AsRef<Uuid> for CallId {
    fn as_ref(&self) -> &Uuid {
        &self.0
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CallUser {
    user_id: UserId,
    skw_id: Option<String>,
}

impl CallUser {
    fn new(user_id: UserId) -> Self {
        CallUser {
            user_id,
            skw_id: None,
        }
    }

    pub fn user_id(&self) -> &UserId {
        &self.user_id
    }

    pub fn skw_id(&self) -> Option<&str> {
        self.skw_id.as_deref()
    }
}
