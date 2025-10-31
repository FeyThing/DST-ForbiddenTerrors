
local SourceModifierList = require("util/sourcemodifierlist")

local function OnEnterDark(inst)
    local self = inst.components.df_ichormanager
    self:AddRateSource(self.inst, TUNING.DF_ICHOR_RATE.DARKNESS, "darkness")
end

local function OnEnterLight(inst)
    local self = inst.components.df_ichormanager
    self:RemoveRateSource(self.inst, "darkness")
end

local function OnInvincibleToggle(inst, data)
    local self = inst.components.df_ichormanager
    if data.invincible then
        self:AddImmunitySource(self.inst, "invincible")
    else
        self:RemoveImmunitySource(self.inst, "invincible")
    end
end

local function OnDeath(inst)
    local self = inst.components.df_ichormanager
    self:AddImmunitySource(self.inst, "death")
end

local function OnRespawned(inst)
    local self = inst.components.df_ichormanager
    self:RemoveImmunitySource(self.inst, "death")
end

local function OnInit(inst, self)
    self.inittask = nil
    inst:ListenForEvent("enterdark", OnEnterDark)
    inst:ListenForEvent("enterlight", OnEnterLight)
    inst:ListenForEvent("invincibletoggle", OnInvincibleToggle)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_respawnedfromghost", OnRespawned)

	if inst.components.health ~= nil and inst.components.health:IsDead() then
		self:AddImmunitySource(self.inst, "death")
	end
	if inst.components.health ~= nil and inst.components.health:IsInvincible() then
		self:AddImmunitySource(self.inst, "invincible")
	end
	if not inst:IsInLight() then
		self:AddRateSource(self.inst, TUNING.DF_ICHOR_RATE.DARKNESS, "darkness")
	end

    self:CheckForUpdate()
end

local function onlevel(self, level)
    self.inst.replica.df_ichormanager:SetLevel(level)
end

local DF_IchorManager = Class(function(self, inst)
    self.inst = inst

    self.enabled = false

    self.level = 0
    self.percent = 0

    self.rate = 0
    self.immunity = false

    self.ratesources = SourceModifierList(inst, 0, SourceModifierList.additive)
    self.immunitysources = SourceModifierList(inst, false, SourceModifierList.boolean)

    self.inittask = inst:DoTaskInTime(0, OnInit, self)
end,
nil,
{
    level = onlevel,
})

function DF_IchorManager:AddRateSource(src, rate, key)
    self.ratesources:SetModifier(src, rate, key)
    self.rate = self.ratesources:Get()
end

function DF_IchorManager:RemoveRateSource(src, key)
    self.ratesources:RemoveModifier(src, key)
    self.rate = self.ratesources:Get()
end

function DF_IchorManager:AddImmunitySource(src, key)
    self.immunitysources:SetModifier(src, true, key)
    self.immunity = self.immunitysources:Get()
    self:CheckForUpdate()
end

function DF_IchorManager:RemoveImmunitySource(src, key)
    self.immunitysources:RemoveModifier(src, key)
    self.immunity = self.immunitysources:Get()
    self:CheckForUpdate()
end

function DF_IchorManager:CheckForUpdate()
    if self.immunity then
        self:_Start()
    else
        self:_Stop()
    end
end

function DF_IchorManager:_Start()
    if self.enabled then
        self.enabled = false
        self.inst:StopUpdatingComponent(self) 
        self:DoDelta(0)
    end
end

function DF_IchorManager:_Stop()
    if not self.enabled then
        self.enabled = true
        self.inst:StartUpdatingComponent(self) 
        self:DoDelta(0)
    end
end

function DF_IchorManager:OnRemoveFromEntity()
    self:_Stop()
    if self.inittask ~= nil then
        self.inittask:Cancel()
        self.inittask = nil
    else
        self.inst:RemoveEventCallback("enterdark", OnEnterDark)
        self.inst:RemoveEventCallback("enterlight", OnEnterLight)
        self.inst:RemoveEventCallback("invincibletoggle", OnInvincibleToggle)
        self.inst:RemoveEventCallback("death", OnDeath)
        self.inst:RemoveEventCallback("ms_respawnedfromghost", OnRespawned)
    end
