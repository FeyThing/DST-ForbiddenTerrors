local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local function GetFullCollisionMask()
    local mask = 0
    for k, v in pairs(COLLISION) do
        mask = bit.bor(mask, v)
    end
    return mask
end

local MAX_COLLISIONS = 15
local function GetNextCollisionMask()
    local mask = GetFullCollisionMask()

    for i = 0, MAX_COLLISIONS do
        local collision = 2^i
        if bit.band(mask, collision) == 0 then
            return collision
        end
    end
    
    printwrap("Current Collisions", COLLISION)
    assert(false, "No more physical collisions to be found, this will severely impact the IA mods so we're just crashing here")
end

local function InheritCollisionMask(base_mask, inherit_mask)
    for name, mask in pairs(COLLISION) do
        if bit.band(mask, inherit_mask) > 0 then
            COLLISION[name] = mask + base_mask
        end
    end
end

COLLISION.PERMEABLE_LAND_OCEAN_LIMITS = GetNextCollisionMask()

InheritCollisionMask(COLLISION.PERMEABLE_LAND_OCEAN_LIMITS, COLLISION.LAND_OCEAN_LIMITS)
