use std::sync::atomic::{AtomicUsize, Ordering};
use tokio_postgres::{Client, NoTls};

const PG_URL: &str = "postgres://postgres:postgres@localhost:12781";

refinery::embed_migrations!();

pub async fn connect_isolated_db() -> Client {
    static CNT: AtomicUsize = AtomicUsize::new(0);

    let n = CNT.fetch_add(1, Ordering::SeqCst);
    let db = format!("test{}", n);

    // DBに接続
    let (base_client, conn) = tokio_postgres::connect(PG_URL, NoTls).await.unwrap();

    tokio::spawn(async move {
        conn.await.unwrap();
    });

    // databaseの作成
    base_client
        .execute(format!("CREATE DATABASE {};", db).as_str(), &[])
        .await
        .unwrap();

    // 作成したdatabaseに接続
    let new_uri = format!("{}/{}", PG_URL, db);

    let (mut client, conn) = tokio_postgres::connect(new_uri.as_str(), NoTls)
        .await
        .unwrap();

    tokio::spawn(async move {
        conn.await.unwrap();
    });

    // migration
    migrations::runner().run_async(&mut client).await.unwrap();

    client
}
