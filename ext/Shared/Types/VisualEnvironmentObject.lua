---@class VisualEnvironmentObject
---@field logic LogicVisualEnvironmentEntityData
---@field blueprint VisualEnvironmentBlueprint
---@field ve VisualEnvironmentEntityData
---@field entity VisualEnvironmentEntity|nil
---@field supportedClasses table<string>
---@overload fun(arg: VisualEnvironmentObject): VisualEnvironmentObject
VisualEnvironmentObject = class "VisualEnvironmentObject"

---@param p_VEName string
---@param p_VEPriority number
---@param p_VEType string
---@return VisualEnvironmentObject
function VisualEnvironmentObject:__init(p_VEName, p_VEPriority, p_VEType)
    --Not sure if we need the LogicelVEEntity, but :shrug:
    local s_LVEED = UtilityFunctions:InitEngineType("LogicVisualEnvironmentEntityData")
    self.logic = s_LVEED
    s_LVEED.visibility = 0

    local s_VEB = UtilityFunctions:InitEngineType("VisualEnvironmentBlueprint")
    s_VEB.name = p_VEName
    s_LVEED.visualEnvironment = s_VEB
    self.blueprint = s_VEB

    local s_VE = UtilityFunctions:InitEngineType("VisualEnvironmentEntityData")
    s_VEB.object = s_VE
    s_VE.enabled = true
    s_VE.priority = p_VEPriority
    s_VE.visibility = 0

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

return VisualEnvironmentObject