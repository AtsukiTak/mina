use chrono::NaiveTime;
use mina_domain::relationship::Relationship;
use rego::Error;
use tokio_postgres::{
    types::{Json, ToSql},
    Client, Row, Transaction,
};
use uuid::Uuid;

/*
 * ===========
 * Load
 * ===========
 */
/// # Note
/// - `tokio-postgres` crateは今のところRecord型の
///     デシリアライズに対応していないため、
///     `jsonb_build_array` 関数を用いてjsonb型に一度変換する
/// - 対応するcall_schedulesの行が0であることもあるため、
///     INNER JOINではなくLEFT OUTER JOINを使う
/// - 対応するcall_schedulesの行が0の場合、LEFT OUTER JOINの
///     結果として各行にNULLが詰められ、要素が全てNULLの
///     配列が集約結果として出てくる。
///     それを削除するためにarray_remove関数を使う
/// - `json` 型は比較演算子が利用不可能なので `jsonb` 型を使う
pub async fn load_related_to_user(
    client: &mut Client,
    user_id: &str,
) -> Result<Vec<Relationship>, Error> {
    const STMT: &str = r#"
        SELECT
            relationships.id,
            relationships.user_a,
            relationships.user_b,
            array_remove(
                array_agg(
                    jsonb_build_array(
                        schedules.id,
                        schedules.time,
                        schedules.weekdays
                    )
                ),
                to_jsonb(ARRAY[NULL, NULL, NULL])
            ) as schedules
        FROM
            relationships
        LEFT OUTER JOIN
            call_schedules AS schedules
        ON
            relationships.id = schedules.relationship_id
            AND
            (
                relationships.user_a = $1
                OR
                relationships.user_b = $1
            )
        GROUP BY
            relationships.id,
            relationships.user_a,
            relationships.user_b
    "#;

    Ok(client
        .query(STMT, &[&user_id])
        .await
        .map_err(Error::internal)?
        .into_iter()
        .map(to_relationship)
        .collect())
}

fn to_relationship(row: Row) -> Relationship {
    let id: Uuid = row.get("id");
    let user_a: String = row.get("user_a");
    let user_b: String = row.get("user_b");
    let schedules: Vec<(Uuid, NaiveTime, u8)> = row
        // `weekdays` はi16として保存されている
        .get::<_, Vec<Json<(Uuid, NaiveTime, i16)>>>("schedules")
        .into_iter()
        .map(|json| {
            let Json((id, time, weekdays)) = json;
            (id, time, weekdays as u8)
        })
        .collect();

    Relationship::from_raw_parts(id, user_a, user_b, schedules)
}

/*
 * ===========
 * INSERT
 * ===========
 */
pub async fn insert(client: &mut Client, relationship: &Relationship) -> Result<(), Error> {
    let tx = client.transaction().await.map_err(Error::internal)?;

    (futures::try_join! {
        insert_relationship(&tx, relationship),
        insert_schedules(&tx, relationship)
    })
    .map_err(Error::internal)?;

    tx.commit().await.map_err(Error::internal)
}

async fn insert_relationship<'a>(
    tx: &Transaction<'a>,
    relationship: &Relationship,
) -> Result<(), Error> {
    const STMT: &str = r#"
        INSERT INTO relationships
        (
            id,
            user_a,
            user_b
        )
        VALUES ($1, $2, $3)
    "#;

    let (user_a, user_b) = relationship.users();
    tx.execute(
        STMT,
        &[
            relationship.id().as_ref(),
            &user_a.as_str(),
            &user_b.as_str(),
        ],
    )
    .await
    .map_err(Error::internal)?;

    Ok(())
}

async fn insert_schedules<'a>(
    tx: &Transaction<'a>,
    relationship: &Relationship,
) -> Result<(), Error> {
    if relationship.schedules().is_empty() {
        return Ok(());
    }

    const BASE_STMT: &str = r#"
        INSERT INTO call_schedules
        (
            id,
            relationship_id,
            time,
            weekdays
        )
        VALUES
    "#;

    let values_stmt = relationship
        .schedules()
        .iter()
        .enumerate()
        .map(|(i, _)| {
            format!(
                "(${}, ${}, ${}, ${})",
                i * 4 + 1,
                i * 4 + 2,
                i * 4 + 3,
                i * 4 + 4
            )
        })
        .collect::<Vec<String>>()
        .join(", ");

    let values: Vec<&(dyn ToSql + Sync)> =
        relationship
            .schedules()
            .iter()
            .fold(Vec::new(), |mut vec, schedule| {
                vec.push(schedule.id().as_ref());
                vec
            });

    tx.execute(
        format!("{} {}", BASE_STMT, values_stmt).as_str(),
        values.as_slice(),
    )
    .await
    .map_err(Error::internal)?;

    Ok(())
}
