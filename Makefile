REGION_NAME ?= north-america/us/california/socal-latest.osm.pbf
FILE_REGION_EXPORT := data/$(notdir ${REGION_NAME})
FILE_WAYS := data/ways.osm.pbf

GPS_TRACES_SRC_DIR ?= data/traces

export PG_USER ?= postgis_admin
export PG_PASS ?= some-secret-password-here
export PG_HOST ?= localhost
export PG_PORT ?= 5432
export PG_DB   ?= postgis
export PG_URL  ?= postgresql://${PG_USER}:${PG_PASS}@${PG_HOST}:${PG_PORT}/${PG_DB}

.SUFFIXES: .sql

.PHONY: all
all: ingest-osm segment-roads ingest-traces match-traces-to-segments

${FILE_REGION_EXPORT}:
	curl "https://download.geofabrik.de/${REGION_NAME}" -o "${FILE_REGION_EXPORT}"

${FILE_WAYS}: ${FILE_REGION_EXPORT}
	osmium tags-filter "${FILE_REGION_EXPORT}" \
		--overwrite \
		"wr/highway,path,bicycle,foot" \
		-o "${FILE_WAYS}"

.PHONY: ingest-osm
ingest-osm: ${FILE_WAYS} carto/map-style.lua
	osm2pgsql -d ${PG_URL} \
		--create \
		--slim \
		--hstore \
		--number-processes $(shell nproc) \
		--style scripts/osm2pgsql.lua \
		--output=flex \
		${FILE_WAYS}

# FIXME: This is extremely not how Makefiles are meant to work.
.PHONY: ingest-traces
ingest-traces: $(wildcard ${GPS_TRACES_SRC_DIR}/*)
	./scripts/ingest_traces.sh ${GPS_TRACES_SRC_DIR}

.PHONY: segment-roads
segment-roads: ${FILE_WAYS} ./sql/segmentize_roads.sql
	psql ${PG_URL} < ./sql/segmentize_roads.sql

.PHONY: match-traces-to-segments
match-traces-to-segments: ${FILE_WAYS} ./sql/match_trace_segments.sql
	psql ${PG_URL} < ./sql/match_trace_segments.sql

.PHONY: psql-shell
psql-shell:
	psql ${PG_URL}
