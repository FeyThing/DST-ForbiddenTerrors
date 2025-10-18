local SHADER = resolvefilepath("shaders/df_anim_waterfall.ksh")
local SHADER_CORNER = resolvefilepath("shaders/df_anim_waterfall_corner.ksh")

local BUILDBANK = "waterfall_oceanevil"
local BUILDBANK_CORNER = "waterfall_oceanevil_corner"

--[[
    TODO (CLEANUP CHECK)
    Improve corner rendering (currently it has seams and shrinks/pinches together at the top)
    Make sure shading is accurate (I think it is a bit too transparent?)
    Maybe add an inner corner peice with better sorting???
    Cleanup the shader from ATC
]]

-- Hack to prevent z fighting
local SORT_A = -3
local SORT_B = -2

local assets =
{
    Asset("ANIM", "anim/waterfall_oceanevil.zip"),
    Asset("ANIM", "anim/waterfall_oceanevil_corner.zip"),
    Asset("SHADER", "shaders/df_anim_waterfall.ksh"),
    Asset("SHADER", "shaders/df_anim_waterfall_corner.ksh"),
}

local DIR = table.invert({
    "N",
    "S",
    "W",
    "E",
    "NW",
    "NE",
    "SW",
    "SE",
})

local DIR_TO_DATA = {
    [DIR.N] = {0 * DEGREES, BUILDBANK, SHADER, SORT_A},
    [DIR.S] = {-180 * DEGREES, BUILDBANK, SHADER, SORT_B},
    [DIR.W] = {-90 * DEGREES, BUILDBANK, SHADER, SORT_A},
    [DIR.E] = {-270 * DEGREES, BUILDBANK, SHADER, SORT_B},
    [DIR.NW] = {-90 * DEGREES, BUILDBANK_CORNER, SHADER_CORNER, SORT_A},
    [DIR.NE] = {-360 * DEGREES, BUILDBANK_CORNER, SHADER_CORNER, SORT_A},
    [DIR.SW] = {-180 * DEGREES, BUILDBANK_CORNER, SHADER_CORNER, SORT_B},
    [DIR.SE] = {-270 * DEGREES, BUILDBANK_CORNER, SHADER_CORNER, SORT_B},
}

local WAVEBLOCKER_RADIUS = 4

local function CheckToggleWaveBlocker_Client(inst)
    if TheWorld.components.wavemanager then
        -- Register wave manager blocker. Assume that 'closed' and 'open_pst' is the only time it is invisible.
        if not inst:IsAsleep() and inst:IsValid() then
            TheWorld.components.wavemanager:RegisterBlocker(inst, WAVEBLOCKER_RADIUS)
        else
            TheWorld.components.wavemanager:UnregisterBlocker(inst)
        end
    end
end

local function OnRemove_Client(inst)
    TheWorld.components.wavemanager:UnregisterBlocker(inst)
end

local function Init(inst, dir, x, y)
    local data = DIR_TO_DATA[dir]
    inst.Transform:SetPosition(x, 0, y)
    inst.AnimState:SetBuild(data[2])
    inst.AnimState:SetBank(data[2])
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(data[3])
    inst.AnimState:SetFloatParams(x, y, data[1])
    inst.AnimState:ForceSetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(data[4])
end

-- TODO (HALF): Xeno you should add some waterfall sounds here
local function EnableSound(inst, enable)
    -- if enable then
    --     if not inst.SoundEmitter:PlayingSound("WATERFALL") then
	-- 	    inst.SoundEmitter:PlaySound("dontstarve_DLC003/amb/Waterfall/LP_1", "WATERFALL")
    --     end
    -- elseif not enable then
    --     if inst.SoundEmitter:PlayingSound("WATERFALL") then
    --         inst.SoundEmitter:KillSound("WATERFALL")
    --     end
    -- end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.Init = Init
    inst.EnableSound = EnableSound

    if not TheNet:IsDedicated() then
        if TheWorld.components.wavemanager then
            -- Client
            inst:ListenForEvent("onremove", OnRemove_Client)
            -- Server + Not Dedicated
            inst:ListenForEvent("entitywake", CheckToggleWaveBlocker_Client)
            inst:ListenForEvent("entitysleep", CheckToggleWaveBlocker_Client)
        end
	end

    return inst
end

return Prefab("waterfall_oceanevil", fn, assets)
