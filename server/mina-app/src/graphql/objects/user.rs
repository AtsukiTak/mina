use async_graphql::Object;
use mina_domain::user::User;

pub struct GQLUser {
    user: User,
}

#[Object]
impl GQLUser {
    async fn id(&self) -> &str {
        self.user.id().as_str()
    }

    async fn name(&self) -> Option<&str> {
        self.user.name()
    }
}

impl From<User> for GQLUser {
    fn from(user: User) -> Self {
        GQLUser { user }
    }
}
