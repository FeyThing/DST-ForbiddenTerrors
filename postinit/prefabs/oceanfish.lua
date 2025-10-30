local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local FISH_DATA = require("prefabs/oceanfishdef")

local brain = require "brains/df_oceanfishbrain"


local prefabs = {
	"fishmeat_small",
}

SetSharedLootTable('oceanfish_small_df', {
	{'fishmeat_small',  1},
})

local DIET = {OMNI = {caneat = {FOODGROUP.OMNI}}}

local SET_HOOK_TIME_SHORT = {base = 1, var = 0.5}
local SET_HOOK_TIME_MEDIUM = {base = 2, var = 0.5}

local BREACH_FX_SMALL = {"ocean_splash_small1", "ocean_splash_small2"}
local BREACH_FX_MEDIUM = {"ocean_splash_med1", "ocean_splash_med2"}

local SHADOW_SMALL = {1, 0.75}
local SHADOW_MEDIUM = {1.5, 0.75}

FISH_DATA.fish["oceanfish_small_df"] = {
	prefab = "oceanfish_small_df",
	bank = "oceanfish_small_df",
	build = "oceanfish_small_df",
	weight_min = 172.41,
	weight_max = 228.88,
	
	walkspeed = 2,
	runspeed = 4,
	stamina = {
		drain_rate = 		0.15,
		recover_rate = 		0.1,
		struggle_times = 	{low = 4, r_low = 1, high = 4, r_high = 2},
		tired_times = 		{low = 4, r_low = 0, high = 4, r_high = 1},
		tiredout_angles = 	{has_tention = 30, low_tention = 60},
	},
	
	schoolmin = 2,
	schoolmax = 6,
	schoolrange = 3,
	schoollifetimemin = 480,
	schoollifetimemax = 960,
	
	herdwandermin = 30,
	herdwandermax = 60,
	herdarrivedist = 8,
	herdwanderdelaymin = 30,
	herdwanderdelaymax = 60,
	
	set_hook_time = SET_HOOK_TIME_MEDIUM,
	breach_fx = BREACH_FX_SMALL,
	loot = {"fishmeat_small"},
	heavy_loot = {"fishmeat_small", "fishmeat_small"},
	cooking_product = "fishmeat_small_cooked",
	perish_product = "fishmeat_small",
	fishtype = "meat",
	
	lures = TUNING.OCEANFISH_LURE_PREFERENCE.OMNI,
	diet = DIET.OMNI,
	cooker_ingredient_value = {meat = 1, fish = 1, frozen = 1},
	edible_values = {health = TUNING.HEALING_MEDSMALL, hunger = TUNING.CALORIES_MED, sanity = 0, foodtype = FOODTYPE.MEAT},
	
	dynamic_shadow = SHADOW_SMALL,
}

--

FISH_DATA.school[SEASONS.AUTUMN][WORLD_TILES.OCEAN_EVIL] = {
	oceanfish_small_2 = 1,
	oceanfish_medium_1 = 1,
	oceanfish_small_df = 5,
}

FISH_DATA.school[SEASONS.WINTER][WORLD_TILES.OCEAN_EVIL] = {
	oceanfish_small_df = 1,
}

FISH_DATA.school[SEASONS.SPRING][WORLD_TILES.OCEAN_EVIL] = {
	oceanfish_small_df = 6,
}

FISH_DATA.school[SEASONS.SUMMER][WORLD_TILES.OCEAN_EVIL] = {
	oceanfish_small_2 = 1,
	oceanfish_medium_1 = 1,
	oceanfish_small_df = 5,
}

--
local MAX_CHASEAWAY_DIST_SQ = 40 * 40
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40


local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }
local range = TUNING.DF_OCEANFISH_TARGET_DIST

local function Retarget(inst)
	if not inst:IsHungryFish() then
		return
	end
	
	return FindEntity(inst, range, function(guy)
		return inst.components.combat:CanTarget(guy) and not TheWorld.Map:IsPassableAtPoint(guy.Transform:GetWorldPosition())
	end, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
end

local function KeepTarget(inst, target)
	return not TheWorld.Map:IsPassableAtPoint(target.Transform:GetWorldPosition())
end

local function _ShareTargetFn(dude)
	return dude:HasTag("piranha")
end

local function OnAttacked(inst, data)
	local attacker = data ~= nil and data.attacker or nil
	if attacker and (attacker:HasTag("piranha") or TheWorld.Map:IsPassableAtPoint(attacker.Transform:GetWorldPosition())) then
		return
	end
	
	inst.components.combat:SetTarget(attacker)
	inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, _ShareTargetFn, MAX_TARGET_SHARES)
end

local function IsHungryFish(inst)
	local lasteattime = inst.components.eater and inst.components.eater.lasteattime
	
	return lasteattime == nil or (GetTime() - lasteattime  > 5)
end

ENV.AddPrefabPostInit("oceanfish_small_df", function(inst)
	inst:RemoveTag("notarget")
	inst:RemoveTag("NOCLICK")
	inst:AddTag("piranha")

	if not TheWorld.ismastersim then
		return
	end

	local combat = inst:AddComponent("combat")
	combat.hiteffectsymbol = "smol_bod_water"
	combat:SetRange(TUNING.PIRANHA_ATTACK_RANGE)
	combat:SetAttackPeriod(TUNING.PIRANHA_ATTACK_PERIOD)
	combat:SetDefaultDamage(TUNING.PIRANHA_DAMAGE)
	combat:SetRetargetFunction(0, Retarget)
	combat:SetKeepTargetFunction(KeepTarget)
    combat:SetShouldAggroFn(KeepTarget)

	local health = inst:AddComponent("health")
	health:SetMaxHealth(TUNING.PIRANHA_HEALTH)

	--
	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('oceanfish_small_df')
	
	inst.IsHungryFish = IsHungryFish
	inst:SetBrain(brain)

	inst:ListenForEvent("attacked", OnAttacked)
end)


ENV.AddPrefabPostInit("oceanfish_small_df_inv", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	---inst:AddComponent("snowmandecor")
	
	if inst.components.tradable then
		inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.RAREMEAT
	end
end)