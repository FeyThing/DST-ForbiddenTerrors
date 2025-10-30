local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Drownable = require("components/drownable")

local _IsOverWater = Drownable.IsOverWater
function Drownable:IsOverWater(...)
    return _IsOverWater(self, ...) and not self.inst:IsOnDFOceanTile(true)
end