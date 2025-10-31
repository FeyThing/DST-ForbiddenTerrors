local function UpdateFar(inst)
    --Should be gone, i hope.
    local self = inst.components.df_creatureprox
    self:_UpdateCreaturesFar()
end

local function OnNearCollisionCallback(collider, creature)
    if creature == nil or creature.Physics == nil or not creature.Physics:IsActive() then
        return
    end

    local self = collider._creature_prox
    self:_UpdateCreatureNear(creature)
end

local function Init(inst)
    local self = inst.components.df_creatureprox
    if self.enabled == nil then
        self:SetEnabled(true)
    end
end

local function onnear(self, near)
    if self.collider ~= nil then
        self.collider.Physics:SetCapsule(near, 2)
    end
end

local DF_CreatureProx = Class(function(self, inst)
    self.inst = inst
    self.near = 2
    self.far = 3
    self.isclose = false
    self.period = .333
    self.onnear = nil
    self.onfar = nil
    self.task = nil
    self.testfn = nil

    self.close_creatures = {}

    self.enabled = nil

    self.init_task = inst:DoTaskInTime(0, Init)
end,
nil,
{
    near = onnear,
})

function DF_CreatureProx:SetOnCreatureNear(fn)
    self.onnear = fn
end

function DF_CreatureProx:SetOnAnyCreatureFar(fn)
    self.onanyfar = fn
end

function DF_CreatureProx:SetOnAnyCreatureNear(fn)
    self.onanynear = fn
end

function DF_CreatureProx:SetOnCreatureFar(fn)
    self.onfar = fn
end

function DF_CreatureProx:SetTestfn(fn)
    self.testfn = fn
end

function DF_CreatureProx:IsCreatureClose()
    return self.isclose
end

function DF_CreatureProx:SetDist(near, far)
    self.near = near
    self.far = far
end

function DF_CreatureProx:Start()
    if self.collider == nil then
        self.collider = SpawnPrefab("df_creatureprox_collider")
        self.collider.Physics:SetCapsule(self.near, 2)
        self.collider.Physics:SetCollisionCallback(OnNearCollisionCallback)
        self.collider._creature_prox = self
        self:UpdatePosition()
    end
end

function DF_CreatureProx:Stop()
    if self.collider ~= nil then
        for creature, _ in pairs(self.close_creatures) do
            if self.onfar then
                self.onfar(self.inst, creature)
            end
        end
        self.close_creatures = {}
        self:_UpdateIsClose(false)

        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end

        self.collider:Remove()
        self.collider = nil
    end
end

function DF_CreatureProx:SetEnabled(enabled)
    if enabled == self.enabled then
        return
    end

    if enabled then
        self:Start()
    else
        self:Stop()
    end

    self.enabled = enabled
end

function DF_CreatureProx:OnEntitySleep()
    if self.enabled then
        self:Stop()
    end
end

function DF_CreatureProx:OnEntityWake()
    if self.enabled then
        self:Start()
    end
end

function DF_CreatureProx:_UpdateCreatureNear(creature)
    if self.close_creatures[creature] ~= nil or self.testfn ~= nil and not self.testfn(creature) then
        return
    end

    self.close_creatures[creature] = true
    if self.onnear then
        self.onnear(self.inst, creature)
    end

    self:_UpdateIsClose(next(self.close_creatures) ~= nil)
end

function DF_CreatureProx:_UpdateCreaturesFar()
    local farsq = self.far * self.far
	for creature, _ in pairs(self.close_creatures) do
        if not creature:IsValid() or creature:GetDistanceSqToInst(self.inst) > farsq then
            self.close_creatures[creature] = nil
            if self.onfar then
                self.onfar(self.inst, creature)
            end
        end
    end

    self:_UpdateIsClose(next(self.close_creatures) ~= nil)
end

function DF_CreatureProx:_UpdateIsClose(isclose)
    if self.isclose == isclose then
        return
    end

    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end

    if isclose then
        if self.onanynear then
            self.onanynear(self.inst)
        end
        self.task = self.inst:DoPeriodicTask(self.period, UpdateFar)
    else
        if self.onanyfar then
            self.onanyfar(self.inst)
        end
    end
    self.isclose = isclose
end

function DF_CreatureProx:OnRemoveEntity()
    self:Stop()
end

function DF_CreatureProx:OnRemoveFromEntity()
    self:Stop()
end

function DF_CreatureProx:UpdatePosition() --asgerrr: ideally the collider would just follow the parent entity automatically, but none of the ways i have tried (making the collider a child entity, using Physics.ConstrainTo) have worked without causing other issues
    if self.collider ~= nil then
        self.collider.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    end
end

return DF_CreatureProx
