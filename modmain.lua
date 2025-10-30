require("evilforest_util")
require("strings/strings_en")

GLOBAL.DF_DEV = GetModConfigData("devmode")
if GLOBAL.DF_DEV then
    GLOBAL.CHEATS_ENABLED = true
    modimport("init/init_debugcommands")
end

DFUpvalueHacker = require("tools/df_upvaluehacker")
GLOBAL.DFUpvalueHacker = DFUpvalueHacker

local inits = {
    "init_constants",
    "init_tuning",
	"init_actions",
    "init_RPC",
    "init_languages",
    "init_postinit",
	"init_assets",
    "init_recipes",
    "init_prefabs",
	"init_widgets",
}

for _, v in pairs(inits) do
	modimport("init/"..v)
end

AddReplicableComponent("df_ichormanager")
