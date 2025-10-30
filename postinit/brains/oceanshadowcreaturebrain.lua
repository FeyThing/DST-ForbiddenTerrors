local DFENV = env
GLOBAL.setfenv(1, GLOBAL)
--------------------------------------------------------------

local OceanShadowCreatureBrain = require("brains/oceanshadowcreaturebrain")

local targetonland = DFUpvalueHacker.GetUpvalue(OceanShadowCreatureBrain.OnStart, "targetonland")
local function DF_targetonland(inst, ...)
    if inst.components.combat.target then
        local target = inst.components.combat.target
        if target:IsOnDFOcean() then
            return true
        end
    end
    return targetonland(inst, ...)
end

DFUpvalueHacker.SetUpvalue(OceanShadowCreatureBrain.OnStart, DF_targetonland, "targetonland")
