local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local Evilcanopy = require "widgets/evilcanopy"
local DF_IchorOver = require "widgets/df_ichorover"

ENV.AddClassPostConstruct("screens/playerhud", function(self)
	local OldCreateOverlays = self.CreateOverlays

	function self:CreateOverlays(owner, ...)
        OldCreateOverlays (self, owner, ...)
		self.evilcanopy = self.overlayroot:AddChild(Evilcanopy(owner))
        self.df_ichorover = self.overlayroot:AddChild(DF_IchorOver(owner))
	end

	local OldOnUpdate = self.OnUpdate

	function self:OnUpdate(dt, ...)
        OldOnUpdate (self, dt, ...)
		if self.evilcanopy then
			self.evilcanopy:OnUpdate(dt)
		end
	end
end)