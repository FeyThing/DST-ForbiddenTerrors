local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local FISH_DATA = require("prefabs/oceanfishdef")

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

ENV.AddPrefabPostInit("oceanfish_small_df_inv", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	---inst:AddComponent("snowmandecor")
	
	if inst.components.tradable then
		inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.RAREMEAT
	end
end)