local DF_Pan = Class(function(self, inst)
	self.inst = inst
end)

local FLOATSAM_TAGS = {"oceanfishinghookable", "oceanfishable"}
local FLOATSAM_NOT_TAGS = {"oceanfish", "INLIMBO"}

function DF_Pan:PanAt(pos, doer)
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, 3, FLOATSAM_TAGS, FLOATSAM_NOT_TAGS)
	
	for i, v in ipairs(ents) do
		v:PushEvent("df_panned", {doer = doer, pan = self.inst, pos = pos})
	end
	
	local used = #ents > 0
	if used and self.inst.components.finiteuses then
		self.inst.components.finiteuses:Use(1)
	end
	
	return used
end

return DF_Pan