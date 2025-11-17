local CLUSTER_LENGTH = 10
local CLUSTER_WIDTH = 2

local MAX_CLUSTERS = 30

local RIVER_TILE_DIST = 1

local GRASS_PREFABS = {
    df_grass = 7,
    df_poison_ivy = 1,
}

-- Keep up to date for each natural tiles in the dark forest
local DF_TILES_GENERATED = {WORLD_TILES.EVILFOREST, WORLD_TILES.EVILMUDDY, WORLD_TILES.FOREST}

local PLANT_TAGS = {"plant"}

return Class(function(self, inst)
	assert(inst.ismastersim, "DF Grass Spawner should not exist on the client!")
	
	self.inst = inst
	self.spawned = false
	
	local function SpawnGrass(start_x, start_y)
		local angle = math.random() * 2 * math.pi
		local dir_x, dir_y = math.cos(angle), math.sin(angle)
		
		local manager = TheWorld.components.darkforest_manager
		local jitter = (math.random() - 0.5) * 0.2
		
		for i = 1, CLUSTER_LENGTH do
			local ja = jitter * i
			local jx = dir_x * math.cos(ja) - dir_y * math.sin(ja)
			local jy = dir_x * math.sin(ja) + dir_y * math.cos(ja)
			
			local step_x = math.floor(start_x + jx * i)
			local step_y = math.floor(start_y + jy * i)
			
			for w = -CLUSTER_WIDTH, CLUSTER_WIDTH do
				local offset_tx = step_x + math.floor(-jy * w)
				local offset_ty = step_y + math.floor(jx * w)
				
				local tile = TheWorld.Map:GetTile(offset_tx, offset_ty)
				if table.contains(DF_TILES_GENERATED, tile) then
					local x, y, z = TheWorld.Map:GetTileCenterPoint(offset_tx, offset_ty)
					x = x + (math.random() - 0.5) * TILE_SCALE
					z = z + (math.random() - 0.5) * TILE_SCALE
					
					if math.random() < 0.85 then
						local has_space = #TheSim:FindEntities(x, y, z, 0.2 + math.random(), PLANT_TAGS) == 0
							and #TheSim:FindEntities(x, y, z, 4, nil, PLANT_TAGS) == 0
						
						if has_space then
							SpawnPrefab(weighted_random_choice(GRASS_PREFABS)).Transform:SetPosition(x, y, z)
						end
					end
				end
			end
		end
	end
	
	local function SpawnGrassClusters(src)
		local manager = TheWorld.components.darkforest_manager
		if self.spawned or manager == nil then
			return
		end
		
		local width, height = TheWorld.Map:GetSize()
		local candidates = {}
		
		for x = 0, width - 1 do
			for y = 0, height - 1 do
				local tile = TheWorld.Map:GetTile(x, y)
				
				if tile == WORLD_TILES.OCEAN_EVIL then
					for dx = -RIVER_TILE_DIST, RIVER_TILE_DIST do
						for dy = -RIVER_TILE_DIST, RIVER_TILE_DIST do
							local nx, ny = x + dx, y + dy
							
							if nx >= 0 and ny >= 0 and nx < width and ny < height then
								local n_tile = TheWorld.Map:GetTile(nx, ny)
								
								if n_tile ~= WORLD_TILES.OCEAN_EVIL and manager:IsDarkForestAtTile(nx, ny) then
									table.insert(candidates, {x = nx, y = ny})
								end
							end
						end
					end
				end
			end
		end
		
		shuffleArray(candidates)
		
		local num_clusters = math.min(#candidates, MAX_CLUSTERS)
		for i = 1, num_clusters do
			local start = candidates[i]
			SpawnGrass(start.x, start.y)
		end
		
		self.spawned = true
	end
	
	function self:OnSave()
		return {spawned = self.spawned}
	end
	
	function self:OnLoad(data)
		if data and data.spawned then
			self.spawned = true
		end
	end
	
	inst:ListenForEvent("darkforest_initialized", SpawnGrassClusters)
end)