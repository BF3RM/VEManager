---@class Time
---@overload fun():Time
Time = class 'Time'

---@type Logger
local m_Logger = Logger("Time", false)

---@type VisualEnvironmentHandler
local m_VisualEnvironmentHandler = require("VisualEnvironmentHandler")

function Time:__init()
	m_Logger:Write('Initializing Time Module')

	self:RegisterVars()
	self:RegisterEvents()
end

function Time:RegisterVars()
	-- Initialize variables
	m_Logger:Write('[Client Time Module] Registered Vars')

	self.m_SystemRunning = false
	self.m_ClientTime = 0
	self.m_TotalDayLength = 0
	self.m_FirstRun = false
	self.m_IsDay = nil

	self.m_LastPrintHours = -1
	self.m_BaseDynamicPresetPriority = 10

	self.m_SunPosX = 0
	self.m_SunPosY = 0

	self.m_SortedDynamicPresetsTable = {}
	self.m_SavedValuesForReset = {}

	self.m_CurrentPreset = 1

	self.m_CloudSpeed = CONFIG.CLOUDS_DEFAULT_SPEED
	self.m_Sunrise = CONFIG.DN_SUN_TIMINGS[1] / 24
	self.m_Sunset = CONFIG.DN_SUN_TIMINGS[2] / 24

	self.m_RawPresets = VEManagerClient:GetRawPresets()
end

function Time:RegisterEvents()
	NetEvents:Subscribe('VEManager:AddTimeToClient', self, self._OnAddTime)
	NetEvents:Subscribe('ClientTime:Pause', self, self._OnPauseUnpause)
	NetEvents:Subscribe('ClientTime:Disable', self, self._OnDisable)
end

function Time:OnLevelLoaded()
	self.m_ServerSyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self._OnServerSync) -- Server Sync
	self:_Sync()
end

function Time:OnLevelDestroy()
	self.m_ServerSyncEvent = NetEvents:Unsubscribe('TimeServer:Sync') -- Server Sync
	self:_Disable()
end

function Time:_Disable()
	self:_ResetForcedValues()
	self:RegisterVars()
	m_Logger:Write("Reset Time System")
end

function Time:_Sync()
	m_Logger:Write('Sync Time')
	NetEvents:Send('TimeServer:PlayerSync')
end

---@param p_ServerDayTime number
---@param p_TotalServerTime number
function Time:_OnServerSync(p_ServerDayTime, p_TotalServerTime)
	if not p_ServerDayTime or not p_TotalServerTime then
		return
	elseif self.m_SystemRunning then
		self.m_ClientTime = p_ServerDayTime
		--self.m_TotalClientTime = p_TotalServerTime -- Not currently used
		self:_Run()
	end
end

-- Update sun position, for smoother sun relative to time
---@param p_ClientTime number
function Time:_UpdateSunPosition(p_ClientTime)
	local s_DayFactor = p_ClientTime / self.m_TotalDayLength
	local s_SunPosX = 275
	local s_SunPosY = 0

	if s_DayFactor <= self.m_Sunrise then -- Moon
		local s_FactorNight = (s_DayFactor + 1 - self.m_Sunset) / (self.m_Sunrise + 1 - self.m_Sunset)
		s_SunPosY = 180 * (1 - s_FactorNight)
		self.m_IsDay = false
	elseif s_DayFactor <= self.m_Sunset then -- Day
		local s_FactorDay = (s_DayFactor - self.m_Sunrise) / (self.m_Sunset - self.m_Sunrise)
		s_SunPosY = 180 * s_FactorDay
		self.m_IsDay = true
	else -- Moon
		local s_FactorNight = (s_DayFactor - self.m_Sunset) / (self.m_Sunrise + 1 - self.m_Sunset)
		s_SunPosY = 180 * (1 - s_FactorNight)
		self.m_IsDay = false
	end

	-- Avoid crashes
	s_SunPosY = MathUtils:Round(s_SunPosY * 100) / 100
	if s_SunPosY < 0 or s_SunPosY > 180 then
		return
	end

	-- Update position (if needed)
	if self.m_SunPosY ~= s_SunPosY or self.m_SunPosY ~= s_SunPosY then
		-- Update class variables
		self.m_SunPosX = s_SunPosX
		self.m_SunPosY = s_SunPosY
		VisualEnvironmentManager:SetSunRotationX(self.m_SunPosX)
		VisualEnvironmentManager:SetSunRotationY(self.m_SunPosY)
	end
