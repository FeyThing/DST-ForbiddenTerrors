local assets = {
	Asset("ANIM", "anim/df_fog.zip"),
	Asset("ANIM", "anim/df_fog_dark.zip"),
}

local FOG_VARS = 4

local function DoFogFade(inst, out, out_fn, fade_time)
	inst._fading = out
	
	if out then
		inst.components.colourtweener:StartTween({1, 1, 1, 0}, fade_time or 2, out_fn)
	else
		inst.components.colourtweener:StartTween({1, 1, 1, 1}, fade_time or 8)
	end
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst.AnimState:SetBank("df_fog")
	inst.AnimState:SetBuild("df_fog")
	inst.AnimState:PlayAnimation("idle"..math.random(4), true)
	inst.AnimState:OverrideSymbol("fogbit_1", "df_fog", "fogbit_"..math.random(FOG_VARS))
	inst.AnimState:SetFinalOffset(7)
	inst.AnimState:SetSortOrder(2)
	inst.AnimState:SetLayer(LAYER_WORLD_DEBUG)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
	inst.AnimState:SetMultColour(.7, .7, .7, 0)
	inst.AnimState:SetLightOverride(0.5)
	inst.AnimState:SetScale(6, 6)
	
	--inst.AnimState:SetClientsideBuildOverride("insane", "df_fog", "df_fog_dark")
	
	inst:AddTag("FX")
	
	inst:AddComponent("colourtweener")
	
	inst.DoFogFade = DoFogFade
	
	inst.persists = false
	
	return inst
end

--

local CYCLEDONE_GRADUAL_DEFAULT = TUNING.DF_FOG_BLOCKER_DURATION_GRADUAL

local function ExtendFogBlocker(inst, doer, spawned, time_override)
	if inst.components.timer then
		local timeleft = time_override or TUNING.DF_FOG_BLOCKER_DURATION
		
		if inst.components.timer:TimerExists("fogblockercycle") then
			inst.components.timer:SetTimeLeft("fogblockercycle", timeleft)
		else
			inst.components.timer:StartTimer("fogblockercycle", timeleft)
		end
	end
end

local function SetFogBlockRange(inst, range, doer)
	inst._fogblockrange:set(range or 2)
end

local function OnSave(inst, data)
	data.range = inst._fogblockrange:value()
	
	local gradual_time = inst._gradual_time or CYCLEDONE_GRADUAL_DEFAULT
	if gradual_time ~= CYCLEDONE_GRADUAL_DEFAULT then
		data.gradual_time = gradual_time
	end
end

local function OnLoad(inst, data)
	if data then
		if data.gradual_time then
			inst._gradual_time = data.gradual_time
		end
		if data.range then
			inst:SetFogBlockRange(data.range)
		end
	end
end

local function OnTimerDone(inst, data)
	if data.name == "fogblockercycle" then
		local cur_range = inst._fogblockrange:value()
		local gradual_time = inst._gradual_time or CYCLEDONE_GRADUAL_DEFAULT
		
		if cur_range > 1 and gradual_time > 0 then
			inst:SetFogBlockRange(cur_range - (inst._gradual_step or 1))
			
			inst:ExtendFogBlocker(nil, nil, gradual_time)
		else
			inst:Remove()
		end
	end
end

local function OnFogBlockRangeDirty(inst)
	TheWorld:PushEvent("darkforestfog_blockerupdate", {blocker = inst})
end

local function blocker()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	
	--inst:AddTag("fx")
	inst:AddTag("NOBLOCK")
	inst:AddTag("df_fog_blocker")
	
	inst._fogblockrange = net_smallbyte(inst.GUID, "df_fog_blocker._fogblockrange", "fogblockrangedirty")
	inst._fogblockrange:set(6)
	
	inst:ListenForEvent("fogblockrangedirty", OnFogBlockRangeDirty)
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("timer")
	inst.components.timer:StartTimer("fogblockercycle", TUNING.DF_FOG_BLOCKER_DURATION)
	
	inst.ExtendFogBlocker = ExtendFogBlocker
	inst.SetFogBlockRange = SetFogBlockRange
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	
	inst:ListenForEvent("timerdone", OnTimerDone)
	
	return inst
end

return Prefab("df_fog", fn, assets),
	Prefab("df_fog_blocker", blocker)