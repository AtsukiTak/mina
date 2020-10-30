CREATE TABLE users (
  id TEXT NOT NULL,
  name TEXT,
  secret TEXT NOT NULL,
  apple_push_token TEXT,
  snapshot_hash UUID NOT NULL
);
