local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------

DFENV.AddComponentPostInit("birdspawner", function(self)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
local inst = self.inst

--Private
local _map = TheWorld.Map
local _worldstate = TheWorld.state

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self:SetBirdTypesForTile(WORLD_TILES.OCEAN_EVIL, {})
self:SetBirdTypesForTile(WORLD_TILES.OCEAN_EVIL_SHORE, {})

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)