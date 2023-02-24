---@class VisualEnvironmentObject
---@field logic LogicVisualEnvironmentEntityData
---@field blueprint VisualEnvironmentBlueprint
---@field ve VisualEnvironmentEntityData
---@field entity VisualEnvironmentEntity|Entity|nil
---@field supportedClasses table<string>
---@overload fun(arg: VisualEnvironmentObject): VisualEnvironmentObject
---@diagnostic disable-next-line: assign-type-mismatch
VisualEnvironmentObject = class "VisualEnvironmentObject"

---@param p_VEName string
---@param p_VEPriority number
---@param p_VEType string
function VisualEnvironmentObject:__init(p_VEName, p_VEPriority, p_VEType)
	-- spawning from blueprint alone doesn´t work somehow, would have been nice tho since we can store the name there
    local s_VE = UtilityFunctions:InitEngineType("VisualEnvironmentEntityData")
    s_VE.enabled = true
    s_VE.priority = p_VEPriority
    s_VE.visibility = 1

    self.ve = s_VE
    self.type = p_VEType
    self.priority = p_VEType

    -- Supported classes by VisualEnvironmentStates https://docs.veniceunleashed.net/vext/ref/client/type/visualenvironmentstate/
	self.supportedClasses = {
		"CameraParams",
		"CharacterLighting",
		"ColorCorrection",
		"DamageEffect",
		"Dof",
		"DynamicAO",
		"DynamicEnvmap",
		"Enlighten",
		"FilmGrain",
		"Fog",
		"LensScope",
		"MotionBlur",
		"OutdoorLight",
		"PlanarReflection",
		"ScreenEffect",
		"Sky",
		"SunFlare",
		"Tonemap",
		"Vignette",
		"Wind"
	}
end

---@class VisualEnvironmentEntity
---@field state VisualEnvironmentState


return VisualEnvironmentObject