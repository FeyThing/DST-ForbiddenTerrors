GLOBAL.setfenv(1, GLOBAL)

--
local DF_OCEAN_TILES = DF_OCEAN_TILES
--

-- Note: Sorting by the tile id is not accurate idk why ds and dst does it... -Half

local RenderTileOrder = nil

local _AddRenderLayer = Map.AddRenderLayer
function Map:AddRenderLayer(...)
    if RenderTileOrder == nil then
        RenderTileOrder = {}
        local tiles = require("worldtiledefs")
        for i, v in ipairs(tiles.ground) do
            RenderTileOrder[v[1]] = i
        end
    end
    _AddRenderLayer(self, ...)
end

local function TileRendersOver(tile1, tile2)
    return (RenderTileOrder[tile1] or 0) > (RenderTileOrder[tile2] or 0)
end

function Map:TileRendersOver(tile1, tile2)
    return TileRendersOver(tile1, tile2)
end

local _SetTile = Map.SetTile
function Map:SetTile(x, y, tile, ...)
    local remap = DF_REMAP_INVISIBLETILES[tile]
    if remap then
        tile = remap[self:GetTile(x, y)] or tile
    end
    _SetTile(self, x, y, tile, ...)
end

local _GetTile = Map.GetTile
function Map:GetTile(x, y, ...)
    local tile = _GetTile(self, x, y, ...)
    return DF_REMAP_INVISIBLETILES_INVERTED[tile] or tile
end

-- Unmodified original tile
Map.InternalGetTile = _GetTile

local _GetTileAtPoint = Map.GetTileAtPoint
function Map:GetTileAtPoint(x, y, ...)
    local tile = _GetTileAtPoint(self, x, y, ...)
    return DF_REMAP_INVISIBLETILES_INVERTED[tile] or tile
end

local FOGBLOCKER_TAGS = {"df_fog_blocker", "lightsource", "fire"}
local FOGBLOCKER_NOT_TAGS = {"INLIMBO"} -- Inv items like torch, miner hats, and such are recognized from their fire fxs
local FOGBLOCKER_DIST = 10

function Map:IsDarkForestFogBlocked(x, y, z)
	local ismastersim = TheWorld.ismastersim
	if (ismastersim and not TheWorld:HasTag("df_fog_ongoing")) or (not ismastersim and ThePlayer and not ThePlayer:HasTag("df_fog_ongoing")) then
		return true, true
	end
	
	local ents = TheSim:FindEntities(x, y, z, FOGBLOCKER_DIST, nil, FOGBLOCKER_NOT_TAGS, FOGBLOCKER_TAGS)
	table.insert(ents, ThePlayer) -- Other players are ignored but not ourselves
	
	for i, v in ipairs(ents) do
		local is_light = v:HasAnyTag(FOGBLOCKER_TAGS)
		local ent_range = (v._fogblockrange == nil and not v:HasTag("player") and TUNING.DF_FOG_BLOCK_RANGES.FIRE) or 0
		
		local range = math.max(v._fogblockrange and v._fogblockrange:value() or 0, ent_range)
		
		local dist = v:GetDistanceSqToPoint(x, y, z)
		if range > 0 and dist <= range * range then
			return true, is_light
		end
	end
	
	return false
end

---------------------------------------------------------

local function _test_is_df_ocean_tile_at_point(x, y, z, map)
    return DF_OCEAN_TILES[map:GetTileAtPoint(x, y, z)] ~= nil
end

--------------------- IsCloseToTile ---------------------

Map.IsCloseToTile = Map.IsCloseToTile or function(self, x, y, z, radius, tile_scale, typefn, ...)
    if radius == 0 then return typefn(x, y, z, ...) end
    -- Correct improper radiuses caused by changes to the radius based on overhang
    if radius < 0 then return self:IsSurroundedByTile(x, y, z, radius * -1, tile_scale, typefn, ...) end
    
    local num_edge_points = math.ceil((radius*2) / tile_scale) - 1

    --test the corners first
    if typefn(x + radius, y, z + radius, ...) then return true end
    if typefn(x - radius, y, z + radius, ...) then return true end
    if typefn(x + radius, y, z - radius, ...) then return true end
    if typefn(x - radius, y, z - radius, ...) then return true end

    --if the radius is less than 2(1 after the -1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return false end

    local dist = (radius*2) / (num_edge_points + 1)
    --test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if typefn(x - radius + idist, y, z + radius, ...) then return true end
        if typefn(x - radius + idist, y, z - radius, ...) then return true end
        if typefn(x - radius, y, z - radius + idist, ...) then return true end
        if typefn(x + radius, y, z - radius + idist, ...) then return true end
    end

    --test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if typefn(x - radius + idist, y, z - radius + jdist, ...) then return true end
        end
    end
    return false
end

function Map:IsCloseToDFOcean(x, y, z, radius)
    return self:IsCloseToTile(x, y, z, radius - 1, 4, _test_is_df_ocean_tile_at_point, self)
end

---------------------------------------------------------

------------------- IsSurroundedByTile ------------------

Map.IsSurroundedByTile = Map.IsSurroundedByTile or function(self, x, y, z, radius, tile_scale, typefn, ...)
    if radius == 0 then return typefn(x, y, z, ...) end
    -- Correct improper radiuses caused by changes to the radius based on overhang
    if radius < 0 then return self:IsCloseToTile(x, y, z, radius * -1, tile_scale, typefn, ...) end

    local num_edge_points = math.ceil((radius*2) / tile_scale) - 1

    --test the corners first
    if not typefn(x + radius, y, z + radius, ...) then return false end
    if not typefn(x - radius, y, z + radius, ...) then return false end
    if not typefn(x + radius, y, z - radius, ...) then return false end
    if not typefn(x - radius, y, z - radius, ...) then return false end

    --if the radius is less than 2(1 after the -1), it won't have any edges to test and we can end the testing here.
    if num_edge_points == 0 then return true end

    local dist = (radius*2) / (num_edge_points + 1)
    --test the edges next
    for i = 1, num_edge_points do
        local idist = dist * i
        if not typefn(x - radius + idist, y, z + radius, ...) then return false end
        if not typefn(x - radius + idist, y, z - radius, ...) then return false end
        if not typefn(x - radius, y, z - radius + idist, ...) then return false end
        if not typefn(x + radius, y, z - radius + idist, ...) then return false end
    end

    --test interior points last
    for i = 1, num_edge_points do
        local idist = dist * i
        for j = 1, num_edge_points do
            local jdist = dist * j
            if not typefn(x - radius + idist, y, z - radius + jdist, ...) then return false end
        end
    end
    return true
end

function Map:IsSurroundedByDFOcean(x, y, z, radius)
    return self:IsSurroundedByTile(x, y, z, radius + 1, 4, _test_is_df_ocean_tile_at_point, self) 
end

---------------------------------------------------------
