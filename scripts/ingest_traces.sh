#!/bin/bash
#
# Run trace conversion / ingest in parallel to speed everything up.
#
# TODO: move files into ${TO_DIR} when done processing

set -ex

FROM_DIR="$1"; shift
TO_DIR="$1"; shift

MAX_PROCS=$(nproc)

gunzip_file () {
    local f="$1"; shift
    echo "gunzip_file: $f"
    gunzip < "$f" > "$(dirname $f)/$(basename -s .gz $f)"
}

fit_to_gpx () {
    local f="$1"; shift
    echo "fit_to_gpx: $f"
    gpsbabel -i garmin_fit -f "$f" -o gpx -F "$f.gpx"
}

ogr2ogr_import () {
    local f="$1"; shift
    echo "ogr2ogr_import: $f"
    ogr2ogr -update -append \
            -f PostgreSQL PG:"dbname='gis' host='127.0.0.1' port='5432' user='gis' password='password'" \
            "$f";
}

export -f gunzip_file
export -f fit_to_gpx
export -f ogr2ogr_import

ls ${FROM_DIR}/*.gz | xargs -n1 -P ${MAX_PROCS} bash -c 'gunzip_file "$@"' _
ls ${FROM_DIR}/*.fit | xargs -n1 -P ${MAX_PROCS} bash -c 'fit_to_gpx "$@"' _
ls ${FROM_DIR}/*.gpx | xargs -n1 -P ${MAX_PROCS} bash -c 'ogr2ogr_import "$@"' _
