require("stategraphs/commonstates")

local NUM_IDLE_ANIMS = 6

local events = {
	CommonHandlers.OnLocomote(false,true),
	CommonHandlers.OnHop(),
	EventHandler("worked", function(inst, data)
		inst.sg:GoToState("chopped")
	end),
	EventHandler("doattack", function(inst)
		if not inst.sg:HasStateTag("busy") or (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) then
			inst.sg:GoToState("attack")
		end
	end),
	EventHandler("df_stoptree", function(inst)
		if not inst.sg:HasStateTag("df_treeform") then
			inst.sg:GoToState("stopped")
		end
	end),
}

local states = {
	State{
		name = "stopped",
		tags = {"df_treeform", "busy"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			
			if inst.sg.mem.idlenum == nil then
				inst.sg.mem.idlenum = math.random(1,NUM_IDLE_ANIMS)
			end
			inst.AnimState:PlayAnimation("idle"..inst.sg.mem.idlenum)
		end,
		
		events = {
			EventHandler("df_resumetree", function(inst)
				-- Reset the anim num so the next one will be random
				inst.sg.mem.idlenum = nil
				inst.sg:GoToState("idle")
			end),
		},
	},
	
	State{
		name = "chopped",
		tags = {"df_treeform", "busy"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			
			if inst.sg.mem.idlenum == nil then -- Shouldn't happen but just in case
				inst.sg.mem.idlenum = math.random(1,NUM_IDLE_ANIMS)
			end
			inst.AnimState:PlayAnimation("chop"..inst.sg.mem.idlenum)
			inst.SoundEmitter:PlaySound("turnoftides/common/together/driftwood/chop")
		end,
		
		events = {
			EventHandler("df_resumetree", function(inst)
				inst.sg.statemem.resumetree = true
			end),
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if inst.sg.statemem.resumetree then
						inst.sg.mem.idlenum = nil
						inst.sg:GoToState("idle")
					else
						inst.sg:GoToState("stopped")
					end
				end
			end),
		},
	},
	
	State{
		name = "attack",
		tags = {"attack", "busy"},
		
		onenter = function(inst, target)
			inst.components.locomotor:StopMoving()
			
			inst.AnimState:PlayAnimation("atk")
			inst.components.combat:StartAttack()
			
			inst.sg.statemem.target = inst.components.combat.target
		end,
		
		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("df_sound/set_sfx/creature/df_tree_atk") end),
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
}
CommonStates.AddIdle(states, nil, "idle1")
CommonStates.AddWalkStates(states,
{
		walktimeline =
    {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("df_sound/set_sfx/movement/df_tree_walk") end),
        TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("df_sound/set_sfx/movement/df_tree_walk") end),
        TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("df_sound/set_sfx/movement/df_tree_walk") end),
        TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("df_sound/set_sfx/movement/df_tree_walk") end),
    },
},
{
	startwalk = "walk", walk = "walk", stopwalk = "walk"
})
CommonStates.AddAmphibiousCreatureHopStates(states,
{
	swimming_clear_collision_frame = 5*FRAMES, -- to-do figure out what this is for exactly
},
{
	pre = "walk",
	loop = "walk",
	pst = "idle1",
})

return StateGraph("df_unassuming_tree", states, events, "idle")