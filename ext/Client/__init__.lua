---@class VEManagerClient
---@overload fun():VEManagerClient
VEManagerClient = class 'VEManagerClient'

---@type Logger
local m_Logger = Logger("VEManagerClient", false)

--#region Imports
local m_VisualEnvironmentHandler = require("VisualEnvironmentHandler")
local m_Patches = require("Patches")
--#endregion

function VEManagerClient:__init()
	m_Logger:Write('Initializing VEManagerClient')
	self:RegisterVars()
	self:RegisterEvents()
end

function VEManagerClient:RegisterVars()
	-- Table of raw JSON presets
	self.m_RawPresets = {}
end

function VEManagerClient:RegisterEvents()
	Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)
	Events:Subscribe('Partition:Loaded', self, self._OnPartitionLoaded)
	Events:Subscribe('Level:Loaded', self, self._OnLevelLoaded)
	Events:Subscribe('Level:Destroy', self, self._OnLevelDestroy)
	Events:Subscribe('UpdateManager:Update', self, self.OnUpdateManager)

	Events:Subscribe('VEManager:RegisterPreset', self, self._RegisterPreset)
	Events:Subscribe('VEManager:EnablePreset', self, self._EnablePreset)
	Events:Subscribe('VEManager:DisablePreset', self, self.DisablePreset)
	Events:Subscribe('VEManager:SetVisibility', self, self.SetVisibility)
	Events:Subscribe('VEManager:UpdateVisibility', self, self.UpdateVisibility)
	Events:Subscribe('VEManager:FadeIn', self, self.FadeIn)
	Events:Subscribe('VEManager:FadeTo', self, self.FadeTo)
	Events:Subscribe('VEManager:FadeOut', self, self.FadeOut)
	Events:Subscribe('VEManager:Pulse', self, self.OnPulse)
	Events:Subscribe('VEManager:Lerp', self, self.Lerp)
	Events:Subscribe('VEManager:VEGuidRequest', self, self.OnVEGuidRequest)
	Events:Subscribe('VEManager:Reload', self, self.Reload)
	Events:Subscribe('VEManager:DestroyVE', self, self.OnVEDestroyRequest)
	Events:Subscribe('VEManager:ReplaceVE', self, self.OnVEReplaceRequest)
	Events:Subscribe('VEManager:Reinitialize', self, self.LoadPresets)
	Events:Subscribe('VEManager:ApplyTexture', self, self.ApplyTexture)
	--Events:Subscribe('VEManager:Crossfade', self, self.Crossfade)

	-- Events from server
	NetEvents:Subscribe('VEManager:EnablePreset', self, self.EnablePreset)
end

--#region Event Functions

---@param p_LevelName string
---@param p_GameModeName string
function VEManagerClient:_OnLevelLoaded(p_LevelName, p_GameModeName)
	LEVEL_LOADED = true
	self:_LoadPresets()
	m_Patches:OnLevelLoaded(p_LevelName, p_GameModeName)
end

function VEManagerClient:_OnLevelDestroy()
	self:RegisterVars()
	collectgarbage('collect')
end

---@param p_Partition DatabasePartition
function VEManagerClient:_OnPartitionLoaded(p_Partition)
	-- Send to Time (to apply patches)
	m_Time:OnPartitionLoaded(p_Partition)
end
--#endregion

---@param p_ID string
---@param p_Preset string
function VEManagerClient:_RegisterPreset(p_ID, p_Preset)
	self.m_RawPresets[p_ID] = json.decode(p_Preset)
end

---@param p_ID string
function VEManagerClient:_EnablePreset(p_ID)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	--[[ reset all running lerps as EnablePreset() is a function to apply the main visual environment,
	if you don´t want to stop active lerps use SetVisibility() ]]
	m_VisualEnvironmentHandler:ResetLerps()

	m_Logger:Write("Enabling preset: " .. tostring(p_ID))

	local s_Initialized, s_AlreadyExists = m_VisualEnvironmentHandler:InitializeVE(p_ID, 1.0)

	if not s_Initialized and not s_AlreadyExists then
		m_Logger:Error("Failed to create VE Entity from preset " .. tostring(p_ID))
	elseif not s_Initialized and s_AlreadyExists then
		m_Logger:Warning("Didnt create VE Entity, since it already exists. This shouldnt happen. Making " .. tostring(p_ID) .. " visible nevertheless")
	end

	if self.m_RawPresets[p_ID]["LiveEntities"] ~= nil then
		LiveEntityHandler:SetVisibility(p_ID, false)
	end
end

---@param p_ID string
function VEManagerClient:DisablePreset(p_ID)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_Logger:Write("Disabling preset: " .. tostring(p_ID))

	if not m_VisualEnvironmentHandler:DestroyVE(p_ID) then
		m_Logger:Error("Failed to destroy VE of preset " .. tostring(p_ID))
	end

	if self.m_RawPresets[p_ID]["LiveEntities"] ~= nil then
		LiveEntityHandler:SetVisibility(p_ID, true)
	end
end