end

function Time:_SetCloudSpeed()
	if CONFIG.DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH then
		self.m_CloudSpeed = 1 / (self.m_TotalDayLength / 60 * 0.5)
		m_Logger:Write('Set Cloud Speed = ' .. tostring(self.m_CloudSpeed))
	end
end

function Time:_ResetForcedValues()
	if #self.m_SortedDynamicPresetsTable < 1 then
		m_Logger:Write("No modified presets to revert.")
		return
	end
	m_Logger:Write("Reverting dynamic presets to default values:")

	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]
		m_Logger:Write(" - " .. tostring(s_ID) .. " (" .. tostring(l_Index) .. ")")

		if not m_VisualEnvironmentHandler:CheckIfExists(s_ID) then return end
		local s_Object = m_VisualEnvironmentHandler:GetVisualEnvironmentObject(s_ID)
		VEManagerClient.m_Presets[s_ID]["ve"].priority = self.m_SavedValuesForReset[l_Index].priority

		for _, l_Class in ipairs(s_Object.ve.components) do -- Remove patches
			-- Un-patch Sun Positions
			if l_Class.typeInfo.name == "OutdoorLightComponentData" then
				local s_Class = OutdoorLightComponentData(l_Class)
				s_Class:MakeWritable()
				-- Reset values
				s_Class.sunRotationX = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationX
				s_Class.sunRotationY = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationY
			-- Un-patch Star Cloudlayer
			elseif l_Class.typeInfo.name == "SkyComponentData" then
				local s_Class = SkyComponentData(l_Class)
				s_Class:MakeWritable()
				-- Reset values
				s_Class.sunSize = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunSize
				s_Class.sunScale = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunScale
				s_Class.cloudLayer2Altitude = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Altitude
				s_Class.cloudLayer2TileFactor = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2TileFactor
				s_Class.cloudLayer2Rotation = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Rotation
				s_Class.cloudLayer2Speed = self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Speed
			end
		end
	end
	-- reset
	self.m_SortedDynamicPresetsTable = {}
end

---@param p_SystemRunning boolean
function Time:_OnPauseUnpause(p_SystemRunning)
	self.m_SystemRunning = p_SystemRunning
end

function Time:_OnDisable()
	-- Check if presets exist
	if #self.m_SortedDynamicPresetsTable < 1 then
		return
	end

	-- Disable time system if running
	self.m_SystemRunning = false

	-- Hide Presets
	for l_ID, l_ValueTable in pairs(self.m_SortedDynamicPresetsTable) do
		VEManagerClient:SetVisibility(l_ValueTable[1], 0)
	end
	-- Reset patched values
	self:_ResetForcedValues()
end

