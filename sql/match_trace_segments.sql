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
                  path_segments.geom,
                  track_points.wkb_geometry
            ) ASC
        ) as row_number
    FROM track_points
    INNER JOIN path_segments ON (
          path_segments.buffered_geom && track_points.wkb_geometry
    )
  )
  SELECT path_segment_id, COUNT(*) as num_hits
  FROM within_bounds_by_track_point
  WHERE row_number = 1
  GROUP BY 1;

CREATE OR REPLACE VIEW path_segments_traces_view AS
  SELECT
      path_segments.id as path_segment_id,
      osm_id,
      geom,
      COALESCE(num_hits, 0) as num_hits,
      z_order,
      surface_paved
  FROM path_segments
  LEFT JOIN path_segment_traces ON (path_segment_id = path_segments.id);


-- This is an expensive query, use a materialized view to speed things up.
DROP MATERIALIZED VIEW IF EXISTS unmatched_traces;
CREATE MATERIALIZED VIEW unmatched_traces AS
  SELECT
      track_points.wkb_geometry as geom
  FROM track_points
  WHERE NOT EXISTS (
        SELECT 1
        FROM path_segments
        WHERE track_points.wkb_geometry && path_segments.buffered_geom
  );

COMMIT;
