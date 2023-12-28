---@class VisualEnvironmentHandler
---@overload fun():VisualEnvironmentHandler
---@diagnostic disable-next-line: assign-type-mismatch
VisualEnvironmentHandler = class 'VisualEnvironmentHandler'

---@type Logger
local m_Logger = Logger("VisualEnvironmentHandler", false)

---@type EasingTransitions
local m_Easing = require "__shared/Utils/Easing"
---@type RuntimeEntityHandler
local m_RuntimeEntityHandler = require("RuntimeEntityHandler")

function VisualEnvironmentHandler:__init()
	m_Logger:Write('Initializing VisualEnvironmentHandler')
	self:RegisterVars()
end

function VisualEnvironmentHandler:RegisterVars()
	-- Table of visual environment objects
	---@type table<VisualEnvironmentObject>
	self._VisualEnvironmentObjects = {}
	-- Table of currently lerping visual environments
	---@class LerpProperties
	---@field enabled boolean -- if lerp is enabled
	---@field pulsing boolean -- if pulsing is enabled
	---@field transitionFunctionName EasingTransitions|string
	---@field transitionFunction function<EasingTransitions>
	---@field transitionTime number
	---@field startTime number
	---@field startValue number
	---@field endValue number
	---@field firstRun boolean
	---@type table<string, LerpProperties> key: Name, value: LerpProperties
	self._Lerping = {}
end

function VisualEnvironmentHandler:OnLevelDestroy()
	self:RegisterVars()
end

---@param p_ID string
---@param p_Object table<VisualEnvironmentObject>
function VisualEnvironmentHandler:RegisterVisualEnvironmentObject(p_ID, p_Object)
	self._VisualEnvironmentObjects[p_ID] = p_Object
end

---@param p_ID string
---@return VisualEnvironmentObject
function VisualEnvironmentHandler:GetVisualEnvironmentObject(p_ID)
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]

	return s_Object
end

---@return table<VisualEnvironmentObject>
function VisualEnvironmentHandler:GetVisualEnvironmentObjects()
	return self._VisualEnvironmentObjects
end

---@return number
function VisualEnvironmentHandler:GetTotalVEObjectCount()
	return #self._VisualEnvironmentObjects
end

---@param p_ID string
---@return boolean
function VisualEnvironmentHandler:CheckIfExists(p_ID)
	if not LEVEL_LOADED then
		return false
	end

	if p_ID == nil then
		m_Logger:Error("\nThe VE object ID provided is nil.")
	elseif self._VisualEnvironmentObjects[p_ID] == nil then
		m_Logger:Error("\nThere isn't a VE object with this id or it hasn't been parsed yet. Id: " .. tostring(p_ID))
	end

	return true
end

---@param p_ID string
---@return Guid|nil
function VisualEnvironmentHandler:GetEntityDataGuid(p_ID)
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]
	local s_Guid = s_Object.entity.data.instanceGuid

	if s_Guid then
		return s_Guid
	end
	return nil
end

---@param p_ID string
---@param p_Visibility number
---@return boolean IsInitialized
---@return boolean DoesAlreadyExist
function VisualEnvironmentHandler:InitializeVE(p_ID, p_Visibility)
	---@param l_Index integer
	---@param l_Object VisualEnvironmentObject
	for l_Index, l_Object in pairs(self._VisualEnvironmentObjects) do
		if l_Index == p_ID then
			m_Logger:Write("Spawning VE: ")

			if l_Object.entity then
				m_Logger:Warning("- " .. tostring(l_Index) .. ", already exists.")
				self:SetVisibility(p_ID, 1.0)
				return false, true
			end

			---@type VisualEnvironmentEntity|Entity|nil
			---@diagnostic disable-next-line: assign-type-mismatch
			local s_Entity = EntityManager:CreateEntity(l_Object.ve, LinearTransform())
			l_Object.entity = s_Entity

			-- check if entity creation was successful
			if not l_Object.entity then
				m_Logger:Warning("- " .. tostring(l_Index) .. ", could not be spawned.")
				return false, false
			end

			l_Object.ve.visibility = p_Visibility or 1.0
			l_Object.entity:Init(Realm.Realm_Client, true)

			---@type VisualEnvironmentState
			local s_State = VisualEnvironmentEntity(l_Object.entity).state

			if s_State then
				s_State.visibility = p_Visibility
				VisualEnvironmentManager:SetDirty(true)
			else
				self:Reload(p_ID)
			end

			if l_Object.rawPreset["RuntimeEntities"] ~= nil then
				m_RuntimeEntityHandler:SetVisibility(l_Object, false)
			end

			m_Logger:Write("- " ..
				l_Index .. " | Priority: " .. l_Object.ve.priority .. " | Visibility: " .. p_Visibility)
			return true, false
		end
	end
	return false, false
