local DFENV = env
GLOBAL.setfenv(1, GLOBAL)
--------------------------------------------------------------

local ShadowCreatureBrain = require("brains/shadowcreaturebrain")

local targetatsea = DFUpvalueHacker.GetUpvalue(ShadowCreatureBrain.OnStart, "targetatsea")
local function DF_targetatsea(inst, ...)
    if inst.components.combat.target and inst.followtoboat then
        local target = inst.components.combat.target
        if target:IsOnDFOcean() then
           return true
        end
    end
    if inst.components.combat.target and inst.followtoland then
        local target = inst.components.combat.target
        if not target:IsOnDFOcean() then
           return true
        end
    end
    return targetatsea(inst, ...)
end

DFUpvalueHacker.SetUpvalue(ShadowCreatureBrain.OnStart, DF_targetatsea, "targetatsea")
