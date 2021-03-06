use super::{
    objects::{GQLMe, GQLMyRelationship, GQLUser},
    ContextData,
};
use async_graphql::{Context, Error, InputObject, Object, SimpleObject};
use chrono::{NaiveTime, Weekday};
use std::str::FromStr;
use uuid::Uuid;

pub struct Mutation;

#[Object]
impl Mutation {
    /// anonymousとして登録する
    async fn signup_as_anonymous(&self, context: &Context<'_>) -> Result<UserAndSecret, Error> {
        let repos = context.data::<ContextData>()?.repos();

        mina_usecase::user::signup_as_anonymous(repos)
            .await
            .map_err(Error::from)
            .map(|res| UserAndSecret {
                user: GQLUser::from(res.user),
                secret: res.secret,
            })
    }

    /// 自分のAPNS用のtokenを設定する
    async fn set_apple_push_token(
        &self,
        context: &Context<'_>,
        apple_push_token: String,
    ) -> Result<GQLMe, Error> {
        let data = context.data::<ContextData>()?;
        let repos = data.repos();
        let me = data.me_or_err()?.clone();

        mina_usecase::user::set_apple_push_token(apple_push_token, me, repos)
            .await
            .map_err(Error::from)
            .map(GQLMe::from)
    }

    /// パートナーリクエストを送信する
    async fn send_partner_request(
        &self,
        context: &Context<'_>,
        to_user_id: String,
    ) -> Result<&'static str, Error> {
        let data = &context.data::<ContextData>()?;
        let me = data.me_or_err()?;

        let _ = mina_usecase::user::send_partner_request(to_user_id, &me, data.repos())
            .await
            .map_err(Error::from)?;

        Ok("success")
    }

    /// パートナーリクエストを受理する
    async fn accept_partner_request(
        &self,
        context: &Context<'_>,
        request_id: Uuid,
    ) -> Result<&'static str, Error> {
        let data = &context.data::<ContextData>()?;
        let me = data.me_or_err()?;

        mina_usecase::user::accept_partner_request(request_id, me, data.repos()).await?;

        Ok("success")
    }

    /// 指定のRelationshipに新しいCallScheduleを追加する
    ///
    /// # Params
    /// - relationship_id: Uuid
    /// - weekdays: コンマ区切りのString. eg "Sun,Sat"
    /// - time: "%H:%M"で表現されるString. eg "15:42"
    async fn add_call_schedule(
        &self,
        context: &Context<'_>,
        input: AddCallScheduleInput,
    ) -> Result<GQLMyRelationship, Error> {
        let data = &context.data::<ContextData>()?;
        let me = data.me_or_err()?;

        let weekdays = input
            .weekdays
            .split(",")
            .map(Weekday::from_str)
            .collect::<Result<Vec<Weekday>, _>>()
            .map_err(|_| Error::from("Invalid format of weekdays field"))?;

        let time = NaiveTime::parse_from_str(input.time.as_str(), "%H:%M")
            .map_err(|_| Error::from("Invalid format of time field"))?;

        let relationship = mina_usecase::user::add_call_schedule(
            input.relationship_id,
            weekdays,
            time,
            me,
            data.repos(),
        )
        .await?;

        Ok(GQLMyRelationship::from((me.clone(), relationship)))
    }
}

#[derive(SimpleObject)]
struct UserAndSecret {
    user: GQLUser,
    secret: String,
}

#[derive(InputObject)]
struct AddCallScheduleInput {
    relationship_id: Uuid,
    weekdays: String,
    time: String,
}
