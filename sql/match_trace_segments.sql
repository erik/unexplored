BEGIN;

DROP TABLE IF EXISTS path_segment_traces CASCADE;

-- TODO: Spend more time on the EXPLAIN
CREATE TABLE path_segment_traces AS
  WITH within_bounds_by_track_point AS (
    SELECT
        track_points.ogc_fid AS track_point_id,
        path_segments.id     AS path_segment_id,
        row_number() OVER (
            PARTITION BY track_points.ogc_fid
            ORDER BY ST_Distance(
                  path_segments.way,
                  track_points.wkb_geometry
            ) ASC
        ) as row_number
    FROM track_points
    INNER JOIN path_segments ON (
        ST_DWithin(
                path_segments.way,
                track_points.wkb_geometry,
                20
        )
    )
  )
  SELECT path_segment_id, COUNT(*) as num_hits
  FROM within_bounds_by_track_point
  WHERE row_number = 1
  GROUP BY 1;

COMMIT;

CREATE OR REPLACE VIEW path_segments_traces_view AS
  SELECT
      path_segments.id as path_segment_id,
      osm_id,
      way,
      num_hits,
      z_order,
      surface_paved
  FROM path_segments
  INNER JOIN path_segment_traces ON (path_segment_id = path_segments.id)
