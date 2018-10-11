CREATE TABLE IF NOT EXISTS videos (
  id integer primary key,
  external_id varchar(255),
  title varchar(255),
  description text,
  channel_id integer,
  watched_at timestamp,
  published_at timestamp
);

CREATE TABLE IF NOT EXISTS channels (
  id integer primary key,
  external_id varchar(255),
  url varchar(255),
  name varchar(255)
);
