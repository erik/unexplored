-- Note: this will run after the Postgis init script sets up the admin
-- user / database for us.

-- Create user dedicated to Mapnik
CREATE USER mapnik_renderer;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mapnik_renderer;

-- hstore extension is used by osm2pgsql
CREATE EXTENSION IF NOT EXISTS hstore;
