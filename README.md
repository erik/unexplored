# unexplored

Match GPS traces against OpenStreetMap data to find where you haven't gone yet.

![example tile output](https://user-images.githubusercontent.com/188935/113249128-0d7b2280-9273-11eb-9fac-1c22d27ad44d.png)

## notes

This is a weekend hack, and setting things up is going to be somewhat manual. If
you want a version of this tool that works _well_, check out
[wandrer.earth](https://wandrer.earth).

All of the heavy lifting is outsourced to some core parts of the OpenStreetMap
software stack:

1. `osmium` for filtering a OSM PBF export
2. `gpsbabel` for converting FIT files into GPS
3. `postgis` for geospatial storage + querying
4. `osm2pgsql` to ingest OSM data into `postgis`
5.  `ogr2ogr` / `gdal` to ingest GPS traces into `postgis`
6. `carto` / `kosmtik` for map styling
7. `mapnik` to render tiles

For more information about how these pieces fit together, see
[switch2osm](https://switch2osm.org/).

Matching GPS traces to OSM paths is done through a rather naive distance
check. A more fully-fledged implementation of this idea would use map-matching,
as provided by a tool like [GraphHopper] or [OSRM].

[GraphHopper]: https://github.com/graphhopper/graphhopper#map-matching
[OSRM]: http://project-osrm.org/docs/v5.5.1/api/#match-service

## setup

``` bash
mkdir -p data/

# Any file ending in [.fit, .fit.gz, .gpx, .gpx.gz] will be processed.
cp -R YOUR-GPS-TRACES-DIR/ data/

# Bring up our database
docker-compose up postgis -d

# This does a lot of work, `make` could take a while:
#
# 1. Download region extract from geofabrik
# 2. Process region extract and ingest to database
# 3. Split OSM ways into smaller segments
# 4. Ingest GPS traces to database
# 5. Match each GPS trace point against the ingested segments
make

# Bring up kosmtik on http://127.0.0.1:6789/
docker-compose up
```

## license

This project reuses some code from GPL-2.0-licensed [osm2pgsql], meaning this
repository falls under the same conditions.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

[osm2pgsql]: https://github.com/openstreetmap/osm2pgsql
