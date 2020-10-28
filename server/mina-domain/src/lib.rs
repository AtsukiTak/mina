// pub mod call;
// pub mod id;
pub mod user;

pub trait RepositorySet {
    type UserRepo: user::UserRepository;

    fn user_repo(&mut self) -> &mut Self::UserRepo;
}
