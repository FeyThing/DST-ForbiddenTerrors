local UIAnim = require("widgets/uianim")

local DF_IchorOver = Class(UIAnim, function(self, owner)
	self.owner = owner
	UIAnim._ctor(self)

	self:SetClickable(false)

	self:SetHAnchor(ANCHOR_MIDDLE)
	self:SetVAnchor(ANCHOR_MIDDLE)
	self:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)

    self:GetAnimState():SetBank("df_ichor_over")
    self:GetAnimState():SetBuild("df_ichor_over")
    self:GetAnimState():PlayAnimation("over_idle")

	self.level = 0

    if owner ~= nil then
        self.inst:ListenForEvent("df_ichorlevelchanged", function(owner, level)
            self:SetLevel(level, TheFrontEnd:GetFadeLevel() >= 1)
        end, owner)
        self.inst:DoTaskInTime(0, function()
            if owner.replica.df_ichormanager then
                self:SetLevel(owner.replica.df_ichormanager:GetLevel(), true) 
            end
        end)
	end
end)

function DF_IchorOver:SetLevel(level, insant)
    if self.level == level then
        return
    end

    if not insant and level == 0 then
        self:GetAnimState():PlayAnimation("over_pst")
        self:GetAnimState():PushAnimation("over_idle")
    elseif not insant and self.level == 0 then
        self:GetAnimState():PlayAnimation("over_pre")
        self:GetAnimState():PushAnimation("over_idle_"..level, true)
    else
        self:GetAnimState():PlayAnimation("over_idle_"..level, true)
    end

    self.level = level
end

return DF_IchorOver
