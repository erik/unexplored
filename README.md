Skeletal setup of a couple core pieces of OpenStreetMap software.

1. `osmium` for filtering a region export (from geofabrik.de).
2. `postgis` for geospatial storage + querying.
3. `osm2pgsql` to ingest OSM data into `postgis`
4. `mapnik` to render tiles
