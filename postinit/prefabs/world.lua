local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

------------------------------------

local InitializeParticleWorldTileState = InitializeParticleWorldTileState
local OnAnyTerraformParticleWorldTileState = OnAnyTerraformParticleWorldTileState

local function OnTerraForm(inst, data)
    if data == nil then return end
    SendModRPCToClient(GetClientModRPC("Dark Forest", "OnTerraform"), nil, ZipAndEncodeString(data))
    if inst.components.df_localtilewatcher ~= nil then
        inst.components.df_localtilewatcher:OnTerraform(data)
    end
end

-- TODO (HALF): The outer collision is a bit wonky you might want to tweak it
-- I would suggest editing the waterfall shader so it turns transparent quicker because atm it is waaaaay too big.
local function CreateTilePhysics(inst, ...)
    -- DF's ocean waterfall collider

    -- Inner collsion
    inst.Map:AddTileCollisionSet(
        COLLISION.GROUND,
        TileGroups.NonDFOceanTiles, true,
        TileGroups.DFOceanTiles, true,
        0.25, 128 -- radius, height
    )

    -- Outer collsion
    inst.Map:AddTileCollisionSet(
        COLLISION.GROUND,
        TileGroups.NonDFOceanTiles, true,
        TileGroups.DFOceanTiles, true,
        0.4, 128 -- radius, height
    )

    -- Ugly hack
    local _AddTileCollisionSet = Map.AddTileCollisionSet
    function Map:AddTileCollisionSet(mask, group1, check1, group2, check2, radius, height, ...)
        if mask == COLLISION.LAND_OCEAN_LIMITS and group1 == TileGroups.LandTiles and group2 == TileGroups.LandTiles and not check1 and check2 then
            print("HIJACKING OCEAN COLLIDER")
            _AddTileCollisionSet(self, 
                COLLISION.LAND_OCEAN_LIMITS,
                TileGroups.NonDFOceanTiles, true,
                TileGroups.LandTiles, true,
                0.25, 64
            )

            _AddTileCollisionSet(self, 
                COLLISION.PERMEABLE_LAND_OCEAN_LIMITS,
                TileGroups.DFOceanTiles, true,
                TileGroups.LandTiles, true,
                0.25, 64
            )
            return
        end
        return _AddTileCollisionSet(self, mask, group1, check1, group2, check2, radius, height, ...)
    end
    inst.DF_CreateTilePhysics(inst, ...)
    Map.AddTileCollisionSet = _AddTileCollisionSet
end

DFENV.AddPrefabPostInit("world", function(inst)
	inst.DF_CreateTilePhysics = inst.CreateTilePhysics
    inst.CreateTilePhysics = CreateTilePhysics
	
	inst:AddComponent("darkforest_manager")
	
    if not TheNet:IsDedicated() then
        if IsWorldDFEnabled() then
			inst:AddComponent("df_fog")
			
            inst:AddComponent("df_waterfallmanager")
            inst.components.df_waterfallmanager:RegisterWaterfallTile(WORLD_TILES.OCEAN_EVIL_SHORE, "waterfall_oceanevil")
			
            inst:AddComponent("df_localtilewatcher")
            inst:ListenForEvent("worldmapsetsize", function() InitializeParticleWorldTileState() end)
            inst:ListenForEvent("df_local_onanyterraform", function(_, data) OnAnyTerraformParticleWorldTileState(data) end)
        end
    end

    if not inst.ismastersim then
        return
    end
	
    if IsWorldDFEnabled() then
		inst:AddComponent("df_fog_cycle")
		
		inst:AddComponent("df_grassspawner")
		
        inst:ListenForEvent("onterraform", OnTerraForm)
        inst:AddComponent("df_shoretilemanager")
    end
end)

DFENV.AddSimPostInit(function()
	if TheWorld.components.darkforest_manager then
		TheWorld.components.darkforest_manager:Initialize()
	end
end)