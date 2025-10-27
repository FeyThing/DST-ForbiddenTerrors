local assets = {
    Asset("ANIM", "anim/df_shadow_seeker.zip"),
}

local prefabs = {
	
}

local brain = require("brains/df_shadowseekerbrain")

local function retargetfn(inst)
    local maxrangesq = TUNING.SHADOWCREATURE_TARGET_DIST * TUNING.SHADOWCREATURE_TARGET_DIST
    local rangesq, rangesq1, rangesq2 = maxrangesq, math.huge, math.huge
    local target1, target2 = nil, nil
    for i, v in ipairs(AllPlayers) do
        if not v:HasTag("playerghost") then
            local distsq = v:GetDistanceSqToInst(inst)
            if distsq < rangesq2 and inst.components.combat:CanTarget(v) then
                    target2 = v
                    rangesq2 = distsq
                    rangesq = math.max(rangesq1, rangesq2)               
            end
        end
    end

	local forcechange = inst.forceretarget
	inst.forceretarget = nil

    if target1 ~= nil and rangesq1 <= math.max(rangesq2, maxrangesq * .25) then
        --Targets with shadow dominance have higher priority within half targeting range
        --Force target switch if current target does not have shadow dominance
        return target1
    end
	return target2, forcechange
end

--- This is taken from the shadow creatures, Ichor buildup needs to replace the sanity conditions. So I'm commenting it out for now.

--[[local function keeptargetfn(inst, target)
	if inst.sg.mem.forcedespawn then
		return true
	elseif target.components.sanity == nil then
		--not player; could be bernie or other creature
		if inst.wantstodespawn then
			--don't deaggro, so you can actually see the despawn
			inst.sg.mem.forcedespawn = true
		end
		return true
	elseif target.components.sanity:IsCrazy() then
		inst._deaggrotime = nil
		return true
	end

	--start deaggro timer when target is becomes sane
	local t = GetTime()
	if inst._deaggrotime == nil then
		inst._deaggrotime = t
		return true
	end

	--V2C: NOTE: -combat cmp sets lastwasattackedbytargettime when retargeting also
	--           -so it may use the longer delay sometimes even when not attacked
	--           -this is fine XD
	--
	--Deaggro if target has been sane for 2.5s, hasn't hit us in 6s, and hasn't tried to attack us for 5s
	if inst._deaggrotime + 2.5 >= t or
		inst.components.combat.lastwasattackedbytargettime + 6 >= t or
		(	target.components.combat and
			target.components.combat:IsRecentTarget(inst) and
			(target.components.combat.laststartattacktime or 0) + 5 >= t
		)
	then
		return true
	elseif inst.wantstodespawn then
		--don't deaggro, so you can actually see the despawn
		inst.sg.mem.forcedespawn = true
		return true
	end
	return false
end]]

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
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


    MakeInventoryPhysics(inst)
	
    inst.AnimState:SetBank("df_shadow_seeker")
    inst.AnimState:SetBuild("df_shadow_seeker")
    inst.AnimState:PlayAnimation("idle_loop", true)

	
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
	inst:SetStateGraph("SGdf_shadow_seeker")
    inst:SetBrain(brain)
    ----------

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 7
    inst.components.locomotor.runspeed = 9
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(64)
        inst.components.combat:SetAttackPeriod(2)
        inst.components.combat:SetRetargetFunction(3, retargetfn)
		--inst.ShouldKeepTarget = keeptargetfn 
	
    return inst
end

return Prefab("df_shadow_seeker", fn, assets, prefabs)