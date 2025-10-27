-------------------------------------------------------------------------
--[[ DF Prefab Spawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "DF Prefab Spawner should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local REATTEMPT_DELAY = TUNING.TOTAL_DAY_TIME / 8

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _activeplayers = {}
local _world = TheWorld
local _worldstate = _world.state
local _map = _world.Map
local _spawned = {}
local _num_spawned = {}

local _saved_player_spawn_info = {}
local _spawn_tasks = {}

--------------------------------------------------------------------------
--[[ Presets ]]
--------------------------------------------------------------------------

local DF_DRIFTWOOD_NOSPAWN_ONEOF_TAGS = {"flotsam"}
local DF_OCEANFISH_NOSPAWN_ONEOF_TAGS = {"oceanfish_small_df"}
local DF_MOSQUITO_NOSPAWN_ONEOF_TAGS = {"df_mosquito"}
local DF_UNASSUMING_TREE_NOSPAWN_ONEOF_TAGS = {"df_unassuming_tree"}

local presets =
{
    df_driftwood = {
        prefabs = { "df_driftwood" },
        timefn = function()
            return GetRandomMinMax(TUNING.DF_DRIFTWOOD_SPAWN_DELAY.MIN, TUNING.DF_DRIFTWOOD_SPAWN_DELAY.MAX)
        end,
        lifetimefn = function()
            return GetRandomMinMax(TUNING.DF_DRIFTWOOD_LIFETIME.MIN, TUNING.DF_DRIFTWOOD_LIFETIME.MAX)
        end,
        radiusfn = function()
            return GetRandomMinMax(5, 45)
        end,
        spawncheckfn = function(x, y, z)
            return _map:IsSurroundedByDFOcean(x, y, z, 1.25) and
                    TheWorld.Map:GetPlatformAtPoint(x, z) == nil and
                    #TheSim:FindEntities(x, y, z, 10, nil, nil, DF_DRIFTWOOD_NOSPAWN_ONEOF_TAGS) <= 0 and
                    FindClosestPlayerInRange(x, y, z, 4, true) == nil
        end,
    },
    oceanfish_small_df = {
        prefabs = { "oceanfish_small_df" },
        timefn = function()
            return GetRandomMinMax(TUNING.DF_OCEANFISH_SPAWN_DELAY.MIN, TUNING.DF_OCEANFISH_SPAWN_DELAY.MAX)
        end,
        radiusfn = function()
            return GetRandomMinMax(5, 45)
        end,
        canspawnfn = function()
            return not _worldstate.iswinter and not _worldstate.isnight
        end,
        spawncheckfn = function(x, y, z)
            return _map:IsSurroundedByDFOcean(x, y, z, 1.25) and
                    TheWorld.Map:GetPlatformAtPoint(x, z) == nil and
                    #TheSim:FindEntities(x, y, z, 10, nil, nil, DF_OCEANFISH_NOSPAWN_ONEOF_TAGS) <= 0 and
                    FindClosestPlayerInRange(x, y, z, 8, true) == nil
        end,
    },
    df_mosquito = {
        prefabs = { "df_mosquito" }, 
        timefn = function()
            return GetRandomMinMax(TUNING.DF_MOSQUITO_SPAWN_DELAY.MIN, TUNING.DF_MOSQUITO_SPAWN_DELAY.MAX)
        end,
        radiusfn = function()
            return GetRandomMinMax(10, 45)
        end,
        canspawnfn = function()
            return not _worldstate.iswinter and not _worldstate.isday
        end,
        spawncheckfn = function(x, y, z)
            return _map:IsSurroundedByDFOcean(x, y, z, 1) and
                    TheWorld.Map:GetPlatformAtPoint(x, z) == nil and
                    #TheSim:FindEntities(x, y, z, 10, nil, nil, DF_MOSQUITO_NOSPAWN_ONEOF_TAGS) <= 0 and
                    FindClosestPlayerInRange(x, y, z, 8, true) == nil
        end,
    },
    df_unassuming_tree = {
        prefabs = { "df_unassuming_tree" }, 
        timefn = function()
            return GetRandomMinMax(TUNING.DF_UNASSUMING_TREE_SPAWN_DELAY.MIN, TUNING.DF_UNASSUMING_TREE_SPAWN_DELAY.MAX)
        end,
        radiusfn = function()
            return GetRandomMinMax(35, 45)
        end,
        canspawnfn = function()
            return _world:HasTag("df_fog_ongoing") and _num_spawned.df_unassuming_tree < TUNING.DF_UNASSUMING_TREE_MAX_SPAWNED
        end,
        spawncheckfn = function(x, y, z)
            return _map:IsSurroundedByLand(x, y, z, 1) and
                    #TheSim:FindEntities(x, y, z, 10, nil, nil, DF_UNASSUMING_TREE_NOSPAWN_ONEOF_TAGS) <= 0 and
                    FindClosestPlayerInRange(x, y, z, 30) == nil
        end,
    },
}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetSpawnPointForPlayer(player, preset_name)
    print("TRYING TO SPAWN", preset_name)
    local preset = presets[preset_name]
    if not player.indarkforest or preset.canspawnfn ~= nil and not preset.canspawnfn() then
        return
    end
    print("CAN SPAWN", preset_name)

    local pt = player:GetPosition()
    local platform = player:GetCurrentPlatform()

    local function TestSpawnPoint(offset)
        local spawnpoint_x, spawnpoint_y, spawnpoint_z = (pt + offset):Get()
        return preset.spawncheckfn(spawnpoint_x, spawnpoint_y, spawnpoint_z)
    end

    local theta = math.random() * TWOPI

    if platform and platform.components.boatphysics then
        local vel_x, vel_z = platform.components.boatphysics.velocity_x, platform.components.boatphysics.velocity_z

        if vel_x ~= 0 or vel_z ~= 0 then
            local vel = platform.components.boatphysics:GetVelocity()

            local lower = 0.1
            local upper = 1.5

            local vel_remapped = (math.min(upper, math.max(lower, vel)) - lower) / upper
            vel_remapped = 1 - vel_remapped

            local offset = math.random() * vel_remapped * PI * (math.random() > .5 and 1 or -1)
            theta = VecUtil_GetAngleInRads(vel_x, -vel_z) + offset
        end
    end

    for i=1, 3 do
        local resultoffset = FindValidPositionByFan(theta, preset.radiusfn(), 12, TestSpawnPoint)

        if resultoffset ~= nil then
            print("FOUND POS", preset_name)
            return pt + resultoffset
        end
    end
end

local function SpawnPrefabForPlayer(player, reschedule, prefab, preset_name)
    local inst = nil

    local spawnpoint = GetSpawnPointForPlayer(player, preset_name)
    if spawnpoint ~= nil then
        inst = self:SpawnPrefab(spawnpoint, prefab, preset_name)
    end
    if reschedule ~= nil then
        reschedule(player)
    end

    return inst
end

local function CancelSpawn(player)
    if _spawn_tasks[player] ~= nil then
        for preset, task in pairs(_spawn_tasks[player]) do
            task:Cancel()
        end
        _spawn_tasks[player] = nil
    end
end

local function ScheduleSpawn(player, time_overrides)
    time_overrides = time_overrides or {}
    _spawn_tasks[player] = {}

    for k, v in pairs(presets) do
        TheWorld.components.df_prefabspawner:ScheduleSpawn(player, k, time_overrides[k]) 
    end
end

local function LoadPlayerSpawnInfo(player)
    if _spawn_tasks[player] ~= nil then
        CancelSpawn(player)
    end
    ScheduleSpawn(player, _saved_player_spawn_info[player.userid])
    _saved_player_spawn_info[player.userid] = nil
end

local function SavePlayerSpawnInfo(player, isworldsave)
	if _spawn_tasks[player] ~= nil then
        _saved_player_spawn_info[player.userid] = {}
        for preset_name, task in pairs(_spawn_tasks[player]) do
            _saved_player_spawn_info[player.userid][preset_name] = GetTaskRemaining(task)
        end
		if not isworldsave then
			CancelSpawn(player)
		end
	end
end

local function RememberInst(inst, preset_name)
    _spawned[inst] = preset_name
    _num_spawned[preset_name] = _num_spawned[preset_name] + 1
end

local function ForgetInst(inst)
    local preset_name = _spawned[inst]
    if preset_name then
        _num_spawned[preset_name] = _num_spawned[preset_name] - 1
        _spawned[inst] = nil
    end
end

local function AutoRemoveTarget(inst, target)
    if target:IsAsleep() then
        target:Remove()
    end
end

local function OnTargetSleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
end

local function OnTimerDone(inst, data)
    if data.name == "df_prefabspawner_despawn" then
        ForgetInst(inst)

        if inst:IsAsleep() then
            inst:Remove()
        else
            inst.persists = false
            _world:ListenForEvent("entitysleep", OnTargetSleep, inst)
            if inst.OnDFPrefabDespawned ~= nil then
                inst:OnDFPrefabDespawned()
            end
        end
    end
end

local function cleartimer(inst)
    inst.components.timer:StopTimer("df_prefabspawner_despawn")
    ForgetInst(inst)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function SpawnPresetPrefab(player, preset_name)
    local preset = presets[preset_name]
    if TheWorld.components.df_prefabspawner ~= nil then
        _spawn_tasks[player][preset_name] = nil
        local inst = SpawnPrefabForPlayer(player, nil, preset.prefabs[math.random(#preset.prefabs)], preset_name)
        TheWorld.components.df_prefabspawner:ScheduleSpawn(player, preset_name, inst == nil and REATTEMPT_DELAY)
    end
end

local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)

    LoadPlayerSpawnInfo(player)
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            SavePlayerSpawnInfo(player)
            table.remove(_activeplayers, i)
            return
        end
    end

    CancelSpawn(player)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end
for preset_name, preset in pairs(presets) do
    _num_spawned[preset_name] = 0
end

--Register events
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:TrackInst(inst, time, preset_name)
    if inst.components.timer == nil then
        inst:AddComponent("timer")
    end
    inst.components.timer:StartTimer("df_prefabspawner_despawn", time)

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("onpickup", cleartimer)
    inst:ListenForEvent("onremove", cleartimer)

    RememberInst(inst, preset_name)
end

function self:SpawnPrefab(spawnpoint, prefab, preset_name)
    local preset = presets[preset_name]
    -- notrealflotsam means the prefab won't get the flotsam tag, so it won't block other flotsam from spawning.

    if prefab == nil then
        return
    end

    local inst = SpawnPrefab(prefab)
    inst.Transform:SetRotation(math.random() * 360)

    inst.Physics:Teleport(spawnpoint:Get())

    if inst.OnDFPrefabSpawned ~= nil then
        inst:OnDFPrefabSpawned()
    end

    if preset and preset.lifetimefn then
       self:TrackInst(inst, preset.lifetimefn(), preset_name)
    end

    return inst
end

function self:ScheduleSpawn(player, preset_name, override_time)
    _spawn_tasks[player][preset_name] = player:DoTaskInTime(override_time or presets[preset_name].timefn(), SpawnPresetPrefab, preset_name)
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    local ents = {}
    data.ents = {}
    data.time = {}
    data.preset_names = {}

    for inst, preset_name in pairs(_spawned) do
        if inst ~= nil then
            table.insert(ents, inst.GUID)
            table.insert(data.ents, inst.GUID)
            table.insert(data.time, inst.components.timer:GetTimeLeft("df_prefabspawner_despawn"))
            table.insert(data.preset_names, preset_name)
        end
    end

    for i, v in ipairs(_activeplayers) do
        SavePlayerSpawnInfo(v, true)
    end

    data.missingplayerspawninfo = deepcopy(_saved_player_spawn_info)

    return data, ents
end

function self:OnLoad(data)
    if data == nil or data.missingplayerspawninfo == nil then
        return
    end

    _saved_player_spawn_info = data.missingplayerspawninfo
    for i, v in ipairs(_activeplayers) do
        LoadPlayerSpawnInfo(v)
    end
end

function self:LoadPostPass(newents, data)
    if data == nil or data.ents == nil or data.time == nil or data.preset_names == nil then
        return
    end

    for k, v in pairs(data.ents) do
        if newents[v] ~= nil then
            self:TrackInst(newents[v].entity, data.time[k], data.preset_names[k])
        end
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local numprefabs = 0
    for k, v in pairs(_spawned) do
        numprefabs = numprefabs + 1
    end
    for i, v in ipairs(_activeplayers) do
        SavePlayerSpawnInfo(v, true)
    end
    local time_str = ""
    for userid, data in pairs(_saved_player_spawn_info) do
        time_str = time_str .. string.format("%s: [\n", userid)
        for preset, time in pairs(data) do
            time_str = time_str .. string.format("  %s = %i,\n", preset, time)
        end
        time_str = time_str .. "]\n"
    end

    return string.format("prefabs:%d\n", numprefabs) .. time_str
end

end)
