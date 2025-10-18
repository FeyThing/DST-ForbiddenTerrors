local DFENV = env
GLOBAL.setfenv(1, GLOBAL)

local Moisture = require("components/moisture")

	local OldGetMoistureRate = Moisture.GetMoistureRate
	function Moisture:GetMoistureRate(...)
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
		
		local indarkforest = GetClosestDarkForestTileToPoint(x, 0, z, 12) ~= nil
		local intile = DF_OCEAN_TILES[tile] and not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and TheWorld.Map:GetPlatformAtPoint(x, z) == nil
			and (self.inst.components.rider == nil or not self.inst.components.rider:IsRiding())
		
		local rate = OldGetMoistureRate(self, ...)
		
		local notfog, inlight = TheWorld.Map:IsDarkForestFogBlocked(x, y, z)
		if indarkforest and self.inst:HasTag("df_fog_ongoing") and not inlight and (self.inst.sg and self.inst.sg:HasStateTag("moving")) then
			rate = (rate + TUNING.DF_FOG_MOISTURE_DT) * (1 - self:GetWaterproofness())
		end
		
		if intile then
			local waterproofmult = self.inherentWaterproofness or 0
			local coat = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
			
			if coat and coat.components.waterproofer then
				waterproofmult = waterproofmult + coat.components.waterproofer:GetEffectiveness()
			end
			
			local tile_rate = 1 - (waterproofmult * TUNING.DF_WATERPROOFNESS_MULT)
			rate = rate + tile_rate
		end
		
		return rate
	end