---@class Time
---@overload fun():Time
---@diagnostic disable-next-line: assign-type-mismatch
Time = class 'Time'

---@type VEMLogger
local m_VEMLogger = VEMLogger("Time", true)

---@type VisualEnvironmentHandler
local m_VisualEnvironmentHandler = require("VisualEnvironmentHandler")

function Time:__init()
	m_VEMLogger:Write('Initializing Time Module')

	self:RegisterVars()
	self:RegisterEvents()
end

function Time:RegisterVars()
	-- Initialize variables
	m_VEMLogger:Write('[Client Time Module] Registered Vars')

	self._SystemRunning = false
	self._ClientTime = 0
	self._TotalDayLength = 0
	self._FirstRun = false
	self._IsDay = nil

	self._LastPrintHours = -1
	self._BaseDynamicPresetPriority = 10

	self._SunPosX = 0
	self._SunPosY = 0

	self._SortedDynamicPresetsTable = {}
	self._SavedValuesForReset = {}

	self._CurrentPreset = 1

	self._Sunrise = VEM_CONFIG.DN_SUN_TIMINGS[1] / 24
	self._Sunset = VEM_CONFIG.DN_SUN_TIMINGS[2] / 24

	self._DynamicTypes = { 'Dynamic', 'DefaultDynamic' }
end

function Time:RegisterEvents()
	NetEvents:Subscribe('VEManager:AddTimeToClient', self, self._OnAddTime)
	NetEvents:Subscribe('ClientTime:Pause', self, self._OnPauseUnpause)
	NetEvents:Subscribe('ClientTime:Disable', self, self._OnDisable)

	Events:Subscribe('VEManager:PresetsLoaded', self, self._OnPresetsLoaded)
	Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
end

function Time:_OnPresetsLoaded()
	self._SyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self._OnServerSync) -- Server Sync
	self:_Sync()
end

function Time:OnLevelDestroy()
	-- With this we get rid of carrying old presets when the map changes.
	self:_ResetForcedValues()
	self:RegisterVars()
	m_VEMLogger:Write("Reset Time System")
end

function Time:_Sync()
	m_VEMLogger:Write('Sync Time')
	NetEvents:Send('TimeServer:PlayerSync')
end

---@param p_ServerDayTime number
---@param p_TotalServerTime number
function Time:_OnServerSync(p_ServerDayTime, p_TotalServerTime)
	m_VEMLogger:Write('Server sync event !!!!!!!!!!!!')
	if not p_ServerDayTime or not p_TotalServerTime then
		return
	elseif self._SystemRunning then
		self._ClientTime = p_ServerDayTime
		--self.m_TotalClientTime = p_TotalServerTime -- Not currently used
		self:_Run()
	end
end

-- Update sun position, for smoother sun relative to time
---@param p_ClientTime number
function Time:_UpdateSunPosition(p_ClientTime)
	if self._SunPosY and self._SunPosX then
		local s_DayFactor = p_ClientTime / self._TotalDayLength
		local s_SunPosX = self._SortedDynamicPresetsTable[self._CurrentPreset]['sunRotationX']
		local s_SunPosY = 0

		if s_DayFactor <= self._Sunrise then -- Moon
			local s_FactorNight = (s_DayFactor + 1 - self._Sunset) / (self._Sunrise + 1 - self._Sunset)
			s_SunPosY = 180 * (1 - s_FactorNight)
			self._IsDay = false
		elseif s_DayFactor <= self._Sunset then -- Day
			local s_FactorDay = (s_DayFactor - self._Sunrise) / (self._Sunset - self._Sunrise)
			s_SunPosY = 180 * s_FactorDay
			self._IsDay = true
		else -- Moon
			local s_FactorNight = (s_DayFactor - self._Sunset) / (self._Sunrise + 1 - self._Sunset)
			s_SunPosY = 180 * (1 - s_FactorNight)
			self._IsDay = false
		end

		-- Avoid crashes
		s_SunPosY = MathUtils:Round(s_SunPosY * 100) / 100
		if s_SunPosY < 0 or s_SunPosY > 180 then
			return
		end

		-- Update position (if needed)
		if self._SunPosY ~= s_SunPosY or self._SunPosX ~= s_SunPosX then
			-- Update class variables
			self._SunPosX = s_SunPosX
			self._SunPosY = s_SunPosY
			VisualEnvironmentManager:SetSunRotationX(self._SunPosX)
			VisualEnvironmentManager:SetSunRotationY(self._SunPosY)
		end
	end
