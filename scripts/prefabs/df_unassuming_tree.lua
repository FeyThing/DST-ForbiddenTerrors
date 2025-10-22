local brain = require "brains/df_unassuming_treebrain"

local assets = {
	Asset("ANIM", "anim/df_unassuming_tree.zip"),
}

local prefabs = {
	"monstermeat",
	"livinglog",
	"character_fire",
}

local SIGHT_MUST_TAGS = {"player"}
local SIGHT_CANT_TAGS = {"INLIMBO", "playerghost", "hiding", "noattack", "invisible"}
local SIGHT_ONEOF_TAGS = nil

local function CanPlayersSeeUs(inst)
	local pos = inst:GetPosition()
	local in_fog = IsInDarkForest(inst) and TheWorld:HasTag("df_fog_ongoing")
	local in_light = inst:IsInLight()
	
	-- Never move in light if it's not foggy
	if not in_fog and in_light then
		return true
	end
	
	local players = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.DF_UNASSUMING_TREE_SIGHT_RANGE, SIGHT_MUST_TAGS, SIGHT_CANT_TAGS, SIGHT_ONEOF_TAGS)
	for _,player in ipairs(players) do
		-- Does a player have night vision
		if CanEntitySeeInDark(player) then
			return true
		end
		
		-- Is a player looking towards it while not in darkness
		local player_in_light = player:IsInLight()
		local rotation = player.Transform:GetRotation()
		local forward = Vector3(math.cos(-rotation/RADIANS), 0, math.sin(-rotation/RADIANS))
		if player_in_light and IsWithinAngle(player:GetPosition(), forward, TUNING.DF_UNASSUMING_TREE_SIGHT_ANGLE/RADIANS, pos) then
			return true
		end
	end
end

local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target) and not target:HasOneOfTags(SIGHT_CANT_TAGS)
end

local function OnWorked(inst, worker)
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_big")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function OnNewState(inst, data)
	if inst.components.workable ~= nil then
		local canwork = inst.sg:HasAnyStateTag("df_treeform")
		if inst.components.workable.workable ~= canwork then
			inst.components.workable:SetWorkable(canwork)
		end
	end
end

local function OnLoad(inst, data)
end

local function OnSave(inst, data)
end

local UNASSUMING_LOOT = {
	"livinglog",
	"livinglog",
	"monstermeat",
	-- to-do
}

local function fn(build)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()
	
	MakeCharacterPhysics(inst, 1000, .5)
	
	inst.DynamicShadow:SetSize(4, 1.5)
	inst.Transform:SetFourFaced()
	
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("largecreature")
	
	inst.AnimState:SetBank("df_unassuming_tree")
	inst.AnimState:SetBuild("df_unassuming_tree")
	inst.AnimState:PlayAnimation("idle1")
	inst.scrapbook_anim = "idle1"
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.DF_UNASSUMING_TREE_WALKSPEED
	inst:SetStateGraph("SGdf_unassuming_tree")
	
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED -- 40/min
	
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.DF_UNASSUMING_TREE_DAMAGE)
	inst.components.combat:SetRange(TUNING.DF_UNASSUMING_TREE_ATTACK_RANGE)
	inst.components.combat:SetAttackPeriod(TUNING.DF_UNASSUMING_TREE_ATTACK_PERIOD)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.hiteffectsymbol = "body_lower_body_lower-0"
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkable(false)
	inst.components.workable:SetWorkAction(ACTIONS.CHOP)
	inst.components.workable:SetWorkLeft(TUNING.DF_UNASSUMING_TREE_WORK)
	inst.components.workable:SetOnFinishCallback(OnWorked)
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(UNASSUMING_LOOT)
	
	inst:AddComponent("inspectable")
	
	inst.CanPlayersSeeUs = CanPlayersSeeUs
	inst:SetBrain(brain)
	
	MakeLargeBurnable(inst)
	MakeMediumPropagator(inst)
	MakeHauntableIgnite(inst)
	
	inst:ListenForEvent("newstate", OnNewState)
	
	inst.OnLoad = OnLoad
	inst.OnSave = OnSave
	
	return inst
end

return Prefab("df_unassuming_tree", fn, assets, prefabs)