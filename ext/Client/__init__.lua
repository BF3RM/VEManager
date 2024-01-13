---@class VEManagerClient
---@overload fun():VEManagerClient
---@diagnostic disable-next-line: assign-type-mismatch
VEManagerClient = class 'VEManagerClient'

---@type VEMLogger
local m_VEMLogger = VEMLogger("VEManagerClient", true)

--#region Imports
require "Types/VisualEnvironmentObject"
---@type VisualEnvironmentHandler
local m_VisualEnvironmentHandler = require("VisualEnvironmentHandler")
---@type RuntimeEntityHandler
local m_RuntimeEntityHandler = require("RuntimeEntityHandler")
---@type Patches
local m_Patches = require("Patches")
---@type Time
local m_Time = require("Time")
--#endregion

function VEManagerClient:__init()
	m_VEMLogger:Write('Initializing VEManagerClient')
	self:RegisterVars()
	self:RegisterEvents()
end

function VEManagerClient:RegisterVars()
	-- Table of raw JSON presets
	-- Default Dynamic day-night cycle Presets
	self._RawPresets = {
		DefaultNight = require("Presets/DefaultNight"),
		DefaultLateNight = require("Presets/DefaultLateNight"),
		DefaultMorning = require("Presets/DefaultMorning"),
		DefaultNoon = require("Presets/DefaultNoon"),
		DefaultEvening = require("Presets/DefaultEvening"),
		Vanilla = require("Presets/Vanilla"),
	}
	self.m_vanillaPreset = nil
end

function VEManagerClient:RegisterEvents()
	if VEM_CONFIG.PATCH_DN_COMPONENTS then
		Events:Subscribe('Partition:Loaded', self, self._OnPartitionLoaded)
	end
	Events:Subscribe('Level:Loaded', self, self._OnLevelLoaded)
	Events:Subscribe('Level:Destroy', self, self._OnLevelDestroy)
	Events:Subscribe('UpdateManager:Update', self, self._OnUpdateManager)

	Events:Subscribe('VEManager:RegisterPreset', self, self._RegisterPreset)
	Events:Subscribe('VEManager:EnablePreset', self, self._OnEnablePreset)
	Events:Subscribe('VEManager:DisablePreset', self, self._OnDisablePreset)
	Events:Subscribe('VEManager:SetVisibility', self, self._OnSetVisibility)
	Events:Subscribe('VEManager:SetSingleValue', self, self._OnSetSingleValue)
	Events:Subscribe('VEManager:FadeTo', self, self._OnFadeTo)
	Events:Subscribe('VEManager:FadeIn', self, self._OnFadeIn)
	Events:Subscribe('VEManager:FadeOut', self, self._OnFadeOut)
	Events:Subscribe('VEManager:Pulse', self, self._OnPulse)
	Events:Subscribe('VEManager:VEGuidRequest', self, self._OnVEGuidRequest)
	Events:Subscribe('VEManager:Reload', self, self._OnReload)
	Events:Subscribe('VEManager:ReplaceVE', self, self._OnReplaceVE)
	Events:Subscribe('VEManager:Reinitialize', self, self._OnReinitialize)
	Events:Subscribe('VEManager:ApplyTexture', self, self._OnApplyTexture)

	NetEvents:Subscribe('VEManager:EnablePreset', self, self._OnEnablePreset)
end

--#region VU Event Functions

---@param p_LevelName string
---@param p_GameModeName string
---@param p_IsDedicatedServer boolean
function VEManagerClient:_OnLevelLoaded(p_LevelName, p_GameModeName, p_IsDedicatedServer)
	LEVEL_LOADED = true
	m_Patches:OnLevelLoaded(p_LevelName, p_GameModeName, p_IsDedicatedServer)
	self:_LoadPresets()
end

function VEManagerClient:_OnLevelDestroy()
	LEVEL_LOADED = false
	self:RegisterVars()
	m_VisualEnvironmentHandler:OnLevelDestroy()
	collectgarbage('collect')
end

---@param p_Partition DatabasePartition
function VEManagerClient:_OnPartitionLoaded(p_Partition)
	m_Patches:PatchComponents(p_Partition)
end

---@param p_DeltaTime number
---@param p_UpdatePass UpdatePass
function VEManagerClient:_OnUpdateManager(p_DeltaTime, p_UpdatePass)
	if p_UpdatePass == UpdatePass.UpdatePass_PreSim then
		m_RuntimeEntityHandler:OnUpdateManagerPreSim(p_DeltaTime)
	elseif p_UpdatePass == UpdatePass.UpdatePass_PostSim then
		m_VisualEnvironmentHandler:UpdateLerp(p_DeltaTime)
	end
end

--#endregion

---@param p_ID string
---@param p_Preset string
function VEManagerClient:_RegisterPreset(p_ID, p_Preset)
	self._RawPresets[p_ID] = json.decode(p_Preset)
	m_VEMLogger:Write("Registered Preset: " .. p_ID)
end

