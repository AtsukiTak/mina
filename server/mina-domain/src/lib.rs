// pub mod call;
// pub mod id;
mod cred;
pub mod partner_request;
pub mod user;

pub use cred::Cred;

pub trait RepositorySet {
    type UserRepo: user::UserRepository;

    fn user_repo(&self) -> &Self::UserRepo;
}
