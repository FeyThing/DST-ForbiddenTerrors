local NAMES = STRINGS.NAMES
local RECIPE_DESC = STRINGS.RECIPE_DESC
local ANNOUNCE = STRINGS.CHARACTERS.GENERIC
local DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE

STRINGS.ACTIONS.DF_HIDEIN = "Hide in"
STRINGS.ACTIONS.DF_PANNING = "Pan"
STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.DF_HIDEIN = {
	OCCUPIED = "Looks like someone is already hiding here.",
}

--- Env
NAMES.DF_GRASS = "Wild Grass"
DESCRIBE.DF_GRASS = "It's tall enough to hide in."
NAMES.DF_REEDS = "Bog Reeds"
NAMES.DF_ROCK_WATER = "Submerged Rock"
DESCRIBE.DF_ROCK_WATER = "Mining it could lose rocks."
NAMES.DF_MUSHROOM = "Night Mushroom"
NAMES.DF_CAP = "Night Cap"
NAMES.DF_CAP_COOKED = "Grilled Night Cap"
NAMES.DF_POISON_IVY = "Poison Ivy"
NAMES.DF_BERRYBUSH = "Spiky BerryBush"
NAMES.DF_DRIFTWOOD = "Gnarled Driftwood"
NAMES.EVILTREE_TALL1 = "Ancient Tree"
NAMES.EVILTREE_TALL2 = "Gnarled Tree"

--- Mobs
NAMES.DF_MOSQUITO = "Bogskito"
NAMES.DF_UNASSUMING_TREE = "Unassuming Tree"
NAMES.OCEANFISH_SMALL_DF = "Piranha"

--- Other
DESCRIBE.TURF_EVILFOREST = "It's a creepy tuft of grass"
NAMES.TURF_EVILFOREST = "DarkForest Turf"

NAMES.HIDDEN_IN_DF_FOG = "???"
ANNOUNCE.DESCRIBE_HIDDEN_IN_DF_FOG = "Did you see that? I didn't."

---	Recipes
RECIPE_DESC.TURF_EVILFOREST = "A patch of disturbing grass."