require("stategraphs/commonstates")


local events = {
	CommonHandlers.OnLocomote(false,true),
	EventHandler("doattack", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("attack")
		end
	end),
}

	
local states = {	
	State{
		name = "attack",
		tags = {"attack", "busy"},
		
		onenter = function(inst, target)
			inst.components.locomotor:StopMoving()
			
			inst.AnimState:PlayAnimation("leech")
			inst.components.combat:StartAttack()
			
			inst.sg.statemem.target = inst.components.combat.target
		end,
		
		timeline = {
			TimeEvent(12*FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
			end),
		},
		
		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle_loop")
				end
			end)
		},
	},
}

CommonStates.AddIdle(states, nil, "idle_loop")
CommonStates.AddWalkStates(states, nil, {startwalk = "walk_pre", walk = "walk_loop", stopwalk = "walk_pst"})

return StateGraph("df_unassuming_tree", states, events, "idle")