GLOBAL.setfenv(1, GLOBAL)

--
local unpack = unpack
local PhysicsCollisionCallbacks = PhysicsCollisionCallbacks
--

--
local _block_mask = setmetatable({}, {__mode = "k"})
local _teleport_callbacks = setmetatable({}, {__mode = "k"})
--

--Creatureprox physic entities should NOT proc the callback of the thing it's colliding with!
local _OnPhysicsCollision = OnPhysicsCollision
function OnPhysicsCollision(guid1, guid2, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames, ...)
    local i1, i2 = Ents[guid1], Ents[guid2]

    local _guid1Callback, _guid2Callback = PhysicsCollisionCallbacks[guid1], PhysicsCollisionCallbacks[guid2]
    PhysicsCollisionCallbacks[guid1] = (i2 and (not i2._creature_prox_collider and PhysicsCollisionCallbacks[guid1])) or nil
    PhysicsCollisionCallbacks[guid2] = (i1 and (not i1._creature_prox_collider and PhysicsCollisionCallbacks[guid2])) or nil
    _OnPhysicsCollision(guid1, guid2, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames, ...)
    PhysicsCollisionCallbacks[guid1] = _guid1Callback
    PhysicsCollisionCallbacks[guid2] = _guid2Callback
end

function GetPhysicsCollisionCallback(inst)
    return PhysicsCollisionCallbacks[inst.GUID]
end

function Physics:MaskCollidesWithAny(collision)
    return bit.band(collision, self:GetCollisionMask()) > 0
end

function Physics:MaskCollidesWithAll(collision)
    return bit.band(collision, self:GetCollisionMask()) == collision
end

function Physics:SetBlockMask(name, group, collision)
    if _block_mask[self] == nil then
        _block_mask[self] = {}
    end
    _block_mask[self][name] = {
        group = group,
        collision = collision,
        iscolliding = self:MaskCollidesWithAll(collision)
    }
    if self:GetCollisionGroup() == group then
        self:ClearCollidesWith(collision)
    end
end

function Physics:ClearBlockMask(name)
    local mask = _block_mask[self] ~= nil and _block_mask[self][name] or nil
    if mask == nil then return end

    local iscolliding = self:GetCollisionGroup() == mask.group and mask.iscolliding

    _block_mask[self][name] = nil
    if IsTableEmpty(_block_mask[self]) then
        _block_mask[self] = nil
    end

    if iscolliding then
        self:CollidesWith(mask.collision)
    end
end

function Physics:HasBlockMask(name)
    return _block_mask[self] ~= nil and _block_mask[self][name] ~= nil or false
end

local _SetCollisionGroup = Physics.SetCollisionGroup
function Physics:SetCollisionGroup(group, ...)
    if _block_mask[self] == nil then return _SetCollisionGroup(self, group, ...) end
    if self:GetCollisionGroup() == group then return end
    for k, v in pairs(_block_mask[self]) do
        if group == v.group then
            v.iscolliding = self:MaskCollidesWithAll(v.collision)
            self:ClearCollidesWith(v.collision)
        elseif v.iscolliding then
            self:CollidesWith(v.collision)
        end
    end
    return _SetCollisionGroup(self, group, ...)
end

local _CollidesWith = Physics.CollidesWith
function Physics:CollidesWith(collision, ...)
    local rets = {_CollidesWith(self, collision, ...)}
    if _block_mask[self] == nil then return unpack(rets) end
    for k, v in pairs(_block_mask[self]) do
        if self:GetCollisionGroup() == v.group then
            v.iscolliding = self:MaskCollidesWithAll(v.collision)
            self:ClearCollidesWith(v.collision)
        end
    end
    return unpack(rets)
end

local _SetCollisionMask = Physics.SetCollisionMask
function Physics:SetCollisionMask(mask, ...)
    local rets = {_SetCollisionMask(self, mask, ...)}
    if _block_mask[self] == nil then return unpack(rets) end
    for k, v in pairs(_block_mask[self]) do
        if self:GetCollisionGroup() == v.group then
            v.iscolliding = self:MaskCollidesWithAll(v.collision)
            self:ClearCollidesWith(v.collision)
        end
    end
    return unpack(rets)
end

function Physics:SetTeleportCallback(fn)
    _teleport_callbacks[self] = fn
end

local _Teleport = Physics.Teleport
function Physics:Teleport(...)
    _Teleport(self, ...)
    if _teleport_callbacks[self] ~= nil then
        _teleport_callbacks[self]()
    end
end

local _TeleportRespectingInterpolation = Physics.TeleportRespectingInterpolation
function Physics:TeleportRespectingInterpolation(...)
    _TeleportRespectingInterpolation(self, ...)
    if _teleport_callbacks[self] ~= nil then
        _teleport_callbacks[self]()
    end
end

local _Remove = EntityScript.Remove
function EntityScript:Remove(...)
    if _block_mask[self.Physics] then
        _block_mask[self.Physics] = nil
    end
    if _teleport_callbacks[self.Physics] then
        _teleport_callbacks[self.Physics] = nil
    end
    return _Remove(self, ...)
end
