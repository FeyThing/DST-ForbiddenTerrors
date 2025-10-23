local assets=
{
	Asset("ANIM", "anim/df_pan.zip"),
}

local prefabs = {
	
}

--[[local function onfinished(inst)
	inst:Remove()
end]]

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "df_pan", "swap_object")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("df_pan")
	inst.AnimState:SetBuild("df_pan")
	inst.AnimState:PlayAnimation("idle")
	
	inst:AddTag("worksOnFloor")

	MakeInventoryFloatable(inst, "small", 0.1, 0.88)

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AXE_DAMAGE)

	-----
	--[[inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.PAN)]]
	-------
	inst:AddComponent("finiteuses")

	--[[local uses = TUNING.PAN_USES
    local player = GetPlayer()
    if player and player:HasTag("treasure_hunter") then
        uses = uses * 2
    end

	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished( onfinished)
	inst.components.finiteuses:SetConsumption(ACTIONS.PAN, 1)]]
	-------
	inst:AddComponent("inspectable")
	-------
	inst:AddComponent("equippable")

	inst:AddComponent("inventoryitem")

	inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
	MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)

	inst.components.equippable:SetOnEquip( onequip )

	inst.components.equippable:SetOnUnequip( onunequip)

	return inst
end


return Prefab( "df_pan", fn, assets, prefabs)
