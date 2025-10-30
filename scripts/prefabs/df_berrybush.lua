local assets = {
	Asset("ANIM", "anim/df_berrybush.zip"),
}

local prefabs = {
		"berries",
		"dug_df_berrybush",
		"twigs",
}

local BERRY_TYPES = { "berries", "berriesmore", "berriesmost" }
local function setberries(inst, pct)
	if inst._setberriesonanimover then
		inst._setberriesonanimover = nil
		inst:RemoveEventCallback("animover", setberries)
	end

	local berries =
		(not pct and "") or
		(pct >= .9 and "berriesmost") or
		(pct >= .33 and "berriesmore") or
		"berries"

	for i, berry_type in ipairs(BERRY_TYPES) do
		if berry_type == berries then
			inst.AnimState:Show(berry_type)
		else
			inst.AnimState:Hide(berry_type)
		end
	end
end

local function setberriesonanimover(inst)
	if inst._setberriesonanimover then
		setberries(inst, nil)
	else
		inst._setberriesonanimover = true
		inst:ListenForEvent("animover", setberries)
	end
end

local function cancelsetberriesonanimover(inst)
	if inst._setberriesonanimover then
		setberries(inst, nil)
	end
end

local function makeemptyfn(inst)
	if POPULATING then
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
	elseif inst:HasTag("withered") or inst.AnimState:IsCurrentAnimation("dead") then
		--inst.SoundEmitter:PlaySound("dontstarve/common/bush_fertilize")
		inst.AnimState:PlayAnimation("dead_to_idle")
		inst.AnimState:PushAnimation("idle")
	else
		inst.AnimState:PlayAnimation("idle", true)
	end
	
	if inst.components.df_hidingspot ~= nil then
		inst.components.df_hidingspot:SetCanHide(false)
	end
	setberries(inst, nil)
end

local function makebarrenfn(inst)--, wasempty)
	if not POPULATING and (inst:HasTag("withered") or inst.AnimState:IsCurrentAnimation("idle")) then
		inst.AnimState:PlayAnimation("idle_to_dead")
		inst.AnimState:PushAnimation("dead", false)
	else
		inst.AnimState:PlayAnimation("dead")
	end
	
	if inst.components.df_hidingspot ~= nil then
		inst.components.df_hidingspot:SetCanHide(false)
	end
	cancelsetberriesonanimover(inst)
end

local function shake(inst)
	if inst.components.pickable and
			not inst.components.pickable:CanBePicked() and
			inst.components.pickable:IsBarren() then
		inst.AnimState:PlayAnimation("shake_dead")
		inst.AnimState:PushAnimation("dead", false)
	else
		inst.AnimState:PlayAnimation("shake")
		inst.AnimState:PushAnimation("idle")
	end
	cancelsetberriesonanimover(inst)
end

local function onpickedfn(inst, picker)
	if inst.components.pickable then
		--V2C: nil cycles_left means unlimited picks, so use max value for math
		--local old_percent = inst.components.pickable.cycles_left ~= nil and (inst.components.pickable.cycles_left + 1) / inst.components.pickable.max_cycles or 1
		--setberries(inst, old_percent)
		if inst.components.pickable:IsBarren() then
			inst.AnimState:PlayAnimation("idle_to_dead")
			inst.AnimState:PushAnimation("dead", false)
			setberries(inst, nil)
		else
			inst.AnimState:PlayAnimation("picked")
			inst.AnimState:PushAnimation("idle")
			setberriesonanimover(inst)
		end
	end
	
	if inst.components.df_hidingspot ~= nil then
		inst.components.df_hidingspot:SetCanHide(false)
	end
end

local function getregentimefn_normal(inst)
	if not inst.components.pickable then
		return TUNING.BERRY_REGROW_TIME
	end
	--V2C: nil cycles_left means unlimited picks, so use max value for math
	local max_cycles = inst.components.pickable.max_cycles
	local cycles_left = inst.components.pickable.cycles_left or max_cycles
	local num_cycles_passed = math.max(0, max_cycles - cycles_left)
	return TUNING.BERRY_REGROW_TIME
		+ TUNING.BERRY_REGROW_INCREASE * num_cycles_passed
		+ TUNING.BERRY_REGROW_VARIANCE * math.random()
end

local function makefullfn(inst)
	local anim = "idle"
	local berries = nil
	if inst.components.pickable then
		if inst.components.pickable:CanBePicked() then
			berries = (inst.components.pickable.cycles_left and inst.components.pickable.cycles_left / inst.components.pickable.max_cycles) or 1
		elseif inst.components.pickable:IsBarren() then
			anim = "dead"
		end
	end
	if anim ~= "idle" then
		inst.AnimState:PlayAnimation(anim)
	elseif POPULATING then
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
	else
		inst.AnimState:PlayAnimation("grow")
		inst.AnimState:PushAnimation("idle", true)
	end
	
	if inst.components.df_hidingspot ~= nil then
		inst.components.df_hidingspot:SetCanHide(true)
	end
	
	setberries(inst, berries)
