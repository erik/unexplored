REGION_NAME ?= north-america/us/california/socal-latest.osm.pbf
FILE_REGION_EXPORT := data/$(notdir ${REGION_NAME})
FILE_WAYS := data/ways.osm.pbf

POSTGRES_DSN ?= postgresql://gis:password@127.0.0.1:5432/gis

.PHONY: all
all: ${FILE_WAYS}

${FILE_REGION_EXPORT}:
	curl "https://download.geofabrik.de/${REGION_NAME}" -o "${FILE_REGION_EXPORT}"

${FILE_WAYS}: ${FILE_REGION_EXPORT}
	osmium tags-filter "${FILE_REGION_EXPORT}" \
		--overwrite \
		--invert-match \
		--omit-referenced \
		"w/bicycle=no" \
		-o "${FILE_WAYS}"

.PHONY: segment-roads
segment-roads: ${FILE_WAYS}
	psql ${POSTGRES_DSN} < ./postgis/segmentize_roads.sql

.PHONY: psql
psql:
	psql ${POSTGRES_DSN}

.PHONY: osm2pgsql
osm2pgsql: ${FILE_WAYS}
	osm2pgsql -d ${POSTGRES_DSN} \
		--create \
		--slim \
		-G \
		--hstore \
		--tag-transform-script
