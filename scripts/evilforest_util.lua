function IsInDarkForestAtPoint(x, y, z, range)
	local node = TheWorld.Map:FindNodeAtPoint(x, y, z)
	
	if node == nil and range and range > 0 then
		local pt = Vector3(x, y, z)
		local node_offset = FindValidPositionByFan(0, range, 64, function(offset)
			local _node = TheWorld.Map:FindNodeAtPoint((pt + offset):Get())
			
			return _node and _node.tags and table.contains(_node.tags, "DF_Forest")
		end)
		
		return node_offset ~= nil
	else
		return node and node.tags and table.contains(node.tags, "DF_Forest")
	end
	
	return false
end

function IsInDarkForest(inst, range)
	local x, y, z = inst.Transform:GetWorldPosition()
	
	return IsInDarkForestAtPoint(x, y, z, range)
end

function GetClosestDarkForestTileToPoint(x, y, z, maxdist) -- LukaS: Kinda hacky, don't overuse it or suffer the consequences of L A G
	if TheWorld.components.darkforest_manager == nil then
		return
	end
	
	if IsInDarkForestAtPoint(x, y, z) then
		return TheWorld.Map:GetTileAtPoint(x, y, z), 0
	end
	
	maxdist = maxdist or math.huge
	local dftiles = TheWorld.components.darkforest_manager:GetGrid().grid
	local mindist = math.huge
	local tile
	
	for i, isdf in pairs(dftiles) do
		if isdf then
			local tx, ty = TheWorld.components.darkforest_manager:GetGrid():GetXYFromIndex(i)
			local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)
			local dist = distsq(x, z, cx, cz)
			if dist < mindist then
				mindist = dist
				tile = TheWorld.Map:GetTileAtPoint(cx, cy, cz)
			end
		end
	end
	
	if math.sqrt(mindist) <= maxdist then
		return tile, math.sqrt(mindist)
	end
end

function HiddenInDarkForestFog(inst, viewer)
	local in_fog = false
	
	viewer = viewer or ThePlayer
	
	if TUNING.DF_FOG_ENABLED and inst:IsValid() and not inst:IsInLimbo() and inst.Transform and inst.AnimState then
		local x, y, z = inst.Transform:GetWorldPosition()
		
		in_fog = IsInDarkForest(inst) and not TheWorld.Map:IsDarkForestFogBlocked(x, 0, z) -- TODO: need to add fog toggle pattern
	end
	
	return in_fog and (viewer == nil or viewer:GetDistanceSqToInst(inst) > 4)
end

local OldGetDisplayName = EntityScript.GetDisplayName
function EntityScript:GetDisplayName(...)
	return HiddenInDarkForestFog(self, ThePlayer) and STRINGS.NAMES.HIDDEN_IN_DF_FOG or OldGetDisplayName(self, ...)
end

function EvilforestUpvalue(fn, upvalue_name, set_upvalue)
	if fn == nil or upvalue_name == nil then
		return
	end
	
	local i = 1
	while true do
		local val, v = debug.getupvalue(fn, i)
		
		if not val then
			break
		end
		if val == upvalue_name then
			if set_upvalue then
				debug.setupvalue(fn, i, set_upvalue)
			end
			
			return v, i
		end
		i = i + 1
	end
end

-- TODO (HALF): Xeno you should add a check here so this stuff is only enabled in world that your deep rainforest spawns in
function IsWorldDFEnabled()
	return TheWorld:HasTag("forest")
end

local THE_LUA_REGISTRY = debug.getregistry()
function UpdateLuaRegistry(old, new)
	for k, v in pairs(THE_LUA_REGISTRY) do
		if old == v then
			THE_LUA_REGISTRY[k] = new
		end
	end
end
