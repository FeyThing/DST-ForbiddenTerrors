Assets = {
	Asset( "ANIM", "anim/evil_canopy.zip"),

    Asset( "ANIM", "anim/df_ichor_over.zip"),
	
	Asset( "ANIM", "anim/df_unassuming_tree.zip"),

	Asset("SOUNDPACKAGE", "sound/df_sound.fev"),
	Asset("SOUND", "sound/df_sound.fsb"),

	Asset("IMAGE", "images/evil_inventoryimages.tex"),
	Asset("ATLAS", "images/evil_inventoryimages.xml"),
	Asset("ATLAS_BUILD", "images/evil_inventoryimages.xml", 256),

	Asset("ATLAS", "images/df_map_icons.xml"),
	Asset("IMAGE", "images/df_map_icons.tex"),

	Asset("SHADER", "shaders/df_sink.ksh")
}

AddMinimapAtlas("images/df_map_icons.xml")

GLOBAL.AddAssetsParticleWorldTileState(Assets)

local EVIL_ICONS = GLOBAL.resolvefilepath("images/evil_inventoryimages.xml")
local _GetInventoryItemAtlas_Internal = GLOBAL.GetInventoryItemAtlas_Internal
function GLOBAL.GetInventoryItemAtlas_Internal(imagename, ...)
    return GLOBAL.TheSim:AtlasContains(EVIL_ICONS, imagename) and EVIL_ICONS
            or _GetInventoryItemAtlas_Internal(imagename, ...)
end
