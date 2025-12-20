local assets = {
	Asset("ANIM", "anim/df_scyther.zip"),
}

local prefabs = {
	"nightmarefuel",
}

local function NotifyBrainOfTarget(inst, target)
	if inst.brain ~= nil and inst.brain.SetTarget ~= nil then
		inst.brain:SetTarget(target)
	end
end

local function retargetfn(inst)
	local maxrangesq = TUNING.SHADOWCREATURE_TARGET_DIST * TUNING.SHADOWCREATURE_TARGET_DIST
	local rangesq, rangesq1, rangesq2 = maxrangesq, math.huge, math.huge
	local target1, target2 = nil, nil
	for i, v in ipairs(AllPlayers) do
		if v.components.sanity:IsCrazy() and not v:HasTag("playerghost") then
			local distsq = v:GetDistanceSqToInst(inst)
			if distsq < rangesq then
				if inst.components.shadowsubmissive:TargetHasDominance(v) then
					if distsq < rangesq1 and inst.components.combat:CanTarget(v) then
						target1 = v
						rangesq1 = distsq
						rangesq = math.max(rangesq1, rangesq2)
					end
				elseif distsq < rangesq2 and inst.components.combat:CanTarget(v) then
					target2 = v
					rangesq2 = distsq
					rangesq = math.max(rangesq1, rangesq2)
				end
			end
		end
	end

	local forcechange = inst.forceretarget
	inst.forceretarget = nil

	if target1 ~= nil and rangesq1 <= math.max(rangesq2, maxrangesq * .25) then
		--Targets with shadow dominance have higher priority within half targeting range
		--Force target switch if current target does not have shadow dominance
		return target1, not inst.components.shadowsubmissive:TargetHasDominance(inst.components.combat.target)
	end
	return target2, forcechange
end

--V2C: called from SG instead of combat component
local function keeptargetfn(inst, target)
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
	--		   -so it may use the longer delay sometimes even when not attacked
	--		   -this is fine XD
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
end

local function onkilledbyother(inst, attacker)
	if attacker ~= nil and attacker.components.sanity ~= nil then
		attacker.components.sanity:DoDelta(inst.sanityreward or TUNING.SANITY_SMALL)
	end
end

local function CalcSanityAura(inst, observer)
	return inst.components.combat:HasTarget()
		and observer.components.sanity:IsCrazy()
		and -TUNING.SANITYAURA_LARGE
		or 0
end

local function ShareTargetFn(dude)
	return dude:HasTag("shadowcreature") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, 30, ShareTargetFn, 1)
end

local function OnNewCombatTarget(inst, data)
	NotifyBrainOfTarget(inst, data.target)

	--Reset deaggro delay when we change targets
	inst._deaggrotime = nil
end

local function OnDeath(inst, data)
	if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("crazy") then
		--max one nightmarefuel if killed by a crazy NPC (e.g. Bernie)
		inst.components.lootdropper:SetLoot({ "nightmarefuel" })
		inst.components.lootdropper:SetChanceLootTable(nil)
	end
end

local function CLIENT_ShadowSubmissive_HostileToPlayerTest(inst, player)
	if player:HasTag("shadowdominance") then
		return false
	end
	local combat = inst.replica.combat
	if combat ~= nil and combat:GetTarget() == player then
		return true
	end
	local sanity = player.replica.sanity
	if sanity ~= nil and sanity:IsCrazy() then
		return true
	end
	return false
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeCharacterPhysics(inst, 10, 1.5)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)
	
	inst.Transform:SetFourFaced()
	
	inst:AddTag("shadowcreature")
	inst:AddTag("gestaltnoloot")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")
	inst:AddTag("shadow_aligned")
	inst:AddTag("NOBLOCK")
	
	--shadowsubmissive (from shadowsubmissive component) added to pristine state for optimization
	inst:AddTag("shadowsubmissive")
	
	inst.AnimState:SetBank("df_scyther")
	inst.AnimState:SetBuild("df_scyther")
	inst.AnimState:PlayAnimation("idle_scythe", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)
	
	if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity:ForceUpdate()
	end
	
	inst.HostileToPlayerTest = CLIENT_ShadowSubmissive_HostileToPlayerTest
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura
	
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.DF_SCYTHER_HEALTH)
	inst.components.health.nofadeout = true
	
	inst.sanityreward = TUNING.SANITY_LARGE -- 33
	
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.DF_SCYTHER_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.DF_SCYTHER_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	--inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.ShouldKeepTarget = keeptargetfn --V2C: call from SG instead!
	inst.components.combat.onkilledbyother = onkilledbyother
	
	inst:AddComponent("shadowsubmissive")
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("shadow_creature")
	
	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	inst:ListenForEvent("death", OnDeath)
	
	inst:SetStateGraph("SGdf_scyther")
	--inst:SetBrain(brain)
	
	inst.persists = false
	
	return inst
end

return Prefab("df_scyther", fn, assets, prefabs)