-- ADD TIME TO MAP
-- Add(Map name, starting hour (24h), day length (min))
---@param p_StartingTime number
---@param p_IsStatic boolean
---@param p_LengthOfDayInSeconds number
function Time:_OnAddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds)
	if self.m_SystemRunning or self.m_FirstRun then
		self:RegisterVars()
	end

	local s_Types = {'Dynamic', 'DefaultDynamic'}
	m_Logger:Write("Searching for dynamic presets:")

	-- Create the list of day-night cycle presets from (default) dynamic presets
	for _, l_Type in ipairs(s_Types) do
		m_Logger:Write("Found for Type: " .. l_Type)
		-- Get all dynamic presets
		-- (if no Dynamic presets, DefaultDynamic presets will be loaded)
		if #self.m_SortedDynamicPresetsTable < 2 then
			for l_ID, l_Preset in pairs(self.m_RawPresets) do
				if l_Preset.Sky ~= nil and l_Preset.OutdoorLight ~= nil then
					local s_SunRotationY = tonumber(l_Preset.OutdoorLight.SunRotationY)
					local s_SkyBrightness = tonumber(l_Preset.Sky.BrightnessScale)
					local s_Object = m_VisualEnvironmentHandler:GetVisualEnvironmentObject(l_ID)

					if s_Object.type == l_Type and s_SunRotationY ~= nil then
						-- Check if night mode (moon enabled)
						if s_SkyBrightness ~= nil and s_SkyBrightness <= 0.01 then
							s_SunRotationY = 360 - s_SunRotationY
						end
						m_Logger:Write(" - " .. tostring(l_ID) .. " (sun: " .. tostring(s_SunRotationY) .. ")")
						table.insert(self.m_SortedDynamicPresetsTable, {l_ID, s_SunRotationY})
					end
				end
			end
		end
	end

	-- Sort presets in the table based on position in the day-night cycle
	table.sort(self.m_SortedDynamicPresetsTable, function(a,b) return tonumber(a[2]) < tonumber(b[2]) end)

	-- Set priorities & patch presets
	m_Logger:Write("Sorted dynamic presets:")
	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]

		-- Save default values to revert later
		self.m_SavedValuesForReset[l_Index] = {}
		self.m_SavedValuesForReset[l_Index].priority = VEManagerClient.m_Presets[s_ID]["ve"].priority

		-- Update preset priority to match it's position in the day-night cycle (morning -> night etc)
		VEManagerClient.m_Presets[s_ID]["ve"].priority = l_Index + self.m_BaseDynamicPresetPriority

		-- Patch Sun Positions
		for _, l_Class in pairs(VEManagerClient.m_Presets[s_ID]["ve"].components) do

			if l_Class.typeInfo.name == "OutdoorLightComponentData" then
				local s_Class = OutdoorLightComponentData(l_Class)
				s_Class:MakeWritable()
				-- Save values
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name] = {}
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationX = s_Class.sunRotationX
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunRotationY = s_Class.sunRotationX
				-- Replace values
				s_Class.sunRotationX = 0.0
				s_Class.sunRotationY = 0.0
			elseif l_Class.typeInfo.name == "SkyComponentData" then -- Patch Star Cloudlayer
				--local s_Class = _G[l_Class.typeInfo.name]()
				local s_Class = SkyComponentData(l_Class)
				s_Class:MakeWritable()
				-- Save values
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name] = {}
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunSize = s_Class.sunSize
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].sunScale = s_Class.sunScale
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Altitude = s_Class.cloudLayer2Altitude
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2TileFactor = s_Class.cloudLayer2TileFactor
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Rotation = s_Class.cloudLayer2Rotation
				self.m_SavedValuesForReset[l_Index][l_Class.typeInfo.name].cloudLayer2Speed = s_Class.cloudLayer2Speed
				-- Replace values
				s_Class.sunSize = 0.01
				s_Class.sunScale = 1.5
				s_Class.cloudLayer2Altitude = 5000000.0
				s_Class.cloudLayer2TileFactor = 0.60000002384186
				s_Class.cloudLayer2Rotation = 237.07299804688
				s_Class.cloudLayer2Speed = -0.0010000000474975
			end
		end
		local s_SunRotationY = l_Preset[2]
		m_Logger:Write(" - " .. tostring(s_ID) .. " (sun: " .. tostring(s_SunRotationY) .. " deg)")
	end

	-- Save dayLength in Class (minutes -> seconds)
	self.m_TotalDayLength = p_LengthOfDayInSeconds
	m_Logger:Write('[Time-Client]: Length of Day: ' .. self.m_TotalDayLength .. ' Seconds')
	self.m_ClientTime = p_StartingTime
	m_Logger:Write('[Time-Client]: Starting at Time: ' .. p_StartingTime / 3600 / (self.m_TotalDayLength / 86000) .. ' Hours ('.. p_StartingTime ..' Seconds)')

	-- Update sun & clouds
	self:_UpdateSunPosition(self.m_ClientTime)
	self:_SetCloudSpeed()

	-- Sun/Moon position fix
	local s_SunMoonPos = self.m_SunPosY

	if not self.m_IsDay then
		-- Moon visible (from 180 to 360) but actual moon position in VE is 0 to 180
		s_SunMoonPos = 360 - s_SunMoonPos
	end

	-- Find starting preset
	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_SunPosY = l_Preset[2]
		if s_SunPosY < s_SunMoonPos then
			self.m_CurrentPreset = l_Index
		end
	end

	-- Initialize
	self.m_FirstRun = true
	self:_Run()

	if p_IsStatic ~= true then
		self.m_SystemRunning = true
		m_Logger:Write("Day-Night Cycle Activated")
	end
end