end

function Time:_SetCloudSpeed()
	if VEM_CONFIG.DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH then
		self._CloudSpeed = 1 / (self._TotalDayLength / 60 * 0.5)
		m_VEMLogger:Write('Set Cloud Speed = ' .. tostring(self._CloudSpeed))
	end
end

function Time:_ResetForcedValues()
	if #self._SortedDynamicPresetsTable < 1 then
		m_VEMLogger:Write("No modified presets to revert.")
		return
	end
	m_VEMLogger:Write("Reverting dynamic presets to default values:")

	for l_Index, l_Preset in ipairs(self._SortedDynamicPresetsTable) do
		m_VEMLogger:Write(" - " .. tostring(l_Preset['presetID']) .. " (" .. tostring(l_Index) .. ")")

		if not m_VisualEnvironmentHandler:CheckIfExists(l_Preset['presetID']) then return end
		local s_Object = m_VisualEnvironmentHandler:GetVisualEnvironmentObject(l_Preset['presetID'])
		s_Object.ve.priority = self._SavedValuesForReset[l_Index].priority

		for _, l_Class in ipairs(s_Object.ve.components) do -- Remove patches
			-- Un-patch Sun Positions
			if l_Class.typeInfo.name == "OutdoorLightComponentData" then
				local s_Class = OutdoorLightComponentData(l_Class)
				s_Class:MakeWritable()
				-- Reset values
				s_Class.sunRotationX = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationX
				s_Class.sunRotationY = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationY
				-- Un-patch Star Cloudlayer
			elseif l_Class.typeInfo.name == "SkyComponentData" then
				local s_Class = SkyComponentData(l_Class)
				s_Class:MakeWritable()
				-- Reset values
				s_Class.sunSize = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunSize
				s_Class.sunScale = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunScale
				s_Class.cloudLayer2Altitude = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name]
					.cloudLayer2Altitude
				s_Class.cloudLayer2TileFactor = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name]
					.cloudLayer2TileFactor
				s_Class.cloudLayer2Rotation = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name]
					.cloudLayer2Rotation
				s_Class.cloudLayer2Speed = self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Speed
			end
		end
	end
	-- reset
	self._SortedDynamicPresetsTable = {}
end

---@param p_SystemRunning boolean
function Time:_OnPauseUnpause(p_SystemRunning)
	self._SystemRunning = p_SystemRunning
end

function Time:_OnDisable()
	-- Check if presets exist
	if #self._SortedDynamicPresetsTable < 1 then
		return
	end

	-- Disable time system if running
	self._SystemRunning = false

	-- Hide Presets
	for _, l_ValueTable in ipairs(self._SortedDynamicPresetsTable) do
		if not m_VisualEnvironmentHandler:CheckIfExists(l_ValueTable['presetID']) then return end
		m_VisualEnvironmentHandler:SetVisibility(l_ValueTable['presetID'], 0)
	end
	-- Reset patched values
	m_VisualEnvironmentHandler:SetVisibility('Vanilla', 1)
	self:_ResetForcedValues()
end

