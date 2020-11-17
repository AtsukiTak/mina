CREATE TABLE users (
  id TEXT NOT NULL,
  name TEXT,
  secret_cred TEXT NOT NULL,
  apple_push_token TEXT,
  snapshot_hash UUID NOT NULL
);

CREATE TABLE partner_requests (
  id UUID NOT NULL,
  from_user TEXT NOT NULL,
  to_user TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE relationships (
  id UUID NOT NULL,
  user_a TEXT NOT NULL,
  user_b TEXT NOT NULL,
  next_call_time TIMESTAMPTZ,
  processing_call_id UUID,
  snapshot_hash UUID NOT NULL
);

CREATE TABLE call_schedules (
  id UUID NOT NULL,
  relationship_id UUID NOT NULL,
  time TIME NOT NULL,
  weekdays SMALLINT NOT NULL
);

CREATE TABLE calls (
  id UUID NOT NULL,
  relationship_id UUID NOT NULL,
  user_a_skw_id TEXT,
  user_b_skw_id TEXT,
  created_at TIMESTAMPTZ NOT NULL
);