end

local SPAWN_THRESH = 100
local DESPAWN_THRESH = 80

local LEVEL_THRESHOLDS = {10, 20, 40, 60, 80}
local MAX_LEVEL = #LEVEL_THRESHOLDS
function DF_IchorManager:DoDelta(delta)
    if not self.immunity then
        self.percent = math.clamp(self.percent + delta, 0, 100)
    else
        self.percent = 0
    end

    local level = MAX_LEVEL
    for i, thresh in ipairs(LEVEL_THRESHOLDS) do
        if self.percent < thresh then
            level = i - 1
            break
        end
    end

    if level ~= self.level then
        self.level = level
    end

    if self.seeker == nil then
        if self.percent >= SPAWN_THRESH and not TheWorld.state.isday then
            self:SpawnSeeker()
        end
    else
        if self.percent <= DESPAWN_THRESH or TheWorld.state.isday then 
            self:DespawnSeeker()
        end
    end
end

function DF_IchorManager:SetPercent(perc)
    self.percent = perc
    self:DoDelta(0)
end

local DF_ICHOR_MUST_TAGS = { "df_ichoraura" }
local DF_ICHOR_CANT_TAGS = { "INLIMBO" }
function DF_IchorManager:OnUpdate(dt)
    local rate = self.rate
    if self.seeker ~= nil or not self.inst.indarkforest then
        rate = math.min(rate, TUNING.DF_ICHOR_BLOCKED_MAX_RATE)
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.DF_ICHOR_AURA_SEACH_RANGE, DF_ICHOR_MUST_TAGS, DF_ICHOR_CANT_TAGS)
    for i, v in ipairs(ents) do
        if v.components.df_ichoraura ~= nil and v ~= self.inst then
            rate = rate + v.components.df_ichoraura:GetAura(self.inst)
        end
    end


    if GetClosestDarkForestTileToPoint(x, 0, z, 12) ~= nil then
					
        if TheWorld.state.isnight and TheWorld.state.isnewmoon then
            rate = rate + TUNING.DF_ICHOR_MOON_RATE
        end

        if self.inst:HasTag("crazy") or (self.inst.components.sanity and self.inst.components.sanity:IsCrazy()) then
            rate = rate + TUNING.DF_ICHOR_MOON_RATE
        end

        if rate ~= 0 or TheWorld.state.isnewmoon or self.inst:HasTag("crazy") or (self.inst.components.sanity and self.inst.components.sanity:IsCrazy()) then
            self:DoDelta(rate)
        end
        return
    end
end

function DF_IchorManager:DespawnSeeker()
    if self.seeker == nil then
        return
    elseif not self.seeker:IsValid() then
        self.seeker = nil
    end

    self.seeker:SetHider(nil)
    self.seeker = nil
end

function DF_IchorManager:SpawnSeeker()
    self:DespawnSeeker()

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local angle = math.random() * TWOPI
    x = x + 15 * math.cos(angle)
    z = z - 15 * math.sin(angle)

    local seeker = SpawnPrefab("df_shadow_seeker")
    seeker.Transform:SetPosition(x, 0, z)

    seeker:SetHider(self.inst)

    self.inst:ListenForEvent("onremove", function()
        if seeker == self.seeker then
           self:DespawnSeeker()
        end
    end, seeker)

    self.inst:ListenForEvent("entitysleep", function()
        seeker:DoTaskInTime(0, function() seeker:Remove() end)
    end, seeker)

    seeker:ListenForEvent("onremove", function()
        if seeker == self.seeker then
           self:Remove()
        end
    end, self.inst)

    self.seeker = seeker
end

function DF_IchorManager:OnSave()
    return {
        percent = self.percent
    }
end

function DF_IchorManager:OnLoad(data)
    if data == nil then
        return
    end

    if data.percent ~= nil then
        self:SetPercent(data.percent)
    end
end

return DF_IchorManager
