local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Drownable = require("components/drownable")

local function IsOnDFOcean(self)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return DF_OCEAN_TILES[tile] ~= nil
end

local _IsOverWater = Drownable.IsOverWater
function Drownable:IsOverWater(...)
    return _IsOverWater(self, ...) and not IsOnDFOcean(self)
end