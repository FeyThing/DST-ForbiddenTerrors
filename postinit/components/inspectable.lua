local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local Inspectable = require("components/inspectable")
	
	local OldGetDescription = Inspectable.GetDescription
	function Inspectable:GetDescription(viewer, ...)
		if HiddenInDarkForestFog(self.inst, viewer) then
			return subfmt(GetString(viewer, "DESCRIBE_HIDDEN_IN_DF_FOG"), {name = tostring(self.inst:GetBasicDisplayName())})
		end
		
		return OldGetDescription(self, viewer, ...)
	end