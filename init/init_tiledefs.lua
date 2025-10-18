--[[
tile_name - the name of the tile, this is how you'll refer to your tile in the WORLD_TILES table.
tile_range - the string defining the range of possible ids for the tile.
the following ranges exist: "LAND", "NOISE", "OCEAN", "IMPASSABLE"
tile_data {
	[ground_name]
	[old_static_id] - optional, the static tile id that this tile had before migrating to this API, if you aren't migrating your tiles from an old API to this one, omit this.
}
ground_tile_def {
	[name] - this is the texture for the ground, it will first attempt to load the texture at "levels/texture/<name>.tex", if that fails it will then treat <name> as the whole file path for the texture.
	[atlas] - optional, if missing it will load the same path as name, but ending in .xml instead of .tex,  otherwise behaves the same as <name> but with .xml instead of .tex.
	[noise_texture] -  this is the noise texture for the ground, it will first attempt to load the texture at "levels/texture/<noise_texture>.tex", if that fails it will then treat <noise_texture> as the whole file path for the texture.
	[runsound] - soundpath for the run sound, if omitted will default to "dontstarve/movement/run_dirt"
	[walksound] - soundpath for the walk sound, if omitted will default to "dontstarve/movement/walk_dirt"
	[snowsound] - soundpath for the snow sound, if omitted will default to "dontstarve/movement/run_snow"
	[mudsound] - soundpath for the mud sound, if omitted will default to "dontstarve/movement/run_mud"
	[flashpoint_modifier] - the flashpoint modifier for the tile, defaults to 0 if missing
	[colors] - the colors of the tile when for blending of the ocean colours, will use DEFAULT_COLOUR(see tilemanager.lua for the exact values of this table) if missing.
	[flooring] - if true, inserts this tile into the GROUND_FLOORING table.
	[hard] - if true, inserts this tile into the GROUND_HARD table.
	[cannotbedug] - if true, inserts this tile into the TERRAFORM_IMMUNE table.
	other values can also be stored in this table, and can tested for via the GetTileInfo function.
}
minimap_tile_def {
	[name] - this is the texture for the minimap, it will first attempt to load the texture at "levels/texture/<name>.tex", if that fails it will then treat <name> as the whole file path for the texture.
	[atlas] - optional, if missing it will load the same path as name, but ending in .xml instead of .tex,  otherwise behaves the same as <name> but with .xml instead of .tex.
	[noise_texture] -  this is the noise texture for the minimap, it will first attempt to load the texture at "levels/texture/<noise_texture>.tex", if that fails it will then treat <noise_texture> as the whole file path for the texture.
}
turf_def {
	[name] - the postfix for the prefabname of the turf item
	[anim] - the name of the animation to play for the turf item, if undefined it will use name instead
	[bank_build] - the bank and build containing the animation, if undefined bank_build will use the value "turf"
}
-]]

--NOTE: When updating this file be sure to parallel changes over to sw and ham mods
--Yes I know that's annoying and id rather it be delegated to one file but interacting between mods in the frontend is annoying, this is more sane.

