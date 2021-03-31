-- Using the flex output of osm2pgsql to create a custom table
-- https://osm2pgsql.org/doc/manual.html#the-flex-output

-- Set of all the tags we care about
included_way_tags = {
   'highway',
   'bicycle',
   'foot',
   'path',
}

-- Filter these out. Takes precedence over included_way_tags
excluded_way_tags = {
   highway = { 'motorway', 'motorway_link', 'ferry' },
   footway = { 'sidewalk' },
   access  = { 'no', 'private' },
   bicycle = { 'no' },
   service = { 'parking_aisle', 'alley' },
   [ "access:bicycle" ] = { 'no' },
}

function matches_any_key(tags, possible_keys)
   for _, k in ipairs(possible_keys) do
      if tags[k] ~= nil then
         return true
      end
   end

   return false
end

function matches_any_values(tags, possible_values)
   for key, values in pairs(possible_values) do
      local tag_value = tags[key]
      for _, val in ipairs(values) do
         if val == tag_value then
            return true
         end
      end
   end

   return false
end

function match_way_tags(tags)
   -- First match against our inclusive set
   if not matches_any_key(tags, included_way_tags) then
      return false
   end

   -- Then see if we match any exlcuded tags
   return not matches_any_values(tags, excluded_way_tags)
end

likely_paved_tags = {
   surface = {
      'asphalt',
      'concrete',
      'concrete:plates',
      'metal',
      'paved',
      'paving_stones',
      'sett',
      'wood',
   },
   highway = {
      'trunk',
      'residential',
   },

}

likely_unpaved_tags = {
   surface = {
      'compacted',
      'dirt',
      'dirt',
      'earth',
      'fine_gravel',
      'grass',
      'grass_paver',
      'gravel',
      'gravel',
      'ground',
      'ice',
      'mud',
      'rock',
      'sand',
      'snow',
      'unpaved',
   },
}

-- Figure out if the way is paved (probably).
--
-- Returns:
--   paved:   true
--   unpaved: false
--   idk:     nil
function is_surface_likely_paved(tags)
   if matches_any_values(tags, likely_paved_tags) then
      return true
   end
   if matches_any_values(tags, likely_unpaved_tags) then
      return false
   end

   return nil
end


-- Adapted from osm2pgsql, list of {key, value, z_order}
tag_z_order = {
   { 'bridge', 'yes', 10 }, { 'bridge', 'true', 10 }, { 'bridge', 1, 10 },
   { 'tunnel', 'yes', -10 }, { 'tunnel', 'true', -10 }, { 'tunnel', 1, -10 },
   { 'highway', 'minor', 3 },
   { 'highway', 'road', 3 },
   { 'highway', 'unclassified', 3 },
   { 'highway', 'residential', 3 },
   { 'highway', 'tertiary_link', 4 },
   { 'highway', 'tertiary', 4 },
   { 'highway', 'secondary_link', 6 },
   { 'highway', 'secondary', 6 },
   { 'highway', 'primary_link', 7 },
   { 'highway', 'primary', 7 },
   { 'highway', 'trunk_link', 8 },
   { 'highway', 'trunk', 8 },
   { 'highway', 'motorway_link', 9 },
   { 'highway', 'motorway', 9 },
}

function get_z_order(tags)
   -- The default z_order is 0
   z_order = 0

   for i, k in ipairs(tag_z_order) do
      if k[2] and tags[k[1]] == k[2] then
         z_order = z_order + k[3]
      end
   end

   return z_order
end


table_all_paths = osm2pgsql.define_way_table(
   'all_paths', {
      { column = 'name', type = 'text' },
      { column = 'geom', type = 'linestring' },
      { column = 'tags', type = 'hstore' },

      { column = 'z_order', type = 'integer' },
      { column = 'surface_paved', type = 'boolean' },
})

function osm2pgsql.process_way(object)
   if not match_way_tags(object.tags) then
      return
   end

   table_all_paths:add_row({
      tags = object.tags,
      name = object.tags.name,

      z_order = get_z_order(object.tags),
      surface = is_surface_likely_paved(object.tags),

      geom = { create = 'line' }
   })
end
