local DFENV = env
GLOBAL.setfenv(1, GLOBAL)



local _SetLayer = AnimState.SetLayer
function AnimState:SetLayer(layer, ...)
    if layer <= LAYER_BELOW_GROUND and IsWorldDFEnabled() then
        layer = LAYER_BACKGROUND -- TODO: if sorting issues occur use ground and increase the sort
    end
    return _SetLayer(self, layer, ...)
end

AnimState.ForceSetLayer = _SetLayer
