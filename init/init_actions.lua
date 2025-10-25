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

ENV.AddStategraphActionHandler("wilson", ActionHandler(DF_HIDEIN, "doshortaction"))
ENV.AddStategraphActionHandler("wilson_client", ActionHandler(DF_HIDEIN, "doshortaction"))

ENV.AddComponentAction("SCENE", "df_hidingspot", function(inst, doer, actions, right)
	if right and inst:HasTag("df_canhide") and not doer:HasTag("df_hiding") then
		table.insert(actions, DF_HIDEIN)
	end
end)