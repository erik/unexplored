CREATE USER renderer WITH PASSWORD 'password';
CREATE DATABASE gis;

GRANT ALL PRIVILEGES ON DATABASE gis TO renderer;

CREATE EXTENSION postgis;
CREATE EXTENSION hstore;

ALTER TABLE geometry_columns OWNER TO renderer;
ALTER TABLE spatial_ref_sys OWNER TO renderer;
