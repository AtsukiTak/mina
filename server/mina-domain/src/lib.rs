pub mod call;
mod cred;
pub mod partner_request;
pub mod relationship;
pub mod user;

pub use cred::Cred;

pub trait RepositorySet {
    type UserRepo: user::UserRepository;
    type RelationshipRepo: relationship::RelationshipRepository;
    type PartnerRequestRepo: partner_request::PartnerRequestRepository;
    type CallRepo: call::CallRepository;

    fn user_repo(&self) -> &Self::UserRepo;

    fn relationship_repo(&self) -> &Self::RelationshipRepo;

    fn partner_request_repo(&self) -> &Self::PartnerRequestRepo;

    fn call_repo(&self) -> &Self::CallRepo;
}
