class 'Time'

local Patches = require('modules/patches')

function Time:__init()
	print('Initializing Time Module')
	self:RegisterVars()
	self:RegisterEvents()
end

function Time:RegisterVars()
	-- Initialise variables
	print('[Client Time Module] Registered Vars')
	self.m_SystemRunning = false
	self.m_IsStatic = nil
	self.m_ClientTime = 0
	self.m_TotalClientTime = 0
	self.m_TotalDayLength = 0
	self.m_OriginalSunX = nil
	self.m_OriginalSunY = nil
	self.m_NightPriority = 11
	self.m_MorningPriority = 12
	self.m_NoonPriority = 13
	self.m_EveningPriority = 14
	self.m_CurrentNightPreset = nil
	self.m_CurrentMorningPreset = nil
	self.m_CurrentNoonPreset = nil
	self.m_CurrentEveningPreset = nil
	self.m_LastPrintHours = -1
	self.m_FirstRun = false
	self.m_IsDay = nil

	self.m_SunPosX = 0
	self.m_SunPosY = 0

	self.m_CurrentPresetTable = {}
	self.m_SortedDynamicPresetsTable = {}

	self.m_CurrentPreset = 1

	self.m_CloudSpeed = VEM_CONFIG.CLOUDS_DEFAULT_SPEED
	self.m_Sunrise = VEM_CONFIG.DN_SUN_TIMINGS[1] / 24
	self.m_Sunset = VEM_CONFIG.DN_SUN_TIMINGS[2] / 24
end

function Time:RegisterEvents()
	self.m_PartitionLoadedEvent = Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoad)
	--self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
	self.m_LevelLoadEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
	self.m_LevelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
	self.m_AddTimeToClientEvent = NetEvents:Subscribe('VEManager:AddTimeToClient', self, self.AddTimeToClient)

	NetEvents:Subscribe('ClientTime:Pause', self, self.PauseContinue)
	NetEvents:Subscribe('ClientTime:Disable', self, self.Disable)
end

function Time:OnPartitionLoad(p_Partition)
	Patches:Components(p_Partition)

	if p_Partition.guid == Guid('6E5D35D9-D9D5-11DE-ADB5-9D4DBC23632A') then
		for _, instance in pairs(p_Partition.instances) do
			if instance.instanceGuid == Guid('32CE96BB-E578-9589-7B11-B670661DF2DF') then
				g_Stars = instance
			end
		end
	end
end

function Time:OnLevelLoaded()
	self.m_ServerSyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self.ServerSync) -- Server Sync
	self:RequestTime()
end

function Time:OnLevelDestroy()
	self.m_ServerSyncEvent = NetEvents:Unsubscribe('TimeServer:Sync') -- Server Sync
	self:RemoveTime()
end

function Time:RequestTime()
	print('Request Time')
	NetEvents:Send('TimeServer:PlayerRequest')
end

function Time:RemoveTime()
	self:RegisterVars()
	self:ResetSunPosition()
	print("Reset Time System")
end

function Time:ServerSync(p_ServerDayTime, p_TotalServerTime)
	if p_ServerDayTime == nil or p_TotalServerTime == nil then
		return

	elseif self.m_SystemRunning == true then
		--print('Server Sync:' .. 'Current Time: ' .. p_ServerDayTime .. ' | ' .. 'Total Time:' .. p_TotalServerTime)
		self.m_ClientTime = p_ServerDayTime
		self.m_TotalClientTime = p_TotalServerTime
		self:Run()
	end
end

function Time:AddTimeToClient(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds) -- Add Time System to Map | To be called on Level:Loaded | time in 24hr format (0-23)
	self.m_IsStatic = p_IsStatic
	self:Add(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds)
end

function Time:UpdateSunPosition(p_ClientTime) -- for smoother sun relative to time
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
	--else
	--	print("Faulty ClientTime: " .. p_ClientTime)
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

function Time:SetCloudSpeed()
	if VEM_CONFIG.DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH then
		self.m_CloudSpeed = 1 / (self.m_TotalDayLength / 60 * 0.5)
		print('Set Cloud Speed = ' .. tostring(self.m_CloudSpeed))
	end
end

function Time:ResetSunPosition()
	VisualEnvironmentManager:SetSunRotationX(0)
	VisualEnvironmentManager:SetSunRotationY(70)
end

function Time:PauseContinue(p_SystemRunning)
	self.m_SystemRunning = p_SystemRunning
end

function Time:Disable()
	-- Check if presets exist
	if #self.m_CurrentPresetTable < 1 then
		return
	end

	-- Disable time system if running
	self.m_SystemRunning = false

	-- Hide Presets
	for l_ID, l_Value in pairs(self.m_CurrentPresetTable) do
		g_VEManagerClient:SetVisibility(l_ID, 0)
	end
end

