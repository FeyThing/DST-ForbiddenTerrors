local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local WORLDGEN_MAIN = rawget(_G, "WORLDGEN_MAIN") ~= nil

local GroundTiles = require("worldtiledefs")
local NoiseFunctions = require("noisetilefunctions")

local minimap_table = GroundTiles.minimap
local ground_table = GroundTiles.ground

local TileRanges =
{
    LAND = "LAND",
    NOISE = "NOISE",
    OCEAN = "OCEAN",
    DF_OCEAN = "DF_OCEAN",
    IMPASSABLE = "IMPASSABLE",
}

-------------------------------
-- Validate Missing Data     --
-------------------------------

global("DF_OCEAN_TILES", "DF_SHORE_TO_OCEAN_TILES", "DF_OCEAN_TO_SHORE_TILES", "DF_REMAP_INVISIBLETILES", "DF_REMAP_INVISIBLETILES_INVERTED")
if not DF_OCEAN_TILES then
    DF_OCEAN_TILES = {}
    DF_SHORE_TO_OCEAN_TILES = {}
    DF_OCEAN_TO_SHORE_TILES = {}
    DF_REMAP_INVISIBLETILES = {}
    DF_REMAP_INVISIBLETILES_INVERTED = {}
end

if not WORLDGEN_MAIN and not TileGroups.DFOceanTiles then
    TileGroups.NonDFOceanTiles = TileGroupManager:AddTileGroup(TileGroups.OceanTiles)
    TileGroups.DFOceanTiles = TileGroupManager:AddTileGroup()
end

local function TestGroundImage(name)
    local trimmed_name = name:gsub("%.tex$", "")..".tex"
    if resolvefilepath_soft(trimmed_name, true) then
        return true
    end
    return resolvefilepath_soft("levels/tiles/"..trimmed_name, true) and true or false
end

local function TestGroundNoise(name)
    local trimmed_name = name:gsub("%.tex$", "")..".tex"
    if softresolvefilepath(trimmed_name, true) then
        return true
    end
    return resolvefilepath_soft("levels/textures/"..trimmed_name, true) and true or false
end

-- Validate ground def so we don't try to use assets that only exist in core during worldgen.
local function ValidateGroundDef(def)
    if def == nil then return end

    local name, noise_texture = def.name, def.noise_texture
    if name == nil or noise_texture == nil then
        return
    end

    if TestGroundImage(name) and TestGroundNoise(noise_texture) then
        return
    end

    def.name = "dirt"
    def.noise_texture = "Ground_noise_dirt"
    def.atlas = nil
end

-------------------------------
--      Get Tile Data        --
-------------------------------

local function GetGroundTileDef(tile_id)
    for i=#ground_table, 1, -1 do
        local ground = ground_table[i]
        if ground[1] == tile_id then
            return deepcopy(ground[2])
        end
    end
end

local function GetMinimapTileDef(tile_id)
    for i, ground in pairs(minimap_table) do
        if ground[1] == tile_id then
            return deepcopy(ground[2])
        end
    end
end

-------------------------------
--        Add Tiles          --
-------------------------------

local AddTile, MakeTileInvisible, AddShoreTile

MakeTileInvisible = function(def)
    def.ground_tile_def = def.ground_tile_def or {}
    def.ground_tile_def.name = "tile_invisible"
    def.ground_tile_def.noise_texture = "ground_invisible"
end

AddShoreTile = function(tile, def)
    local shore_tile = tile .. "_SHORE"
    local shore_def = deepcopy(def)
    shore_def.ground_tile_def = shore_def.ground_tile_def or {}
    shore_def.ground_tile_def.is_shoreline = true
    MakeTileInvisible(shore_def)
    AddTile(shore_tile, shore_def)
    DF_SHORE_TO_OCEAN_TILES[WORLD_TILES[shore_tile]] = WORLD_TILES[tile]
    DF_OCEAN_TO_SHORE_TILES[WORLD_TILES[tile]] = WORLD_TILES[shore_tile]

    RegisterParticleWorldTileState(WORLD_TILES[shore_tile], "levels/particle_tiles/".. string.lower(tile) .. ".tex", "shaders/df_tileoceanstate_animated.ksh", {has_variant = true, layer = LAYER_GROUND})
    SetProxyParticleWorldTileState(WORLD_TILES[shore_tile], WORLD_TILES[tile])
end

AddTile = function(tile, def)
    if not WORLD_TILES[tile] then

        ValidateGroundDef(def.ground_tile_def)

        local range = def.tile_range
        if range == TileRanges.DF_OCEAN then
            MakeTileInvisible(def)
            range = TileRanges.OCEAN
        elseif type(range) == "function" then
            range = TileRanges.NOISE
        end

        DFENV.AddTile(tile, range, def.tile_data, def.ground_tile_def, def.minimap_tile_def, def.turf_def)

        local tile_id = WORLD_TILES[tile]
        if def.tile_range == TileRanges.DF_OCEAN then
            if not WORLDGEN_MAIN then
                TileGroupManager:AddInvalidTile(TileGroups.TransparentOceanTiles, tile_id)
                TileGroupManager:AddInvalidTile(TileGroups.NonDFOceanTiles, tile_id)
                TileGroupManager:AddValidTile(TileGroups.DFOceanTiles, tile_id)
            end
            DF_OCEAN_TILES[tile_id] = true
            if def.ground_tile_def == nil or not def.ground_tile_def.is_shoreline then
                AddShoreTile(def.tile, def)
            end
        elseif def.tile_range == TileRanges.LAND then
        elseif type(def.tile_range) == "function" then
            NoiseFunctions[tile_id] = def.tile_range
        end
    end
end

-------------------------------
--           Init            --
-------------------------------

local function AddTileDefs(tiledefs)
    for i, def in pairs(tiledefs) do
        AddTile(def.tile, def)
    end
end

DF_TILEDEFS_UTIL = {
    TileRanges = TileRanges,
    AddTile = AddTile,
    GetGroundTileDef = GetGroundTileDef,
    GetMinimapTileDef = GetMinimapTileDef,
    AddTileDefs = AddTileDefs,
    AddShoreTile = AddShoreTile,
}
