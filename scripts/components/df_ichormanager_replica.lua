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

function DF_IchorManager:SetLevel(level)
    if TheWorld.ismastersim then
        self._level:set(level)
    end
    self.level = level
    self.inst:PushEvent("df_ichorlevelchanged", level)
end

function DF_IchorManager:GetLevel()
    return self.level
end

return DF_IchorManager
