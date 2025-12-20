require("stategraphs/commonstates")

local events = {
	EventHandler("attacked", function(inst)
		if not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("noattack") or inst.components.health:IsDead()) then
			inst.sg:GoToState("hit")
		end
	end),
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}

local function onattackreflected(inst)
	inst.sg.statemem.attackreflected = true
end

local function OnAnimOverRemoveAfterSounds(inst)
    if inst.sg.mem.soundcache == nil or next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    else
        inst:Hide()
        inst.sg.statemem.readytoremove = true
    end
end

local function TryDropTarget(inst)
	if inst.ShouldKeepTarget then --nightmarecreatures don't drop target
		local target = inst.components.combat.target
		if target and not inst:ShouldKeepTarget(target) then
			inst.components.combat:DropTarget()
			return true
		end
	end
end

local function TryDespawn(inst)
	if inst.sg.mem.forcedespawn or (inst.wantstodespawn and not inst.components.combat:HasTarget()) then
		inst.sg:GoToState("disappear")
		return true
	end
end

local function TeleportAround(inst)
	local x0, y0, z0 = inst.Transform:GetWorldPosition()
	for k = 1, 4 --[[# of attempts]] do
		local x = x0 + math.random() * 20 - 10
		local z = z0 + math.random() * 20 - 10
		if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
			inst.Physics:Teleport(x, 0, z)
			break
		end
	end
end

local function TeleportToTarget(inst, target)
	local x, y, z = inst.Transform:GetWorldPosition()
	local distance = math.sqrt(inst:GetDistanceSqToInst(target))
	local distanceoffset = 1
	local angleoffset = 30
	local radius = GetRandomWithVariance(distance, distanceoffset)
	for i = 1,4 do
		local angle = (180 - GetRandomWithVariance(0, angleoffset) - target:GetAngleToPoint(x,0,z)) * DEGREES
		local x2 = x + radius * math.cos(angle)
		local z2 = z + radius * math.sin(angle)
		if TheWorld.Map:IsPassableAtPoint(x2, 0, z2) then
			inst.Physics:Teleport(x2, 0, z2)
			break
		end
	end
end

local function Relocate(inst)
	local target = inst.components.combat.target
	if inst.sg.mem.scytheready and target ~= nil and target:IsValid() then
		TeleportToTarget(inst, target)
		inst.sg:GoToState("stealth_pre")
	else
		TeleportAround(inst)
		inst.sg.mem.scytheready = nil
		inst.sg:GoToState("appear")
	end
end

local states = {
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst)
			local dropped = TryDropTarget(inst)
			if TryDespawn(inst) then
				return
			elseif dropped then
				inst.sg:GoToState("idle") -- to-do had to change this from "taunt", figure out what to do for scyther
				return
			end
			if inst.components.combat:HasTarget() and not inst.sg.mem.scytheready then
				inst.sg.statemem.scything = true
				inst.AnimState:PlayAnimation("scythe")
			else
				inst.AnimState:PlayAnimation(inst.sg.mem.scytheready and "idle_scythe" or "idle", true)
			end
		end,
		
		timeline = {
			TimeEvent(21*FRAMES, function(inst)
				if inst.sg.statemem.scything then
					inst.sg.mem.scytheready = true
				end
			end),
		},
		
		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if inst.components.combat:HasTarget() and inst.sg.mem.scytheready then
						inst.sg:GoToState("hide")
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
		},
	},
	
	State{
		name = "hide",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hide")
		end,
		
        timeline =
        {
			TimeEvent(28*FRAMES, function(inst)
				inst.sg:AddStateTag("noattack")
			end),
        },

		events =
		{
			EventHandler("animover", function(inst)
				Relocate(inst)
			end),
		},
	},
	
	State{
		name = "stealth_pre",
		tags = { "busy", "noattack" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("stealth_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("stealth")
			end),
		},
	},
	
	State{
		name = "stealth",
		tags = { "noattack", "df_canattack" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("stealth_loop", true)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.components.combat:TryAttack() then
					inst.sg:GoToState("atk_stealth_pre")
				else
					inst.sg:GoToState("stealth")
				end
			end),
		},
	},
	
    State{
        name = "atk_stealth_pre",
        tags = { "attack", "busy" },

        onenter = function(inst)
			inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_stealth_pre")
        end,

        timeline =
        {
            TimeEvent(40*FRAMES, function(inst) --[[PlayExtendedSound(inst, "attack") -- to-do sounds and adjust frames]] end),
			TimeEvent(42*FRAMES, function(inst)
				--The stategraph event handler is delayed, so it won't be
				--accurate for detecting attacks due to damage reflection
				inst:ListenForEvent("attacked", onattackreflected)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst:RemoveEventCallback("attacked", onattackreflected)
			end),
			TimeEvent(43*FRAMES, function(inst)
				if inst.sg.statemem.attackreflected and not inst.components.health:IsDead() then
					inst.sg.mem.scytheready = nil
					inst.sg:GoToState("hit")
				end
			end),
        },

        events =
        {
			EventHandler("onattackother", function(inst, data)
				if data.target ~= nil and data.target:IsValid() then
					-- to-do apply debuff?
					inst.sg.mem.scytheready = nil
					inst.sg.statemem.hittarget = true
				end
			end),
            EventHandler("animover", function(inst)
				if inst.sg.statemem.hittarget then
					inst.sg:GoToState("atk_stealth_loop", inst.sg.statemem.target)
					return
				end
				
                if math.random() < .333 then
					TryDropTarget(inst)
					inst.forceretarget = true --V2C: try to keep legacy behaviour; it used SetTarget(nil) here, which would always result in a retarget
                end
                inst.sg:GoToState("atk_stealth_pst")
            end),
        },
    },
	
	State{
		name = "atk_stealth_loop",
		tags = { "busy" },
		
		onenter = function(inst)
		end,
	},
	
    State{
        name = "atk_stealth_pst",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk_stealth_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
				Relocate(inst)
            end),
        },
    },
	
	State{
		name = "hit",
		tags = { "busy", "hit" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation(inst.sg.mem.scytheready and "disappear_scythe" or "disappear")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				TeleportAround(inst)
				inst.sg:GoToState("appear")
			end),
		},
	},
	
	State{
		name = "appear",
		tags = { "busy" },

		onenter = function(inst)
			TryDropTarget(inst)
			inst.AnimState:PlayAnimation(inst.sg.mem.scytheready and "reappear_scythe" or "reappear")
			--PlayExtendedSound(inst, "appear") -- to-do sounds
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
		},
	},
	
	State{
		name = "death",
		tags = { "busy" },

		onenter = function(inst)
			--PlayExtendedSound(inst, "death") -- to-do sounds
			inst.AnimState:PlayAnimation(inst.sg.mem.scytheready and "disappear_scythe" or "disappear")
			RemovePhysicsColliders(inst)
			inst.components.lootdropper:DropLoot(inst:GetPosition())
			inst:AddTag("NOCLICK")
			inst.persists = false
		end,

		events =
		{
			EventHandler("animover", OnAnimOverRemoveAfterSounds),
		},

		onexit = function(inst)
			inst:RemoveTag("NOCLICK")
		end,
	},
	
	State{
		name = "disappear",
		tags = { "busy", "noattack" },

		onenter = function(inst)
			--PlayExtendedSound(inst, "death") -- to-do sounds
			inst.AnimState:PlayAnimation(inst.sg.mem.scytheready and "disappear_scythe" or "disappear")
			inst:AddTag("NOCLICK")
			inst.persists = false
		end,

		events =
		{
			EventHandler("animover", OnAnimOverRemoveAfterSounds),
		},

		onexit = function(inst)
			inst:RemoveTag("NOCLICK")
		end,
	},
}

return StateGraph("df_scyther", states, events, "appear")