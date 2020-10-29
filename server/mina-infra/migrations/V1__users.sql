CREATE TABLE users (
  id TEXT NOT NULL,
  name TEXT,
  secret TEXT NOT NULL,
  snapshot_hash UUID NOT NULL
);
