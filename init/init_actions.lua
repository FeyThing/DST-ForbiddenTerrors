local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local DF_HIDEIN = ENV.AddAction("DF_HIDEIN", STRINGS.ACTIONS.DF_HIDEIN, function(act)
	if act.target ~= nil then
		if act.target.components.df_hidingspot ~= nil then
			return act.target.components.df_hidingspot:Hide(act.doer)
		end
	end
end)
DF_HIDEIN.priority = 2

ENV.AddStategraphActionHandler("wilson", ActionHandler(DF_HIDEIN, "doshortaction"))
ENV.AddStategraphActionHandler("wilson_client", ActionHandler(DF_HIDEIN, "doshortaction"))

ENV.AddComponentAction("SCENE", "df_hidingspot", function(inst, doer, actions, right)
	if right and inst:HasTag("df_canhide") and not doer:HasTag("df_hiding") then
		table.insert(actions, DF_HIDEIN)
	end
end)