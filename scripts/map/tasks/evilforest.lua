require("map/rooms/evilforest_rooms")

AddTask("Evil Forest", {
	locks={},
	keys_given={KEYS.ISLAND_TIER2},
	region_id = "evilforest",
	level_set_piece_blocker = true,
	room_tags = {"RoadPoison", "not_mainland"},
	room_choices={
		["EvilForest"] = function() return 4 + math.random(SIZE_VARIATION) end,
		["EvilForest Ponds"] = function() return 2 + math.random(SIZE_VARIATION) end,
		["EvilForest Bog"] = 2,
		["EvilForest Outland"] = 1,
		["EvilForest Graveyard"] = 1,
		["BG EvilForest"] = function() return math.random(SIZE_VARIATION) end,
	},
	room_bg=WORLD_TILES.EVILFOREST_NOISE,
	background_room = "BG EvilForest",
	colour={r=.05,g=.5,b=.05,a=1},
})	

AddTask("Evil Land", {
	locks={LOCKS.NONE},
	keys_given={KEYS.TIER2},
	region_id = "evilforest",
	level_set_piece_blocker = true,
	room_tags = {"RoadPoison", "evilforest"},
	room_choices={
		["EvilForest"] = 2,
		["EvilForest Ponds"] = function() return 3 + math.random(SIZE_VARIATION) end,
		["BG EvilForest"] = function() return math.random(SIZE_VARIATION) end,
	},
	room_bg=WORLD_TILES.EVILFOREST_NOISE,
	background_room = "BG EvilForest",
	colour={r=.05,g=.5,b=.05,a=1},
})