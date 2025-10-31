require "prefabutil"

local WAXED_PLANTS = require "prefabs/waxed_plant_common"

local function make_plantable(data)
    local assets = {
        Asset("ANIM", "anim/"..(data.build or data.name)..".zip"),
    }

    local function ondeploy(inst, pt, deployer)
        local tree = SpawnPrefab(data.name)
        if tree ~= nil then
            tree.Transform:SetPosition(pt:Get())
            inst.components.stackable:Get():Remove()
            if tree.components.pickable then 
                tree.components.pickable:OnTransplant()
            elseif tree.components.hackable then 
                tree.components.hackable:OnTransplant()
            end 
            if deployer ~= nil and deployer.SoundEmitter ~= nil then
                deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
            end
            if TheWorld.components.lunarthrall_plantspawner and tree:HasTag("lunarplant_target") then
                TheWorld.components.lunarthrall_plantspawner:setHerdsOnPlantable(tree)
            end
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        
        inst:AddTag("deployedplant")

        if data.common_postinit then
            data.common_postinit(inst)
        end

        if data.noburn then inst:AddTag("fire_proof") end

        inst.AnimState:SetBank(data.bank or data.name)
        inst.AnimState:SetBuild(data.build or data.name)
        inst.AnimState:PlayAnimation("dropped")

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = data.inspectoverride or "dug_"..data.name
        inst:AddComponent("inventoryitem")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

        if data.noburn then
            MakeHauntableLaunch(inst)
        else
            MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
            MakeSmallPropagator(inst)

            MakeHauntableLaunchAndIgnite(inst)
        end

        inst:AddComponent("deployable")
        inst.components.deployable.ondeploy = ondeploy
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        if data.spacing then
            inst.components.deployable:SetDeploySpacing(data.spacing)
        end
        if data.deploydistance then
            inst.components.deployable.deploydistance = data.deploydistance
        end

        ---------------------
        return inst
    end

    return Prefab("dug_"..data.name, fn, assets)
end

local defs = {
    df_grass = {
    },
    df_berrybush = {
    },
    df_poison_ivy = {
    },
}

local prefs = {}
for name, data in pairs(defs) do
    data.name = name

    table.insert(prefs, make_plantable(data))
    table.insert(prefs, MakePlacer("dug_"..data.name.."_placer", data.bank or data.name, data.build or data.name, data.anim or "idle"))
    table.insert(prefs, WAXED_PLANTS.CreateDugWaxedPlant(data))
end

return unpack(prefs)