return Class(function(self, inst) -- Adapted from Winterlands blizzard cycle. Too tired to be original atm.
	assert(TheWorld.ismastersim, "DF Fog Cycle should only exist on the server")
	
	self.inst = inst
	
	local active = false
	local _fog_cd_task
	local _fog_duration_task
	
	local function StartFog()
		if active then
			return
		end
		
		active = true
		
		TheWorld:AddTag("df_fog_ongoing")
		for i, v in ipairs(AllPlayers) do
			v:AddTag("df_fog_ongoing")
		end
	end
	
	local function StopFog()
		if not active then
			return
		end
		
		active = false
		
		TheWorld:RemoveTag("df_fog_ongoing")
		for i, v in ipairs(AllPlayers) do
			v:RemoveTag("df_fog_ongoing")
		end
	end
	
	local function ScheduleNextFog(cooldown)
		if _fog_cd_task then
			_fog_cd_task:Cancel()
			_fog_cd_task = nil
		end
		if _fog_duration_task then
			_fog_duration_task:Cancel()
			_fog_duration_task = nil
			StopFog()
		end
		
		local cd = cooldown or math.random(TUNING.DF_FOG_COOLDOWNS.min, TUNING.DF_FOG_COOLDOWNS.max)
		
		local function OnFogStart()
			_fog_cd_task = nil
			StartFog()
			
			local duration = math.random(TUNING.DF_FOG_DURATIONS.min, TUNING.DF_FOG_DURATIONS.max)
			
			local function OnFogEnd()
				_fog_duration_task = nil
				StopFog()
				ScheduleNextFog()
			end
			
			_fog_duration_task = inst:DoTaskInTime(duration, OnFogEnd)
			_fog_duration_task._fn = OnFogEnd
		end
		
		_fog_cd_task = inst:DoTaskInTime(cd, OnFogStart)
		_fog_cd_task._fn = OnFogStart
	end
	
	function self:IsFogActive()
		return active
	end
	
	function self:OnSave()
		local data = {}
		
		if _fog_duration_task then
			data.fog_duration_left = GetTaskRemaining(_fog_duration_task)
		elseif _fog_cd_task then
			data.fog_cd_left = GetTaskRemaining(_fog_cd_task)
		end
		data.fog_active = active
		
		return data
	end
	
	function self:OnLoad(data)
		if data then
			if data.fog_duration_left then
				StartFog()
				
				_fog_duration_task = inst:DoTaskInTime(data.fog_duration_left, function()
					_fog_duration_task = nil
					StopFog()
					ScheduleNextFog()
				end)
				_fog_duration_task._fn = _fog_duration_task.fn
			elseif data.fog_cd_left then
				ScheduleNextFog(data.fog_cd_left)
			else
				ScheduleNextFog()
			end
		else
			ScheduleNextFog()
		end
	end
	
	function self:LongUpdate(dt)
		if _fog_cd_task then
			_fog_cd_task:Cancel()
			_fog_cd_task = inst:DoTaskInTime(math.max(0, GetTaskRemaining(_fog_cd_task) - dt), _fog_cd_task._fn)
		elseif _fog_duration_task then
			_fog_duration_task:Cancel()
			_fog_duration_task = inst:DoTaskInTime(math.max(0, GetTaskRemaining(_fog_duration_task) - dt), _fog_duration_task._fn)
		end
	end
	
	ScheduleNextFog()
end)