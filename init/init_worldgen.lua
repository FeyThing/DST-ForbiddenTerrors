local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local AddLevelPreInitAny = ENV.AddLevelPreInitAny
local AddTaskSetPreInitAny = ENV.AddTaskSetPreInitAny
local AddRoomPreInit = ENV.AddRoomPreInit
local AddTaskPreInit = ENV.AddTaskPreInit
local GetModConfigData = ENV.GetModConfigData

local tasks = require("map/tasks/evilforest")

local evilforest_tasks = {"Evil Forest", "Evil Land"}

AddTaskSetPreInitAny(function(tasksetdata)
   	if tasksetdata.location == "forest" and tasksetdata.tasks and #tasksetdata.tasks > 1 then
		for i, setpieces in ipairs(evilforest_tasks) do
			table.insert(tasksetdata.tasks, setpieces)
		end	
   	end
end)

--	Rivergen

-- Keep up to date for each natural tiles in the dark forest
local DF_TILES_GENERATED = {WORLD_TILES.EVILFOREST, WORLD_TILES.EVILMUDDY, WORLD_TILES.EVILFOREST_WATER_CONVERT, WORLD_TILES.FOREST}
local DF_WATERSETTINGS = TUNING.DF_WATERSETTINGS

local function GetEdgePoint(points_x, points_y, edge, min_x, max_x, min_y, max_y)
	local candidates = {}
	
	for i = 1, #points_x do
		local x, y = points_x[i], points_y[i]
		
		if (edge == "left" and x <= min_x + 2) or
		   (edge == "right" and x >= max_x - 2) or
		   (edge == "top" and y >= max_y - 2) or
		   (edge == "bottom" and y <= min_y + 2) then
		   
			table.insert(candidates, {x = x, y = y})
		end
	end
	
	return #candidates > 0 and candidates[math.random(#candidates)] or nil
end

local function GenerateRiverPath(start, finish, length, step, jitter)
	local path = {}
	
	local x, y = start.x, start.y
	local dir_x, dir_y = finish.x - x, finish.y - y
	
	local dist = math.sqrt(dir_x ^ 2 + dir_y ^ 2)
	if dist == 0 then
		return path
	end
	
	dir_x, dir_y = dir_x / dist, dir_y / dist
	
	for i = 1, length do
		table.insert(path, {x = math.floor(x), y = math.floor(y)})
		
		local angle = (math.random() - 0.5) * jitter
		local s, c = math.sin(angle), math.cos(angle)
		
		local ndx = dir_x * c - dir_y * s
		local ndy = dir_x * s + dir_y * c
		dir_x, dir_y = ndx, ndy
		
		x = x + dir_x * step
		y = y + dir_y * step
	end
	
	return path
end

function Node:PopulateDarkForestRivers(width, height, df_tiles)
	if table.contains(self.data.tags, "DF_Rivers") then
		local points_x, points_y, points_type = WorldSim:GetPointsForSite(self.id)
		local min_x, max_x, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
		
		for i = 1, #points_x do
			local x, y = points_x[i], points_y[i]
			
			if table.contains(DF_TILES_GENERATED, points_type[i]) then
				if x < min_x then min_x = x end
				if x > max_x then max_x = x end
				if y < min_y then min_y = y end
				if y > max_y then max_y = y end
			end
		end
		
		local edges = {"left", "right", "top", "bottom"}
		local start_edge = edges[math.random(#edges)]
		
		local finish_edge = (start_edge == "left" and "right")
			or (start_edge == "right" and "left")
			or (start_edge == "top" and "bottom")
			or "top"
		
		local start = GetEdgePoint(points_x, points_y, start_edge, min_x, max_x, min_y, max_y)
		local finish = GetEdgePoint(points_x, points_y, finish_edge, min_x, max_x, min_y, max_y)
		
		if start and finish then
			local path = GenerateRiverPath(start, finish, DF_WATERSETTINGS.LENGTH, DF_WATERSETTINGS.STEPS, DF_WATERSETTINGS.JITTER)
			
			for i, p in ipairs(path) do
				local radius = math.random(DF_WATERSETTINGS.WIDENESS_MIN, DF_WATERSETTINGS.WIDENESS_MAX)
				
				for dx = -radius, radius do
					for dy = -radius, radius do
						if dx * dx + dy * dy <= radius * radius then
							local tx, ty = Clamp(p.x + dx, 0, width - 1), Clamp(p.y + dy, 0, height - 1)
							
							if df_tiles[tx..","..ty] then
								WorldSim:SetTile(tx, ty, WORLD_TILES.EVILFOREST_WATER_CONVERT)
								WorldSim:ReserveTile(tx, ty)
							end
						end
					end
				end
			end
		end
	end
end

local _GlobalPrePopulate = Graph.GlobalPrePopulate
function Graph:GlobalPrePopulate(entities, width, height, ...)
	local nodes = self:GetNodes(true)
	local df_tiles = {}
	
	for k, node in pairs(nodes) do
		if node.data and node.data.tags and table.contains(node.data.tags, "DF_Forest") then
			local points_x, points_y, points_type = WorldSim:GetPointsForSite(node.id)
			
			for i = 1, #points_x do
				local x, y = points_x[i], points_y[i]
				
				if table.contains(DF_TILES_GENERATED, points_type[i]) then
					df_tiles[x..","..y] = true
				end
			end
		end
	end
	
	if not IsTableEmpty(df_tiles) then
		for k, node in pairs(nodes) do
			if node.data and node.data.tags and table.contains(node.data.tags, "DF_Forest") then
				node:PopulateDarkForestRivers(width, height, df_tiles)
			end
		end
	end
	
	return _GlobalPrePopulate(self, entities, width, height, ...)
end

ENV.AddSimPostInit(function()
	for x = 0, TheWorld.Map:GetSize() - 1 do
		for y = 0, TheWorld.Map:GetSize() - 1 do
			local tile = TheWorld.Map:GetTile(x, y)
			
			-- NOTE: Water tiles replace previous non-land tiles after our process, so we need a temporary "land" tile before our final river placement for it to stay
			if tile == WORLD_TILES.EVILFOREST_WATER_CONVERT then
				TheWorld.Map:SetTile(x, y, WORLD_TILES.OCEAN_EVIL)
			end
		end
	end
end)