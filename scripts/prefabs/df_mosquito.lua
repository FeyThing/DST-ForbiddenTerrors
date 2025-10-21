local assets =
{
    Asset("ANIM", "anim/df_mosquito.zip"),
}

local prefabs =
{
    "mosquitosack"
}

local brain = require("brains/df_mosquitobrain")

local sounds =
{
    takeoff = "dontstarve/creatures/mosquito/mosquito_takeoff",
    attack = "dontstarve/creatures/mosquito/mosquito_attack",
    buzz = "dontstarve/creatures/mosquito/mosquito_fly_LP",
    hit = "dontstarve/creatures/mosquito/mosquito_hurt",
    death = "dontstarve/creatures/mosquito/mosquito_death",
    explode = "dontstarve/creatures/mosquito/mosquito_explo",
}

SetSharedLootTable("mosquito",
{
    {"mosquitosack", .5},
})

local SHARE_TARGET_DIST = 30
local MAX_TARGET_SHARES = 10

local function StartBuzz(inst)
    if not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function StopBuzz(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local function StoreHomePos(inst, allow_overwrite)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition(), not allow_overwrite)
end

local function IsMosquitoMusk(item)
    return item:HasTag("mosquitomusk")
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "insect", "INLIMBO" }
local RETARGET_ONEOF_TAGS = { "character", "animal", "monster" }

local function KillerRetarget(inst)
    local leader = inst.components.follower ~= nil and inst.components.follower:GetLeader() or nil
    
    return FindEntity(inst, SpringCombatMod(20),
        function(guy)
            local has_musk = guy.components.inventory ~= nil and guy.components.inventory:FindItem(IsMosquitoMusk)
            local is_ally = inst.components.combat:IsAlly(guy) or (leader ~= nil and leader.components.combat:IsAlly(guy))

            return not has_musk and not is_ally and inst.components.combat:CanTarget(guy)
        end,
        RETARGET_MUST_TAGS,
        RETARGET_CANT_TAGS,
        RETARGET_ONEOF_TAGS
    )
end

local function SwapBelly(inst, size)
    for i = 1, 3 do
        if i == size then
            inst.AnimState:Show("body_"..tostring(i))
        else
            inst.AnimState:Hide("body_"..tostring(i))
        end
    end
end

local function TakeDrink(inst, data)
    inst.drinks = inst.drinks + 1

    if inst.drinks > inst.maxdrinks then
        inst.toofat = true
        inst.components.health:Kill()
    else
        SwapBelly(inst, inst.drinks)
    end
end

local function ShareTargetFn(dude)
    return dude:HasTag("mosquito") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SpringCombatMod(SHARE_TARGET_DIST), ShareTargetFn, MAX_TARGET_SHARES)
end

local function OnChangedLeader(inst, new_leader, prev_leader)
    if new_leader ~= nil then
        inst.lastleader = new_leader
    end
end

local function mosquito()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeFlyingCharacterPhysics(inst, 1, 1)

    inst.DynamicShadow:SetSize(1, 1)
    inst.Transform:SetFourFaced()

    inst:AddTag("mosquito")
    inst:AddTag("insect")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("largecreature")


    inst.AnimState:SetBank("df_mosquito")
    inst.AnimState:SetBuild("df_mosquito")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetBrain(brain)

    ----------

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.MOSQUITO_WALKSPEED
    inst.components.locomotor.runspeed = TUNING.MOSQUITO_RUNSPEED
    inst.components.locomotor.pathcaps = { allowocean = true }
    inst:SetStateGraph("SGdf_mosquito")

    inst.sounds = sounds

    inst.OnEntityWake = StartBuzz
    inst.OnEntitySleep = StopBuzz

    ---------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("mosquito")

    inst:AddComponent("tradable")

     ------------------

    MakeLargeBurnableCharacter(inst, "body", Vector3(0, -1, 1))
    MakeLargeFreezableCharacter(inst, "body", Vector3(0, -1, 1))


    ------------------
    inst:AddComponent("follower")
    inst.components.follower.OnChangedLeader = OnChangedLeader
    
    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DF_MOSQUITO_HEALTH)

    ------------------
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetDefaultDamage(TUNING.DF_MOSQUITO_DAMAGE)
    inst.components.combat:SetRange(TUNING.DF_MOSQUITO_ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.DF_MOSQUITO_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, KillerRetarget)
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)

    inst.drinks = 1
    inst.maxdrinks = TUNING.DF_MOSQUITO_MAX_DRINKS
    inst:ListenForEvent("onattackother", TakeDrink)
    SwapBelly(inst, 1)
    inst.scrapbook_hide = {"body_2", "body_3"}

    MakeHauntablePanic(inst)

    ------------------
    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true

    ------------------
    inst:AddComponent("knownlocations")

    ------------------
    inst:AddComponent("inspectable")

    inst:ListenForEvent("attacked", OnAttacked)

    inst.incineratesound = inst.sounds.death

    return inst
end

return Prefab("df_mosquito", mosquito, assets, prefabs)
