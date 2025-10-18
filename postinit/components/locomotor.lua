local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local LocoMotor = require("components/locomotor")

local _ScanForPlatformInDir_Internal = LocoMotor.ScanForPlatformInDir_Internal

function LocoMotor:ScanForPlatformInDir_Internal(...)

    local _IsVisualGroundAtPoint = Map.IsVisualGroundAtPoint
    function Map:IsVisualGroundAtPoint(x, y, z, ...)
        local tile = self:GetTileAtPoint(x, y, z)
        return DF_OCEAN_TILES[tile] ~= nil or _IsVisualGroundAtPoint(self, x, y, z, ...)
    end
    local rets = {_ScanForPlatformInDir_Internal(self, ...)}

    Map.IsVisualGroundAtPoint = _IsVisualGroundAtPoint

    return unpack(rets)
end