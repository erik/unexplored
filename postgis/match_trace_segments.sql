BEGIN;

DROP TABLE IF EXISTS path_segment_traces CASCADE;

-- This is faster than it has any right to be. Is it working
-- correctly?
CREATE TABLE path_segment_traces AS
  WITH trace_points AS (
    SELECT ogc_fid as id
         -- TODO: Do this transformation on ingest if possible.
         , ST_Transform(wkb_geometry, 3857) as point
    FROM track_points
  ), within_bounds_by_trace_point AS (
    SELECT
        trace_points.id  AS trace_point_id,
        path_segments.id AS path_segment_id,
        row_number() OVER (
            PARTITION BY trace_points.id
            ORDER BY ST_Distance(path_segments.way, trace_points.point) ASC
        ) as row_number
    FROM trace_points
    INNER JOIN path_segments ON (
        ST_DWithin(path_segments.way, trace_points.point, 20)
    )
  )
  SELECT path_segment_id, COUNT(*) as num_hits
  FROM within_bounds_by_trace_point
  WHERE row_number = 1
  GROUP BY 1;

CREATE OR REPLACE VIEW path_segments_traces_view AS
  SELECT path_segments.id as id, osm_id, way
  FROM path_segments
  INNER JOIN path_segment_traces ON (path_segment_id = path_segments.id)
  WHERE num_hits >= 1;

CREATE OR REPLACE VIEW path_segments_traces_negation_view AS
  SELECT path_segments.id as id, osm_id, way
  FROM path_segments
  LEFT JOIN path_segment_traces ON (path_segment_id = path_segments.id)
  WHERE path_segment_traces IS NULL;


COMMIT;
