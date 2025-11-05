local ENV = env
GLOBAL.setfenv(1, GLOBAL)

--ENV.AddStategraphPostInit("wilson", function(sg)
--end)

ENV.AddStategraphState("wilson",
	State{
		name = "df_hide",
		tags = {"hiding", "silentmorph"},
		
		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			
			inst:Hide()
			if inst.Physics ~= nil then
				inst.Physics:Teleport(inst.Transform:GetWorldPosition())
			end
			if inst.DynamicShadow ~= nil then
				inst.DynamicShadow:Enable(false)
			end
			
			-- to-do change player colliders maybe? just like the tent, things can push you away from the bush while you still stay hidden
			
			inst.sg.statemem.target = target
		end,
		
		events = {
			EventHandler("df_onunhide", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
		
		onexit = function(inst)
			inst:Show()
			if inst.DynamicShadow ~= nil then
				inst.DynamicShadow:Enable(true)
			end
			
			local target = inst.sg.statemem.target
			if target ~= nil and target.components.df_hidingspot ~= nil then
				target.components.df_hidingspot:Unhide()
			end
		end,
	}
)