---@param p_ID string
function VEManagerClient:_OnEnablePreset(p_ID)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	-- reset all running priority 1 lerps as EnablePreset() is a function to apply the main visual environment
	m_VisualEnvironmentHandler:ResetPriorityOneLerps()

	m_VEMLogger:Write("Enabling preset: " .. tostring(p_ID))

	local s_Initialized, s_AlreadyExists = m_VisualEnvironmentHandler:InitializeVE(p_ID, 1.0)

	if not s_Initialized and not s_AlreadyExists then
		m_VEMLogger:Error("Failed to create VE Entity from preset " .. tostring(p_ID))
	elseif not s_Initialized and s_AlreadyExists then
		m_VEMLogger:Warning("Didnt create VE Entity, since it already exists. This shouldnt happen. Making " ..
			tostring(p_ID) .. " visible nevertheless")
	end
end

---@param p_ID string
function VEManagerClient:_OnDisablePreset(p_ID)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VEMLogger:Write("Disabling preset: " .. tostring(p_ID))

	if not m_VisualEnvironmentHandler:DestroyVE(p_ID) then
		m_VEMLogger:Error("Failed to destroy VE of preset " .. tostring(p_ID))
	end
end

---@param p_ID string
function VEManagerClient:_OnSetVisibility(p_ID, p_Visibility)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:SetVisibility(p_ID, p_Visibility)
end

---@param p_ID string
---@param p_Class string
---@param p_Property string
---@param p_Value any
function VEManagerClient:_OnSetSingleValue(p_ID, p_Class, p_Property, p_Value)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:SetSingleValue(p_ID, p_Class, p_Property, p_Value)
end

---@param p_ID string
---@param p_VisibilityStart number|nil
---@param p_VisibilityEnd number
---@param p_FadeTime number time of the transition in miliseconds
---@param p_TransitionType EasingTransitions|nil
function VEManagerClient:_OnFadeTo(p_ID, p_VisibilityStart, p_VisibilityEnd, p_FadeTime, p_TransitionType)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:FadeTo(p_ID, p_VisibilityStart, p_VisibilityEnd, p_FadeTime, p_TransitionType)
end

---@param p_ID string
---@param p_FadeTime number
function VEManagerClient:_OnFadeIn(p_ID, p_FadeTime)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:FadeTo(p_ID, 0, 1, p_FadeTime)
end

---@param p_ID string
---@param p_FadeTime number
function VEManagerClient:_OnFadeOut(p_ID, p_FadeTime)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:FadeTo(p_ID, nil, 0, p_FadeTime)
end

---@param p_ID string
---@param p_PulseTime number time of the transition in miliseconds
---@param p_DecreaseFirst boolean sets if the first pulse decreases the current value until 0
---@param p_TransitionType EasingTransitions|nil
function VEManagerClient:_OnPulse(p_ID, p_PulseTime, p_DecreaseFirst, p_TransitionType)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:Pulse(p_ID, p_PulseTime, p_DecreaseFirst, p_TransitionType)
end

---@param p_ID string
function VEManagerClient:_OnVEGuidRequest(p_ID)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	local s_Guid = m_VisualEnvironmentHandler:GetEntityDataGuid(p_ID)

	if s_Guid then
		Events:Dispatch("VEManager:AnswerVEGuidRequest", s_Guid)
	end
end

---@param p_ID string
function VEManagerClient:_OnReload(p_ID)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	m_VisualEnvironmentHandler:Reload(p_ID)
end

---@param p_ID string
---@param p_Replacement string
function VEManagerClient:_OnReplaceVE(p_ID, p_Replacement)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	local s_Preset = json.decode(p_Replacement)

	if not s_Preset then
		m_VEMLogger:Warning('Error when parsing the replacement preset. Id: ' .. tostring(p_ID))
	end
	self._RawPresets[p_ID] = s_Preset
	m_VisualEnvironmentHandler:DestroyVE(p_ID)
	-- We need to trigger the recreation the the VEObject again and replace it by loading it. So we call:
	self:_LoadPresets()
	m_VisualEnvironmentHandler:InitializeVE(p_ID, 1)
end

function VEManagerClient:_OnReinitialize()
	m_VisualEnvironmentHandler:__init()
end

---@param p_ID string
---@param p_Guid Guid
---@param p_Path string
function VEManagerClient:_OnApplyTexture(p_ID, p_Guid, p_Path)
	if not m_VisualEnvironmentHandler:CheckIfExists(p_ID) then return end

	-- m_VisualEnvironmentHandler:__init()
	m_VisualEnvironmentHandler:ApplyTexture(p_ID, p_Guid, p_Path)
end

---@return table<string, string>
function VEManagerClient:GetRawPresets()
	return self._RawPresets
end

