local function GenerateAndSpawnEvilTreeShadePositions(inst)
	local self = inst.components.eviltreeshade
	if self == nil then
		return
	end
	
	self:GenerateEvilTreeShadePositions()
	self:SpawnShadows()
end

local EvilTreeShade = Class(function(self, inst)
	self.inst = inst
	
	self.range = math.floor(TUNING.SHADE_CANOPY_RANGE / 4)
	
	self.EvilTreeShade_positions = {}
	self.spawned = false
	
	inst:DoTaskInTime(0, GenerateAndSpawnEvilTreeShadePositions)
end)

function EvilTreeShade:OnRemoveEntity()
	self:DespawnShadows(true)
	self:RemoveEvilTreeShadePositions()
end

EvilTreeShade.OnRemoveFromEntity = EvilTreeShade.OnRemoveEntity

Global_EvilTreeShade = {}
local EvilTreeShades = Global_EvilTreeShade

function EvilTreeShade:GenerateEvilTreeShadePositions()
	local x, y, z = self.inst.Transform:GetWorldPosition()
	
	for i = -self.range, self.range do
		for t = -self.range, self.range do
			if math.random() < 0.8 and ((t * t) + (i * i)) <= self.range * self.range then
				local newx = math.floor((x + i * 4) / 4) * 4 + 2
				local newz = math.floor((z + t * 4) / 4) * 4 + 2
				
				local shadetile_key = newx.."-"..newz
				local shadetile = EvilTreeShades[shadetile_key]
				
				if not shadetile then
					table.insert(self.EvilTreeShade_positions, {newx, newz})
					EvilTreeShades[shadetile_key] = {refs = 1, spawnrefs = 0}
				else
					shadetile.refs = shadetile.refs + 1
				end
			end
		end
	end
end

function EvilTreeShade:RemoveEvilTreeShadePositions()
	for i, v in ipairs(self.EvilTreeShade_positions) do
		local x, z = v[1], v[2]
		
		local shadetile_key = x.."-"..z
		local shadetile = EvilTreeShades[shadetile_key]
		
		shadetile.refs = shadetile.refs - 1
		if shadetile.refs == 0 then
			EvilTreeShades[shadetile_key] = nil
		end
	end
end

function EvilTreeShade:OnEntitySleep()
	if not IsTableEmpty(self.EvilTreeShade_positions) then
		self:DespawnShadows()
	end
end

function EvilTreeShade:OnEntityWake()
	if not IsTableEmpty(self.EvilTreeShade_positions) then
		self:SpawnShadows()
	end
end

function EvilTreeShade:SpawnShadows()
	if self.spawned or not self.inst.entity:IsAwake() then
		return
	end
	
	for i, v in ipairs(self.EvilTreeShade_positions) do
		local x, z = v[1], v[2]
		local shadetile = EvilTreeShades[x.."-"..z]
		
		shadetile.spawnrefs = shadetile.spawnrefs + 1
		if shadetile.spawnrefs == 1 then
			shadetile.id = SpawnEvilTreeShade(x, z)
		end
	end
	
	self.spawned = true
end

function EvilTreeShade:DespawnShadows(ignore_entity_sleep)
	if not self.spawned or (not ignore_entity_sleep and self.inst.entity:IsAwake()) then
		return
	end
	
	for i, v in ipairs(self.EvilTreeShade_positions) do
		local x, z = v[1], v[2]
		local shadetile = EvilTreeShades[x.."-"..z]
		
		shadetile.spawnrefs = shadetile.spawnrefs - 1
		if shadetile.spawnrefs == 0 then
			DespawnEvilTreeShade(shadetile.id)
			shadetile.id = nil
		end
	end
	
	self.spawned = false
end

return EvilTreeShade