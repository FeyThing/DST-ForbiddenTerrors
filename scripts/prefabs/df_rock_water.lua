local assets =
{
	Asset("ANIM", "anim/df_rock_water.zip"),
    Asset("MINIMAP_IMAGE", "rock"),
}

local prefabs =
{
    "rocks",
	"flint",
    "nitre",
}    

SetSharedLootTable( 'df_rock_water',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'flint',  1.00},
    {'flint',  0.60},
    {'nitre',  1.00},
    {'nitre',  0.25},

})

local MAXWORK = 10
local MEDIUM  = 6
local LOW     = 3

local COLLISION_DAMAGE_SCALE = 0.5

local function CurrentlyWorking(inst, worker, workleft)
    local pt = Point(inst.Transform:GetWorldPosition())
		if workleft <= 0 then
			inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
			inst.components.lootdropper:DropLoot(pt)
			inst:Remove()
            local x, y, z = inst.Transform:GetWorldPosition()
			local fx = SpawnPrefab("df_waterspot")
			fx.Transform:SetPosition(x, y, z)
    elseif workleft < TUNING.ROCKS_MINE / 3 then
        inst.AnimState:PlayAnimation("low")
    elseif workleft < TUNING.ROCKS_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("med")
    else
        inst.AnimState:PlayAnimation("full")
    end
end

local function OnCollide(inst, data)
    local boat_physics = data.other.components.boatphysics

    if boat_physics ~= nil then
        local hit_velocity = math.floor(math.abs(boat_physics:GetVelocity() * data.hit_dot_velocity) * COLLISION_DAMAGE_SCALE / boat_physics.max_velocity + 0.5)

        inst.components.workable:WorkedBy(data.other, hit_velocity * TUNING.SEASTACK_MINE)
    end
end

local function CLIENT_ForceFloaterUpdate(inst)
    inst.components.floater:OnLandedServer()
end

local function prerock_fn(bank, build, anim, icon)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
	
    inst:SetPhysicsRadiusOverride(2.35)
	--MakeObstaclePhysics(inst, 1)
    MakeWaterObstaclePhysics(inst, 0.80, 2, 0.75)

    inst.MiniMapEntity:SetIcon("rock.png")

    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("floaterobject")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim)

    MakeSnowCoveredPristine(inst)
    MakeInventoryFloatable(inst, "large", nil, 0.85)
    inst.components.floater:SetIsObstacle()
    inst.components.floater.bob_percent = 0

    local land_time = POPULATING and (math.random() * 5 * FRAMES) or 0
    inst:DoTaskInTime(land_time, CLIENT_ForceFloaterUpdate)

    inst.entity:SetPristine()
    

    if not TheWorld.ismastersim then
        return inst
    end

    inst._OnCollide = OnCollide


	inst:AddComponent("lootdropper") 
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	inst.components.workable:SetOnWorkCallback(CurrentlyWorking)

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "df_rock_water"
	MakeSnowCovered(inst)

    MakeHauntableWork(inst)

    inst:ListenForEvent("on_collide", inst._OnCollide)

	return inst
end


local function df_rock_water_fn()
	local inst = prerock_fn("df_rock_water", "df_rock_water", "full","df_rock_water.tex")

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.AnimState:SetBank("df_rock_water")
    inst.AnimState:SetBuild("df_rock_water")
    inst.AnimState:PlayAnimation("full", true)

	
	inst.components.lootdropper:SetChanceLootTable('df_rock_water')

	return inst
end


return Prefab( "df_rock_water", df_rock_water_fn, assets, prefabs)