function VEManagerClient:_LoadPresets()
	m_Logger:Write("Loading presets... (Name, Type, Priority)")

	-- prepare presets
	for l_Index, l_Preset in pairs(self.m_RawPresets) do

		-- Variables check
		if not l_Preset.Name then
			l_Preset.Name = 'unknown_preset_' .. tostring(m_VisualEnvironmentHandler:GetTotalVEObjectCount())
		end

		if not l_Preset.Type then
			l_Preset.Type = 'generic'
		end

		if not l_Preset.Priority then
			l_Preset.Priority = 1
		else
			l_Preset.Priority = tonumber(l_Preset.Priority)
		end

		-- Generate our VisualEnvironment
		local s_IsBasePreset = l_Preset.Priority == 1

		local s_VEObject = VisualEnvironmentObject(l_Preset.Name, l_Preset.Priority, l_Preset.Type)

		--Foreach class
		local s_ComponentCount = 0

		for _, l_Class in ipairs(s_VEObject.supportedClasses) do
			if l_Preset[l_Class] ~= nil then

				-- Create class and add it to the VE entity.
				local s_Class = UtilityFunctions:InitEngineType(l_Class .. "ComponentData")

				s_Class.excluded = false
				s_Class.isEventConnectionTarget = 3
				s_Class.isPropertyConnectionTarget = 3
				s_Class.indexInBlueprint = s_ComponentCount
				s_Class.transform = LinearTransform()

				-- Foreach field in class
				for _, l_Field in ipairs(s_Class.typeInfo.fields) do
					-- Fix lua types
					local s_FieldName = l_Field.name

					if s_FieldName == "End" then
						s_FieldName = "EndValue"
					end

					-- Get type
					local s_Type = l_Field.typeInfo.name --Boolean, Int32, Vec3 etc.
					-- pm_Logger:Write("Field: " .. tostring(s_FieldName) .. " | " .. " Type: " .. tostring(s_Type))

					-- Initialize value
					local s_Value = nil

					-- If the preset contains that field
					if l_Preset[l_Class][s_FieldName] then

						if UtilityFunctions:IsBasicType(s_Type) then
							s_Value = UtilityFunctions:ParseValue(s_Type, l_Preset[l_Class][s_FieldName])

						elseif l_Field.typeInfo.enum then
							s_Value = tonumber(l_Preset[l_Class][s_FieldName])

						elseif s_Type == "TextureAsset" then
							s_Value = UtilityFunctions:GetTexture(l_Preset[l_Class][s_FieldName])

							if not s_Value then
								m_Logger:Write("\t- TextureAsset has not been saved (" .. l_Preset[l_Class][s_FieldName] .. " | " .. tostring(l_Class) .. " | " .. tostring(s_FieldName) .. ")")
							end
						elseif l_Field.typeInfo.array then
							error("\t- Found unexpected array") -- TODO: Instead of error (that breaks the code), a continue should be used (unfortunately with goto), or set an "errorFound" true/false parameter to true and skip the component addition
							return
						else
							error("\t- Found unexpected DataContainer: " .. s_Type) -- TODO: Instead of error (that breaks the code), a continue should be used (unfortunately with goto), or set an "errorFound" true/false parameter to true and skip the component addition
							return
						end

						-- Set value
						if s_Value then
							s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = s_Value
						end
					end

					-- If not in the preset or incorrect value
					if s_Value == nil then
						-- Try to get original value
						-- m_Logger:Write("Setting default value for field " .. s_FieldName .. " of class " .. l_Class .. " | " ..tostring(s_Value))
						s_Value = UtilityFunctions:GetFieldDefaultValue(l_Class, l_Field)

						if s_Value == nil then
							m_Logger:Write("\t- Failed to fetch original value: " .. tostring(l_Class) .. " | " .. tostring(s_FieldName))

							if s_FieldName == "FilmGrain" then -- fix FilmGrain texture
								m_Logger:Write("\t\t- Fixing value for field " .. s_FieldName .. " of class " .. l_Class .. " | " .. tostring(s_Value))
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = TextureAsset(ResourceManager:FindInstanceByGuid(Guid('44AF771F-23D2-11E0-9C90-B6CDFDA832F1'), Guid('1FD2F223-0137-2A0F-BC43-D974C2BD07B4')))
							end
						else
							-- Applying original value
							if UtilityFunctions:IsBasicType(s_Type) then
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = s_Value

							elseif l_Field.typeInfo.enum then
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = tonumber(s_Value)

							elseif s_Type == "TextureAsset" then
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = TextureAsset(s_Value)

							elseif l_Field.typeInfo.array then
								m_Logger:Write("\t- Found unexpected array, ignoring")
							else
								-- Its a DataContainer
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = _G[s_Type](s_Value)
							end
						end
					end
				end
				s_ComponentCount = s_ComponentCount + 1
				s_VEObject["ve"].components:add(s_Class)
			end
		end
		s_VEObject["ve"].runtimeComponentCount = s_ComponentCount
		m_VisualEnvironmentHandler:RegisterVisualEnvironmentObject(s_VEObject)
	end
	Events:Dispatch("VEManager:PresetsLoaded")
	NetEvents:Send("VEManager:PlayerReady")
	m_Logger:Write("Presets loaded")
end

return VEManagerClient()