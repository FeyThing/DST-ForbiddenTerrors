local assets = {
    Asset("ANIM", "anim/df_shadowseacreature.zip"),
}

local prefabs = {
    "shadow_teleport_in",
    "shadow_teleport_out",
    "nightmarefuel",
}

local sounds = {
    attack = "dontstarve/sanity/creature1/attack",
    attack_grunt = "dontstarve/sanity/creature1/attack_grunt",
    death = "dontstarve/sanity/creature1/die",
    idle = "dontstarve/sanity/creature1/idle",
    taunt = "dontstarve/sanity/creature1/taunt",
    appear = "dontstarve/sanity/creature1/appear",
    disappear = "dontstarve/sanity/creature1/dissappear",
}

local brain = require("brains/shadowcreaturebrain")

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

    if target1 ~= nil and rangesq1 <= math.max(rangesq2, maxrangesq * .25) then
        --Targets with shadow dominance have higher priority within half targeting range
        --Force target switch if current target does not have shadow dominance
        return target1, not inst.components.shadowsubmissive:TargetHasDominance(inst.components.combat.target)
    end
    return target2
end

local function onkilledbyother(inst, attacker)
    if attacker and attacker.components.sanity then
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
end

local function OnDeath(inst, data)
    if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("crazy") then
        --max one nightmarefuel if killed by a crazy NPC (e.g. Bernie)
        inst.components.lootdropper:SetLoot({ "nightmarefuel" })
        inst.components.lootdropper:SetChanceLootTable(nil)
    end
end

local function ExchangeWithShadowCreature(inst)
    if inst.components.combat.target then
        local target = inst.components.combat.target
        local x,y,z = target.Transform:GetWorldPosition()

        local tospawn = nil
        local sx,sy,sz = inst.Transform:GetWorldPosition()
        local radius = 0
        local theta = inst:GetAngleToPoint(Vector3(x,y,z)) * DEGREES
        if TheWorld.Map:IsVisualGroundAtPoint(x,y,z) then
            tospawn = inst.iscrawlinghorror and "crawlinghorror" or "terrorbeak"
            while not TheWorld.Map:IsVisualGroundAtPoint(sx,sy,sz) and radius < 30 do
                radius = radius + 2
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                sx = sx + offset.x
                sy = sy + offset.y
                sz = sz + offset.z
            end
        else
            tospawn = inst.iscrawlinghorror and "crawlinghorror" or "oceanhorror"
            while TheWorld.Map:IsVisualGroundAtPoint(sx,sy,sz) and radius < 30 do
                radius = radius + 2
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                sx = sx + offset.x
                sy = sy + offset.y
                sz = sz + offset.z
            end
        end

        if radius >= 30 then
            return nil
        else
            local shadow = SpawnPrefab(tospawn)
            shadow.components.health:SetPercent(inst.components.health:GetPercent())
            shadow.Transform:SetPosition(sx,sy,sz)
            shadow.sg:GoToState("appear")
            shadow.components.combat:SetTarget(target)
            TheWorld:PushEvent("ms_exchangeshadowcreature", {ent = inst, exchangedent = shadow})
            local fx = SpawnPrefab("shadow_teleport_in")
            fx.Transform:SetPosition(sx,sy,sz)
        end
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

local function SetCrawlingHorror(inst)
    inst.iscrawlinghorror = true -- no need to save as persists = false
    -- inst.Transform:SetScale(0.9, 0.9, 0.9)
    -- inst.Physics:SetCapsule(inst.Physics:GetRadius() * 0.9, 1)
end

local function fn()
    -- NOTE (HALF): Use the IA swimming horror if possible
    if Prefabs["swimminghorror"] then
        return Prefabs["swimminghorror"].fn()
    end

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, 1.5)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)

    inst.Transform:SetSixFaced()

    inst:AddTag("shadowcreature")
    inst:AddTag("gestaltnoloot")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadow_aligned")

    --shadowsubmissive (from shadowsubmissive component) added to pristine state for optimization
    inst:AddTag("shadowsubmissive")

    inst.AnimState:SetBank("df_shadowseacreature")
    inst.AnimState:SetBuild("df_shadowseacreature")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1, 1, 1, .5)

    inst.scrapbook_bank = "df_shadowseacreature"

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

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED
    inst.components.locomotor.pathcaps = { allowocean = true, ignoreLand = true }

    inst.sounds = sounds
    inst:SetStateGraph("SGdf_oceanshadowcreature")

    inst:SetBrain(brain)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CRAWLINGHORROR_HEALTH)
    inst.components.health.nofadeout = true

    inst.sanityreward = TUNING.SANITY_MED

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.CRAWLINGHORROR_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.CRAWLINGHORROR_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat.onkilledbyother = onkilledbyother

    inst:AddComponent("shadowsubmissive")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ocean_shadow_creature") -- its the same but change it for consistancy

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
    inst:ListenForEvent("death", OnDeath)

    inst.ExchangeWithShadowCreature = ExchangeWithShadowCreature
    inst.followtoland = true

    inst.SetCrawlingHorror = SetCrawlingHorror

    inst.persists = false

    return inst
end

return Prefab("df_swimminghorror", fn, assets, prefabs)
