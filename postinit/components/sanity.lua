local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local Sanity = require("components/sanity")

local _DoDelta = Sanity.DoDelta
function Sanity:DoDelta(delta, ...)
    if delta ~= nil and delta > 0 then
        self.inst.components.df_ichormanager:DoDelta(-delta * TUNING.DF_ICHOR_SANITY_DELTA_MULT) 
    end
    return _DoDelta(self, delta, ...)
end