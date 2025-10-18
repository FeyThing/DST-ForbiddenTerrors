local assets =
{
    Asset("ANIM", "anim/df_reeds.zip"),
    Asset("SOUND", "sound/common.fsb"),

    Asset("MINIMAP_IMAGE", "reeds"),
}

local prefabs =
{
    "cutreeds",
}

local function onpickedfn(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked")
end

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function CheckBeached(inst)
    inst._checkgroundtask = nil
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst:GetCurrentPlatform() ~= nil or TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
        if inst.components.pickable ~= nil then
            inst.components.pickable:Pick(TheWorld)
        end
        inst:Remove()
        local beached = SpawnPrefab("cutreeds") -- temporarily
        beached.Transform:SetPosition(x, y, z)
    end
end

local function OnCollide(inst, other)
    if inst._checkgroundtask == nil then
        -- This collision callback is called very fast so only do the checks after some time in a staggered method.
        inst._checkgroundtask = inst:DoTaskInTime(1 + math.random(), CheckBeached)
    end
end

local function MakeReeds(name, build, icon)
    local function fn()
        local inst = CreateEntity()
    
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(icon)

        MakeInventoryPhysics(inst, nil, 0.7)
    
        inst:AddTag("plant")
        inst:AddTag("silviculture") -- for silviculture book
    
        inst.AnimState:SetBank("df_reeds")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle", true)
    
        inst.entity:SetPristine()
    
        if not TheWorld.ismastersim then
            return inst
        end
    
		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
        local color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(color, color, color, 1)
    
        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
        inst.components.pickable:SetUp("cutreeds", TUNING.REEDS_REGROW_TIME)
        inst.components.pickable.onregenfn = onregenfn
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
    
        inst:AddComponent("inspectable")
    
        ---------------------
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL
    
        MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
        AddToRegrowthManager(inst)
        MakeSmallPropagator(inst)
        MakeNoGrowInWinter(inst)
        MakeHauntableIgnite(inst)
        ---------------------
        ---
        inst.Physics:SetCollisionCallback(OnCollide)
        inst:DoTaskInTime(1 + math.random(), CheckBeached)
    
        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeReeds("df_reeds", "df_reeds", "reeds.png")