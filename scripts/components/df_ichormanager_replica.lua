local function OnIchorLevelDirty(inst)
    local self = inst.replica.df_ichormanager
    if self ~= nil then
        self:SetLevel(self._level:value())
    end
end

local DF_IchorManager = Class(function(self, inst)
    self.inst = inst

    self.level = 0
    self._level = net_tinybyte(inst.GUID, "df_ichormanager.level", "df_ichorleveldirty")

    if not TheWorld.ismastersim then
        self.inst:ListenForEvent("df_ichorleveldirty", OnIchorLevelDirty)
    end
end)

local MAX_LEVEL = 5
function DF_IchorManager:SetLevel(level)
    if TheWorld.ismastersim then
        self._level:set(level)
    end

    if not TheNet:IsDedicated() and self.inst == ThePlayer then
        if level > 3 then
            if self.level <= 3 then
               TheFocalPoint.SoundEmitter:PlaySound("df_sound/set_sfx/HUD/df_ichor_heartbeat", "df_ichor_heartbeat")
            end
            TheFocalPoint.SoundEmitter:SetVolume("df_ichor_heartbeat", math.min(level, MAX_LEVEL)/MAX_LEVEL)
        else
            TheFocalPoint.SoundEmitter:KillSound("df_ichor_heartbeat")
        end
    end

    self.level = level
    self.inst:PushEvent("df_ichorlevelchanged", level)
end

function DF_IchorManager:GetLevel()
    return self.level
end

return DF_IchorManager
