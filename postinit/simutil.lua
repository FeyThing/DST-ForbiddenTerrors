local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

require("simutil")

local _CanEntitySeeInStorm = EvilforestUpvalue(CanEntitySeeInStorm, "_CanEntitySeeInStorm")

local function _IsEntityInFog(inst)
    if inst.components.df_fogtracker ~= nil then
        return inst.components.df_fogtracker:GetFogIntensity() >= TUNING.DF_FOG_VISION_CUTOFF
    end
end

local _CanEntitySeePoint = CanEntitySeePoint
function CanEntitySeePoint(inst, x, y, z, ...)
    return _CanEntitySeePoint(inst, x, y, z, ...)
        and (not _IsEntityInFog(inst) or
            _CanEntitySeeInStorm(inst) or
            inst:GetDistanceSqToPoint(x, y, z) < TUNING.DF_FOG_VISION_RANGE_SQ)
end

