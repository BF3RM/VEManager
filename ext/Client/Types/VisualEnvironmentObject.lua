---@class VisualEnvironmentObject
---@field ve VisualEnvironmentEntityData
---@field entity VisualEnvironmentEntity|Entity|nil
---@field supportedClasses table<string>
---@overload fun(arg: VisualEnvironmentObject): VisualEnvironmentObject
---@diagnostic disable-next-line: assign-type-mismatch
VisualEnvironmentObject = class "VisualEnvironmentObject"

---@type Logger
local m_Logger = Logger("VisualEnvironmentObject", true)

---@type VisualEnvironmentHandler
local m_VisualEnvironmentHandler = require("VisualEnvironmentHandler")

---@param p_Preset table
function VisualEnvironmentObject:__init(p_Preset)
	if not p_Preset.Name then
		p_Preset.Name = 'unknown_preset_' .. tostring(m_VisualEnvironmentHandler:GetTotalVEObjectCount())
	end

	if not p_Preset.Type then
		p_Preset.Type = 'generic'
	end

	if not p_Preset.Priority then
		p_Preset.Priority = 1
	elseif p_Preset.Type == 'Dynamic' then
		p_Preset.Priority = 200
	else
		p_Preset.Priority = tonumber(p_Preset.Priority)
	end

	m_Logger:Write("(" .. p_Preset.Name ..", " .. p_Preset.Priority .. ", " .. p_Preset.Type .. ")")

	-- spawning from blueprint alone doesn´t work somehow, would have been nice tho since we can store the name there
    local s_VE = UtilityFunctions:InitEngineType("VisualEnvironmentEntityData")
    s_VE.enabled = true
    s_VE.priority = p_Preset.Priority
    s_VE.visibility = 1

	self.name = p_Preset.Name
    self.ve = s_VE
    self.type = p_Preset.Type
    self.priority = p_Preset.Priority
	self.rawPreset = p_Preset

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