local assets =
{
    Asset("ANIM", "anim/df_driftwood.zip"),
}

SetSharedLootTable('df_driftwood',
{
    {'twigs',           1.0},
    {'log',   1.0},
    {'log',   1.0},
})

local function OnChopped(inst, chopper, remaining_chops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("turnoftides/common/together/driftwood/chop")
    end

    if remaining_chops > 0 then
        inst.AnimState:PlayAnimation("chop")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function OnChoppedDown(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/appear_wood")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble",nil,.4)

    inst.AnimState:PlayAnimation("fall")
    inst.components.lootdropper:DropLoot()
    inst:ListenForEvent("animover", inst.Remove)
    RemovePhysicsColliders(inst)
end

local function OnChoppedDownBurnt(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")

    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end

    inst.AnimState:PlayAnimation("chop_burnt")
    inst.components.lootdropper:DropLoot()
    inst:ListenForEvent("animover", inst.Remove)
    RemovePhysicsColliders(inst)
end

local function OnBurnt(inst)
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("hauntable")
    MakeHauntableWork(inst)

    inst.components.lootdropper:SetChanceLootTable(nil)
    inst.components.lootdropper:SetLoot({"charcoal"})

    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(nil)
    inst.components.workable:SetOnFinishCallback(OnChoppedDownBurnt)
    inst.AnimState:PlayAnimation("burnt", true)
    inst:AddTag("burnt")
end

local function GetStatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst.components.burnable ~= nil and
            inst.components.burnable:IsBurning() and
            "BURNING")
        or nil
end

local function OnDFPrefabSpawned(inst)
    inst.AnimState:PlayAnimation("emerge")
    inst.AnimState:PushAnimation("idle", true)
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data == nil then
        return
    end

    if data.burnt and not inst:HasTag("burnt") then
        -- Make the appropriate driftwood burnt function, then immediately call it on the instance we're loading.
        OnBurnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    -- inst.entity:AddMiniMapEntity() -- TODO (HALF): Xeno add this
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("df_driftwood")
    inst.AnimState:SetBuild("df_driftwood")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("flotsam")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	local scale = math.random() > 0.5 and 1 or -1
	inst.AnimState:SetScale(scale, 1)
	
    MakeMediumBurnable(inst, TUNING.MED_BURNTIME)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    MakeSmallPropagator(inst)

    -- NOTE (HALF): For cookie cutters that somehow jump all the way into the df ocean, lol
	inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 0

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("df_driftwood")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.CHOP)

    inst.components.workable:SetWorkLeft(TUNING.DF_DRIFTWOOD_CHOPS)

    inst.components.workable:SetOnWorkCallback(OnChopped)
    inst.components.workable:SetOnFinishCallback(OnChoppedDown)

    MakeHauntableWorkAndIgnite(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.OnDFPrefabSpawned = OnDFPrefabSpawned

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("df_driftwood", fn, assets)