function Time:_Run()
	if not self.m_SystemRunning and not self.m_FirstRun then
		return
	end

	if not self.m_ClientTime then
		m_Logger:Warning("Nil ClientTime: " .. tostring(self.m_ClientTime))
		return
	end

	local s_PrintEnabled = false
	local s_Hour = MathUtils:Round(self.m_ClientTime / self.m_TotalDayLength * 24)

	if s_Hour ~= self.m_LastPrintHours then
		s_PrintEnabled = true
		self.m_LastPrintHours = s_Hour
	end

	self:_UpdateSunPosition(self.m_ClientTime)

	-- Sun/Moon position fix
	local s_SunMoonPos = self.m_SunPosY

	if not self.m_IsDay then
		-- Moon visible (from 180 to 360) but actual moon position in VE is 0 to 180
		s_SunMoonPos = 360 - s_SunMoonPos
	end

	-- Get sun positions for each preset
	local s_CurrentPresetSunPosY = self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2]
	local s_NextPreset = self.m_CurrentPreset % #self.m_SortedDynamicPresetsTable + 1
	local s_NextPresetSunPosY = self.m_SortedDynamicPresetsTable[s_NextPreset][2]

	-- Check if still in current presets
	if s_SunMoonPos >= s_NextPresetSunPosY and (
		s_CurrentPresetSunPosY < s_NextPresetSunPosY or
		(s_NextPresetSunPosY < s_CurrentPresetSunPosY and s_SunMoonPos < s_CurrentPresetSunPosY)
		) then
		self.m_CurrentPreset = s_NextPreset
		s_CurrentPresetSunPosY = self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2]

		s_NextPreset = self.m_CurrentPreset % #self.m_SortedDynamicPresetsTable + 1
		s_NextPresetSunPosY = self.m_SortedDynamicPresetsTable[s_NextPreset][2]
	end

	--m_Logger:Write("Current preset: " .. tostring(self.m_CurrentPreset))
	--m_Logger:Write("Next preset: " .. tostring(s_NextPreset))

	-- Calculate visibility factor
	local s_VisibilityFactor = nil

	if s_SunMoonPos <= s_NextPresetSunPosY and s_SunMoonPos <= s_CurrentPresetSunPosY then
		-- When changing from 360 to 0 with s_SunMoonPos after 0
		s_VisibilityFactor = (s_SunMoonPos + 360 - s_CurrentPresetSunPosY) / (s_NextPresetSunPosY + 360 - s_CurrentPresetSunPosY)
	elseif s_SunMoonPos <= s_NextPresetSunPosY then
		-- Normal case
		s_VisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY) / (s_NextPresetSunPosY - s_CurrentPresetSunPosY)
	else
		-- When changing from 360 to 0 with s_SunMoonPos before 360
		s_VisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY) / (s_NextPresetSunPosY + 360 - s_CurrentPresetSunPosY)
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

	--m_Logger:Write("Sun/Moon: " .. tostring(s_SunMoonPos) .. " ( " .. self.m_CurrentPreset .. " -> " .. s_NextPreset .. " ), visibility: " .. tostring(s_VisibilityFactor))
	--m_Logger:Write("Visibility Factor: " .. tostring(s_VisibilityFactor))

	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]
		local s_Factor = 0

		if l_Index == self.m_CurrentPreset then
			s_Factor = s_CurrentPresetVisibilityFactor
		elseif l_Index == s_NextPreset then
			s_Factor = s_NextPresetVisibilityFactor
		end

		m_VisualEnvironmentHandler:SetVisibility(s_ID, s_Factor)

		if s_Factor ~= 0 then -- TODO: Check if cloud speed works properly

			if not m_VisualEnvironmentHandler:CheckIfExists(s_ID) then return end
			m_VisualEnvironmentHandler:SetSingleValue(s_ID, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		end
	end

	if self.m_FirstRun then
		self.m_FirstRun = false
	end

	-- Log visibilities
	if s_PrintEnabled and CONFIG.PRINT_DN_TIME_AND_VISIBILITIES then
		local s_NextPresetID = self.m_SortedDynamicPresetsTable[s_NextPreset][1]
		local s_CurrentPresetID = self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][1]

		m_Logger:Write("[" .. tostring(s_Hour) .. "h - sun:" .. tostring(s_SunMoonPos) .. "] " .. tostring(s_CurrentPresetID) .. " (" .. MathUtils:Round(s_CurrentPresetVisibilityFactor*100) .. "%) -> " .. tostring(s_NextPresetID) .. " (" .. MathUtils:Round(s_NextPresetVisibilityFactor*100) .. "%)" )
	end
end

return Time()
