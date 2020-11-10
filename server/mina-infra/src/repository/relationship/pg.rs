use chrono::NaiveTime;
use mina_domain::relationship::Relationship;
use rego::Error;
use tokio_postgres::{
    types::{Json, ToSql},
    Client, Row, Transaction,
};
use uuid::Uuid;

#[derive(Debug, Clone, Copy)]
pub struct SnapshotHash(Uuid);

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
) -> Result<Vec<(Relationship, SnapshotHash)>, Error> {
    const STMT: &str = r#"
        SELECT
            relationships.id,
            relationships.user_a,
            relationships.user_b,
            relationships.snapshot_hash,
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
            relationships.user_b,
            relationships.snapshot_hash
    "#;

    Ok(client
        .query(STMT, &[&user_id])
        .await
        .map_err(Error::internal)?
        .into_iter()
        .map(to_relationship)
        .collect())
}

fn to_relationship(row: Row) -> (Relationship, SnapshotHash) {
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
    let relationship = Relationship::from_raw_parts(id, user_a, user_b, schedules);

    let snapshot_hash: Uuid = row.get("snapshot_hash");

    (relationship, SnapshotHash(snapshot_hash))
}

/*
 * ===========
 * INSERT
 * ===========
 */
pub async fn insert(
    client: &mut Client,
    relationship: &Relationship,
) -> Result<SnapshotHash, Error> {
    let tx = client.transaction().await.map_err(Error::internal)?;
    let snapshot_hash = Uuid::new_v4();

    (futures::try_join! {
        insert_relationship(&tx, relationship, &snapshot_hash),
        insert_schedules(&tx, relationship)
    })?;

    tx.commit().await.map_err(Error::internal)?;

    Ok(SnapshotHash(snapshot_hash))
}

async fn insert_relationship<'a>(
    tx: &Transaction<'a>,
    relationship: &Relationship,
    snapshot_hash: &Uuid,
) -> Result<(), Error> {
    const STMT: &str = r#"
        INSERT INTO relationships
        (
            id,
            user_a,
            user_b,
            snapshot_hash
        )
        VALUES ($1, $2, $3, $4)
    "#;

    let [user_a, user_b] = relationship.users();
    tx.execute(
        STMT,
        &[
            relationship.id().as_ref(),
            &user_a.as_str(),
            &user_b.as_str(),
            snapshot_hash,
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
        .map(|(i, schedule)| {
            format!(
                "(${}, ${}, ${}, {})",
                i * 3 + 1,
                i * 3 + 2,
                i * 3 + 3,
                // weekdaysは直接stmtに埋め込む.
                // u8を&(dyn ToSql)に変換できないため.
                // (u8を入れる箱を事前に作り、そこへの参照を
                // 渡せばいいが、それはかなり面倒.
                // sql injectionの恐れもないため
                // 単純に埋め込むことにする.
                schedule.weekdays().into_raw_value()
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
                vec.push(relationship.id().as_ref());
                vec.push(schedule.time());
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

/*
 * =============
 * UPDATE
 * =============
 */
pub async fn update(
    client: &mut Client,
    relationship: &Relationship,
    old_hash: &SnapshotHash,
) -> Result<SnapshotHash, Error> {
    let tx = client.transaction().await.map_err(Error::internal)?;
    let new_hash = Uuid::new_v4();

    (futures::try_join! {
        update_relationship(&tx, relationship, &old_hash.0, &new_hash),
        delete_schedules(&tx, relationship),
    })?;

    // call_schedulesを削除してから改めてinsertする
    // 順序が逆になってしまう恐れがあるのでpipeliningしない
    insert_schedules(&tx, relationship).await?;

    tx.commit().await.map_err(Error::internal)?;

    Ok(SnapshotHash(new_hash))
}

/// 楽観ロック
async fn update_relationship<'a>(
    tx: &Transaction<'a>,
    relationship: &Relationship,
    old_hash: &Uuid,
    new_hash: &Uuid,
) -> Result<(), Error> {
    const STMT: &str = r#"
        UPDATE
            relationships
        SET
            user_a = $1,
            user_b = $2,
            snapshot_hash = $3
        WHERE
            id = $4
            AND
            snapshot_hash = $5
    "#;

    let [user_a, user_b] = relationship.users();
    let count = tx
        .execute(
            STMT,
            &[
                &user_a.as_str(),
                &user_b.as_str(),
                new_hash,
                relationship.id().as_ref(),
                old_hash,
            ],
        )
        .await
        .map_err(Error::internal)?;

    if count == 1 {
        Ok(())
    } else {
        // 楽観ロックに失敗した場合
        Err(rego::Error::conflict("relationship"))
    }
}

/// Relationshipに紐づく全てのscheduleを削除する
async fn delete_schedules<'a>(
    tx: &Transaction<'a>,
    relationship: &Relationship,
) -> Result<(), Error> {
    const STMT: &str = r#"
        DELETE FROM
            call_schedules
        WHERE
            relationship_id = $1
    "#;

    tx.execute(STMT, &[relationship.id().as_ref()])
        .await
        .map_err(Error::internal)
        .map(drop)
}
