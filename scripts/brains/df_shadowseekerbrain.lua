require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"

local MIN_FOLLOW = 5
local MED_FOLLOW = 15
local MAX_FOLLOW = 30

local function GetHider(inst)
    local combat = inst.components.combat
    if combat ~= nil then
        return combat.target
    end
end

local function GetVisibleHider(inst)
	local hider = GetHider(inst)
	if hider == nil or hider.sg == nil or not hider.sg:HasStateTag("hiding") then
		return hider
	end
end

local function GetHiderPosition(inst)
    local hider = GetHider(inst)
    return hider ~= nil and hider:GetPosition() or nil
end

local ShadowCreatureBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function ShadowCreatureBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode( function() return GetVisibleHider(self.inst) ~= nil end, "I SEE YOU", 
            ChaseAndAttack(self.inst, 100)
        ),
        Follow(self.inst, function() return GetHider(self.inst) end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),
        Wander(self.inst, function() return GetHiderPosition(self.inst) end, 20),
    }, .25)

    self.bt = BT(self.inst, root)
end

return ShadowCreatureBrain
