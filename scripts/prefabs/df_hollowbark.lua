local assets = {
    Asset("ANIM", "anim/df_hollowbark.zip"),
}

local prefabs = {
	
}

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()



    MakeInventoryPhysics(inst)
	
    inst.AnimState:SetBank("df_hollowbark")
    inst.AnimState:SetBuild("df_hollowbark")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", 0.15)
	
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
		
	inst:AddComponent("tradable")
		
	inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
		
	inst:AddComponent("inventoryitem")

    inst:AddComponent("forcecompostable")
    inst.components.forcecompostable.brown = true
		
	MakeHauntableLaunchAndPerish(inst)

	
    return inst
end

return Prefab("df_hollowbark", fn, assets, prefabs)