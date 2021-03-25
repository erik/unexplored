REGION_NAME ?= north-america/us/california/socal-latest.osm.pbf
FILE_REGION_EXPORT := data/$(notdir ${REGION_NAME})
FILE_WAYS := data/ways.osm.pbf

TRACES_NEW_DIR ?= data/traces
TRACES_IMPORT_DIR := data/traces_imported

FIT_TRACES = $(wildcard $(TRACES_DIR)/*.fit ${TRACES_DIR}/*.fit.gz)
GPX_TRACES = $(wildcard $(TRACES_DIR)/*.gpx})

POSTGRES_DSN ?= postgresql://gis:password@127.0.0.1:5432/gis

.SUFFIXES: .fit .fit.gz .gpx

.PHONY: all
all: ingest-osm segment-roads

${FILE_REGION_EXPORT}:
	curl "https://download.geofabrik.de/${REGION_NAME}" -o "${FILE_REGION_EXPORT}"

${FILE_WAYS}: ${FILE_REGION_EXPORT}
	osmium tags-filter "${FILE_REGION_EXPORT}" \
		--overwrite \
		--invert-match \
		--omit-referenced \
		"w/bicycle=no" \
		-o "${FILE_WAYS}"

.PHONY: ingest-osm
ingest-osm: ${FILE_WAYS}
	osm2pgsql -d ${POSTGRES_DSN} \
		--create \
		--slim \
		-G \
		--hstore \
		--tag-transform-script carto/openstreetmap-carto.lua \
		--number-processes $(shell nproc) \
		-S carto/openstreetmap-carto.style \
		${FILE_WAYS}

# FIXME: This is extremely not how Makefiles are meant to work.
.PHONY: ingest-traces
ingest-traces: $(wildcard $(TRACES_NEW_DIR)/*)
	scripts/ingest_traces.sh $(TRACES_NEW_DIR) $(TRACES_IMPORT_DIR)

.PHONY: segment-roads
segment-roads: ${FILE_WAYS}
	psql ${POSTGRES_DSN} < ./postgis/segmentize_roads.sql

.PHONY: psql-shell
psql-shell:
	psql ${POSTGRES_DSN}
