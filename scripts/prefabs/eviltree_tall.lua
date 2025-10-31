local valid_lantern_prefabs = {
	lantern = true,
	df_lantern = true,
}

local function PutLantern(inst, enable, item)
	inst.AnimState:ClearOverrideSymbol("lantern")
	inst.AnimState:ClearOverrideSymbol("lantern_overlay")
	
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetWorkable(enable)
	
	if enable then
		inst.components.trader:Disable()
		
		inst.AnimState:Show("rope")
		inst.AnimState:Show("lantern")
		inst.AnimState:Show("lantern_overlay")
		
		if item and item:IsValid() then
			local skin_build = item:GetSkinBuild()
			
			if skin_build then
				inst.AnimState:OverrideItemSkinSymbol("lantern", skin_build, "swap_lantern", item.GUID, "lantern")
				inst.AnimState:OverrideItemSkinSymbol("lantern_overlay", skin_build, "lantern_overlay", item.GUID, "lantern")
			end
			if inst._light == nil then
				inst._light = SpawnPrefab("lanternlight")
				inst._light._lantern = inst
			end
			
			inst._light.entity:SetParent(inst.entity)
			inst._light.Light:SetIntensity(Lerp(.4, .6, 1))
			inst._light.Light:SetRadius(Lerp(3, 5, 1))
			inst._light.Light:SetFalloff(.9)
		end
	else
		inst.components.trader:Enable()
		
		inst.AnimState:Hide("rope")
		inst.AnimState:Hide("lantern")
		inst.AnimState:Hide("lantern_overlay")
		
		if inst._light then
			inst._light:Remove()
			inst._light = nil
		end
		
		inst.components.inventory:DropEverything(true)
	end
end

local function ShouldAcceptItem(inst, item)
	return item and inst.valid_lantern_prefabs[item.prefab]
end

local function OnGetItem(inst, giver, item)
	inst:PutLantern(true, item)
end

local function OnWorked(inst, worker, workleft)
	if workleft > 0 then
		inst.AnimState:PlayAnimation("chop")
		--inst.AnimState:PushAnimation("idle")
	end
	inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
end

local function OnWorkFinished(inst)
	inst.components.lootdropper:SpawnLootPrefab("twigs")
	inst.components.lootdropper:SpawnLootPrefab("log")
	
	inst.components.timer:StartTimer("grow", 480 + math.random(480))
	
	inst.components.trader:Disable()
	
	inst.AnimState:PlayAnimation("break")
	--inst.AnimState:PushAnimation("idle")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	
	inst:PutLantern(false)
end

local MIN = TUNING.SHADE_CANOPY_RANGE
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER

local function OnFar(inst, player)
	if player.canopytrees then   
		player.canopytrees = player.canopytrees - 1
		player:PushEvent("onchangeevilzone", player.canopytrees > 0)
	end
	
	inst.players[player] = nil
end

local function OnNear(inst, player)
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

local function OnInit(inst)
	local lantern = inst.components.inventory:FindItem(function(item)
		return item and inst.valid_lantern_prefabs[item.prefab] end)
	
	if lantern then
		inst:PutLantern(true, lantern)
	end
end

local function OnTimerOver(inst, data)
	if data.name == "grow" then
		inst.AnimState:PlayAnimation("grow")
		--inst.AnimState:PushAnimation("idle")
		
		inst.components.trader:Enable()
		
		inst.components.workable:SetWorkLeft(4)
		inst.components.workable:SetWorkable(true)
	end
end

local function MakeTree(name, has_branch)
	local assets = {
		Asset("ANIM", "anim/eviltree_tall.zip"),
		Asset("ANIM", "anim/eviltree_tall_empty.zip"),
		
		Asset("SCRIPT", "scripts/prefabs/eviltreeshadow.lua")
	}
	
	local function fn()
		local inst = CreateEntity()
		
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()
		
		MakeObstaclePhysics(inst, 2.6)
		
		inst.MiniMapEntity:SetIcon("eviltree_tall.tex") 
		
		inst.AnimState:SetBank(has_branch and "eviltree_tall" or "eviltree_tall_empty")
		inst.AnimState:SetBuild(has_branch and "eviltree_tall" or "eviltree_tall_empty")
		inst.AnimState:PlayAnimation("idle", true)
		inst.AnimState:Hide("rope")
		inst.AnimState:Hide("lantern")
		inst.AnimState:Hide("lantern_overlay")
		
		inst:AddTag("antlion_sinkhole_blocker")
		inst:AddTag("birdblocker")
		--inst:AddTag("NOCLICK")
		inst:AddTag("shadecanopy")
		inst:AddTag("walkableperipheral")
		
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
		
		inst.valid_lantern_prefabs = valid_lantern_prefabs
		inst.players = {}
		
		inst:AddComponent("inventory")
		
		inst:AddComponent("lootdropper")
		
		inst:AddComponent("playerprox")
		inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
		inst.components.playerprox:SetDist(MIN, MAX)
		inst.components.playerprox:SetOnPlayerFar(OnFar)
		inst.components.playerprox:SetOnPlayerNear(OnNear)
		
		inst:AddComponent("timer")

		inst:AddComponent("inspectable")
		
		if has_branch then
			inst:AddComponent("trader")
			inst.components.trader:SetAcceptTest(ShouldAcceptItem)
			inst.components.trader.onaccept = OnGetItem
			inst.components.trader.acceptnontradable = true
			inst.components.trader.deleteitemonaccept = false
		end
		
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetOnWorkCallback(OnWorked)
		inst.components.workable:SetOnFinishCallback(OnWorkFinished)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetWorkable(has_branch)
		
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
		inst.PutLantern = PutLantern
		
		inst:ListenForEvent("timerdone", OnTimerOver)
		inst:ListenForEvent("animover", function()
			if inst.AnimState:IsCurrentAnimation("break") then
				inst.AnimState:Hide("branch")
			elseif inst.AnimState:IsCurrentAnimation("grow") then
				inst.AnimState:Show("branch")
			end
		end)
		
		if has_branch then
			inst.oninit = inst:DoTaskInTime(0, OnInit)
		end
		
		return inst
	end
	
	return Prefab(name, fn, assets)
end

return MakeTree("eviltree_tall1", true),
	MakeTree("eviltree_tall2", false)