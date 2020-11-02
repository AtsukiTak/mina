CREATE TABLE users (
  id TEXT NOT NULL,
  name TEXT,
  secret_cred TEXT NOT NULL,
  apple_push_token TEXT,
  partners TEXT[] NOT NULL DEFAULT '{}',
  snapshot_hash UUID NOT NULL
);

CREATE TABLE partner_requests (
  id UUID NOT NULL,
  from_user TEXT NOT NULL,
  to_user TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);
