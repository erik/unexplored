CREATE TABLE gps_traces (
  -- TODO: timestamp, metadata?
  id     SERIAL PRIMARY KEY,
  points geometry(LINESTRING, 3857)
);
