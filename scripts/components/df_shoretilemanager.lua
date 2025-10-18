--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local DF_OCEAN_TILES = DF_OCEAN_TILES
local DF_SHORE_TO_OCEAN_TILES = DF_SHORE_TO_OCEAN_TILES
local DF_OCEAN_TO_SHORE_TILES = DF_OCEAN_TO_SHORE_TILES
local TileGroupManager = TileGroupManager

--------------------------------------------------------------------------
--[[ ShoreTileManager class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "IAShoreTileManager should not exist on client")

--------------------------------------------------------------------------
--[[ constants ]]
--------------------------------------------------------------------------

local SURROUNDING_OFFSETS = {
    {x = 1, y = 1},
    {x = 1, y = 0},
    {x = 1, y = -1},
    {x = 0, y = 1},
    {x = 0, y = -1},
    {x = -1, y = 1},
    {x = -1, y = 0},
    {x = -1, y = -1},
}

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _world = TheWorld
local _map = _world.Map
local _patched_shoreline = false

--------------------------------------------------------------------------
--[[ Private Member Functions ]]
--------------------------------------------------------------------------

local function IsAboveGroundOcean(tile)
    return DF_OCEAN_TILES[tile] ~= nil
end

local function IsShore(x, y)
    for _, offset in ipairs(SURROUNDING_OFFSETS) do
        local tile = _map:GetTile(x + offset.x, y + offset.y)
        if tile ~= nil and not IsAboveGroundOcean(tile) and tile ~= WORLD_TILES.INVALID then
            return true
        end
    end
end

local function ConvertTile(x, y)
    local tile = _map:GetTile(x, y)
    if DF_SHORE_TO_OCEAN_TILES[tile] ~= nil then
        if not IsShore(x, y) then
            _map:SetTile(x, y, DF_SHORE_TO_OCEAN_TILES[tile])
        end
    elseif DF_OCEAN_TO_SHORE_TILES[tile] ~= nil then
        if IsShore(x, y) then
            _map:SetTile(x, y, DF_OCEAN_TO_SHORE_TILES[tile])
        end
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    data.patched_shoreline = _patched_shoreline
    return data
end

function self:OnLoad(data)
    if data then
        _patched_shoreline = data.patched_shoreline
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnTerraform(src, data)
    if not data then return end

    local x, y, original_tile, tile = data.x, data.y, data.original_tile, data.tile
    
    if DF_SHORE_TO_OCEAN_TILES[tile] == original_tile or DF_OCEAN_TO_SHORE_TILES[tile] == original_tile then return end

    ConvertTile(x, y)

    if IsAboveGroundOcean(tile) ~= IsAboveGroundOcean(original_tile) then
        for _, offset in ipairs(SURROUNDING_OFFSETS) do
            ConvertTile(x + offset.x, y + offset.y)
        end
    end
end

local function Initialize()
    if _patched_shoreline then return end

    local w, h = _map:GetSize()
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            ConvertTile(x, y)
        end
    end
    _patched_shoreline = true
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("onterraform", OnTerraform)
inst:DoStaticTaskInTime(0, Initialize)

 
end)