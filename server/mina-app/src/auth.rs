use headers::{authorization::Basic, Authorization, Header as _};
use rego::app::warp::Error;
use warp::{Filter, Rejection};

/// # Note
/// 各routeの最後で、`Error::recover` を忘れないこと
pub fn basic_opt(
) -> impl Filter<Extract = (Option<Authorization<Basic>>,), Error = Rejection> + Clone {
    warp::header::value("Authorization")
        .and_then(|val| async move {
            Authorization::<Basic>::decode(&mut std::iter::once(&val))
                .map_err(|_| warp::reject::custom(Error::bad_request("Invalid auth header")))
        })
        .map(|auth| Some(auth))
        .or_else(|_| async { Ok((None,)) })
}
