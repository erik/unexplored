table_all_paths = osm2pgsql.define_way_table(
   'all_paths', {
      { column = 'name', type = 'text' },
      { column = 'geom', type = 'linestring' },
      { column = 'tags', type = 'hstore' },

      { column = 'access', type = 'text' },
      { column = 'path', type = 'text' },
      { column = 'foot', type = 'text' },
      { column = 'bicycle', type = 'text' },
      { column = 'highway', type = 'text' },
})

function osm2pgsql.process_way(object)
   local should_ignore = (
      object.tags.highway == nil or
      object.tags.access == 'no' or
      object.tags.access == 'private' or
      object.tags.bicycle == 'no'
   )
   if should_ignore then
      return
   end

   table_all_paths:add_row({
      tags = object.tags,
      name = object.tags.name,

      highway = object.tags.highway,
      bicycle = object.tags.bicycle,
      path = object.tags.path,
      foot = object.tags.foot,

      access = object.tags.access,

      geom = { create = 'line' }
   })
end
