BEGIN;

DROP TABLE IF EXISTS path_segments CASCADE;

CREATE TABLE path_segments AS
  WITH segmentized_paths AS (
      SELECT way_id as osm_id
            , ST_Segmentize(geom, 500) as way
      FROM public.all_paths
      WHERE 1=1
        AND geom IS NOT NULL
        -- AND COALESCE(access, '') NOT IN ('no', 'private')
        AND COALESCE(bicycle, '') NOT IN ('no', 'private')
        AND (
             highway IS NOT NULL
          OR bicycle IS NOT NULL
          OR foot IS NOT NULL
        )
  ), series_by_path AS (
      SELECT osm_id, generate_series(1, ST_NPoints(way)) as n
      FROM segmentized_paths
  )
  SELECT osm_id
       , ST_MakeLine(ST_PointN(way, n), ST_PointN(way, n+1)) as way
  FROM series_by_path
  INNER JOIN segmentized_paths USING (osm_id)
  -- FIXME: Why are we getting nulls here?
  WHERE ST_PointN(way, n) IS NOT NULL
    AND ST_PointN(way, n+1) IS NOT NULL
  ;

-- TODO: Can we do this as part of the CREATE TABLE AS?
ALTER TABLE path_segments ADD COLUMN id SERIAL;
ALTER TABLE path_segments ADD PRIMARY KEY (id);
ALTER TABLE path_segments ALTER COLUMN osm_id SET NOT NULL;
ALTER TABLE path_segments ALTER COLUMN way SET NOT NULL;

-- TODO: Should benchmark this, theoretically SP-GiST is better than
-- GiST at overlapping data (such as roads?)
CREATE INDEX path_segments_way_idx ON path_segments USING SPGIST (way);

COMMIT;
