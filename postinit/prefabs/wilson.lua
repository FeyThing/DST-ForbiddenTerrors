local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local _IsCarefulWalking = require("components/carefulwalker")

local function MakePassDFOcean(inst)
    inst.Physics:SetBlockMask("df_ocean_boundaries", COLLISION.CHARACTERS, COLLISION.PERMEABLE_LAND_OCEAN_LIMITS)
end

local function OnChangeCanopyZone(inst, underleaves)
    inst._underevilcanopy:set(underleaves)
end

local function SetDFOceanWading(inst, enable)
    inst.components.locomotor:SetExternalSpeedMultiplier(player, "sinkshader", enable and 0.5 or nil)
    inst._isdfoceanwading:set(enable)
end

local function IsCarefulWalking(inst, ...)
    return inst:DF_IsCarefulWalking(...) or inst._sinkshader_submerged:value()
end

local function OnDarkForestChanged(inst)
	if inst:IsValid() then
		local x, y, z = inst.Transform:GetWorldPosition()
		local indarkforest = GetClosestDarkForestTileToPoint(x, 0, z, 12) ~= nil
		
		if inst.indarkforest ~= indarkforest then
			inst.indarkforest = indarkforest
			inst:PushEvent("setindarkforest", indarkforest)
			if inst.components.grue then
				if indarkforest then
					inst.components.grue:AddImmunity("darkforest")
				else
					inst.components.grue:RemoveImmunity("darkforest")
				end
			end
		end
	end
end

ENV.AddPlayerPostInit(function(inst)
    inst._underevilcanopy = net_bool(inst.GUID, "localplayer._underevilcanopy","underevilcanopydirty")
    inst._sinkshader_submerged = net_bool(inst.GUID, "localplayer._sinkshader_submerged")
	inst._fogblockrange = net_smallbyte(inst.GUID, "localplayer._fogblockrange")
	inst._fogblockrange:set(TUNING.DF_FOG_BLOCK_RANGES.PLAYER)
	
    inst.DF_IsCarefulWalking = inst.IsCarefulWalking
    inst.IsCarefulWalking = IsCarefulWalking

    MakePassDFOcean(inst)
    -- THis goes in your cmp somewhere 
    -- ALso set _isdfoceanwading
    inst:AddComponent("sinkshader")

	inst:DoTaskInTime(0, function()
		inst._df_fog_update = inst:DoPeriodicTask(1, OnDarkForestChanged)
	end)

    -- Because ghosts replace the physics cmp with a new one...
    inst:ListenForEvent("ms_respawnedfromghost", MakePassDFOcean)
	
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("df_ichormanager")

    inst:ListenForEvent("onchangeevilzone", OnChangeCanopyZone)
end)
