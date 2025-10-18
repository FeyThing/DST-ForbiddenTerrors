local WIDTH, HEIGHT

return Class(function(self, inst) -- Taken from LukaS winterlands_manager, does the job perfectly
	self.inst = inst
	
	local _map = inst.Map
	local _df_grid
	
	local function InitializeDataGrids()
		if _df_grid then return end
		
		WIDTH, HEIGHT = _map:GetSize()
		_df_grid = DataGrid(WIDTH, HEIGHT)
		
		inst:RemoveEventCallback("worldmapsetsize", InitializeDataGrids)
	end
	
	inst:ListenForEvent("worldmapsetsize", InitializeDataGrids)
	
	function self:GetGrid()
		return _df_grid
	end
	
	function self:IsDarkForestAtTile(tx, ty)
		return _df_grid:GetDataAtPoint(tx, ty)
	end
	
	function self:IsDarkForestAtPoint(x, y, z)
		local tx, ty = _map:GetTileCoordsAtPoint(x, y, z)
		return _df_grid:GetDataAtPoint(tx, ty)
	end
	
	function self:Initialize()
		for x = 0, WIDTH - 1 do
			for y = 0, HEIGHT - 1 do
				local index = _df_grid:GetIndex(x, y)
				local tx, ty, tz = _map:GetTileCenterPoint(x, y)

				if IsInDarkForestAtPoint(tx, ty, tz) then
					_df_grid:SetDataAtIndex(index, true)
				end
			end
		end
		
		inst:PushEvent("darkforest_initialized", _df_grid.grid)
	end
end)