---@param p_Class string
---@param p_Field FieldInformation
function VEManagerClient:GetDefaultValue(p_Class, p_Field)
	if p_Field.typeInfo.enum then
		if p_Field.typeInfo.name == "Realm" then
			return Realm.Realm_Client
		else
			m_VEMLogger:Write("\t- Found unhandled enum, " .. p_Field.typeInfo.name)
			return
		end
	end

	local s_States = VisualEnvironmentManager:GetStates()

	for i, l_State in ipairs(s_States) do
		--m_VEMLogger:Write(">>>>>> state:" .. l_State.entityName)

		if l_State.entityName == "Levels/Web_Loading/Lighting/Web_Loading_VE" then
			goto continue
		elseif l_State.entityName ~= 'EffectEntity' then
			local s_Class = l_State[UtilityFunctions:FirstToLower(p_Class)] --colorCorrection

			if s_Class == nil then
				goto continue
			end

			--m_VEMLogger:Write("Sending default value: " .. tostring(p_Class) .. " | " .. tostring(p_Field.typeInfo.name) .. " | " .. tostring(s_Class[firstToLower(p_Field.typeInfo.name)]) .. " (" .. tostring(type(s_Class[firstToLower(p_Field.typeInfo.name)])) .. ")")
			--m_VEMLogger:Write(tostring(s_Class[firstToLower(p_Field.name)]) .. ' | ' .. tostring(p_Field.typeInfo.name))
			return s_Class[UtilityFunctions:FirstToLower(p_Field.name)] --colorCorrection Contrast
		end

		::continue::
	end
end

function VEManagerClient:_LoadPresets()
	m_VEMLogger:Write("Loading presets... (Name, Type, Priority)")


	for _, l_State in ipairs(VisualEnvironmentManager:GetStates()) do
		if l_State.entityName ~= "EffectEntity" and l_State.entityName ~= "Levels/Web_Loading/Lighting/Web_Loading_VE" then
			-- SET VANILLA VE TO PRIORITY 0
			l_State.priority = 0
			l_State.visibility = 0
			self.m_vanillaPreset = l_State
		end
	end

	-- prepare presets
	for l_ID, l_Preset in pairs(self._RawPresets) do
		-- Create Object
		local s_VEObject = VisualEnvironmentObject(l_Preset)

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
					-- pm_VEMLogger:Write("Field: " .. tostring(s_FieldName) .. " | " .. " Type: " .. tostring(s_Type))

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
								m_VEMLogger:Write("\t- TextureAsset has not been saved (" ..
									l_Preset[l_Class][s_FieldName] ..
									" | " .. tostring(l_Class) .. " | " .. tostring(s_FieldName) .. ")")
							end
						elseif l_Field.typeInfo.array then
							error("\t- Found unexpected array") -- TODO: Instead of error (that breaks the code), a continue should be used (unfortunately with goto), or set an "errorFound" true/false parameter to true and skip the component addition
							return
						else
							error("\t- Found unexpected DataContainer: " .. s_Type) -- TODO: Instead of error (that breaks the code), a continue should be used (unfortunately with goto), or set an "errorFound" true/false parameter to true and skip the component addition
							return
						end

						-- Set value
						if s_Value ~= nil then
							s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = s_Value
						end
					end

					-- If not in the preset or incorrect value
					if s_Value == nil then
						---@param p_Class string
						---@param p_Field FieldInformation

						-- Try to get original value
						-- m_VEMLogger:Write("Setting default value for field " .. s_FieldName .. " of class " .. l_Class .. " | " ..tostring(s_Value))
						s_Value = self:GetDefaultValue(l_Class, l_Field)

						if s_Value == nil then
							m_VEMLogger:Write("\t- Failed to fetch original value: " ..
								tostring(l_Class) .. " | " .. tostring(s_FieldName))

							if s_FieldName == "FilmGrain" then -- fix FilmGrain texture
								m_VEMLogger:Write("\t\t- Fixing value for field " ..
									s_FieldName .. " of class " .. l_Class .. " | " .. tostring(s_Value))
								---@diagnostic disable-next-line: param-type-mismatch
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = TextureAsset(ResourceManager
									:FindInstanceByGuid(Guid('44AF771F-23D2-11E0-9C90-B6CDFDA832F1'),
										Guid('1FD2F223-0137-2A0F-BC43-D974C2BD07B4')))
							end
						else
							-- Applying original value
							if UtilityFunctions:IsBasicType(s_Type) then
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = s_Value
							elseif l_Field.typeInfo.enum then
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = tonumber(s_Value)
							elseif s_Type == "TextureAsset" then
								---@diagnostic disable-next-line: param-type-mismatch
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = TextureAsset(s_Value)
							elseif l_Field.typeInfo.array then
								m_VEMLogger:Write("\t- Found unexpected array, ignoring")
							else
								-- Its a DataContainer
								s_Class[UtilityFunctions:FirstToLower(s_FieldName)] = _G[s_Type](s_Value)
							end
						end
					end
				end
				s_ComponentCount = s_ComponentCount + 1
				s_VEObject.ve.components:add(s_Class)
			end
		end
		s_VEObject.ve.runtimeComponentCount = s_ComponentCount
		m_VisualEnvironmentHandler:RegisterVisualEnvironmentObject(l_ID, s_VEObject)
		self._RawPresets[l_ID] = nil
	end
	-- Enabling Vanilla by default :)
	self._OnEnablePreset(self, 'Vanilla')
	Events:Dispatch("VEManager:PresetsLoaded")
	NetEvents:Send("VEManager:PresetsLoaded")
	NetEvents:Send("VEManager:PlayerReady")
	m_VEMLogger:Write("Presets loaded")
end

return VEManagerClient()
