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
	"eviltrees",
}

for _, layout in ipairs(evil_layouts) do
	Layouts[layout] = StaticLayout.Get("map/static_layouts/"..string.lower(layout))
	Layouts[layout].ground_types = EVIL_GROUND_TYPES
end

modimport("init/init_worldgen")