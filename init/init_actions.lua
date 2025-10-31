local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local DF_OCEAN_HOME_ARRIVE_DIST_SQ = 10*10
local function CheckForDFOceanHomeWithinRange(doer, dest)
    local target_pos = Vector3(dest:GetPoint())
    local x, y, z = TheWorld.Transform:GetWorldPosition()
    local _map = TheWorld.Map

    return doer:GetDistanceSqToPoint(target_pos.x, target_pos.y, target_pos.z) <= DF_OCEAN_HOME_ARRIVE_DIST_SQ and 
        doer:CanSubmergeAtPoint(x, y, z)
end

--

local DF_OCEAN_GO_HOME = ENV.AddAction("DF_OCEAN_GO_HOME", "", function(act)
	if act.doer ~= nil then
        act.doer:PushEvent("gohome")
    end
end)
DF_OCEAN_GO_HOME.customarrivecheck = CheckForDFOceanHomeWithinRange
DF_OCEAN_GO_HOME.instant = true

local DF_HIDEIN = ENV.AddAction("DF_HIDEIN", STRINGS.ACTIONS.DF_HIDEIN, function(act)
	if act.target ~= nil then
		if act.target.components.df_hidingspot ~= nil then
			return act.target.components.df_hidingspot:Hide(act.doer)
		end
	end
end)
DF_HIDEIN.priority = 2

local DF_PANNING = ENV.AddAction("DF_PANNING", STRINGS.ACTIONS.DF_PANNING, function(act)
	if act.invobject and act.invobject.components.df_pan then
		local pos = act:GetActionPoint()
		
		return act.invobject.components.df_pan:PanAt(pos, act.doer)
	end
end)
DF_PANNING.distance = 3
DF_PANNING.rmb = true

--

ENV.AddStategraphActionHandler("wilson", ActionHandler(DF_HIDEIN, "doshortaction"))
ENV.AddStategraphActionHandler("wilson_client", ActionHandler(DF_HIDEIN, "doshortaction"))

ENV.AddStategraphActionHandler("wilson", ActionHandler(DF_PANNING, "doshortaction"))
ENV.AddStategraphActionHandler("wilson_client", ActionHandler(DF_PANNING, "doshortaction"))

--

local HIDE_CANT_TAGS = {"burnt", "smolder", "fire", "stokeablefire"}
ENV.AddComponentAction("SCENE", "df_hidingspot", function(inst, doer, actions, right)
	if right and inst:HasTag("df_canhide") and not inst:HasOneOfTags(HIDE_CANT_TAGS) and not doer:HasTag("df_hiding") then
		table.insert(actions, DF_HIDEIN)
	end
end)

ENV.AddComponentAction("POINT", "df_pan", function(inst, doer, pos, actions, right)
	if right and TheWorld.Map:IsOceanAtPoint(pos.x, 0, pos.z) then
		table.insert(actions, ACTIONS.DF_PANNING)
	end
end)