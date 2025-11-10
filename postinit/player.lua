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

local function OnLoad(inst, data, ...)
	--(H) SANITY CHECK: uhh half what the fuck is this
    -- Well this really sucks, thanks for making my life hell klei :) (I blame Zarklord specifically because funi)
    local _DoTaskInTime = inst.DoTaskInTime
    function inst:DoTaskInTime(time, fn, ...)
        return _DoTaskInTime(self, time, fn ~= nil and function(...)
            local _enabled = nil
            local _drownable = inst:IsOnDFOceanTile(true) and inst.components.drownable or nil
            if _drownable then
                _enabled = _drownable.enabled
                _drownable.enabled = false
            end
            local _rets = {fn(...)}
            if _drownable then
                _drownable.enabled = _enabled
            end
            return unpack(_rets)
        end or nil, ...)
    end
	local rets = {inst.DF_OnLoad(inst, data, ...)}
    inst.DoTaskInTime = _DoTaskInTime
    return unpack(rets)
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

    if inst.OnLoad then
        inst.DF_OnLoad = inst.OnLoad
        inst.OnLoad = OnLoad
    end

    inst:AddComponent("df_ichormanager")

    inst:ListenForEvent("onchangeevilzone", OnChangeCanopyZone)
end)
