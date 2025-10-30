local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local ITEM_TAGS = {"_inventoryitem"}
local ITEM_NOT_TAGS = {"INLIMBO"}

local function OnPanned(inst, data)
	local landed = SpawnPrefab("oceanfishableflotsam")
	
	if landed.components.pickable then
		landed.Transform:SetPosition(data.pos.x, 0, data.pos.z)
		landed.components.pickable:Pick(data.doer)
		
		local items = TheSim:FindEntities(data.pos.x, 0, data.pos.z, 0.2, ITEM_TAGS, ITEM_NOT_TAGS)
		local inv = data.doer and data.doer.components.inventory
		
		for i, v in ipairs(items) do
			if inv and v:GetTimeAlive() < 0.1 then
				inv:GiveItem(v, nil, v:GetPosition())
			elseif v.components.inventoryitem then
				v.components.inventoryitem:DoDropPhysics(data.pos.x, 0, data.pos.z, true)
			end
		end
	else
		landed:Remove()
	end
	
	inst:Remove()
end

ENV.AddPrefabPostInit("oceanfishableflotsam_water", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	inst:ListenForEvent("df_panned", OnPanned)
end)