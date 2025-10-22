require("evilforest_util")
require("evilforest_strings")

GLOBAL.DF_DEV = GetModConfigData("devmode")
if GLOBAL.DF_DEV then
    GLOBAL.CHEATS_ENABLED = true
    modimport("init/init_debugcommands")
end

local inits = {
    "init_constants",
    "init_tuning",
	"init_actions",
    "init_RPC",
    "init_postinit",
	"init_assets",
    "init_prefabs",
	"init_widgets",
}

for _, v in pairs(inits) do
	modimport("init/"..v)
end
