local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("CLASSIFIED")
    inst.persists = false

    inst._creature_prox_collider = true

    MakeObstaclePhysics(inst, 2)
    inst.Physics:SetCollides(false)

    return inst
end


return Prefab("df_creatureprox_collider", fn)