-- ADD TIME TO MAP
-- Add(Map name, starting hour (24h), day length (min))
function Time:Add(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds)
	if self.m_SystemRunning or self.m_FirstRun then
		self:RegisterVars()
	end

	local s_Types = {'Dynamic', 'DefaultDynamic'}
	print("Searching for dynamic presets:")

	for _, l_type in pairs(s_Types) do
		-- Get all dynamic presets
		-- (if no Dynamic presets, DefaultDynamic presets will be loaded)
		if #self.m_SortedDynamicPresetsTable < 2 then
			for l_ID, l_Preset in pairs(g_VEManagerClient.m_Presets) do
				local s_SkyBrightness = tonumber(g_VEManagerClient.m_RawPresets[l_ID].Sky.BrightnessScale)
				local s_SunRotationY = tonumber(g_VEManagerClient.m_RawPresets[l_ID].OutdoorLight.SunRotationY)
				
				if g_VEManagerClient.m_Presets[l_ID].type == l_type and s_SunRotationY ~= nil then
					-- Check if night mode (moon enabled)
					if s_SkyBrightness ~= nil and s_SkyBrightness < 0.01 then
						s_SunRotationY = 360 - s_SunRotationY
					end

					print(" - " .. tostring(l_ID) .. " (sun: " .. tostring(s_SunRotationY) .. ")")
					
					table.insert(self.m_SortedDynamicPresetsTable, {l_ID, s_SunRotationY})
				end
			end
		end
	end
	
	-- Table Sort
	table.sort(self.m_SortedDynamicPresetsTable, function(a,b) return tonumber(a[2]) < tonumber(b[2]) end)

	-- Set Priorities
	print("Found dynamic presets:")
	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]
		g_VEManagerClient.m_Presets[s_ID]["ve"].priority = l_Index + 10
		
		-- Patch Sun Positions
		for l_Index, l_Class in pairs(g_VEManagerClient.m_Presets[s_ID]["ve"].components) do
			if l_Class.typeInfo.name == "OutdoorLightComponentData"  then
				local s_Class =  _G[l_Class.typeInfo.name]()
				s_Class:MakeWritable()
				-- They need to be reverted to 0
				s_Class.sunRotationX = 0.0
				s_Class.sunRotationY = 0.0

				g_VEManagerClient.m_Presets[s_ID]["ve"].components[l_Index] = s_Class
			end
		end

		local s_SunRotationY = l_Preset[2]
		print(" - " .. tostring(s_ID) .. " (sun: " .. tostring(s_SunRotationY) .. ")")
	end

	-- Save dayLength in Class (minutes -> seconds)
	self.m_TotalDayLength = p_LengthOfDayInSeconds
	print('[Time-Client]: Length of Day: ' .. self.m_TotalDayLength .. ' Seconds')
	self.m_ClientTime = p_StartingTime
	print('[Time-Client]: Starting at Time: ' .. p_StartingTime / 3600 / (self.m_TotalDayLength / 86000) .. ' Hours ('.. p_StartingTime ..' Seconds)')

	-- Update sun & clouds
	self:UpdateSunPosition(self.m_ClientTime)
	self:SetCloudSpeed()
	
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
	
	-- Initialise
	self.m_FirstRun = true
	self:Run()

	if p_IsStatic ~= true then
		self.m_SystemRunning = true
		print("Time System Activated")
	end

end