-- ADD TIME TO MAP
-- Add(Map name, starting hour (24h), day length (min))
---@param p_StartingTime number
---@param p_IsStatic boolean
---@param p_LengthOfDayInSeconds number
function Time:_OnAddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds, p_OnlyDynamicPresets)
	if self._SystemRunning or self._FirstRun then
		self:RegisterVars()
	end
	-- We hide the Vanilla preset
	m_VisualEnvironmentHandler:SetVisibility('Vanilla', 0)

	m_VEMLogger:Write("Searching for dynamic presets:")

	local s_VisualEnvironmentObjects = m_VisualEnvironmentHandler:GetVisualEnvironmentObjects()

	-- Create the list of day-night cycle presets from (default) dynamic presets
	-- for _, l_Type in ipairs(s_Types) do
	-- 	m_VEMLogger:Write("Found for Type: " .. l_Type)
	-- Get all dynamic presets
	-- (if no Dynamic presets, DefaultDynamic presets will be loaded)
	if #self._SortedDynamicPresetsTable < 2 then
		-- The damn thing initializes the tables/arrays WITH 1.... 			
		for presetID, veObject in pairs(s_VisualEnvironmentObjects) do
			if veObject.rawPreset.Sky ~= nil and veObject.rawPreset.OutdoorLight ~= nil then
				local s_SunRotationY = tonumber(veObject.rawPreset.OutdoorLight.SunRotationY)
				local s_SunRotationX = tonumber(veObject.rawPreset.OutdoorLight.SunRotationX)
				-- local s_SkyBrightness = tonumber(veObject.rawPreset.Sky.BrightnessScale)  -- we are no longer using this it seems?

				-- if l_Object.type == l_Type and s_SunRotationY ~= nil then					
				if s_SunRotationY ~= nil then
					m_VEMLogger:Write(" - " .. tostring(presetID) .. " (Sun: " .. tostring(s_SunRotationY) .. ")")

					-- We get the index of a possible match for the given sunRotationY already stored
					local indexMatch = table.Any(self._SortedDynamicPresetsTable, "sunRotationY", s_SunRotationY)
					if indexMatch then
						-- We replace the already saved preset if the incoming preset is Dynamic and has the same sunRotationY value.
						m_VEMLogger:Write("There is already a preset for sunY: - " ..
							tostring(self._SortedDynamicPresetsTable[indexMatch].sunRotationY))
						m_VEMLogger:Write("The stored preset: - " ..
							tostring(self._SortedDynamicPresetsTable[indexMatch].presetID))
						m_VEMLogger:Write("The new VEObject Type: - " .. tostring(veObject.type))
						if veObject.type == "Dynamic" then
							m_VEMLogger:Write(
								"Replacing an already saved preset with a Dynamic preset for the same sunRotationY value")
							self._SortedDynamicPresetsTable[indexMatch] = {
								presetID = presetID,
								sunRotationY = s_SunRotationY,
								sunRotationX = s_SunRotationX
							}
						end
					elseif table.Contains(p_OnlyDynamicPresets and { "Dynamic" } or self._DynamicTypes, veObject.type) then
						-- We save the new VE preset if its a Dynamic or DefaultDynamic
						m_VEMLogger:Write("Saving a new preset!")
						table.insert(self._SortedDynamicPresetsTable,
							{ presetID = presetID, sunRotationY = s_SunRotationY, sunRotationX = s_SunRotationX })
					end
				end
			end
		end
	end

	m_VEMLogger:WriteTable(self._SortedDynamicPresetsTable)

	-- Sort presets in the table based on position in the day-night cycle
	table.sort(self._SortedDynamicPresetsTable,
		function(a, b) return tonumber(a['sunRotationY']) < tonumber(b['sunRotationY']) end)

	-- Set priorities & patch presets
	m_VEMLogger:Write("Sorted dynamic presets:")
	for l_Index, l_Preset in ipairs(self._SortedDynamicPresetsTable) do
		if not m_VisualEnvironmentHandler:CheckIfExists(l_Preset['presetID']) then return end

		---@type VisualEnvironmentObject
		local s_Object = s_VisualEnvironmentObjects[l_Preset['presetID']]

		-- Save default values to revert later
		self._SavedValuesForReset[l_Index] = {}
		self._SavedValuesForReset[l_Index].priority = s_Object.ve.priority

		-- Update preset priority to match it's position in the day-night cycle (morning -> night etc)
		s_Object.ve.priority = l_Index + self._BaseDynamicPresetPriority

		-- Patch Sun Positions
		for _, l_Class in pairs(s_Object.ve.components) do
			if l_Class.typeInfo.name == "OutdoorLightComponentData" then
				local s_Class = OutdoorLightComponentData(l_Class)
				s_Class:MakeWritable()
				-- Save values
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name] = {}
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationX = s_Class.sunRotationX
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationY = s_Class.sunRotationY
				-- Replace values
				s_Class.sunRotationX = 0.0
				s_Class.sunRotationY = 0.0
			elseif l_Class.typeInfo.name == "SkyComponentData" then -- Patch Star Cloudlayer
				--local s_Class = _G[l_Class.typeInfo.name]()
				local s_Class = SkyComponentData(l_Class)
				s_Class:MakeWritable()
				-- Save values
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name] = {}
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunSize = s_Class.sunSize
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunScale = s_Class.sunScale
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Altitude = s_Class
					.cloudLayer2Altitude
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2TileFactor = s_Class
					.cloudLayer2TileFactor
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Rotation = s_Class
					.cloudLayer2Rotation
				self._SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Speed = s_Class.cloudLayer2Speed
				-- Replace values
				-- s_Class.sunSize = 0.01
				-- s_Class.sunScale = 1.5
				s_Class.cloudLayer2Altitude = 5000000.0
				s_Class.cloudLayer2TileFactor = 0.60000002384186
				s_Class.cloudLayer2Rotation = 237.07299804688
				s_Class.cloudLayer2Speed = -0.0010000000474975

				local levelName = SharedUtils:GetLevelName()
				m_VEMLogger:Write('The level name: ' .. levelName)

				if string.find(levelName, 'XP3_Valley') then
					m_VEMLogger:Write('The level is XP3 Valley!, removing the fucking moon')
					s_Class.panoramicUVMinX = 100
					s_Class.panoramicUVMaxX = 100
					s_Class.panoramicUVMinY = 100
					s_Class.panoramicUVMaxY = 0
				end
			end
		end
		m_VEMLogger:Write(" - " ..
			tostring(l_Preset['presetID']) .. " (sun: " .. tostring(l_Preset['sunRotationY']) .. " deg)")
	end



	-- Save dayLength in Class (minutes -> seconds)
	self._TotalDayLength = p_LengthOfDayInSeconds
	m_VEMLogger:Write('[Time-Client]: Length of Day: ' .. self._TotalDayLength .. ' Seconds')
	self._ClientTime = p_StartingTime
	m_VEMLogger:Write('[Time-Client]: Starting at Time: ' ..
		p_StartingTime / 36100 / (self._TotalDayLength / 86000) .. ' Hours (' .. p_StartingTime .. ' Seconds)')

	-- Update sun & clouds
	self:_UpdateSunPosition(self._ClientTime)
	self:_SetCloudSpeed()

	-- Sun/Moon position fix
	local s_SunMoonPos = self._SunPosY

	if not self._IsDay then
		-- Moon visible (from 180 to 360) but actual moon position in VE is 0 to 180
		s_SunMoonPos = 360 - s_SunMoonPos
	end

	-- Find starting preset
	for l_Index, l_Preset in ipairs(self._SortedDynamicPresetsTable) do
		local s_SunPosY = l_Preset['sunRotationY']
		if s_SunPosY < s_SunMoonPos then
			self._CurrentPreset = l_Index
		end
	end

	-- Initialize
	self._FirstRun = true
	self:_Run()

	if p_IsStatic ~= true then
		self._SystemRunning = true
		m_VEMLogger:Write("Day-Night Cycle Activated")
	end
