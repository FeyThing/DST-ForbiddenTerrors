require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"

local MIN_FOLLOW = 0
local MED_FOLLOW = 8
local MAX_FOLLOW = 16

local SEE_HIDINGSPOT_DIST = 4

local HIDINGSPOT_TAGS = {"df_canhide"}
local HIDINGSPOT_NO_TAGS = {"INLIMBO", "fire"}

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

local function LookInHidingSpot(inst)
	if not inst.wants_to_peek then
		return
	end
	
	local pt = inst:GetPosition()
	local ents = shuffleArray(TheSim:FindEntities(pt.x, pt.y, pt.z, SEE_HIDINGSPOT_DIST, HIDINGSPOT_TAGS, HIDINGSPOT_NO_TAGS))
	
	local target = inst.peek_target
	if target == nil then
		for i, v in ipairs(ents) do
			if v:IsOnValidGround() then
				target = v
				break
			end
		end
	end
	
	if target then
		local action = BufferedAction(inst, target, ACTIONS.PICK)
		local clear_peek_queued = function()
			inst.peek_target = nil
			inst.wants_to_peek = nil
		end
		
		inst:DoTaskInTime(4, clear_peek_queued)
		action:AddSuccessAction(clear_peek_queued)
		action:AddFailAction(clear_peek_queued)
		
		return action
	end
end

local ShadowCreatureBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function ShadowCreatureBrain:OnStart()
	local root = PriorityNode({
		WhileNode(function() return not self.inst.components.combat:InCooldown() and GetVisibleHider(self.inst) ~= nil end, "I SEE YOU", 
			ChaseAndAttack(self.inst, 100)
		),
		DoAction(self.inst, LookInHidingSpot),
		Follow(self.inst, function() return GetHider(self.inst) end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),
		Wander(self.inst, function() return GetHiderPosition(self.inst) end, 20),
	}, 0.25)
	
	self.bt = BT(self.inst, root)
end

return ShadowCreatureBrain