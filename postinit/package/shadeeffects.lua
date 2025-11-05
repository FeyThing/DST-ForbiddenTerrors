local ENV = env
GLOBAL.setfenv(1, GLOBAL)

if TheNet:IsDedicated() then
	local nullfunc = function() end
	
	SpawnEvilTreeShade = nullfunc
	DespawnEvilTreeShade = nullfunc
	ShadeRendererEnabled = nil
	
	return
end

ShadeTypes.EvilTreeShade = ShadeRenderer:CreateShadeType()


ShadeRenderer:SetShadeMaxRotation(ShadeTypes.EvilTreeShade, TUNING.CANOPY_MAX_ROTATION) -- TUNING.EVILTREE_SHADE_MAX_ROTATION

ShadeRenderer:SetShadeRotationSpeed(ShadeTypes.EvilTreeShade, TUNING.CANOPY_ROTATION_SPEED) -- TUNING.EVILTREE_SHADE_ROTATION_SPEED

ShadeRenderer:SetShadeMaxTranslation(ShadeTypes.EvilTreeShade, TUNING.CANOPY_MAX_TRANSLATION) -- TUNING.EVILTREE_SHADE_MAX_TRANSLATION

ShadeRenderer:SetShadeTranslationSpeed(ShadeTypes.EvilTreeShade, TUNING.CANOPY_TRANSLATION_SPEED) -- TUNING.EVILTREE_SHADE_TRANSLATION_SPEED

ShadeRenderer:SetShadeTexture(ShadeTypes.EvilTreeShade, resolvefilepath("images/tree.tex"))

-- Messing around with the value of the 360 makes random rotations of the images less choatic. May need to play with it.
function SpawnEvilTreeShade(x, z)
	return ShadeRenderer:SpawnShade(ShadeTypes.EvilTreeShade, x, z, math.random() * 360, TUNING.CANOPY_SCALE)
end

function DespawnEvilTreeShade(id)
	ShadeRenderer:RemoveShade(ShadeTypes.EvilTreeShade, id)
end

local OldShadeEffectUpdate = ShadeEffectUpdate

function ShadeEffectUpdate(dt, ...)
	local r, g, b = TheSim:GetAmbientColour()
	
	ShadeRenderer:SetShadeStrength(ShadeTypes.EvilTreeShade, Lerp(0.4, 0.7, ((r + g + b) / 3) / 255)) -- TUNING.EVILTREE_SHADE_MIN_STRENGTH, TUNING.EVILTREE_SHADE_MAX_ROTATION
	return OldShadeEffectUpdate(dt, ...)
end