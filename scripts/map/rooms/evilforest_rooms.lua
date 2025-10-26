AddRoom("BG EvilForest", {
	colour = {r = 0.3, g = 0.2, b = 0.1, a = 0.3},
	tags = {"DF_Forest", "DF_Rivers"},
	value = WORLD_TILES.EVILMUDDY_NOISE,
	contents = {
		distributepercent = 0.07,
		distributeprefabs = {
			marsh_tree = 1,
			marsh_bush = 0.66,
			--df_grass = 0.66,
			dead_sea_bones = 0.5,
		},
	}
})

AddRoom("EvilForest", {
	colour = {r = 0.3, g = 0.2, b = 0.1, a = 0.3},
	tags = {"DF_Forest"},
	value = WORLD_TILES.EVILFOREST_NOISE,
	contents = {
		countstaticlayouts = {
			["eviltrees"] = 10 + math.random(10, 18),
			["LivingTree"] = function() return math.random(1,2) end,
		},
		countprefabs = {
			df_berrybush = function() return math.random(4,6) end,
		},
		distributepercent = 0.07,
		distributeprefabs = {
			bigrocks = {weight = 0.2, prefabs = {"rock1", "rock_flintless"}},
			rabbithole = 0.3,
			flower_evil = 0.3,
			df_berrybush = 0.44,
			marsh_bush = 0.66,
			fireflies = 0.33,
			evergreen_sparse = 6,
			gravestone = 0.5,
			df_mushroom = 0.5,
		},
	},
})

AddRoom("EvilForest Ponds", {
	colour = {r = 0.3, g = 0.2, b = 0.1, a = 0.3},
	tags = {"DF_Forest", "DF_Rivers"},
	value = WORLD_TILES.EVILFOREST,
	contents = {
		distributepercent = 0.25,
		distributeprefabs = {				
			pond = 0.2,				
			flower_evil = 0.3,
			evergreen_sparse = 3,				
			--df_grass = 1,
			flint = 0.4,
			fireflies = 0.33,
			marsh_bush = 0.66,
			eviltrees_bald = 0.1
		},
	},
})

AddRoom("EvilForest Bog", {
	colour = {r = 0.3, g = 0.2, b = 0.1, a = 0.3},
	tags = {"DF_Forest", "DF_Rivers"},
	value = WORLD_TILES.EVILFOREST_WATER_CONVERT,
	contents = {
		distributepercent = 0.1,
		distributeprefabs = {
			fireflies = 0.33,
			df_reeds = 0.63,
			df_rock_water = 0.6,
			df_waterspot = 0.3,
		},
	},
})