end


local function dig_up_common(inst, worker, numberries)
	if inst.components.pickable and inst.components.lootdropper then
		local withered = (inst.components.witherable ~= nil and inst.components.witherable:IsWithered())
		
		if withered or inst.components.pickable:IsBarren() then
			inst.components.lootdropper:SpawnLootPrefab("twigs")
			inst.components.lootdropper:SpawnLootPrefab("twigs")
		else
			if inst.components.pickable:CanBePicked() then
				local pt = inst:GetPosition()
				pt.y = pt.y + (inst.components.pickable.dropheight or 0)
				for i = 1, numberries do
					inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product, pt)
				end
			end
			inst.components.lootdropper:SpawnLootPrefab("dug_df_berrybush")
		end
	end
	inst:Remove()
end

local function dig_up_normal(inst, worker)
	dig_up_common(inst, worker, 1)
end


local function ontransplantfn(inst)
	inst.AnimState:PlayAnimation("dead")
	setberries(inst, nil)
	inst.components.pickable:MakeBarren()
end

local function OnHaunt(inst)
	if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
		shake(inst)
		inst.components.hauntable.hauntvalue = TUNING.HAUNT_COOLDOWN_TINY
		return true
	else
		return false
	end
end

local function OnSave(inst, data)
	data.was_herd = inst.components.herdmember and true or nil
end

local function OnPreLoad(inst, data)
	if data and data.was_herd then
		if TheWorld.components.lunarthrall_plantspawner then
			TheWorld.components.lunarthrall_plantspawner:setHerdsOnPlantable(inst)
		end
	end	
end

local function OnUsedAsHidingSpot(inst, doer)
	local pickable = inst.components.pickable
	local witherable = inst.components.witherable
	
	inst:DoTaskInTime(0, function()
		if not pickable:IsBarren() and pickable:CanBePicked() and not witherable:IsWithered() then
			inst.AnimState:PlayAnimation("shake")
			inst.AnimState:PushAnimation("idle")
		end
	end)
end

local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT] / 2) --plantables deployspacing/2
		MakeSmallObstaclePhysics(inst, .1)

		inst:AddTag("bush")
		inst:AddTag("plant")
		inst:AddTag("renewable")
		inst:AddTag("lunarplant_target")

		--witherable (from witherable component) added to pristine state for optimization
		inst:AddTag("witherable")

		inst.MiniMapEntity:SetIcon("df_berrybush.tex")

		inst.AnimState:SetBank("df_berrybush")
		inst.AnimState:SetBuild("df_berrybush")
		inst.AnimState:PlayAnimation("idle", true)
		setberries(inst, 1)

		MakeSnowCoveredPristine(inst)

		inst.scrapbook_specialinfo = "NEEDFERTILIZER"

		inst.entity:SetPristine()
		if not TheWorld.ismastersim then
			return inst
		end

		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
		inst.components.pickable.onpickedfn = onpickedfn
		inst.components.pickable.makeemptyfn = makeemptyfn
		inst.components.pickable.makebarrenfn = makebarrenfn
		inst.components.pickable.makefullfn = makefullfn
		inst.components.pickable.ontransplantfn = ontransplantfn
		inst.components.pickable:SetUp("berries", TUNING.BERRY_REGROW_TIME)
		inst.components.pickable.getregentimefn = getregentimefn_normal
		inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
		inst.components.pickable.cycles_left = inst.components.pickable.max_cycles

		if inst.components.workable then
		inst.components.workable:SetOnFinishCallback(dig_up_normal)
		end

		inst:AddComponent("witherable")

		MakeLargeBurnable(inst)
		MakeMediumPropagator(inst)

		MakeHauntableIgnite(inst)
		AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

		inst:AddComponent("lootdropper")

		if not GetGameModeProperty("disable_transplanting") then
			inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.DIG)
			inst.components.workable:SetWorkLeft(1)
		end
		
		inst:AddComponent("df_hidingspot")
		inst.components.df_hidingspot:SetCanHide(true)
		inst.components.df_hidingspot.onhide = OnUsedAsHidingSpot
		inst.components.df_hidingspot.onunhide = OnUsedAsHidingSpot
		
		inst:AddComponent("inspectable")

		inst:ListenForEvent("onwenthome", shake)
		MakeSnowCovered(inst)
		SetLunarHailBuildupAmountSmall(inst)
		MakeNoGrowInWinter(inst)

		MakeWaxablePlant(inst)


		inst.OnSave = OnSave
		inst.OnPreLoad = OnPreLoad

	return inst
end

return Prefab("df_berrybush", fn, assets, prefabs)