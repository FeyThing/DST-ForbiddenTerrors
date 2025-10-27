local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local modimport = ENV.modimport
--local GetModConfigData = ENV.GetModConfigData

modimport("libraries/df_particletilehelper")
modimport("libraries/df_particleworldtilestate")

require("map/df_terrain")

modimport("postinit/map/maptags")

modimport("init/init_tuning")
modimport("init/init_tiledefs")

--	Setpieces

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

local evil_layouts = {
	["eviltrees"] = {
		defs = {
			eviltrees = {"eviltree_tall1", "eviltree_tall2"},
		},
	},
	["itchy_death"] = {},
	["mushroom_trap"] = {},
	["shady_graveyard"] = {},

}

for k, v in pairs(evil_layouts) do
	Layouts[k] = StaticLayout.Get("map/static_layouts/"..(v.name or string.lower(k)), {
        layout_position = v.layout_position,
        defs = v.defs,
    })

	Layouts[k].ground_types = EVIL_GROUND_TYPES
end

modimport("init/init_worldgen")