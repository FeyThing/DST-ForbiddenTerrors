local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function MakePassDFOcean(inst)
    inst.Physics:SetBlockMask("df_ocean_boundaries", COLLISION.CHARACTERS, COLLISION.PERMEABLE_LAND_OCEAN_LIMITS)
end

local function OnDFOceanChanged(inst)

end

local function OnDFOceanShoreChanged(inst)

end

local function OnChangeCanopyZone(inst, underleaawves)
	inst._underevilcanopy:set(underleaves)
end

ENV.AddPlayerPostInit(function(inst)
	inst._underevilcanopy = net_bool(inst.GUID, "player._underevilcanopy","underevilcanopydirty")

    MakePassDFOcean(inst)

    if inst.components.areaaware ~= nil then
        inst.components.areaaware:StartWatchingTile(WORLD_TILES.OCEAN_EVIL)
        inst.components.areaaware:StartWatchingTile(WORLD_TILES.OCEAN_EVIL_SHORE)

        inst:ListenForEvent("on_OCEAN_EVIL_tile", OnDFOceanChanged)
        inst:ListenForEvent("on_OCEAN_EVIL_SHORE_tile", OnDFOceanChanged)
    end
	
	if not TheWorld.ismastersim then
		return
	end
	
	inst:ListenForEvent("onchangeevilzone", OnChangeCanopyZone)
end)