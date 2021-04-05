-- Note: this will run after the Postgis init script sets up the admin
-- user / database for us.

-- Create user dedicated to Mapnik
CREATE USER mapnik_renderer WITH PASSWORD 'todo';

-- Since we don't have the tables / views created yet, grant perms
-- ahead of time.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
      GRANT SELECT ON TABLES TO mapnik_renderer;

-- hstore extension is used by osm2pgsql
CREATE EXTENSION IF NOT EXISTS hstore;

-- Keep track of imported traces to speed up reruns / allow for
-- incremental uploads.
CREATE TABLE IF NOT EXISTS trace_files (
       file_name TEXT PRIMARY KEY
);