end

function Time:_Run()
	if not self._SystemRunning and not self._FirstRun then
		return
	end

	if not self._ClientTime then
		m_VEMLogger:Warning("Nil ClientTime: " .. tostring(self._ClientTime))
		return
	end

	local s_PrintEnabled = false
	local s_Hour = MathUtils:Round(self._ClientTime / self._TotalDayLength * 24)

	if s_Hour ~= self._LastPrintHours then
		s_PrintEnabled = true
		self._LastPrintHours = s_Hour
	end

	self:_UpdateSunPosition(self._ClientTime)

	-- Sun/Moon position fix
	local s_SunMoonPos = self._SunPosY

	if not self._IsDay then
		-- Moon visible (from 180 to 360) but actual moon position in VE is 0 to 180
		s_SunMoonPos = 360 - s_SunMoonPos
	end

	-- Get sun positions for each preset
	local s_CurrentPresetSunPosY = self._SortedDynamicPresetsTable[self._CurrentPreset]['sunRotationY']
	local s_NextPreset = self._CurrentPreset % #self._SortedDynamicPresetsTable + 1
	local s_NextPresetSunPosY = self._SortedDynamicPresetsTable[s_NextPreset]['sunRotationY']

	-- Check if still in current presets
	if s_SunMoonPos >= s_NextPresetSunPosY and (
			s_CurrentPresetSunPosY < s_NextPresetSunPosY or
			(s_NextPresetSunPosY < s_CurrentPresetSunPosY and s_SunMoonPos < s_CurrentPresetSunPosY)
		) then
		self._CurrentPreset = s_NextPreset
		s_CurrentPresetSunPosY = self._SortedDynamicPresetsTable[self._CurrentPreset]['sunRotationY']

		s_NextPreset = self._CurrentPreset % #self._SortedDynamicPresetsTable + 1
		s_NextPresetSunPosY = self._SortedDynamicPresetsTable[s_NextPreset]['sunRotationY']
	end

	--m_VEMLogger:Write("Current preset: " .. tostring(self.m_CurrentPreset))
	--m_VEMLogger:Write("Next preset: " .. tostring(s_NextPreset))

	-- Calculate visibility factor
	local s_VisibilityFactor = nil

	if s_SunMoonPos <= s_NextPresetSunPosY and s_SunMoonPos <= s_CurrentPresetSunPosY then
		-- When changing from 360 to 0 with s_SunMoonPos after 0
		s_VisibilityFactor = (s_SunMoonPos + 360 - s_CurrentPresetSunPosY) /
			(s_NextPresetSunPosY + 360 - s_CurrentPresetSunPosY)
	elseif s_SunMoonPos <= s_NextPresetSunPosY then
		-- Normal case
		s_VisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY) / (s_NextPresetSunPosY - s_CurrentPresetSunPosY)
	else
		-- When changing from 360 to 0 with s_SunMoonPos before 360
		s_VisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY) /
			(s_NextPresetSunPosY + 360 - s_CurrentPresetSunPosY)
	end

	local s_NextPresetVisibilityFactor = nil
	local s_CurrentPresetVisibilityFactor = nil

	if s_NextPreset ~= 1 then
		s_NextPresetVisibilityFactor = s_VisibilityFactor
		s_CurrentPresetVisibilityFactor = 1.0
	else
		-- Invert visibilities because next preset's priority is less than previous preset's priority
		s_NextPresetVisibilityFactor = 1.0
		s_CurrentPresetVisibilityFactor = 1 - s_VisibilityFactor
	end

	--m_VEMLogger:Write("Sun/Moon: " .. tostring(s_SunMoonPos) .. " ( " .. self.m_CurrentPreset .. " -> " .. s_NextPreset .. " ), visibility: " .. tostring(s_VisibilityFactor))
	--m_VEMLogger:Write("Visibility Factor: " .. tostring(s_VisibilityFactor))

	for l_Index, l_Preset in ipairs(self._SortedDynamicPresetsTable) do
		local s_Factor = 0

		if l_Index == self._CurrentPreset then
			s_Factor = s_CurrentPresetVisibilityFactor
		elseif l_Index == s_NextPreset then
			s_Factor = s_NextPresetVisibilityFactor
		end

		if not m_VisualEnvironmentHandler:CheckIfExists(l_Preset['presetID']) then return end
		m_VisualEnvironmentHandler:SetVisibility(l_Preset['presetID'], s_Factor)

		if s_Factor ~= 0 then -- hardcode for now
			m_VisualEnvironmentHandler:SetSingleValue(l_Preset['presetID'], 'sky', 'cloudLayer1Speed', -0.0001)
		end
	end

	if self._FirstRun then
		self._FirstRun = false
	end

	-- Log visibilities
	if s_PrintEnabled and VEM_CONFIG.PRINT_DN_TIME_AND_VISIBILITIES then
		local s_NextPresetID = self._SortedDynamicPresetsTable[s_NextPreset]['presetID']
		local s_CurrentPresetID = self._SortedDynamicPresetsTable[self._CurrentPreset]['presetID']

		m_VEMLogger:Write("[" ..
			tostring(s_Hour) ..
			"h - sun:" ..
			tostring(s_SunMoonPos) ..
			"] " ..
			tostring(s_CurrentPresetID) ..
			" (" ..
			MathUtils:Round(s_CurrentPresetVisibilityFactor * 100) ..
			"%) -> " .. tostring(s_NextPresetID) .. " (" .. MathUtils:Round(s_NextPresetVisibilityFactor * 100) .. "%)")
	end
end

return Time()
