local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local Sanity = require("components/sanity")

local _DoDelta = Sanity.DoDelta
function Sanity:DoDelta(delta, overtime, ...)
    if delta ~= nil and delta > 0 and not overtime then
        self.inst.components.df_ichormanager:DoDelta(-delta * TUNING.DF_ICHOR_SANITY_DELTA_MULT) 
    end
    return _DoDelta(self, delta, overtime, ...)
end