end

---@param p_ID string
---@return boolean wasSuccessful
function VisualEnvironmentHandler:DestroyVE(p_ID)
	m_Logger:Write("Attempting to destroy VE preset with id " .. p_ID .. "...")
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]

	if s_Object == nil then
		m_Logger:Warning("Tried to destroy a preset that does not exist")
		return false
	end

	if not s_Object.entity then
		m_Logger:Write("Preset entity does not exist. Do you really want to destroy at this point?.")
		return true
	end

	-- destroy entity
	self._Lerping[p_ID] = nil
	---@type VisualEnvironmentState
	local s_State = VisualEnvironmentEntity(s_Object.entity).state
	s_State.visibility = 0
	s_Object.entity:Destroy()
	s_Object.entity = nil
	s_Object.ve.visibility = 0.0
	VisualEnvironmentManager:SetDirty(true)

	if s_Object.rawPreset["RuntimeEntities"] ~= nil then
		m_RuntimeEntityHandler:SetVisibility(s_Object, true)
	end

	m_Logger:Write("-> Destroyed!")
	return true
end

---@param p_IDOrObject string|VisualEnvironmentObject
function VisualEnvironmentHandler:Reload(p_IDOrObject)
	---@type string|VisualEnvironmentObject
	local s_Object = p_IDOrObject

	if p_IDOrObject == type("string") then
		s_Object = self._VisualEnvironmentObjects[p_IDOrObject]
	end

	s_Object.entity:FireEvent("Disable")
	s_Object.entity:FireEvent("Enable")
end

---@param p_ID string
---@param p_Visibility number
function VisualEnvironmentHandler:SetVisibility(p_ID, p_Visibility)
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]

	if not s_Object.entity then
		self:InitializeVE(p_ID, p_Visibility)
	elseif p_Visibility <= 0.0 then
		self:DestroyVE(p_ID)
	else
		s_Object.ve.visibility = p_Visibility
		local s_State = VisualEnvironmentEntity(s_Object.entity).state

		if s_State then
			s_State.visibility = p_Visibility
			VisualEnvironmentManager:SetDirty(true)
		else
			self:Reload(p_ID)
		end
	end

	if s_Object.rawPreset["RuntimeEntities"] ~= nil then
		if p_Visibility > 0.5 then
			m_RuntimeEntityHandler:SetVisibility(s_Object, false)
		else
			m_RuntimeEntityHandler:SetVisibility(s_Object, true)
		end
	end
end

---@param p_ID string
---@param p_VisibilityStart number|nil
---@param p_VisibilityEnd number
---@param p_FadeTime number time of the transition in miliseconds
---@param p_TransitionType EasingTransitions|nil
function VisualEnvironmentHandler:FadeTo(p_ID, p_VisibilityStart, p_VisibilityEnd, p_FadeTime, p_TransitionType)
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]
	local s_TransitionFunction = m_Easing[p_TransitionType]

	if not s_TransitionFunction then
		-- default to linear
		s_TransitionFunction = m_Easing["linear"]
	end

	---@type LerpProperties
	local s_LerpProperties = {
		enabled = true,
		transitionFunctionName = p_TransitionType or "linear",
		transitionFunction = s_TransitionFunction,
		transitionTime = p_FadeTime,
		startTime = SharedUtils:GetTimeMS(),
		startValue = p_VisibilityStart or s_Object.ve.visibility,
		endValue = p_VisibilityEnd,
		firstRun = true
	}

	self._Lerping[p_ID] = s_LerpProperties
end

---@param p_ID string
---@param p_PulseTime number time of the transition in miliseconds
---@param p_DecreaseFirst boolean sets if the first pulse decreases the current value until 0
---@param p_TransitionType EasingTransitions|nil
function VisualEnvironmentHandler:Pulse(p_ID, p_PulseTime, p_DecreaseFirst, p_TransitionType)
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]
	local s_TransitionFunction = m_Easing[p_TransitionType]
	local s_VisibilityStart
	local s_VisibilityEnd

	if s_Object.entity and s_Object.entity.state then
		s_VisibilityStart = s_Object.entity.state.visibility
	else
		s_VisibilityStart = 0
	end

	if not s_TransitionFunction then
		-- default to linear
		s_TransitionFunction = m_Easing["linear"]
	end

	if p_DecreaseFirst then
		s_VisibilityEnd = 0
	else
		s_VisibilityEnd = 1
	end

	---@type LerpProperties
	local s_LerpProperties = {
		enabled = true,
		pulsing = true,
		transitionFunctionName = p_TransitionType or "linear",
		transitionFunction = s_TransitionFunction,
		transitionTime = p_PulseTime,
		startTime = SharedUtils:GetTimeMS(),
		startValue = s_VisibilityStart,
		endValue = s_VisibilityEnd,
		firstRun = true
	}

	self._Lerping[p_ID] = s_LerpProperties
