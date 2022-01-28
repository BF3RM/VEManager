---@class VEEditor
VEEditor = class 'VEEditor'

---@type Logger
local m_Logger = Logger("Editor", true)


function VEEditor:__init()
	Logger:Write("Initializing VEEditor")
	self:RegisterVars()
	self:RegisterEvents()
	self:CreateGUI()
end

function VEEditor:RegisterVars()
	self.m_SupportedTypes = {"Vec2", "Vec3", "Vec4", "Float32", "Boolean", "Int"}
	self.m_SupportedClasses = {
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

	self.m_CineState = nil
	self.m_DefaultState = nil
	self.m_CineVE = nil
	self.m_CineEntityGUID = nil
	self.m_CinePriority = 10000010
	self.m_PresetName = nil
	self.m_PresetPriority = nil
	self.m_CollaborationEnabled = false
	self.m_Visible = false
	self.VALUE_STEP = 0.0001
	self.VALUE_MIN = -25000
	self.VALUE_MAX = 25000
	self.m_CineStateReloaded = false
	self.m_ResetConfirmed = false
end

function VEEditor:RegisterEvents()
	Events:Subscribe('VEManager:PresetsLoaded', self, self.OnPresetsLoaded)
	Events:Subscribe('VEManager:AnswerVEGuidRequest', self, self.OnVEGuidReceived)
	NetEvents:Subscribe('VEEditor:DataToClient', self, self.OnDataFromServer)
	NetEvents:Subscribe('VEEditor:ShowUI', self, self.ShowUI)
	NetEvents:Subscribe('VEEditor:HideUI', self, self.HideUI)
end

function VEEditor:OnPresetsLoaded()
	Events:Dispatch("VEManager:EnablePreset", "EditorLayer")
	Events:Dispatch("VEManager:RequestVEGuid", "EditorLayer")

	if VEE_CONFIG.SHOW_EDITOR_ON_LEVEL_LOAD then
		self:ShowUI()
	else
		self:HideUI()
	end

	-- Get CineState & Default State
	if self.m_CineState == nil then
		self.m_CineState = self:GetVisualEnvironmentState(self.m_CinePriority)
		m_Logger:Write('CineState Name: ' .. self.m_CineState.entityName)
		m_Logger:Write('CineState ID: ' .. self.m_CineState.stateId)
		m_Logger:Write('CineState Priority: ' .. self.m_CineState.priority)
		self.m_CineState.excluded = false
		VisualEnvironmentManager:SetDirty(true)
	end
end

function VEEditor:OnVEGuidReceived(p_Guid)
	self.m_CineEntityGUID = p_Guid
	self.m_CineVE = ResourceManager:SearchForInstanceByGuid(self.m_CineEntityGUID)
end

function VEEditor:OnDataFromServer(p_Path, p_Value, p_Net)
	if self.m_CollaborationEnabled == true then
		self:GenericCallback(p_Path, p_Value, p_Net)
	end
end

function VEEditor:ShowUI()
	Events:Dispatch("VEManager:UpdateVisibility", "EditorLayer", 1.0)
	DebugGUI:ShowUI()
	self.m_Visible = true
end

function VEEditor:HideUI()
	Events:Dispatch("VEManager:UpdateVisibility", "EditorLayer", 0.0)
	DebugGUI:HideUI()
	self.m_Visible = false
end

function VEEditor:GenericSeperator(p_Str, p_Sep)
	if p_Sep == nil then
		p_Sep = "%s"
	end

	local s_Table = {}
	for l_Str in string.gmatch(p_Str, "([^" .. p_Sep .. "]+)") do
		table.insert(s_Table, l_Str)
	end

	return s_Table
end

function VEEditor:GetVisualEnvironmentState(...)
	--Get all visual environment states
	local args = { ... }
	local states = VisualEnvironmentManager:GetStates()
	--Loop through all states
	for _, state in pairs(states) do
		m_Logger:Write(state.priority .. ' | ' .. state.visibility .. ' | ' .. state.entityName)

		if string.find(state.entityName, 'VE') then --entityName e.g. Levels/XP1_001/Lighting/VE_XP_001
			self.m_DefaultState = state
			m_Logger:Write("Found Default Entity")
		end

		for i,priority in pairs(args) do
			if state.priority == priority then
				return state
			end
		end
	end
	return nil
end

function VEEditor:GenericCallback(p_Path, p_Value, p_Net)
	if self.m_CineState == nil or self.m_CineStateReloaded then
		self.m_CineState = self:GetVisualEnvironmentState(self.m_CinePriority)
		m_Logger:Write('CineState Name: ' .. self.m_CineState.entityName)
		m_Logger:Write('CineState ID: ' .. self.m_CineState.stateId)
		m_Logger:Write('CineState Priority: ' .. self.m_CineState.priority)
		self.m_CineState.excluded = false
		self.m_CineStateReloaded = false
	end
	VisualEnvironmentManager:SetDirty(true)

	local s_PathTable = self:GenericSeperator(p_Path, "\\.")
	--m_Logger:Write(s_PathTable)

	-- Check if value is already saved
	if #s_PathTable == 1 and self.m_CineState[s_PathTable[1]] == p_Value then
		return
	elseif #s_PathTable == 2 and self.m_CineState[s_PathTable[1]][s_PathTable[2]] == p_Value then
		return
	elseif #s_PathTable == 3 and self.m_CineState[s_PathTable[1]][s_PathTable[2]][s_PathTable[3]] == p_Value then
		return
	elseif #s_PathTable < 1 or #s_PathTable > 3 then
		m_Logger:Write('Unsupported number of path categories ( ' .. p_Path .. ' -> ' .. tostring(#s_PathTable) .. ')')
		return
	end

	-- Save new value
	VisualEnvironmentManager:SetDirty(true)

	if #s_PathTable == 1 then
		self.m_CineState[s_PathTable[1]] = p_Value
	elseif #s_PathTable == 2 then
		self.m_CineState[s_PathTable[1]][s_PathTable[2]] = p_Value
	elseif #s_PathTable == 3 then
		self.m_CineState[s_PathTable[1]][s_PathTable[2]][s_PathTable[3]] = p_Value
	end

	-- if a TextureAsset - changes have to be made in the datacontainer directly. states don´t seem to support texture changes.
	-- Check if boolean etc. else :Is() will fail
	-- TODO: Automatically Detect Path for Loaded Texture
	if type(p_Value) == "userdata" then
		if p_Value.typeInfo and p_Value.typeInfo.name == 'TextureAsset' then
			m_Logger:Write('TextureAsset found')

			if s_PathTable[1] == 'sky' then
				Events:Dispatch("VEManager:ApplyTexture", "EditorLayer", self.selectedTexture.instanceGuid, s_PathTable[2])
			else
				error('Faulty Texture')
			end
		end
	end

	m_Logger:Write('Value saved at ' .. p_Path)

	VisualEnvironmentManager:SetDirty(true)
	if p_Net ~= true and self.m_CollaborationEnabled then
		self:SendForCollaboration(p_Path, p_Value)
		m_Logger:Write('Sending: ' .. p_Path .. ' with Value: ' .. tostring(p_Value))
	end
end

function VEEditor:SendForCollaboration(p_Path, p_Value)
	NetEvents:Send('VEEditor:CollaborationData', p_Path, p_Value)
end

-- TODO: Automate through typeInfo
function VEEditor:CreateGUI()
	m_Logger:Write("*Creating GUI for VEEditor")
	-- Sky
	DebugGUI:Folder("Sky", function ()

		DebugGUI:Checkbox('Enable', true, function(p_Value)
			self:GenericCallback("sky.enable", p_Value)
		end)

		DebugGUI:Range('Sky Brightness', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.brightnessScale", p_Value)
		end)

		DebugGUI:Range('Sun Size', {DefValue = 0.01, Min = 0, Max = 1, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.sunSize", p_Value)
		end)

		DebugGUI:Range('Sun Scale', {DefValue = 5, Min = 0, Max = 100, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.sunScale", p_Value)
		end)

		DebugGUI:Range('Sun Rotation X', {DefValue = 90, Min = 0, Max = 359, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunRotationX", p_Value)
		end)

		DebugGUI:Range('Sun Rotation Y', {DefValue = 0, Min = 0, Max = 180, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunRotationY", p_Value)
		end)

		DebugGUI:Range('Sun Color Red', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunColor.x", p_Value)
		end)

		DebugGUI:Range('Sun Color Green', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunColor.y", p_Value)
		end)

		DebugGUI:Range('Sun Color Blue', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunColor.z", p_Value)
		end)

		DebugGUI:Range('Panoramic UV Min X', {DefValue = 0, Min = 0, Max = 10, Step = 0.5}, function(p_Value)
			self:GenericCallback("sky.panoramicUVMinX", p_Value)
		end)

		DebugGUI:Range('Panoramic UV Max X', {DefValue = 0, Min = 0, Max = 10, Step = 0.5}, function(p_Value)
			self:GenericCallback("sky.panoramicUVMaxX", p_Value)
		end)

		DebugGUI:Range('Panoramic UV Min Y', {DefValue = 0, Min = 0, Max = 10, Step = 0.5}, function(p_Value)
			self:GenericCallback("sky.panoramicUVMinY", p_Value)
		end)

		DebugGUI:Range('Panoramic UV Max Y', {DefValue = 0, Min = 0, Max = 10, Step = 0.5}, function(p_Value)
			self:GenericCallback("sky.panoramicUVMaxY", p_Value)
		end)

		DebugGUI:Range('Panoramic Tile Factor', {DefValue = 0.25, Min = 0, Max = 100, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.panoramicTileFactor", p_Value)
		end)

		DebugGUI:Range('Panoramic Rotation', {DefValue = 0, Min = 0, Max = 360, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.panoramicRotation", p_Value)
		end)

	end)

	-- Sun Flare
	DebugGUI:Folder("Sun Flare", function ()

		DebugGUI:Checkbox('Enable', true, function(p_Value)
			self:GenericCallback("sunFlare.enable", p_Value)
		end)

		DebugGUI:Checkbox('Element 1 Enable', true, function(p_Value)
			self:GenericCallback("sunFlare.element1Enable", p_Value)
		end)

		DebugGUI:Checkbox('Element 2 Enable', true, function(p_Value)
			self:GenericCallback("sunFlare.element2Enable", p_Value)
		end)

		DebugGUI:Checkbox('Element 3 Enable', true, function(p_Value)
			self:GenericCallback("sunFlare.element3Enable", p_Value)
		end)

		DebugGUI:Checkbox('Element 4 Enable', true, function(p_Value)
			self:GenericCallback("sunFlare.element4Enable", p_Value)
		end)

		DebugGUI:Checkbox('Element 5 Enable', true, function(p_Value)
			self:GenericCallback("sunFlare.element5Enable", p_Value)
		end)

		-- TODO IN AUTOMATION LATER.

	end)

	-- Environment
	DebugGUI:Folder("Environment", function ()

		DebugGUI:Range('Static Envmap Scale', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.staticEnvmapScale", p_Value)
		end)

		DebugGUI:Range('Custom Envmap Scale', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.customEnvmapScale", p_Value)
		end)

		DebugGUI:Range('Custom Envmap Ambient', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.customEnvmapAmbient", p_Value)
		end)

		DebugGUI:Range('Sky Envmap Shadow Scale', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.skyEnvmapShadowScale", p_Value)
		end)

		DebugGUI:Range('Sun Shadow Height Scale', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunShadowHeightScale", p_Value)
		end)

		DebugGUI:Range('Translucency Distortion', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.translucencyDistortion", p_Value)
		end)

		DebugGUI:Range('Translucency Ambient', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.translucencyAmbient", p_Value)
		end)

		DebugGUI:Range('Ground Color Red (if Enlighten Off)', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.groundColor.x", p_Value)
		end)

		DebugGUI:Range('Ground Color Green (if Enlighten Off)', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.groundColor.y", p_Value)
		end)

		DebugGUI:Range('Ground Color Blue (if Enlighten Off)', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.groundColor.z", p_Value)
		end)

		DebugGUI:Range('Sky Color Red (if Enlighten Off)', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.skyColor.x", p_Value)
		end)

		DebugGUI:Range('Sky Color Green (if Enlighten Off)', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.skyColor.y", p_Value)
		end)

		DebugGUI:Range('Sky Color Blue (if Enlighten Off)', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.skyColor.z", p_Value)
		end)

		DebugGUI:Range('Sky Light Angle', {DefValue = 0.85, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.skyLightAngleFactor", p_Value)
		end)

		DebugGUI:Range('Sun Specular Scale', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.sunSpecularScale", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Altitude', {DefValue = 500000, Min = 0, Max = 500000, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1Altitude", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Tile Factor', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1TileFactor", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Rotation', {DefValue = 0, Min = 0, Max = 359, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1Rotation", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Speed', {DefValue = -0.0001 , Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1Speed", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Sunlight Intensity', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1SunLightIntensity", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Ambientlight Intensity', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1AmbientLightIntensity", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 1 Alpha Multiplicator', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer1AlphaMul", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Altitude', {DefValue = 500000, Min = 0, Max = 500000, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2Altitude", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Tile Factor', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2TileFactor", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Rotation', {DefValue = 0, Min = 0, Max = 359, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2Rotation", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Speed', {DefValue = -0.0001 , Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2Speed", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Sunlight Intensity', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2SunLightIntensity", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Ambientlight Intensity', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2AmbientLightIntensity", p_Value)
		end)

		DebugGUI:Range('Cloud Layer 2 Alpha Multiplicator', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.cloudLayer2AlphaMul", p_Value)
		end)

		DebugGUI:Checkbox('Cloud Shadow Enable', true, function(p_Value)
			self:GenericCallback("outdoorLight.cloudShadowEnable", p_Value)
		end)

		DebugGUI:Range('Cloud Shadow Coverage', {DefValue = 1, Min = 0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.cloudShadowCoverage", p_Value)
		end)

		DebugGUI:Range('Cloud Shadow Size', {DefValue = 1, Min = 0, Max = 100, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.cloudShadowSize", p_Value)
		end)

		DebugGUI:Range('Cloud Shadow Speed', {DefValue = -0.0001 , Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.cloudShadowSpeed", p_Value)
		end)

		DebugGUI:Range('Cloud Shadow Exponent', {DefValue = 1, Min = 0, Max = 10, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("outdoorLight.cloudShadowExponent", p_Value)
		end)

	end)

	-- Enlighten
	DebugGUI:Folder("Enlighten", function ()

		DebugGUI:Checkbox('Enable', true, function(p_Value)
			self:GenericCallback("enlighten.enable", p_Value)
		end)

		DebugGUI:Range('Sky Visibility Exponent', {DefValue = 0, Min = 0, Max = 1, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("sky.skyVisibilityExponent", p_Value)
		end)

		--[[DebugGUI:Checkbox('Skybox Enlighten Enable', true, function(p_Value)
			self:GenericCallback("enlighten.skyBoxEnable", p_Value)
		end)

		DebugGUI:Range('Skybox Color Red', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSkyColor.x", p_Value)
		end)

		DebugGUI:Range('Skybox Color Green', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSkyColor.y", p_Value)
		end)

		DebugGUI:Range('Skybox Color Blue', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSkyColor.z", p_Value)
		end)

		DebugGUI:Range('Skybox Backlight Color Red', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxBackLightColor.x", p_Value)
		end)

		DebugGUI:Range('Skybox Backlight Color Green', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxBackLightColor.y", p_Value)
		end)

		DebugGUI:Range('Skybox Backlight Color Blue', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxBackLightColor.z", p_Value)
		end)

		DebugGUI:Range('Skybox Backlight Rotation X', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxBackLightRotationX", p_Value)
		end)

		DebugGUI:Range('Skybox Backlight Rotation Y', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxBackLightRotationY", p_Value)
		end)

		DebugGUI:Range('Skybox Ground Color Red', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxGroundColor.x", p_Value)
		end)

		DebugGUI:Range('Skybox Ground Color Green', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxGroundColor.y", p_Value)
		end)

		DebugGUI:Range('Skybox Ground Color Blue', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxGroundColor.z", p_Value)
		end)

		DebugGUI:Range('Skybox Terrain Color Red', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.terrainColor.x", p_Value)
		end)

		DebugGUI:Range('Skybox Terrain Color Green', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.terrainColor.y", p_Value)
		end)

		DebugGUI:Range('Skybox Terrain Color Blue', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.terrainColor.z", p_Value)
		end)

		DebugGUI:Range('Skybox Sunlight Color Red', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSunLightColor.x", p_Value)
		end)

		DebugGUI:Range('Skybox Sunlight Color Green', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSunLightColor.y", p_Value)
		end)

		DebugGUI:Range('Skybox Sunlight Color Blue', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSunLightColor.z", p_Value)
		end)

		DebugGUI:Range('Bounce Scale', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.bounceScale", p_Value)
		end)

		DebugGUI:Range('Cull Distance', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.cullDistance", p_Value)
		end)

		DebugGUI:Range('Sun Scale', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.sunScale", p_Value)
		end)

		DebugGUI:Range('Skybox Sun Light Color Scale', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxSunLightColorSize", p_Value)
		end)

		DebugGUI:Range('Skybox Backlight Color Size', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(p_Value)
			self:GenericCallback("enlighten.skyBoxBackLightColorSize", p_Value)
		end)]]

	end)

	-- Color Correction
	DebugGUI:Folder("Color Correction", function ()

		DebugGUI:Checkbox('Enable', true, function(p_Value)
			self:GenericCallback("colorCorrection.enable", p_Value)
		end)

		DebugGUI:Checkbox('Color Grading Enable', false, function(p_Value)
			--self:GenericCallback("colorCorrection.colorGradingEnable", p_Value)
			NetEvents:Send('VEEditor:ColorCorrection', p_Value)
		end)

		DebugGUI:Range('Brightness Red', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.brightness.x", p_Value)
		end)

		DebugGUI:Range('Brightness Green', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.brightness.y", p_Value)
		end)

		DebugGUI:Range('Brightness Blue', {DefValue = 1, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.brightness.z", p_Value)
		end)

		DebugGUI:Range('Contrast Red', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.contrast.x", p_Value)
		end)

		DebugGUI:Range('Contrast Green', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.contrast.y", p_Value)
		end)

		DebugGUI:Range('Contrast Blue', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.contrast.z", p_Value)
		end)

		DebugGUI:Range('Saturation Red', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.saturation.x", p_Value)
		end)

		DebugGUI:Range('Saturation Green', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.saturation.y", p_Value)
		end)

		DebugGUI:Range('Saturation Blue', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.saturation.z", p_Value)
		end)

		DebugGUI:Range('Hue', {DefValue = 0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("colorCorrection.hue", p_Value)
		end)

	end)

	-- Tonemap
	DebugGUI:Folder("Tonemap", function ()

		DebugGUI:Range('Method', {DefValue = 2.0, Min = 0.0, Max = 3.0, Step = 1}, function(p_Value)
			self:GenericCallback("tonemap.tonemapMethod", p_Value)
		end)

		DebugGUI:Range('Minimum Exposure', {DefValue = 0.0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.minExposure", p_Value)
		end)

		DebugGUI:Range('Maximum Exposure', {DefValue = 1.0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.maxExposure", p_Value)
		end)

		DebugGUI:Range('Middle Gray ', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.middleGray", p_Value)
		end)

		DebugGUI:Range('Exposure Adjust Time', {DefValue = 1.0, Min = 0.0, Max = 50.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.exposureAdjustTime", p_Value)
		end)

		DebugGUI:Range('Bloom Scale Red', {DefValue = 0.2, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.bloomScale.x", p_Value)
		end)

		DebugGUI:Range('Bloom Scale Green', {DefValue = 0.2, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.bloomScale.y", p_Value)
		end)

		DebugGUI:Range('Bloom Scale Blue', {DefValue = 0.2, Min = 0.0, Max = 5, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.bloomScale.z", p_Value)
		end)

		DebugGUI:Checkbox('Chromostereopsis Enable', false, function(p_Value)
			self:GenericCallback("tonemap.chromostereopsisEnable", p_Value)
		end)

		DebugGUI:Range('Chromostereopsis Scale', {DefValue = 0.0, Min = 0.0, Max = 100.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.chromostereopsisScale", p_Value)
		end)

		DebugGUI:Range('Chromostereopsis Offset', {DefValue = 0, Min = 0.0, Max = 100.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("tonemap.chromostereopsisOffset", p_Value)
		end)

	end)

	-- Fog
	DebugGUI:Folder("Fog", function ()

		DebugGUI:Range('Fog Start', {DefValue = 0.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.start", p_Value)
		end)

		DebugGUI:Range('Fog End', {DefValue = 5000.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.endValue", p_Value)
		end)

		DebugGUI:Range('Curve X', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.curve.x", p_Value)
		end)

		DebugGUI:Range('Curve Y', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.curve.y", p_Value)
		end)

		DebugGUI:Range('Curve Z', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.curve.z", p_Value)
		end)

		DebugGUI:Range('Curve W', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.curve.w", p_Value)
		end)

		DebugGUI:Range('Fog Distance Multiplier [doesn´t work on all maps]', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogDistanceMultiplier", p_Value)
		end)

		DebugGUI:Range('Fog Transparency Fade Start', {DefValue = 25.0, Min = 0.0, Max = 5000.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.transparencyFadeStart", p_Value)
		end)

		DebugGUI:Range('Transparency Fade Clamp', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.transparencyFadeClamp", p_Value)
		end)

		DebugGUI:Range('Transparency Fade End', {DefValue = 100.0, Min = 0.0, Max = 5000.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.transparencyFadeEnd", p_Value)
		end)

		DebugGUI:Range('Fog Color Start', {DefValue = 0.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColorStart", p_Value)
		end)

		DebugGUI:Range('Fog Color End', {DefValue = 10000.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColorEnd", p_Value)
		end)

		DebugGUI:Range('Fog Color Red', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColor.x", p_Value)
		end)

		DebugGUI:Range('Fog Color Green', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColor.y", p_Value)
		end)

		DebugGUI:Range('Fog Color Blue', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColor.z", p_Value)
		end)

		DebugGUI:Range('Fog Color Curve X', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColorCurve.x", p_Value)
		end)

		DebugGUI:Range('Fog Color Curve Y', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColorCurve.y", p_Value)
		end)

		DebugGUI:Range('Fog Color Curve Z', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColorCurve.z", p_Value)
		end)

		DebugGUI:Range('Fog Color Curve W', {DefValue = 1.0, Min = self.VALUE_MIN, Max = self.VALUE_MAX, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("fog.fogColorCurve.w", p_Value)
		end)

	end)

	-- Wind
	DebugGUI:Folder("Wind", function ()

		DebugGUI:Range('Wind Direction', {DefValue = 0.0, Min = 0.0, Max = 359, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("wind.windDirection", p_Value)
		end)

		DebugGUI:Range('Wind Strength', {DefValue = 1.0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("wind.windStrength", p_Value)
		end)

	end)

	-- Depth of Field
	DebugGUI:Folder("Depth of Field", function ()

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			self:GenericCallback("dof.enable", p_Value)
		end)

		DebugGUI:Range('Blur Filter', {DefValue = 6, Min = 0, Max = 6, Step = 1}, function(p_Value)
			self:GenericCallback("dof.blurFilter", p_Value)
		end)

		DebugGUI:Range('Scale', {DefValue = 100.0, Min = 0.0, Max = 500.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.scale", p_Value)
		end)

		DebugGUI:Range('Near Distance Scale', {DefValue = 0.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.nearDistanceScale", p_Value)
		end)

		DebugGUI:Range('Far Distance Scale', {DefValue = 0.1, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.farDistanceScale", p_Value)
		end)

		DebugGUI:Range('Focus Distance', {DefValue = 50.0, Min = 0.0, Max = 1000.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.focusDistance", p_Value)
		end)

		DebugGUI:Range('Add Blur', {DefValue = 0.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.blurAdd", p_Value)
		end)

		DebugGUI:Checkbox('DoF Diffusion Enable', false, function(p_Value)
			self:GenericCallback("dof.diffusionDofEnable", p_Value)
		end)

		DebugGUI:Range('DoF Diffusion Aperture', {DefValue = 1.0, Min = 0.6, Max = 20.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.diffusionDofAperture", p_Value)
		end)

		DebugGUI:Range('DoF Diffusion Focal Length', {DefValue = 1.0, Min = 10.0, Max = 135.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dof.diffusionDofFocalLength", p_Value)
		end)

	end)

	-- Vignette
	DebugGUI:Folder("Vignette", function ()

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			self:GenericCallback("vignette.enable", p_Value)
		end)

		DebugGUI:Range('Vignette Opacity', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.opacity", p_Value)
		end)

		DebugGUI:Range('Vignette Exponent', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.exponent", p_Value)
		end)

		DebugGUI:Range('Vignette Scale X', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.scale.x", p_Value)
		end)

		DebugGUI:Range('Vignette Scale Y', {DefValue = 0.75, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.scale.y", p_Value)
		end)

		DebugGUI:Range('Vignette Color X', {DefValue = 0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.color.x", p_Value)
		end)

		DebugGUI:Range('Vignette Color Y', {DefValue = 0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.color.y", p_Value)
		end)

		DebugGUI:Range('Vignette Color Y', {DefValue = 0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("vignette.color.z", p_Value)
		end)

	end)

	-- FilmGrain
	DebugGUI:Folder("Film Grain", function ()

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			self:GenericCallback("filmGrain.enable", p_Value)
		end)

		DebugGUI:Checkbox('Film Grain Random', false, function(p_Value)
			self:GenericCallback("filmGrain.randomEnable", p_Value)
		end)

		DebugGUI:Checkbox('Film Grain Linear Filtering', false, function(p_Value)
			self:GenericCallback("filmGrain.linearFilteringEnable", p_Value)
		end)

		DebugGUI:Range('Color Scale Red', {DefValue = 1.0, Min = 0.0, Max = 2.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("filmGrain.colorScale.x", p_Value)
		end)

		DebugGUI:Range('Color Scale Green', {DefValue = 1.0, Min = 0.0, Max = 2.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("filmGrain.colorScale.y", p_Value)
		end)

		DebugGUI:Range('Color Scale Blue', {DefValue = 1.0, Min = 0.0, Max = 2.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("filmGrain.colorScale.z", p_Value)
		end)

		DebugGUI:Range('Texture Scale X', {DefValue = 1.0, Min = 0.0, Max = 2.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("filmGrain.textureScale.x", p_Value)
		end)

		DebugGUI:Range('Texture Scale Y', {DefValue = 1.0, Min = 0.0, Max = 2.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("filmGrain.textureScale.y", p_Value)
		end)

	end)

	-- LensScope
	DebugGUI:Folder("Lens Scope", function ()

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			self:GenericCallback("lensScope.enable", p_Value)
		end)

		DebugGUI:Range('Abberation Color 1 Red', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationColor1.x", p_Value)
		end)

		DebugGUI:Range('Abberation Color 1 Green', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationColor1.y", p_Value)
		end)

		DebugGUI:Range('Abberation Color 1 Blue', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationColor1.z", p_Value)
		end)

		DebugGUI:Range('Abberation Displacement 1 X', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationDisplacement1.x", p_Value)
		end)

		DebugGUI:Range('Abberation Displacement 1 Y', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationDisplacement1.y", p_Value)
		end)

		DebugGUI:Range('Abberation Color 2 Red', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationColor2.x", p_Value)
		end)

		DebugGUI:Range('Abberation Color 2 Green', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationColor2.y", p_Value)
		end)

		DebugGUI:Range('Abberation Color 2 Blue', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationColor2.z", p_Value)
		end)

		DebugGUI:Range('Abberation Displacement 2 X', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationDisplacement2.x", p_Value)
		end)

		DebugGUI:Range('Abberation Displacement 2 Y', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationDisplacement2.y", p_Value)
		end)

		DebugGUI:Range('Abberation Strengths X', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationStrengths.x", p_Value)
		end)

		DebugGUI:Range('Abberation Strengths Y', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.chromaticAberrationStrengths.y", p_Value)
		end)

		DebugGUI:Range('Abberation Radial Blend Coeff Distance X', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.radialBlendDistanceCoefficients.x", p_Value)
		end)

		DebugGUI:Range('Abberation Radial Blend Coeff Distance Y', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.radialBlendDistanceCoefficients.y", p_Value)
		end)

		DebugGUI:Range('Blur Center X', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.blurCenter.x", p_Value)
		end)

		DebugGUI:Range('Blur Center Y', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.blurCenter.y", p_Value)
		end)

		DebugGUI:Range('Blur Scale', {DefValue = 1.0, Min = 0.0, Max = 2.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("lensScope.blurScale", p_Value)
		end)

	end)

	--[[ Camera Parameters
	DebugGUI:Folder('Camera Parameters', function ()

		DebugGUI:Range('View Distance', {DefValue = 0, Min = 1.0, Max = 2500.0, Step = 1}, function(p_Value)
			self:GenericCallback("cameraParams.viewDistance", p_Value)
		end)

		DebugGUI:Range('Near Plane', {DefValue = 0, Min = 0.0, Max = 1000, Step = 1}, function(p_Value)
			self:GenericCallback("cameraParams.nearPlane", p_Value)
		end)

		DebugGUI:Range('Sun Shadow View Distance', {DefValue = 0, Min = 0.0, Max = 2500.0, Step = 1}, function(p_Value)
			self:GenericCallback("cameraParams.sunShadowmapViewDistance", p_Value)
		end)

	end)]]

	-- Character Lighting
	DebugGUI:Folder('Character Lighting (Only with Enlighten ON)', function ()

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			self:GenericCallback("characterLighting.characterLightEnable", p_Value)
		end)

		DebugGUI:Checkbox('First Person Enable', true, function(p_Value)
			self:GenericCallback("characterLighting.firstPersonEnable", p_Value)
		end)

		DebugGUI:Range('Character Lighting Mode', {DefValue = 0.0, Min = 0.0, Max = 1.0, Step = 1}, function(p_Value)
			self:GenericCallback("characterLighting.characterLightingMode", p_Value)
		end)

		DebugGUI:Range('Blend Factor [In Mode 1]', {DefValue = 0.0, Min = 0.0, Max = 1.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.blendFactor", p_Value)
		end)

		DebugGUI:Checkbox('Lock to Camera Direction', true, function(p_Value)
			self:GenericCallback("characterLighting.lockToCameraDirection", p_Value)
		end)

		DebugGUI:Range('Camera Up Rotation', {DefValue = 90.0, Min = 0.0, Max = 180.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.cameraUpRotation", p_Value)
		end)

		DebugGUI:Range('Top Character Lighting Red', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.topLight.x", p_Value)
		end)

		DebugGUI:Range('Top Character Lighting Green', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.topLight.y", p_Value)
		end)

		DebugGUI:Range('Top Character Lighting Blue', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.topLight.z", p_Value)
		end)

		DebugGUI:Range('Top Light Direction X', {DefValue = 0.0, Min = 0.0, Max = 360.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.topLightDirX", p_Value)
		end)

		DebugGUI:Range('Top Light Direction Y', {DefValue = 50.0, Min = 0.0, Max = 180.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.topLightDirY", p_Value)
		end)

		DebugGUI:Range('Bottom Character Lighting Red', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.bottomLight.x", p_Value)
		end)

		DebugGUI:Range('Bottom Character Lighting Green', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.bottomLight.y", p_Value)
		end)

		DebugGUI:Range('Bottom Character Lighting Blue', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("characterLighting.bottomLight.z", p_Value)
		end)

	end)

	-- Ambient Occlusion
	DebugGUI:Folder('Ambient Occlusion', function ()

		DebugGUI:Range('HBAO Radius', {DefValue = 0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dynamicAO.hbaoRadius", p_Value)
		end)

		DebugGUI:Range('HBAO Attentuation', {DefValue = 0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dynamicAO.hbaoAttenuation", p_Value)
		end)

		DebugGUI:Range('HBAO Angle Bias', {DefValue = 0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dynamicAO.hbaoAngleBias", p_Value)
		end)

		DebugGUI:Range('HBAO Power Exponent', {DefValue = 0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dynamicAO.hbaoPowerExponent", p_Value)
		end)

		DebugGUI:Range('HBAO Contrast', {DefValue = 0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dynamicAO.hbaoContrast", p_Value)
		end)

		DebugGUI:Range('HBAO Max Footprint Radius', {DefValue = 0, Min = 0.0, Max = 10.0, Step = self.VALUE_STEP}, function(p_Value)
			self:GenericCallback("dynamicAO.hbaoMaxFootprintRadius", p_Value)
		end)

	end)

	--[[ Planar Reflection
	DebugGUI:Folder('Planar Reflection', function ()

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			self:GenericCallback("planarReflection.enable", p_Value)
		end)

		DebugGUI:Checkbox('Sky Render Enable', false, function(p_Value)
			self:GenericCallback("planarReflection.skyRenderEnable", p_Value)
		end)

		DebugGUI:Range('HBAO Attentuation', {DefValue = 0, Min = 0.0, Max = 1.0, Step = 0.01}, function(p_Value)
			self:GenericCallback("planarReflection.horizontalDeviation", p_Value)
		end)

		DebugGUI:Range('HBAO Angle Bias', {DefValue = 0, Min = 0.0, Max = 1.0, Step = 0.01}, function(p_Value)
			self:GenericCallback("planarReflection.verticalDeviation", p_Value)
		end)

		DebugGUI:Range('HBAO Power Exponent', {DefValue = 0, Min = 0, Max = 500.0, Step = 1}, function(p_Value)
			self:GenericCallback("planarReflection.groundHeight", p_Value)
		end)

	end)]]

	-- Textures
	DebugGUI:Folder('Textures (BEWARE: EXPERIMENTAL FEATURE - SAVE BEFORE TRYING)', function ()

		DebugGUI:Text('Manual Texture by GUID', 'Enter GUID here', function(p_TextureGUID)
			self.selectedTexture = TextureAsset(ResourceManager:SearchForInstanceByGuid(Guid(p_TextureGUID)))
		end)

		DebugGUI:Text('Manual Texture by Name', 'Enter Name here', function(p_TextureName)
			for l_Key, l_Value in pairs(g_TextureAssets) do
				if string.find(l_Key, p_TextureName) then
					self.selectedTexture = TextureAsset(l_Value)
				end
			end
		end)

		DebugGUI:Text('Search Loaded Textures', 'Enter Search Parameter here', function(p_SearchParameter)
			print("*-- Search Start --")
			for l_Key, l_Value in pairs(g_TextureAssets) do
				if string.find(l_Key, p_SearchParameter) then
					print("Matching Texture: " .. l_Key)
				end
			end
			print("*-- Search End --")
		end)

		DebugGUI:Range('Loaded Texture index', {DefValue = 0, Min = 1, Max = 500, Step = 1}, function(p_Value)
			-- Make sure value is int
			p_Value = math.floor(p_Value)

			-- Count saved loaded textures
			local counter = 0
			for _, l_Value in pairs(g_TextureAssets) do
				counter = counter + 1
			end

			if counter > 0 then
				-- Find/Select a texture
				p_Value = math.fmod(p_Value, counter)

				counter = 0
				for l_Key, l_Value in pairs(g_TextureAssets) do
					counter = counter + 1

					if counter == p_Value then
						m_Logger:Write("Selected Texture index " .. tostring(p_Value) .. " (" .. l_Key .. ")" )
						self.selectedTexture = TextureAsset(l_Value)
					end
				end
			else
				m_Logger:Write("No loaded textures have been saved!" )
			end
		end)

		self.selectedTextureDestination = 'sky.panoramicTexture' -- Default value
		DebugGUI:Text('Texture Destination', 'sky.panoramicTexture', function(p_Destination)
			self.selectedTextureDestination = p_Destination
		end)

		DebugGUI:Button('Apply Texture', function(p_Value)

			if self.selectedTextureDestination == nil or self.selectedTexture == nil then
				m_Logger:Write('Texture not Valid')
				return
			end

			self:GenericCallback(self.selectedTextureDestination, self.selectedTexture)
			self.m_CineStateReloaded = true
		end)

	end)

	-- Time Control
	DebugGUI:Folder('Time Control', function ()

		local s_Enabled = false
		local s_SyncChangesWithServer = false

		DebugGUI:Checkbox('Enable', false, function(p_Value)
			if p_Value == true then
				s_Enabled = true
				Events:Dispatch('TimeServer:AddTime', 43200, true, 86400)
			elseif p_Value == false and s_Enabled == true then
				s_Enabled = false
				NetEvents:Send('TimeServer:DisableNet')
			end
		end)

		DebugGUI:Checkbox('Enable Server Sync', false, function(p_Value)
			s_SyncChangesWithServer = p_Value
		end)

		DebugGUI:Range('Time', {DefValue = 12, Min = 0, Max = 23, Step = 0.5}, function(p_Value)
			local s_Rounded = MathUtils:Round(p_Value)

			if s_SyncChangesWithServer == true and s_Enabled == true then
				m_Logger:Write('Dispatching Time: ' .. p_Value)

				if p_Value == self.m_CurrentSyncedTimeValue then
					return
				else
					self.m_CurrentSyncedTimeValue = p_Value
					NetEvents:Send('TimeServer:AddTimeNet', s_Rounded)
				end
			elseif s_Enabled == true then
				local s_Hour = s_Rounded * 3600
				Events:Dispatch('TimeServer:AddTime', s_Hour, true, 86400)
			end
		end)

	end)

	-- Utilities
	DebugGUI:Folder("Utilities", function ()

		DebugGUI:Text('Load Preset', 'Insert JSON String here', function(p_Preset)
			local s_Decoded = json.decode(p_Preset)
			Events:Dispatch('VEManager:DestroyVE', 'EditorLayer')
			s_Decoded.Name = "EditorLayer"
			s_Decoded.Priority = 10
			Events:Dispatch('VEManager:ReplaceVE', 'EditorLayer', s_Decoded)
			Events:Dispatch('VEManager:Reinitialize')
			self.m_CineStateReloaded = true
		end)

		DebugGUI:Checkbox('Enable Collaboration Mode', false, function(p_Value)
			self.m_CollaborationEnabled = p_Value
		end)

		DebugGUI:Text('Preset name', 'New Preset', function(p_PresetName)
			self.m_PresetName = p_PresetName
		end)

		DebugGUI:Button('Print Preset', function(p_Value)
			print(self:ParseJSON())
		end)

		DebugGUI:Button('Reset to Default', function(p_Value)
			if self.m_ResetConfirmed then
				m_Logger:Write('CineState Name: ' .. self.m_CineState.entityName)
				m_Logger:Write('CineState ID: ' .. self.m_CineState.stateId)
				m_Logger:Write('CineState Priority: ' .. self.m_CineState.priority)

				for l_Index, l_Class in pairs(self.m_SupportedClasses) do
					m_Logger:Write("Class: " .. l_Class)
					local s_LoweredClass = firstToLower(l_Class)
					if self.m_DefaultState[s_LoweredClass] ~= nil and s_LoweredClass ~= 'enlighten' then
						self.m_CineState[s_LoweredClass] = self.m_DefaultState[s_LoweredClass]:Clone()
					elseif self.m_DefaultState[s_LoweredClass] == nil and s_LoweredClass == "characterLighting" then
						self.m_CineState[s_LoweredClass].characterLightEnable = false
					elseif self.m_DefaultState[s_LoweredClass] == nil and self.m_CineState[s_LoweredClass] ~= nil then
						self.m_CineState[s_LoweredClass].enable = false
					end
				end
				VisualEnvironmentManager:SetDirty(true)
			end
		end)

		-- Reset Button
		DebugGUI:Checkbox('Confirm Reset to Default', false, function(p_Value)
			self.m_ResetConfirmed = p_Value
		end)
	end)
end

-- Print Preset as JSON
function VEEditor:ParseJSON()

	if self.m_CineState == nil then
		return 'No changes'
	end

	local s_Result = {}

	--Foreach class
	local componentCount = 0
	for _, l_Class in pairs(self.m_SupportedClasses) do

		if self.m_CineState[firstToLower(l_Class)] ~= nil then
			-- Create class and add it to the VE entity.
			local s_Class = _G[l_Class.."ComponentData"]()

			local s_Rows = {}

			-- Foreach field in class
			for _, l_Field in ipairs(s_Class.typeInfo.fields) do

				-- Fix lua types
				local s_FieldName = l_Field.name

				if s_FieldName == "End" then
					s_FieldName = "EndValue"
				end

				-- Get type
				local s_Type = l_Field.typeInfo.name --Boolean, Int32, Vec3 etc.

				-- If the preset contains that field
				if self.m_CineState[firstToLower(l_Class)][firstToLower(s_FieldName)] ~= nil then
					local s_Value

					if IsBasicType(s_Type) then
						s_Value = self:ParseValue(s_Type, self.m_CineState[firstToLower(l_Class)][firstToLower(s_FieldName)])
					elseif s_Type == "TextureAsset" then
						s_Value = "\"" .. TextureAsset(self.m_CineState[firstToLower(l_Class)][firstToLower(s_FieldName)]).name .. "\""
					elseif l_Field.typeInfo.enum then
						s_Value = "\"" .. tostring(self.m_CineState[firstToLower(l_Class)][firstToLower(s_FieldName)]) .. "\""
					elseif l_Field.typeInfo.array then
						s_Value = "\"Found unexpected array\""
						s_Value = nil
					else
						s_Value = "\"Found unexpected DataContainer\""
						s_Value = nil
					end

					if s_Value ~= nil then
						table.insert(s_Rows, string.format("\"%s\":%s", s_FieldName, s_Value))
					end

				end

			end

			if s_Rows ~= nil then
				table.insert(s_Result, "\"" .. l_Class .. "\" : {" .. table.concat(s_Rows, ",") .. "}")
			end
		end

	end

	-- Get simple json string
	if s_Result == nil then
		s_Result = 'Error while converting preset to JSON'
	else
		-- Add Preset Name
		if self.m_PresetName == nil then
			self.m_PresetName = "New preset"
		end
		local s_PresetNameInJSON = ", \"Name\":\"" .. self.m_PresetName .. "\""

		-- Final JSON convert
		s_Result = "{" .. table.concat(s_Result, ",") .. s_PresetNameInJSON .. "}"
	end

	return s_Result
end

function VEEditor:ParseValue(p_Type, p_Value)
	-- This separates Vectors. Let's just do it to everything, who cares?
	if (p_Type == "Boolean") then
		return "\"" .. tostring(p_Value) .. "\""
	elseif p_Type == "CString" then
		return "\"" .. p_Value .. "\""

	elseif p_Type == "Float8" or
			p_Type == "Float16" or
			p_Type == "Float32" or
			p_Type == "Float64" or
			p_Type == "Int8" or
			p_Type == "Int16" or
			p_Type == "Int32" or
			p_Type == "Int64" or
			p_Type == "Uint8" or
			p_Type == "Uint16" or
			p_Type == "Uint32" or
			p_Type == "Uint64" then
		return "\"" .. tostring(p_Value) .. "\""

	elseif (p_Type == "Vec2") then -- Vec2
		return "\"(" .. p_Value.x .. ", " .. p_Value.y .. ")\""

	elseif (p_Type == "Vec3") then -- Vec3
		return "\"(" .. p_Value.x .. ", " .. p_Value.y .. ", " .. p_Value.z .. ")\""

	elseif (p_Type == "Vec4") then -- Vec4
		return "\"(" .. p_Value.x .. ", " .. p_Value.y .. ", " .. p_Value.z .. ", " .. p_Value.w .. ")\""
	else
		m_Logger:Write("Unhandled type: " .. p_Type)
		return nil
	end
end

function firstToLower(str)
	return (str:gsub("^%L", string.lower))
end

function IsBasicType( typ )
	if typ == "CString" or
	typ == "Float8" or
	typ == "Float16" or
	typ == "Float32" or
	typ == "Float64" or
	typ == "Int8" or
	typ == "Int16" or
	typ == "Int32" or
	typ == "Int64" or
	typ == "Uint8" or
	typ == "Uint16" or
	typ == "Uint32" or
	typ == "Uint64" or
	typ == "LinearTransform" or
	typ == "Vec2" or
	typ == "Vec3" or
	typ == "Vec4" or
	typ == "Boolean" or
	typ == "Guid" then
		return true
	end
	return false
end

return VEEditor()
