use chrono::{DateTime, Utc};
use mina_domain::partner_request::PartnerRequest;
use rego::Error;
use tokio_postgres::{Client, Row};
use uuid::Uuid;

/*
 * =========
 * Load
 * =========
 */
const LOAD_STMG: &str = r#"
SELECT
    id,
    from_user,
    to_user,
    created_at
FROM partner_requests
WHERE id = $1
"#;

pub async fn load(client: &mut Client, id: &Uuid) -> Result<PartnerRequest, Error> {
    client
        .query_opt(LOAD_STMG, &[id])
        .await
        .map_err(Error::internal)?
        .ok_or(Error::not_found("partner request"))
        .map(to_partner_request)
}

fn to_partner_request(row: Row) -> PartnerRequest {
    let id: Uuid = row.get("id");
    let from_user: String = row.get("from_user");
    let to_user: String = row.get("to_user");
    let created_at: DateTime<Utc> = row.get("created_at");

    PartnerRequest::from_raw_parts(id, from_user, to_user, created_at)
}

/*
 * ===========
 * Insert
 * ===========
 */
const INSERT_STMT: &str = r#"
INSERT INTO partner_requests
(
    id,
    from_user,
    to_user,
    created_at
)
VALUES ($1, $2, $3, $4)
"#;

pub async fn insert(client: &mut Client, partner_requests: &PartnerRequest) -> Result<(), Error> {
    client
        .execute(
            INSERT_STMT,
            &[
                &partner_requests.id(),
                &partner_requests.from_user().as_str(),
                &partner_requests.to_user().as_str(),
                &partner_requests.created_at(),
            ],
        )
        .await
        .map_err(Error::internal)?;

    Ok(())
}
