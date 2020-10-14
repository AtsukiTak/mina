use rand::{distributions::Alphanumeric, thread_rng, Rng};
use std::ops::Deref;

#[derive(PartialEq, Eq, Debug, Clone)]
pub struct Id(String);

impl Id {
    pub const LEN: usize = 16;

    pub fn new() -> Id {
        let s: String = thread_rng()
            .sample_iter(Alphanumeric)
            .take(Self::LEN)
            .collect();
        Id(s)
    }
}

impl AsRef<str> for Id {
    fn as_ref(&self) -> &str {
        self.0.as_str()
    }
}

impl Deref for Id {
    type Target = str;

    fn deref(&self) -> &str {
        self.as_ref()
    }
}
