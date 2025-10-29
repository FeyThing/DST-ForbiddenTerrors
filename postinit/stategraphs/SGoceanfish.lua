local ENV = env
GLOBAL.setfenv(1, GLOBAL)

require("stategraphs/commonstates")

local events = {
	CommonHandlers.OnAttack(),
   	CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
}

local states = {
	State{
		name = "attack",
		tags = {"attack", "busy"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("atk")
			inst.Physics:Stop()
			inst.sg.statemem.target = inst.components.combat.target
			inst.components.combat:StartAttack()
		end,
		
		timeline = {
			TimeEvent(14 * FRAMES, function(inst)
				--inst.SoundEmitter:PlaySound("turnoftides/common/together/water/swim/medium")
				inst.SoundEmitter:PlaySound("df_sound/set_sfx/creature/df_piranha_atk")
			end),
			TimeEvent(16 * FRAMES, function(inst)
				local target = inst.sg.statemem.target
				
				if target and not TheWorld.Map:IsPassableAtPoint(target.Transform:GetWorldPosition()) then
					inst.components.combat:DoAttack(target)
				end
			end),
		},
		
		events = {
			EventHandler("animqueueover", function(inst)
				if math.random() < 0.333 then
					inst.components.combat:SetTarget(nil)
					inst.sg:GoToState("breach")
				else
					inst.sg:GoToState("idle", "atk")
				end
			end),
		},
	},
	
	State{
		name = "death",
		tags = {"busy"},
		
		onenter = function(inst, reanimating)
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
			
			--inst.SoundEmitter:PlaySound(inst.sounds.death)
			inst.components.lootdropper:DropLoot(inst:GetPosition())
			--inst:SetDeathLootLevel(1)
		end,
	},
	
	State{
		name = "hit",
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("hit")
			inst.Physics:Stop()
		end,
		
		events = {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
		},
	}
}

ENV.AddStategraphPostInit("sgoceanfish",function(sg)
	for _, event in pairs(events) do
		sg.events[event.name] = event
	end
	
	for _, state in pairs(states) do
		sg.states[state.name] = state
	end
end)