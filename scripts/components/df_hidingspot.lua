local function oncanhide(self)
	self.inst:AddOrRemoveTag("df_canhide", self.canhide)
end

local DF_HidingSpot = Class(function(self, inst)
	self.inst = inst
	
	self.canhide = true
	self.occupier = nil
end,
nil,
{
	canhide = oncanhide,
})

function DF_HidingSpot:OnRemoveFromEntity()
	self:Unhide()
	self.inst:RemoveTag("df_canhide")
end

function DF_HidingSpot:OnRemoveEntity()
	self:Unhide()
end

function DF_HidingSpot:SetCanHide(canhide)
	self.canhide = canhide
	
	if not canhide then
		self:Unhide(true)
	end
end

function DF_HidingSpot:IsOccupied()
	return self.occupier ~= nil
end

function DF_HidingSpot:Hide(doer)
	if self:IsOccupied() then
		if self.occupier == doer then
			return false
		else
			return false, "OCCUPIED"
		end
	end
	
	self.occupier = doer
	doer:PushEvent("df_onhide", {hidingspot = self.inst})
	doer:AddTag("df_hiding")
	doer.sg:GoToState("df_hide", self.inst)
	
	if self.onhide ~= nil then
		self.onhide(self.inst, doer)
	end
	
	return true
end

function DF_HidingSpot:Unhide(surprise)
	if self.occupier ~= nil then
		self.occupier:RemoveTag("df_hiding")
		self.occupier:PushEvent("df_onunhide", {hidingspot = self.inst})
		
		if surprise and self.occupier.sg then
			self.occupier.sg:GoToState("wakeup")
		end
		
		self.occupier = nil
		
		if self.onunhide ~= nil then
			self.onunhide(self.inst)
		end
	end
end

return DF_HidingSpot