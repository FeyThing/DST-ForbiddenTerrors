local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local EVILFOREST_AMBIENT_SOUND = {  
	[WORLD_TILES.EVILFOREST] = {sound = "dontstarve/AMB/forest", wintersound = "dontstarve/AMB/forest_winter", springsound = "dontstarve/AMB/forest", summersound = "dontstarve_DLC001/AMB/forest_summer", rainsound = "dontstarve/AMB/forest_rain"},
	[WORLD_TILES.EVILMUDDY] = {sound = "dontstarve/AMB/marsh", wintersound = "dontstarve/AMB/marsh_winter", springsound = "dontstarve/AMB/marsh", summersound = "dontstarve_DLC001/AMB/marsh_summer", rainsound = "dontstarve/AMB/marsh_rain"},
	[WORLD_TILES.OCEAN_EVIL] = {sound = "turnoftides/together_amb/ocean/shallow", rainsound = "turnoftides/together_amb/ocean/shallow_rain"},
    [WORLD_TILES.OCEAN_EVIL_SHORE] = {sound = "turnoftides/together_amb/ocean/shallow", rainsound = "turnoftides/together_amb/ocean/shallow_rain"}
}

ENV.AddComponentPostInit("ambientsound", function(self)
	local AMBIENT_SOUNDS, SOUND = EvilforestUpvalue(self.OnUpdate, "AMBIENT_SOUNDS")
	
	if SOUND then
		for k, v in pairs(EVILFOREST_AMBIENT_SOUND) do
			AMBIENT_SOUNDS[k] = EVILFOREST_AMBIENT_SOUND[k]
		end
	end
end)