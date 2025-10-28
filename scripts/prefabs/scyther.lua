local assets = {
    Asset("ANIM", "anim/df_scyther.zip"),
}

local prefabs = {
	
}

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst:AddTag("shadowcreature")
    inst:AddTag("gestaltnoloot")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadow_aligned")
    inst:AddTag("NOBLOCK")

	--shadowsubmissive (from shadowsubmissive component) added to pristine state for optimization
	inst:AddTag("shadowsubmissive")

    MakeInventoryPhysics(inst)
	
    inst.AnimState:SetBank("scyther")
    inst.AnimState:SetBuild("scyther")
    inst.AnimState:PlayAnimation("idle_scythe", true)
    inst.AnimState:SetMultColour(1, 1, 1, .5)

	
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("shadowsubmissive")

	
    return inst
end

return Prefab("scyther", fn, assets, prefabs)