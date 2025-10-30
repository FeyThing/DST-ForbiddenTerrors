local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

DFENV.AddComponentPostInit("shadowcreaturespawner", function(self)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
local inst = self.inst

--Private
local _map = TheWorld.Map

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function DF_SpawnOceanShadowCreature(player)
    local inst = SpawnPrefab("df_swimminghorror")
    if not (player.components.sanity:GetPercent() < .1 and math.random() < TUNING.TERRORBEAK_SPAWN_CHANCE) then
        inst:SetCrawlingHorror()
    end
    return inst
end

local _players = DFUpvalueHacker.GetUpvalue(self.SpawnShadowCreature, "_players")
local StartTracking = DFUpvalueHacker.GetUpvalue(self.SpawnShadowCreature, "StartTracking")
if not _players or not StartTracking then return end
function self:DF_SpawnShadowCreature(player, params)
    params = params or _players[player]

    local position = player:GetPosition()
    if player:IsOnDFOcean() then

        local angle = math.random() * TWOPI
        local offset = FindSwimmableOffset(position, angle, 15, 12)
        local spawn_x = position.x + offset.x
        local spawn_z = position.z + offset.z

        if _map:IsOceanAtPoint(spawn_x, 0, spawn_z) then

            local ent = DF_SpawnOceanShadowCreature(player)
            ent.Transform:SetPosition(spawn_x, 0, spawn_z)
            StartTracking(player, params, ent)
            return ent
        end
    end
end

local _SpawnShadowCreature = self.SpawnShadowCreature
function self:SpawnShadowCreature(player, params, ...)
    if self:DF_SpawnShadowCreature(player, params) ~= nil then return end
    return _SpawnShadowCreature(self, player, params, ...)
end

DFUpvalueHacker.HideFn(self.SpawnShadowCreature, _SpawnShadowCreature)
end)


