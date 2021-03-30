#!/bin/bash
#
# Run trace conversion / ingest in parallel to speed everything up.

set -e

FROM_DIR="$1"; shift
MAX_PROCS=$(nproc)

# Export this so it's available in sub-shells
export PG_CONN="dbname='${PG_DB}' \
         host='${PG_HOST}' \
         port='${PG_PORT}' \
         user='${PG_USER}' \
         password='${PG_PASS}'"

gunzip_file () {
    local src="$1"; shift
    local dst="$(dirname $src)/$(basename -s .gz $src)"
    if [ -f "$dst" ]; then
        return
    fi
    echo "gunzip_file: $src"
    gunzip "$src"
}

fit_to_gpx () {
    local src="$1"; shift
    local dst="$src.gpx"
    if [ -f "$dst" ]; then
        return
    fi

    echo "fit_to_gpx: $src"
    gpsbabel -i garmin_fit -f "$src" -o gpx -F "$dst"
}

ogr2ogr_import () {
    local f="$1"; shift
    echo "ogr2ogr_import: $f"
    ogr2ogr -update -append \
            -t_srs EPSG:3857 \
            -f PostgreSQL "PG:${PG_CONN}" \
            "$f" \
            track_points
}

export -f gunzip_file
export -f fit_to_gpx
export -f ogr2ogr_import

ls ${FROM_DIR}/*.gz | xargs -n1 -P ${MAX_PROCS} bash -c 'gunzip_file "$@"' _
ls ${FROM_DIR}/*.fit | xargs -n1 -P ${MAX_PROCS} bash -c 'fit_to_gpx "$@"' _
ls ${FROM_DIR}/*.gpx | xargs -n1 -P ${MAX_PROCS} bash -c 'ogr2ogr_import "$@"' _

echo 'Finished.'
