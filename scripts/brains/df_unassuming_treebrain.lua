require "behaviours/chaseandattack"

local TARGET_MUST_TAGS = {"_combat", "_health", "player"}
local TARGET_CANT_TAGS = {"INLIMBO", "playerghost"}
local TARGET_ONEOF_TAGS = nil

local function FindTarget(inst)
	if inst.components.combat:HasTarget() then
		return
	end
	
	local target = FindEntity(inst, TUNING.DF_UNASSUMING_TREE_SIGHT_RANGE,
		function(guy)
			return inst.components.combat:CanTarget(guy)
		end,
		TARGET_MUST_TAGS,
		TARGET_CANT_TAGS,
		TARGET_ONEOF_TAGS)
	
	if target ~= nil then
		inst.components.combat:SetTarget(target)
	end
end

local function ShouldStop(inst)
	return not inst.components.combat:HasTarget()
		   or (inst.components.burnable == nil or inst.components.burnable:IsBurning())
		   or inst:CanPlayersSeeUs()
end

local DF_Unassuming_TreeBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function DF_Unassuming_TreeBrain:OnStart()
	local root = PriorityNode({
		FailIfSuccessDecorator(ActionNode(function() FindTarget(self.inst) end)),
		WhileNode(function() return ShouldStop(self.inst) end, "Stop",
			ActionNode(function() self.inst:PushEvent("df_stoptree") end)
		),
		SequenceNode{
			ActionNode(function() self.inst:PushEvent("df_resumetree") end),
			ChaseAndAttack(self.inst),
		},
	}, 0.5)
	
	self.bt = BT(self.inst, root)
end

return DF_Unassuming_TreeBrain