--Fixes
--Removed flashpoint modifier from ocean tiles(Sorry, but its not like this in SW or DST ocean's tiles!)

modimport("init/init_tiledefs_util")

local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local GroundTiles = require("worldtiledefs")
local NoiseFunctions = require("noisetilefunctions")
local TileRanges = DF_TILEDEFS_UTIL.TileRanges

local minimap_table = GroundTiles.minimap
local ground_table = GroundTiles.ground

local EVILFOREST_COLOR =
{
	primary_color =		{15, 45, 5,  255}, -- {153, 76, 0,  200},
	secondary_color =	  {20,  20, 5, 200}, -- {102,  51, 0, 255/2},
	secondary_color_dusk = {0,  10, 2, 125}, -- {51,  25, 0, 80},
	minimap_color =		{3,  22,  13,  150},
}


local EVILFOREST_WAVETINTS =
{
	evilforest = {49, 240, 180} -- 1,  0.20,   0.10
}

local function GetTileForEvilforestNoise(noise)
	return noise < 0.55 and WORLD_TILES.EVILFOREST or WORLD_TILES.FOREST
end

local function GetTileForEvilmuddyNoise(noise)
	return noise < 0.55 and WORLD_TILES.EVILMUDDY or WORLD_TILES.MUD
end

local df_tiledefs = {
	{
		tile = "OCEAN_EVIL",
		tile_range = TileRanges.DF_OCEAN,
		tile_data = {
			ground_name = "Evil Waves",
		},
		ground_tile_def  = {
			runsound="dontstarve/movement/run_marsh",
			walksound="dontstarve/movement/walk_marsh",
			snowsound="dontstarve/movement/run_ice",
			mudsound = "dontstarve/movement/run_mud",
			ocean_depth = "SHALLOW",
			colors = EVILFOREST_COLOR,
			wavetint = EVILFOREST_WAVETINTS.evilforest,
		},
		minimap_tile_def = {
			name = "map_edge",
			noise_texture = "levels/textures/ground_evilbog.tex",
		},
	},
	{
		tile = "EVILFOREST",
		tile_range = TileRanges.LAND,
		tile_data = {
			ground_name = "Evil Ground",
		},
		ground_tile_def  = {
			name			= "grass3",
			noise_texture	= "levels/textures/ground_noise_evilforest.tex",
			runsound 		= "dontstarve/movement/run_dirt",
			walksound 		= "dontstarve/movement/walk_dirt",
			snowsound		= "dontstarve/movement/run_snow",
			mudsound		= "dontstarve/movement/run_mud",
			colors = EVILFOREST_COLOR,
		},
		minimap_tile_def = {
			name 			= "map_edge",
			noise_texture	= "levels/textures/mini_noise_evilforest.tex",
			pickupsound = "grainy",
		},
		turf_def = {
			name = 			"evilforest",
			anim = 			"evilforest",
			bank_build = 	"evil_turf",
			pickupsound = 	"grainy",
		},
	},
	{
        tile = "EVILFOREST_NOISE",
        tile_range = GetTileForEvilforestNoise,
    },
	{
		tile = "EVILMUDDY",
		tile_range = TileRanges.LAND,
		tile_data = {
			ground_name = "Evilmud Ground",
		},
		ground_tile_def  = {
			name			= "marsh",
			noise_texture	= "levels/textures/ground_noise_evilmuddy.tex",
        	runsound	=  "dontstarve/movement/run_marsh",
        	walksound	=  "dontstarve/movement/walk_marsh",
        	snowsound	=  "dontstarve/movement/run_ice",
        	mudsound	=  "dontstarve/movement/run_mud",
			colors = EVILFOREST_COLOR,
		},
		minimap_tile_def = {
			name 			= "map_edge",
			noise_texture	= "levels/textures/mini_noise_evilmuddy.tex",
			pickupsound = "grainy",
		},
		--[[turf_def = {
			name = 			"evilmuddy",
			anim = 			"evilmuddy",
			bank_build = 	"evilmud_turf",
			pickupsound = 	"grainy",
		},]]
	},
	{
        tile = "EVILMUDDY_NOISE",
        tile_range = GetTileForEvilmuddyNoise,
    },
}

local EVILFOREST_WATER_CONVERT = deepcopy(df_tiledefs[2]) -- NOTE: We're using this temporary land tile for river gen, converted later in OCEAN_EVIL
EVILFOREST_WATER_CONVERT.tile = "EVILFOREST_WATER_CONVERT"
EVILFOREST_WATER_CONVERT.turf_def = nil
EVILFOREST_WATER_CONVERT.hard = true
EVILFOREST_WATER_CONVERT.istemptile = true
table.insert(df_tiledefs, EVILFOREST_WATER_CONVERT)

--

DF_TILEDEFS_UTIL.AddTileDefs(df_tiledefs)

DFENV.ChangeTileRenderOrder(WORLD_TILES.DIRT, WORLD_TILES.EVILFOREST)

--	Setpiece Ground Type

EVIL_GROUND_TYPES = {
	WORLD_TILES.IMPASSABLE, WORLD_TILES.EVILFOREST, WORLD_TILES.MUD, WORLD_TILES.GRASS, WORLD_TILES.FOREST, -- 1, 2, 3, 4, 5
	WORLD_TILES.OCEAN_EVIL, WORLD_TILES.DIRT, WORLD_TILES.ROCKY, WORLD_TILES.UNDERROCK, WORLD_TILES.MONKEY_DOCK, -- 6, 7, 8, 9, 10
	WORLD_TILES.OCEAN_COASTAL_SHORE, WORLD_TILES.EVILMUDDY, -- 11, 12
}

local _Initialize = GroundTiles.Initialize
local function Initialize(...)
	--Invisible Tiles Patch

	local df_ocean_remap_isinvisibletile = {}
	for tile_id in pairs(GROUND_INVISIBLETILES) do
		if IsLandTile(tile_id) then
			df_ocean_remap_isinvisibletile[tile_id] = {}
			for df_ocean_tile_id in pairs(DF_OCEAN_TILES) do
				df_ocean_remap_isinvisibletile[tile_id][df_ocean_tile_id] = true
			end  
		end
	end

	for tile_id in pairs(df_ocean_remap_isinvisibletile) do
		DF_REMAP_INVISIBLETILES[tile_id] = {}
		for df_ocean_tile_id in pairs(df_ocean_remap_isinvisibletile[tile_id]) do

			local ground_tile_def, minimap_tile_def = DF_TILEDEFS_UTIL.GetGroundTileDef(tile_id), DF_TILEDEFS_UTIL.GetMinimapTileDef(tile_id)

			local new_tile = INVERTED_WORLD_TILES[tile_id] .. "_TEMP_" .. INVERTED_WORLD_TILES[df_ocean_tile_id]

			DF_TILEDEFS_UTIL.AddTile(new_tile, {
				tile_data = {ground_name = GROUND_NAMES[tile_id]},
				tile_range = TileRanges.LAND,
				ground_tile_def = ground_tile_def,
				minimap_tile_def = minimap_tile_def
			})
	
			local new_tile_id = WORLD_TILES[new_tile]

			DF_REMAP_INVISIBLETILES[tile_id][df_ocean_tile_id] = new_tile_id
			DF_REMAP_INVISIBLETILES_INVERTED[new_tile_id] = tile_id
			
			local _df_ocean_tile_id = DF_SHORE_TO_OCEAN_TILES[df_ocean_tile_id]
			local _df_shore_tile_id = DF_OCEAN_TO_SHORE_TILES[df_ocean_tile_id]

			if _df_ocean_tile_id ~= nil then
				DF_SHORE_TO_OCEAN_TILES[new_tile_id] = INVERTED_WORLD_TILES[tile_id] .. "_TEMP_" .. INVERTED_WORLD_TILES[_df_ocean_tile_id]
			end
			
			if _df_shore_tile_id ~= nil then
				DF_OCEAN_TO_SHORE_TILES[new_tile_id] = INVERTED_WORLD_TILES[tile_id] .. "_TEMP_" .. INVERTED_WORLD_TILES[_df_shore_tile_id]
			end

			SetProxyParticleWorldTileState(df_ocean_tile_id, new_tile_id)
		end
	end

	--Ground
	local ground_land_first
	for i, ground in ipairs(ground_table) do
		if ground[1] ~= nil and IsLandTile(ground[1]) then
			ground_land_first = ground[1]
			break
		end
	end

	local df_ocean_tile_order = {}
	for i, v in ipairs(ground_table) do
		if DF_OCEAN_TILES[v[1]] then
			table.insert(df_ocean_tile_order, {v[1], i})
		end
	end
	table.sort(df_ocean_tile_order, function(a,b) return a[2] < b[2] end)
	for i, data in ipairs(df_ocean_tile_order) do
		local tile = data[1]
		if tile ~= ground_land_first then
			DFENV.ChangeTileRenderOrder(tile, ground_land_first, false)
		end
	end
	return _Initialize(...)
end

GroundTiles.Initialize = Initialize