end

function VisualEnvironmentHandler:ResetPriorityOneLerps()
	-- Only reset base (main) visual environment lerps
	for l_ID, l_LerpProperties in pairs(self._Lerping) do
		---@type VisualEnvironmentObject
		local s_Object = self._VisualEnvironmentObjects[l_ID]

		-- check if alive
		if s_Object and s_Object.entity and s_Object.ve.priority == 1 then
			self:DestroyVE(l_ID)
			self._Lerping[l_ID] = {}
		end
	end
end

---@param p_DeltaTime number
function VisualEnvironmentHandler:UpdateLerp(p_DeltaTime)
	for l_ID, l_LerpingTable in pairs(self._Lerping) do
		local s_TimeSinceStart = SharedUtils:GetTimeMS() - l_LerpingTable.startTime
		local s_CompletionPercentage = s_TimeSinceStart / l_LerpingTable.transitionTime * 100

		if l_LerpingTable.firstRun then
			-- prevent destroying on first run
			l_LerpingTable.startValue = math.max(l_LerpingTable.startValue, 0.01)
			l_LerpingTable.firstRun = false
		end

		-- ! for now only use functions that need these parameters
		-- t = elapsed time (ms)
		-- b = begin
		-- c = change == ending - beginning
		-- d = duration (total time, ms)
		local t = s_TimeSinceStart
		local b = l_LerpingTable.startValue
		local c = l_LerpingTable.endValue - l_LerpingTable.startValue
		local d = l_LerpingTable.transitionTime

		local s_TransitionFunction = l_LerpingTable.transitionFunction

		---@type number
		local s_LerpValue = s_TransitionFunction(t, b, c, d)

		---@diagnostic disable-next-line: param-type-mismatch
		if s_CompletionPercentage >= 100 then
			if l_LerpingTable.pulsing then
				l_LerpingTable.startTime = SharedUtils:GetTimeMS()

				-- Swap if pulsing, so we set the opposite visibility as goal
				if s_LerpValue < 0.1 then
					l_LerpingTable.startValue = 0.0
					l_LerpingTable.endValue = 1.0
				else
					l_LerpingTable.startValue = 1.0
					l_LerpingTable.endValue = 0.0
				end
			else
				self:SetVisibility(l_ID, l_LerpingTable.endValue)
				self._Lerping[l_ID] = nil
			end
		elseif s_CompletionPercentage < 0 then
			m_Logger:Warning('Lerping of preset ' ..
				tostring(l_ID) ..
				' has its completed percentage of ' .. tostring(s_CompletionPercentage) .. ', should never happen')
			self:SetVisibility(l_ID, l_LerpingTable.endValue)
			self._Lerping[l_ID] = nil
		else
			self:SetVisibility(l_ID, s_LerpValue)
		end
	end
end

---@param p_ID string
---@param p_Class string
---@param p_Property string
---@param p_Value any
function VisualEnvironmentHandler:SetSingleValue(p_ID, p_Class, p_Property, p_Value)
	if not p_Class or not p_Property or not p_Value then
		m_Logger:Write("Passed invalid parameters")
		return
	end
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]
	VisualEnvironmentEntity(s_Object.entity).state[p_Class][p_Property] = p_Value
	VisualEnvironmentManager:SetDirty(true)
end

---@param p_ID string
---@param p_Guid Guid
---@param p_Path string
function VisualEnvironmentHandler:ApplyTexture(p_ID, p_Guid, p_Path)
	---@type VisualEnvironmentObject
	local s_Object = self._VisualEnvironmentObjects[p_ID]

	for _, l_Class in pairs(s_Object.ve.components) do
		if l_Class.typeInfo.name == "SkyComponentData" then
			local s_Class = SkyComponentData(l_Class)
			s_Class:MakeWritable()

			local s_Instance = ResourceManager:SearchForInstanceByGuid(p_Guid)

			if s_Instance then
				s_Class[p_Path] = TextureAsset(s_Instance)
			else
				m_Logger:Warning('[ApplyTexture] Could not find instance with guid ' .. tostring(p_Guid))
			end
		end
	end
	self:Reload(p_ID)
end

return VisualEnvironmentHandler()
