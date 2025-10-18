local assets = {
    Asset("ANIM", "anim/df_mushroom.zip"),
}

local prefabs = {
	"small_puff",
}

---NOTE: These mushrooms final code should have them only popping out of the ground if you are insane, and if that day is a New moon.
---Pre-mature digging is allowed.
---Temp code where it comes up as normal mushroom is here 

local function onsave(inst)
    if inst.rain > 0 then
        inst.rain = inst.rain
    end
end

local function onload(inst)
    if inst and inst.rain then
        inst.rain = inst.rain
    end
end

local function onpickedfn(inst)
    if inst.growtask ~= nil then
        inst.growtask:Cancel()
        inst.growtask = nil
    end
    inst.AnimState:PlayAnimation("picked")
    inst.rain = 10 + math.random(10)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function checkregrow(inst)
    if inst.components.pickable ~= nil and not inst.components.pickable.canbepicked and TheWorld.state.israining then
        inst.rain = inst.rain - 1
        if inst.rain <= 0 then
            inst.components.pickable:Regen()
        end
    end
end

local function GetStatus(inst)
    return (not (inst.components.pickable ~= nil and inst.components.pickable.canbepicked) and "PICKED")
        or (inst.components.pickable.caninteractwith and "GENERIC")
        or "INGROUND"
end

local function open(inst)
    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        if inst.growtask then
            inst.growtask:Cancel()
        end
        inst.growtask = inst:DoTaskInTime(3 + math.random() * 6, inst.opentaskfn)
    end
end

local function close(inst)
    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        if inst.growtask then
            inst.growtask:Cancel()
        end
        inst.growtask = inst:DoTaskInTime(3 + math.random() * 6, inst.closetaskfn)
    end
end

local function onregenfn(inst)
    inst.components.pickable.caninteractwith = false -- Wait for the mushroom to become visible.

    if inst.inst.open_time == TheWorld.state.cavephase then
        open(inst)
    else
        inst.AnimState:PushAnimation("inground", false)
        inst:DoTaskInTime(.25, function() inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_down") end )
    end
end

local function testfortransformonload(inst)
    return TheWorld.state.isfullmoon
end

local function OnIsOpenPhase(inst, isopen)
    if isopen then
        open(inst)
    else
        close(inst)
    end
end


local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	
    inst.AnimState:SetBank("df_mushroom")
    inst.AnimState:SetBuild("df_mushroom")
    inst.AnimState:PlayAnimation("night")
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    --[[inst.opentaskfn = function()
        inst.AnimState:PlayAnimation("open_inground")
        inst.AnimState:PushAnimation("open")
        inst.AnimState:PushAnimation("night", false)
        inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_up")
        inst.growtask = nil
        if inst.components.pickable ~= nil then
            inst.components.pickable.caninteractwith = true
        end
    end

    inst.closetaskfn = function()
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("inground", false)
        inst:DoTaskInTime(.25, function() inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_down") end )
        inst.growtask = nil
        if inst.components.pickable then
            inst.components.pickable.caninteractwith = false
        end
    end]]

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("df_cap")
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.makeemptyfn = makeemptyfn

    inst.rain = 0

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(function(inst, chopper)
        if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab("df_cap")
        end

        inst.components.lootdropper:SpawnLootPrefab("df_cap")
        inst:Remove()
    end)
    inst.components.workable:SetWorkLeft(1)

    AddToRegrowthManager(inst)
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)

    --inst:WatchWorldState("iscavenight", OnIsOpenPhase)

    inst:DoPeriodicTask(TUNING.SEG_TIME, checkregrow, TUNING.SEG_TIME + math.random()*TUNING.SEG_TIME)

    --[[if inst.open_time == TheWorld.state.cavephase then
        inst.AnimState:PlayAnimation("night")
        inst.components.pickable.caninteractwith = true
    else
        inst.AnimState:PlayAnimation("inground")
        inst.components.pickable.caninteractwith = false
    end]]

    inst.OnSave = onsave
    inst.OnLoad = onload
	
    return inst
end

local function capfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("df_mushroom")
    inst.AnimState:SetBuild("df_mushroom")
    inst.AnimState:PlayAnimation("night_cap")

    inst.pickupsound = "vegetation_firm"

    --cookable (from cookable component) added to pristine state for optimization
    inst:AddTag("cookable")
    inst:AddTag("mushroom")

    MakeInventoryFloatable(inst, "small", 0.1, 0.88)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    inst:AddComponent("inventoryitem")

    --this is where it gets interesting
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.sanityvalue = -TUNING.SANITY_HUGE
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)

    inst:AddComponent("cookable")
    inst.components.cookable.product = "df_cap_cooked"

    return inst
end

local function cookedfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("df_mushroom")
    inst.AnimState:SetBuild("df_mushroom")
    inst.AnimState:PlayAnimation("night_cap_cooked")

    MakeInventoryFloatable(inst, "small", 0.05, 0.9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.TINY_FUEL
    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunchAndPerish(inst)

    --this is where it gets interesting
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = -TUNING.HEALING_MEDSMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end


return Prefab("df_mushroom", fn, assets, prefabs),
       Prefab("df_cap", capfn, assets, prefabs),
       Prefab("df_cap_cooked", cookedfn, assets, prefabs)
