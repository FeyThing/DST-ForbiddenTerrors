return Class(function(self, inst)
	self.inst = inst
	
	self.enabled = false
	self.enablers = {}
	
	self.lines = 40
	self.rows = 40
	self.spacing_x = TILE_SCALE / 2
	self.spacing_y = TILE_SCALE / 2
	
	self.fog_positions = {}
	self.last_tile = {}
	
	local _player = nil
	
	local batch_index = 1
	local batch_total = 0
	local BATCH_MAX_FOG = 100
	
	local function OnFogBlockRangeDirty(src, data)
		self.blocker_update = true
	end
	
	local function OnInDarkForest(inst, enable)
		self.in_fog = enable
		
		if not _player then
			return
		end
		
		local x, y, z = _player.Transform:GetWorldPosition()
		local gotenablers = not IsTableEmpty(self.enablers)
		
		if (self.in_fog or gotenablers) and not self.enabled then
			self:Enable(true)
		elseif not self.in_fog and self.enabled and not gotenablers then
			self:Enable(false)
		end
	end
	
	--
	
	function self:GetFogPosition(row, line, x, y, z)
		local row_x = -((self.lines - 1) * self.spacing_x) / 2 + (line - 1) * self.spacing_x
		local row_z = -((self.rows - 1) * self.spacing_y) / 2 + (row - 1) * self.spacing_y
		
		return Vector3(x + row_x, 0, z + row_z)
	end
	
	function self:RemoveFog()
		for pt_str, fog in pairs(self.fog_positions) do
			if fog and fog:IsValid() then
				fog:DoFogFade(true, fog.Remove)
			end
		end
		
		self.fog_positions = {}
		self.last_tile = {}
	end
	
	function self:SetFog(entering)
		local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(TheCamera.currentpos:Get())
		local tile_x, tile_y = TheWorld.Map:GetTileCoordsAtPoint(cx, cy, cz)
		
		if self.blocker_update or tile_x ~= self.last_tile[1] or tile_y ~= self.last_tile[2] then
			batch_index = 1
			batch_total = self.rows * self.lines
			self.last_tile = {tile_x, tile_y}
			self.blocker_update = nil
		end
		
		local processed = 0
		while processed < BATCH_MAX_FOG and batch_index <= batch_total do
			local row = math.floor((batch_index - 1) / self.lines) + 1
			local line = (batch_index - 1) % self.lines + 1
			local pt = self:GetFogPosition(row, line, cx, cy, cz)
			local pt_str = string.format("%.2f_%.2f", pt.x, pt.z)
			
			local fog = self.fog_positions[pt_str]
			local in_fog, in_light = TheWorld.Map:IsDarkForestFogBlocked(pt.x, 0, pt.z)
			in_fog = not in_fog
			
			if fog == nil and in_fog then
				fog = SpawnPrefab("df_fog")
				fog.Transform:SetPosition(pt.x, pt.y, pt.z)
				self.fog_positions[pt_str] = fog
				fog:DoFogFade(nil, nil, 6)
			elseif fog and fog:IsValid() then
				if not in_fog and not fog._fading then
					fog:DoFogFade(true, nil, in_light and 0.5 or nil)
				elseif in_fog and fog._fading then
					fog:DoFogFade()
				end
			end
			
			batch_index = batch_index + 1
			processed = processed + 1
		end
	end
	
	function self:SpawnFog()
		self:RemoveFog()
		self:SetFog(true)
	end
	
	function self:IsEnabled()
		return self.enabled or not IsTableEmpty(self.enablers)
	end
	
	function self:AddEnabler(src, enabled)
		if src then
			self.enablers[src] = enabled or nil
		end
	end
	
	function self:Enable(enabled)
		self.enabled = enabled or false
		
		if self:IsEnabled() then
			self:SpawnFog()
			inst:StartUpdatingComponent(self)
			
			-- For fires that don't update the client
			self.update_internal = inst:DoPeriodicTask(1, function()
				self.blocker_update = true
			end)
			
			inst:ListenForEvent("darkforestfog_blockerupdate", OnFogBlockRangeDirty)
		elseif self.update_internal then
			self.update_internal:Cancel()
			self.update_internal = nil
			inst:RemoveEventCallback("darkforestfog_blockerupdate", OnFogBlockRangeDirty)
		end
	end
	
	function self:OnUpdate(dt)
		if not self:IsEnabled() then
			self:RemoveFog()
			inst:StopUpdatingComponent(self)
			return
		end
		
		self:SetFog()
	end
	
	--
	
	local function OnPlayerActivated(inst, player)
		if _player ~= player then
			if _player == nil then
				inst:ListenForEvent("setindarkforest", function(src, enable) OnInDarkForest(self, enable) end, player)
			end
			_player = player
		end
	end
	
	local function OnPlayerDeactivated(inst, player)
		if _player == player then
			inst:RemoveEventCallback("setindarkforest", function(src, enable) OnInDarkForest(self, enable) end, _player)
			_player = nil
		end
	end
	
	if TUNING.DF_FOG_ENABLED then
		self.blocker_update = true
		inst:ListenForEvent("playeractivated", OnPlayerActivated)
		inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
	end
end)