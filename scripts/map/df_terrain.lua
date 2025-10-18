local filters = terrain.filter

local function OnlyAllow(approved)
	local filter = {}
	
	for k, v in pairs(GetWorldTileMap()) do
		if not table.contains(approved, v) then
			table.insert(filter, v)
		end
	end
	
	return filter
end

local df_filters = {
	df_berrybush = OnlyAllow({WORLD_TILES.EVILFOREST}),
	eviltree_tall = OnlyAllow({WORLD_TILES.EVILFOREST}),
}

local df_addedtiles = {
	
}

for terrain, tiles in pairs(df_filters) do
	filters[terrain] = tiles
end

for terrain, tiles in pairs(df_addedtiles) do
	if filters[terrain] == nil then
		filters[terrain] = {}
	end
	
	for _, tile in ipairs(tiles) do
		table.insert(filters[terrain], tile)
	end
end