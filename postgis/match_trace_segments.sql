BEGIN;

DROP TABLE IF EXISTS path_segment_traces;

-- This is faster than it has any right to be. Is it working
-- correctly?
CREATE TABLE path_segment_traces AS
  WITH trace_points AS (
    SELECT ogc_fid as id
         , ST_Transform(wkb_geometry, 3857) as point
    FROM track_points
  ), closest_segment_by_trace_point AS (
    SELECT tp.id as trace_point_id
         , segment.id as path_segment_id
         , segment.distance as distance
    FROM trace_points tp
    JOIN LATERAL (
      SELECT seg.id as id, ST_Distance(tp.point, seg.way) as distance
      FROM path_segments seg
      -- Give a small buffer for errant GPS coords
      WHERE ST_DWithin(seg.way, tp.point, 50)
      ORDER BY ST_Distance(tp.point, seg.way) ASC
      LIMIT 1
    ) as segment
    ON true
  )
  /* for debug
    SELECT trace_point_id, path_segment_id, distance
    FROM closest_segment_by_trace_point
    LIMIT 10;
  */
  SELECT path_segment_id, COUNT(*) as num_hits
  FROM closest_segment_by_trace_point
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