-- ALSO LOOP THIS CODE PLEASE
function Time:Run()
	if self.m_SystemRunning ~= true and not self.m_FirstRun then
		--print("System Running: " .. tostring(self.m_SystemRunning))
		return
	end

	if self.m_ClientTime == nil then
		print("Nil ClientTime: " .. self.m_ClientTime)
		return
	end

	local s_print_enabled = false -- TODO: change syntax
	local s_h_time = MathUtils:Round(self.m_ClientTime / self.m_TotalDayLength * 24)

	if s_h_time ~= self.m_LastPrintHours  then
		s_print_enabled = true
		self.m_LastPrintHours = s_h_time
	end

	self:UpdateSunPosition(self.m_ClientTime)

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
	if s_NextPresetSunPosY < s_CurrentPresetSunPosY then -- fix when next preset on next day
		s_NextPresetSunPosY = 360 + s_NextPresetSunPosY
	end

	-- Check if still in curent presets
	if s_SunMoonPos >= s_NextPresetSunPosY then
		self.m_CurrentPreset = s_NextPreset
		s_CurrentPresetSunPosY = self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2]

		s_NextPreset = self.m_CurrentPreset % #self.m_SortedDynamicPresetsTable + 1
		s_NextPresetSunPosY = self.m_SortedDynamicPresetsTable[s_NextPreset][2]
		if s_NextPresetSunPosY < s_CurrentPresetSunPosY then -- fix when next preset on next day
			s_NextPresetSunPosY = 360 + s_NextPresetSunPosY
		end
	end

	--print("Current preset: " .. tostring(self.m_CurrentPreset))
	--print("Next preset: " .. tostring(s_NextPreset))

	-- Calculate visibility fade factor
	local s_VisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY)  / (s_NextPresetSunPosY - s_CurrentPresetSunPosY)
	--[[if s_VisibilityFactor > 1 then -- Safe check -- TODO: Remove. It should work correctly without this
		s_VisibilityFactor = 1
	end]]
	local s_NextPresetVisibilityFactor = nil
	local s_CurrentPresetVisibilityFactor = nil -- Current preset

	if s_NextPreset ~= 1 then
		s_NextPresetVisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY)  / (s_NextPresetSunPosY - s_CurrentPresetSunPosY)
		--								330 or 10    - 310                      /      20              -  310
		s_CurrentPresetVisibilityFactor = 1.0
	else -- Invert visibilities because next preset's priority is less than previous preset's priority
		s_NextPresetVisibilityFactor = 1.0
		s_CurrentPresetVisibilityFactor = (s_SunMoonPos - s_CurrentPresetSunPosY)  / (s_NextPresetSunPosY - s_CurrentPresetSunPosY)
	end

	print("Sun/Moon: " .. tostring(s_SunMoonPos) .. ", visibility: " .. tostring(s_VisibilityFactor))
	--print("Visibility Factor: " .. tostring(s_VisibilityFactor))

	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]
		--print("Preset ID: " .. tostring(s_ID))
		local s_Factor = 0
		if l_Index == self.m_CurrentPreset then
			s_Factor = s_CurrentPresetVisibilityFactor
		elseif l_Index == s_NextPreset then
			s_Factor = s_NextPresetVisibilityFactor
		end
		
		if self.m_FirstRun then
			--print(s_Factor)
			g_VEManagerClient:SetVisibility(s_ID, s_Factor)
		else
			g_VEManagerClient:UpdateVisibility(s_ID, l_Index + 10, s_Factor)
			if s_Factor ~= 0 then -- TODO: CHeck if cloud speed works
				g_VEManagerClient:SetSingleValue(s_ID, l_Index + 10, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
			end
		end
	end
	
	if self.m_FirstRun then
		self.m_FirstRun = false
	end

	--[[
	s_FactorNight = MathUtils:Clamp(self.m_SunPosY, 0, 1)
	s_FactorMorning = MathUtils:Clamp(s_FactorMorning, 0, 1)
	s_FactorNoon = MathUtils:Clamp(s_FactorNoon, 0, 1)
	s_FactorEvening = MathUtils:Clamp(s_FactorEvening, 0, 1)

	if s_print_enabled and VEM_CONFIG.PRINT_DN_TIME_AND_VISIBILITIES then
		print("Visibilities (Night, Morning, Noon, Evening): " .. MathUtils:Round(s_FactorNight*100) .. "%, " .. MathUtils:Round(s_FactorMorning*100) .. "%, " .. MathUtils:Round(s_FactorNoon*100) .. "%, " .. MathUtils:Round(s_FactorEvening*100) .. "% | Current time: " .. s_h_time .. "h")
		--print("Time Till Switch: " .. MathUtils:Round(s_timeToChange) .. "sec")
	end

	-- Apply visibility factor
	if self.m_FirstRun then
		g_VEManagerClient:SetVisibility(self.m_CurrentNightPreset, s_FactorNight)
		g_VEManagerClient:SetVisibility(self.m_CurrentMorningPreset, s_FactorMorning)
		g_VEManagerClient:SetVisibility(self.m_CurrentNoonPreset, s_FactorNoon)
		g_VEManagerClient:SetVisibility(self.m_CurrentEveningPreset, s_FactorEvening)
		self.m_FirstRun = false
	else
		g_VEManagerClient:UpdateVisibility(self.m_CurrentNightPreset, self.m_NightPriority, s_FactorNight)
		g_VEManagerClient:UpdateVisibility(self.m_CurrentMorningPreset, self.m_MorningPriority, s_FactorMorning)
		g_VEManagerClient:UpdateVisibility(self.m_CurrentNoonPreset, self.m_NoonPriority, s_FactorNoon)
		g_VEManagerClient:UpdateVisibility(self.m_CurrentEveningPreset, self.m_EveningPriority, s_FactorEvening)
		g_VEManagerClient:SetSingleValue(self.m_CurrentNightPreset, self.m_NightPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		g_VEManagerClient:SetSingleValue(self.m_CurrentMorningPreset, self.m_MorningPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		g_VEManagerClient:SetSingleValue(self.m_CurrentNoonPreset, self.m_NoonPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		g_VEManagerClient:SetSingleValue(self.m_CurrentEveningPreset, self.m_EveningPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
	end
	]]

end

-- Singleton.
if g_Time == nil then
	g_Time = Time()
end

return g_Time
