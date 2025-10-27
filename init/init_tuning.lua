local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local function merge(target, new, soft)
    if not target then
        target = {}
    end

    for k, v in pairs(new) do
        if type(v) == "table" then
            target[k] = type(target[k]) == "table" and target[k] or {}
            merge(target[k], v)
        else
            if target[k] then
                if not soft then
                    target[k] = v
                end
            else
                target[k] = v
            end
        end
    end
    return target
end

local TechTree = require("techtree")

local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME
local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH
local sleep_range = 64 --Distance before an entity is unloaded.
local sleep_range_sq = sleep_range*sleep_range

local DF_TUNING = {
	DF_FOG_ENABLED = true,
	DF_FOG_BLOCK_RANGES = {
		FIRE = 12,
		PLAYER = 8,
	},
	DF_FOG_BLOCKER_DURATION = 5,
	DF_FOG_BLOCKER_DURATION_GRADUAL = seg_time * 4,
	DF_FOG_COOLDOWNS = {min = 6 * total_day_time, max = 8 * total_day_time},
	DF_FOG_DURATIONS = {min = 1 * total_day_time, max = 2 * total_day_time},
	DF_FOG_MOISTURE_DT = 0.5,
	
	DF_WATERPROOFNESS_MULT = 0.8,
	DF_WATERSETTINGS = {
		LENGTH = 200,
		STEPS = 1.5,
		JITTER = 0.4,
		WIDENESS_MIN = 1,
		WIDENESS_MAX = 3,
	},
    DF_MOSQUITO_HEALTH = 300,
    DF_MOSQUITO_DAMAGE = 20,
    DF_MOSQUITO_ATTACK_RANGE = 5,
    DF_MOSQUITO_ATTACK_PERIOD = 7,
    DF_MOSQUITO_MAX_DRINKS = 12,
    DF_MOSQUITO_BURST_DAMAGE = 102,
    DF_MOSQUITO_BURST_RANGE = 6,
	
	DF_UNASSUMING_TREE_WALKSPEED = 7,
	DF_UNASSUMING_TREE_WORK = 10,
	DF_UNASSUMING_TREE_DAMAGE = 30,
	DF_UNASSUMING_TREE_ATTACK_RANGE = 3,
	DF_UNASSUMING_TREE_ATTACK_PERIOD = 3,
	DF_UNASSUMING_TREE_SIGHT_RANGE = 12,
	DF_UNASSUMING_TREE_SIGHT_ANGLE = 120,

    DF_DRIFTWOOD_CHOPS = TUNING.DRIFTWOOD_SMALL_CHOPS,

    DF_DRIFTWOOD_SPAWN_DELAY = {
        -- MIN = 30, 
        -- MAX = 45
        MIN = 40, 
        MAX = 80
    },

    DF_DRIFTWOOD_LIFETIME = {
        MIN = TUNING.TOTAL_DAY_TIME * 3,
        MAX = TUNING.TOTAL_DAY_TIME * 4
    },

    DF_OCEANFISH_SPAWN_DELAY = {
        -- MIN = 30, 
        -- MAX = 45
        MIN = 30, 
        MAX = 50
    },

    DF_OCEANFISH_LIFETIME = {
        MIN = TUNING.TOTAL_DAY_TIME * 3,
        MAX = TUNING.TOTAL_DAY_TIME * 4
    },

    DF_MOSQUITO_SPAWN_DELAY = {
        -- MIN = 30, 
        -- MAX = 180
        MIN = 15, 
        MAX = 20
    },

    DF_UNASSUMING_TREE_SPAWN_DELAY = {
        -- MIN=30, 
        -- MAX=180
        MIN = 40, 
        MAX = 80
    },

    DF_UNASSUMING_TREE_MAX_SPAWNED = 20,
}


merge(TUNING, DF_TUNING)
