GLOBAL.setfenv(1, GLOBAL)

local LABEL_SPACING = 40
function EntityScript:SetDFDebugLabel(name, txt, colour)
    if self.df_debug_labels == nil then
        self.df_debug_labels = {}
    end
    local targ_label
    for i,label in ipairs(self.df_debug_labels) do
        if label.name == name and label ~= nil and label:IsValid() then
            targ_label = label
            break
        end
    end
    if targ_label == nil then
        targ_label = SpawnPrefab("df_debug_label")
        targ_label.name = name
        table.insert(self.df_debug_labels, targ_label)
        self:AddChild(targ_label)
        targ_label:SetUIOffset(0, (#self.df_debug_labels-1) * LABEL_SPACING, 0)
    end

    targ_label:SetText(txt)
    if colour ~= nil then
        targ_label:SetColour(unpack(colour))
    end
end

function EntityScript:ClearDFDebugLabel(name)
    local targ_label
    for i,label in ipairs(self.df_debug_labels) do
        if label.name == name and label ~= nil and label:IsValid() then
            targ_label = table.remove(self.df_debug_labels, i)
            break
        end
    end
    if targ_label ~= nil then
        targ_label:Remove()

        for i,label in ipairs(self.df_debug_labels) do
            if label ~= nil and label:IsValid() then
                label:SetUIOffset(0, (i-1) * LABEL_SPACING, 0)
            end
        end

        if IsTableEmpty(self.df_debug_labels) then
            self.df_debug_labels = nil
        end
    end
end

--I wanted to use this function for something but it isn't GetEventCallback**s**, just singular, :/
--Rename this function to `GetEventCallback`, now because im lazy, im not doing that rn, 
--asgerrr: to whoever wrote this: have you not heard of directory-wide search and replace? how do you get anything done without the ability to search across multiple files?
---@param event string
---@param source EntityScript?
---@param source_file string?
---@return function?
function EntityScript:GetEventCallback(event, source, source_file)
    source = source or self

    assert(self.event_listening[event] and self.event_listening[event][source])

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                return fn
            end
        else
            return fn
        end
    end
end

---@param event string
---@param source EntityScript?
---@param source_file string?
---@return function[]
function EntityScript:GetEventCallbacks(event, source, source_file)
    source = source or self

    assert(self.event_listening[event] and self.event_listening[event][source])

    local fns = {}

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                table.insert(fns, fn)
            end
        else
            table.insert(fns, fn)
        end
    end

    return fns
end

---@param var string
---@param source_file string?
---@return function?
function EntityScript:GetWorldStateCallback(var, source_file)
    assert(self.worldstatewatching[var])

    for _, fn in ipairs(self.worldstatewatching[var]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                return fn
            end
        else
            return fn
        end
    end
end

---@param var string
---@param source_file string?
---@return function[]
function EntityScript:GetWorldStateCallbacks(var, source_file)
    assert(self.worldstatewatching[var])

    local fns = {}

    for _, fn in ipairs(self.worldstatewatching[var]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                table.insert(fns, fn)
            end
        else
            table.insert(fns, fn)
        end
    end

    return fns
end

function EntityScript:IsOnDFOcean(allow_boats)
    local x, y, z = self.Transform:GetWorldPosition()
    return TheWorld.Map:IsDFOceanAtPoint(x, y, z, allow_boats)
end

function EntityScript:IsOnDFOceanTile(allow_boats)
    local x, y, z = self.Transform:GetWorldPosition()
    return (allow_boats or self:GetPlatformAtPoint(x, z) == nil) and
        TheWorld.Map:IsDFOceanTileAtPoint(x, y, z)
end
