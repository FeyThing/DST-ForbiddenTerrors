

local MIN = TUNING.SHADE_CANOPY_RANGE
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER

local function OnFar(inst, player)
    if player.canopytrees then   
        player.canopytrees = player.canopytrees - 1
        player:PushEvent("onchangeevilzone", player.canopytrees > 0)
    end
    inst.players[player] = nil
end

local function OnNear(inst,player)
    inst.players[player] = true

    player.canopytrees = (player.canopytrees or 0) + 1

    player:PushEvent("onchangeevilzone", player.canopytrees > 0)
end

local function OnRemoveEntity(inst)
    for player in pairs(inst.players) do
        if player:IsValid() then
            if player.canopytrees then
                player.canopytrees = player.canopytrees - 1
                player:PushEvent("onchangeevilzone", player.canopytrees > 0)
            end
        end
    end
end

local function MakeTrees(name)
	local assets = {
	Asset("ANIM", "anim/eviltree_tall.zip"),
	Asset("SCRIPT", "scripts/prefabs/eviltreeshadow.lua")
	}

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()
	
	MakeObstaclePhysics(inst, 3)
	
	inst.Transform:SetScale(1, 1, 1)

	inst.MiniMapEntity:SetIcon("eviltree_tall.tex") 
	
	inst.AnimState:SetBank("eviltree_tall")
	inst.AnimState:SetBuild("eviltree_tall")
	inst.AnimState:PlayAnimation("idle")

	inst.AnimState:Hide("rope")
	inst.AnimState:Hide("lantern")
	inst.AnimState:Hide("lantern_overlay")
	
	inst:AddTag("antlion_sinkhole_blocker")
	inst:AddTag("birdblocker")
	inst:AddTag("NOCLICK")
	inst:AddTag("shadecanopy")
	
	if not TheNet:IsDedicated() then
		inst:AddComponent("distancefade")
		inst.components.distancefade:Setup(15, 25)
		
		inst:AddComponent("eviltreeshade")
		inst.components.eviltreeshade.range = math.floor(TUNING.SHADE_CANOPY_RANGE / 4)
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst.players = {}
    inst:AddComponent("playerprox")
	inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(MIN, MAX)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
	
	--inst:AddComponent("oasis")
	--inst.components.oasis.radius = TUNING.EVILTREE_OASIS_RADIUS
	
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	
	local scale = math.random() > 0.5 and 1 or -1
	inst.AnimState:SetScale(scale, 1)

	local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)
	
	TheWorld:PushEvent("ms_registeroasis", inst)

	inst.OnRemoveEntity = OnRemoveEntity	
	return inst
end
	return Prefab(name, fn, assets)
end

local function MakeTreesEmpty(name)
	local assets = {
	Asset("ANIM", "anim/eviltree_tall_empty.zip"),
	Asset("SCRIPT", "scripts/prefabs/eviltreeshadow.lua")
	}

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()
	
	MakeObstaclePhysics(inst, 3)
	
	inst.Transform:SetScale(1, 1, 1)

	inst.MiniMapEntity:SetIcon("eviltree_tall.tex") 
	
	inst.AnimState:SetBank("eviltree_tall_empty")
	inst.AnimState:SetBuild("eviltree_tall_empty")
	inst.AnimState:PlayAnimation("idle")
	
	inst:AddTag("antlion_sinkhole_blocker")
	inst:AddTag("birdblocker")
	inst:AddTag("NOCLICK")
	inst:AddTag("shadecanopy")
	
	if not TheNet:IsDedicated() then
		inst:AddComponent("distancefade")
		inst.components.distancefade:Setup(15, 25)
		
		inst:AddComponent("eviltreeshade")
		inst.components.eviltreeshade.range = math.floor(TUNING.SHADE_CANOPY_RANGE / 4)
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst.players = {}
    inst:AddComponent("playerprox")
	inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(MIN, MAX)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
	
	--inst:AddComponent("oasis")
	--inst.components.oasis.radius = TUNING.EVILTREE_OASIS_RADIUS
	
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	
	local scale = math.random() > 0.5 and 1 or -1
	inst.AnimState:SetScale(scale, 1)

	local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)
	
	TheWorld:PushEvent("ms_registeroasis", inst)

	inst.OnRemoveEntity = OnRemoveEntity	
	return inst
end
	return Prefab(name, fn, assets)
end

return MakeTrees("eviltree_tall1"),
MakeTreesEmpty("eviltree_tall2")