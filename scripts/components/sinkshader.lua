local SHADER_PATH = "shaders/df_sink.ksh"

local function UpdateFloatParams(inst, submerge)
    local pitch_offset = (TheCamera.pitch - TheCamera.mindistpitch) / (TheCamera.maxdistpitch - TheCamera.mindistpitch) -- min = 30, max = 60
    inst.AnimState:SetFloatParams(0, -0.3 * submerge,0) ----0.6 needs to be TUNING.SINK_SHADER_MAX_SUBMERGE
    -- (-0.2 - 0.25 * pitch_offset)
    -- LukaS: This value is hard-coded, used to counteract the effects of perspective from the camera
    -- WILL NOT WORK PROPERLY IF THE CAMERA MIN/MAX PITCH VALUES ARE CHANGED, shouldn't be a problem tho
end 

local SinkShader = Class(function(self, inst)
    self.inst = inst

    self.submerge = net_float(inst.GUID, "SinkShader.submerge", "submergedirty")

    self.inst:StartUpdatingComponent(self)

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("submergedirty", function() UpdateFloatParams(inst, self.submerge:value()) end)
        self.inst:ListenForEvent("erodetimedirty", function()
            local erode_time = self._erode_time:value()
            if self.front_fx ~= nil then
                ErodeAway(self.front_fx, erode_time)
            end
            if self.back_fx ~= nil then
                ErodeAway(self.back_fx, erode_time)
            end
        end)
    end

    self.size = "small"
    self.vert_offset = nil
    self.xscale = 0.7
    self.yscale = 0.7
    self.zscale = 0.7
    self.should_parent_effect = true
    self.showing_effect = false
    self._erode_time = net_float(inst.GUID, "sinkshader._erode_time", "erodetimedirty")
end)

function SinkShader:SetScale(scale)
    if scale ~= nil then
        if type(scale) == "table" then
            self.xscale = scale[1]
            self.yscale = scale[2]
            self.zscale = scale[3]
        else
            self.xscale = scale
            self.yscale = scale
            self.zscale = scale
        end

        if self.front_fx ~= nil then
            self.front_fx.Transform:SetScale(self.xscale, self.yscale, self.zscale)
        end
        if self.back_fx ~= nil then
            self.back_fx.Transform:SetScale(self.xscale, self.yscale, self.zscale)
        end
    end
end

function SinkShader:AttachEffect(effect)
    if self.should_parent_effect then
        effect.entity:SetParent(self.inst.entity)
        effect.Transform:SetPosition(0, self.vert_offset or .2, 0)
    else
        local my_x, my_y, my_z = self.inst.Transform:GetWorldPosition()
        effect.Transform:SetPosition(my_x, my_y + (self.vert_offset or 0), my_z)
    end

    effect.Transform:SetScale(self.xscale, self.yscale, self.zscale)
end

function SinkShader:Ripples()
    self.showing_effect = true
    if self.front_fx == nil then
        self.front_fx = SpawnPrefab("float_fx_front")
        self:AttachEffect(self.front_fx)
        self.front_fx.AnimState:PlayAnimation("idle_front_" .. self.size, true)
    end

    if self.back_fx == nil then
        self.back_fx = SpawnPrefab("float_fx_back")
        self:AttachEffect(self.back_fx)
        self.back_fx.AnimState:PlayAnimation("idle_back_" .. self.size, true)
    end

    if self.inst.sg and self.inst.sg:HasStateTag("running") then
        local fx = SpawnPrefab("weregoose_ripple"..tostring(math.random(2)))
        fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    end
end

function SinkShader:NoRipples()
    self.showing_effect = false

    if self.front_fx ~= nil and self.front_fx:IsValid() then
        self.front_fx:Remove()
        self.front_fx = nil
    end
    if self.back_fx ~= nil and self.back_fx:IsValid() then
        self.back_fx:Remove()
        self.back_fx = nil
    end
end

local FLOATING_TAGS = {"playerghost", "ghost", "shadow", "brightmare", "flying"}
function SinkShader:OnUpdate(dt)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local _map = TheWorld.Map
    if self.inst.sg ~= nil and self.inst.sg:HasStateTag("jumping") or self.inst:HasOneOfTags(FLOATING_TAGS) then
        self:SetSubmergedAmount(0)
        return
    end
    if _map:IsSurroundedByWater(x, y, z, 0.25) and _map:IsOceanAtPoint(x, y, z) then
        local tile = _map:GetTileAtPoint(x, y, z)
        if tile == WORLD_TILES.OCEAN_EVIL then
            self:SetSubmergedAmount(2.5)
            return
        elseif tile ==  WORLD_TILES.OCEAN_EVIL_SHORE then
            self:SetSubmergedAmount(1)
            return
        end
    end
    self:SetSubmergedAmount(0)
end

function SinkShader:OnRemoveFromEntity()
    self.inst.AnimState:ClearDefaultEffectHandle() -- LukaS: [TODO] Should probably accomodate for when the player has some other default shader set up
    self.inst.AnimState:SetFloatParams(0, 0, 0)
end

function SinkShader:SetSubmergedAmount(amount)
    if amount ~= 0 then
        self.inst.AnimState:SetDefaultEffectHandle(resolvefilepath(SHADER_PATH))
        self.inst.DynamicShadow:Enable(false)
        self:Ripples()
    else
        self.inst.AnimState:ClearDefaultEffectHandle()
        self.inst.DynamicShadow:Enable(true)
        self:NoRipples()
    end

    if amount >= 2.5 then
        self.inst._sinkshader_submerged:set(true)
		
		if self.inst.components.locomotor then
			self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "sinkshader_submerged", 0.5)
		end
    else
        self.inst._sinkshader_submerged:set(false)
		
		if self.inst.components.locomotor then
			self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "sinkshader_submerged", nil)
		end
    end

    self.submerge:set(math.clamp(amount, 0, 1))
end

function SinkShader:Erode(erode_time)
    if self.ismastersim and self.showing_effect then
        self._erode_time:set(erode_time)
    end
end

return SinkShader