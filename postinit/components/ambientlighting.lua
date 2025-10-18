local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local debug = debug
local select = select

AddComponentPostInit("ambientlighting", function(self, inst)
    local OnPhaseChanged = self.inst:GetEventCallback("phasechanged", nil, "scripts/components/ambientlighting.lua")

    local _, i_realcolour = EvilforestUpvalue(OnPhaseChanged, "_realcolour")
    local _, i_overridecolour = EvilforestUpvalue(OnPhaseChanged, "_overridecolour")

    local get_realcolour = function() return select(2, debug.getupvalue(OnPhaseChanged, i_realcolour)) end
    local get_overridecolour = function() return select(2, debug.getupvalue(OnPhaseChanged, i_overridecolour)) end

    function self:GetRealColour()
        local _realcolour = get_realcolour()
        return _realcolour.currentcolour.x, _realcolour.currentcolour.y, _realcolour.currentcolour.z
    end

    function self:GetOverrideColour()
        local _overridecolour = get_overridecolour()
        return _overridecolour.currentcolour.x, _overridecolour.currentcolour.y, _overridecolour.currentcolour.z
    end
end)
