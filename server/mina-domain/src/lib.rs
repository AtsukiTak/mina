// pub mod call;
// pub mod id;
mod cred;
pub mod user;

pub use cred::Cred;

pub trait RepositorySet {
    type UserRepo: user::UserRepository;

    fn user_repo(&mut self) -> &mut Self::UserRepo;
}
