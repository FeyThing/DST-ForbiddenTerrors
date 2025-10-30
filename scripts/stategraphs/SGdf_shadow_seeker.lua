require("stategraphs/commonstates")

local actionhandlers = {
	ActionHandler(ACTIONS.PICK, "peek"),
}

local events = {
	CommonHandlers.OnLocomote(false,true),
	EventHandler("doattack", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("attack")
		end
	end),
	EventHandler("startseeking", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("appear")
		end
	end),
	EventHandler("stopseeking", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("disappear")
		end
	end),
}

local states = {	
	State{
		name = "appear",
		tags = {"busy"},
		
		onenter = function(inst, target)
			inst.components.locomotor:StopMoving()
			
			inst.AnimState:PlayAnimation("idle_loop")
		end,
		
		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end)
		},
	},
	
	State{
		name = "disappear",
		tags = {"busy"},
		
		onenter = function(inst, target)
			inst.components.locomotor:StopMoving()
			
			inst.AnimState:PlayAnimation("idle_loop")
		end,
		
		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst:Remove()
				end
			end)
		},
	},
	
	State{
		name = "attack",
		tags = {"attack", "busy"},
		
		onenter = function(inst, target)
			inst.components.locomotor:StopMoving()
			
			inst.AnimState:PlayAnimation("leech")
			inst.components.combat:StartAttack()
			inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/attack")
			--[[local x, y, z = inst.Transform:GetWorldPosition()
			local fx = SpawnPrefab("shadow_merm_smacked_poof_fx")
			fx.Transform:SetPosition(x, y, z)]]
			
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
					inst.sg:GoToState("idle")
				end
			end)
		},
	},
	
	State{
		name = "peek",
		tags = {"busy"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			
			inst.AnimState:PlayAnimation("leech")
			inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/attack")
		end,
		
		timeline = {
			TimeEvent(12*FRAMES, function(inst)
				inst:PerformBufferedAction()
			end),
		},
		
		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end)
		},
	},
}

CommonStates.AddIdle(states, nil, "idle_loop")
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stagehand/footstep") end),
		TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stagehand/footstep") end),
		TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stagehand/footstep") end),
		TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stagehand/footstep") end),
	},
	startwalk = "walk_pre", walk = "walk_loop", stopwalk = "walk_pst"
})

return StateGraph("df_shadow_seeker", states, events, "idle", actionhandlers)