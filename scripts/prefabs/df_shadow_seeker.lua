local assets = {
    Asset("ANIM", "anim/df_shadow_seeker.zip"),
}

local prefabs = {
	
}

local brain = require("brains/df_shadowseekerbrain")

local MAX_ALPHA = 1.0

local function SetHider(inst, hider)
    -- Lets play a game of hide and seek :)))))))))))))))))))))))))))))))
    inst.hider = hider
    inst.components.combat:EngageTarget(hider)
    inst:PushEvent("startseeking")
end

local function SetAlpha(inst, alpha)
	inst.AnimState:OverrideMultColour(1, 1, 1, alpha)
	if inst.SoundEmitter ~= nil then
		inst.SoundEmitter:OverrideVolumeMultiplier(alpha / MAX_ALPHA)
	end
    inst._alpha = alpha
end

local function CalculateTargetAlpha(inst)
	local player = ThePlayer
	if player == nil then
		return 0
	end

	local combat = inst.replica.combat
	if combat ~= nil and combat:GetTarget() == player then
		return MAX_ALPHA
	end

    return 0
end

-- NOTE (HALF): Because net events are broken af with net entities -_-
local function UpdateHider(inst)
    if TheWorld.ismastersim then
        local combat = inst.components.combat
        local target = combat ~= nil and combat.target or nil
        if target ~= inst.hider then
            inst.components.combat:EngageTarget(inst.hider)
            target = inst.hider
        end
        if inst.hider == nil or not inst.hider:IsValid() then
            inst:PushEvent("stopseeking")
            return
        end
    end

    local alpha = CalculateTargetAlpha(inst)
    if inst._alpha ~= alpha then
       SetAlpha(inst, alpha)
       inst._alpha = alpha
    end
end

local function ForceUpdateAlpha(inst)
    inst._alpha = nil
end

local function OnNewTarget(inst, data)
	print("OnNewTarget", data.target, data.oldtarget)
	if data then
		if data.oldtarget then
			inst:RemoveEventCallback("df_onhide", inst.on_hider_hide, data.oldtarget)
		end
		if data.target then
			inst:ListenForEvent("df_onhide", inst.on_hider_hide, data.target)
		end
	end
end

local function OnTimerOver(inst, data)
	if data.name == "peek_in_hidingspot" then
		inst.wants_to_peek = true
		inst.components.timer:StartTimer("peek_in_hidingspot", 1 + math.random() * 9)
	end
end

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    inst.Transform:SetTwoFaced()
	
    inst:AddTag("shadowcreature")
    inst:AddTag("gestaltnoloot")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadow_aligned")
    inst:AddTag("NOBLOCK")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("largecreature")
	
    MakeCharacterPhysics(inst, 10, 1.5)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)
	
    inst.AnimState:SetBank("df_shadow_seeker")
    inst.AnimState:SetBuild("df_shadow_seeker")
    inst.AnimState:PlayAnimation("idle_loop", true)
	
    SetAlpha(inst, 0)
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(UpdateHider)
	
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 8
    inst.components.locomotor.runspeed = 10
    inst.components.locomotor.pathcaps = { allowocean = true }
	
	inst:SetStateGraph("SGdf_shadow_seeker")
    inst:SetBrain(brain)
	
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(64)
    inst.components.combat:SetAttackPeriod(2)
	
	inst:AddComponent("timer")
	inst.components.timer:StartTimer("peek_in_hidingspot", 4 + math.random(3))
    
    inst.SetHider = SetHider
    inst.OnEntityWake = ForceUpdateAlpha
    inst.OnEntitySleep = ForceUpdateAlpha
	
    inst.persists = false
	inst.on_hider_hide = function(guy, data)
		local dist = guy and guy:GetDistanceSqToInst(inst) or 90
		
		if dist < 90 then
			inst.wants_to_peek = true
			inst.peek_target = data.hidingspot
		end
	end
	
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("timerdone", OnTimerOver)
	
    return inst
end

return Prefab("df_shadow_seeker", fn, assets, prefabs)