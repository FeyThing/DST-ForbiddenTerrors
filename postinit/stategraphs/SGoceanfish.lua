local ENV = env
GLOBAL.setfenv(1, GLOBAL)

require("stategraphs/commonstates")

local events =
	{
		CommonHandlers.OnAttack(),
   		CommonHandlers.OnAttacked(),
		CommonHandlers.OnDeath(),
	}

local states ={
	State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")  
        end,

        timeline =
        {

            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("df_sound/set_sfx/creature/df_piranha_atk") end),
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if math.random() < .333 then
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
        tags = { "busy" },

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

        events=
        {
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