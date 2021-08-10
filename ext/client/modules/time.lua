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

	if s_DayFactor >= VEM_CONFIG.DN_SUN_TIMINGS[3] then -- Moon
		local s_FactorNight = s_DayFactor  / 1
		s_SunPosY = 180 - s_FactorNight * 45
		self.m_IsDay = false
	elseif s_DayFactor >= VEM_CONFIG.DN_SUN_TIMINGS[3] and s_DayFactor <= VEM_CONFIG.DN_SUN_TIMINGS[1] then -- Moon
		local s_FactorNight = s_DayFactor  / VEM_CONFIG.DN_SUN_TIMINGS[1]
		s_SunPosY = 135 - s_FactorNight * 135
		self.m_IsDay = false
	elseif s_DayFactor >= VEM_CONFIG.DN_SUN_TIMINGS[1] and s_DayFactor <= VEM_CONFIG.DN_SUN_TIMINGS[2] then -- Day
		local s_FactorNight = (s_DayFactor - VEM_CONFIG.DN_SUN_TIMINGS[2]) / VEM_CONFIG.DN_SUN_TIMINGS[3]
		s_SunPosY = 180 * s_FactorNight
		self.m_IsDay = true
	else
		print("Faulty ClientTime: " .. p_ClientTime)
	end

	-- Avoid crashes
	s_SunPosY = MathUtils:Round(s_SunPosY * 100) / 100
	if s_SunPosY < 0 or s_SunPosY > 180 then
		return
	end

	-- Update class variables
	self.m_SunPosX = s_SunPosX
	self.m_SunPosY = s_SunPosY
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
	if self.m_SystemRunning == true or self.m_FirstRun == true then
		self:RegisterVars()
	end

	local s_Types = {'Dynamic', 'DefaultDynamic'}
	
	for _, l_type in pairs(s_Types) do
		-- Get all dynamic presets
		-- (if no Dynamic presets, DefaultDynamic presets will be loaded)
		if #self.m_SortedDynamicPresetsTable < 2 then
			for l_ID, l_Preset in pairs(g_VEManagerClient.m_Presets) do
				if g_VEManagerClient.m_Presets[l_ID].type == l_type then
					--print(g_VEManagerClient.m_RawPresets[l_ID].OutdoorLight.SunRotationY)
					table.insert(self.m_SortedDynamicPresetsTable, {l_ID, tonumber(g_VEManagerClient.m_RawPresets[l_ID].OutdoorLight.SunRotationY)})
				end
			end
		end
	end
	
	-- Table Sort
	table.sort(self.m_SortedDynamicPresetsTable, function(a,b) return tonumber(a[2]) < tonumber(b[2]) end)

	-- Set Priorities
	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]
		g_VEManagerClient.m_Presets[s_ID]["ve"].priority = l_Index + 10
	end

	-- Save dayLength in Class (minutes -> seconds)
	self.m_TotalDayLength = p_LengthOfDayInSeconds
	print('[Time-Client]: Length of Day: ' .. self.m_TotalDayLength .. ' Seconds')
	self.m_ClientTime = p_StartingTime
	print('[Time-Client]: Starting at Time: ' .. p_StartingTime / 3600 / (self.m_TotalDayLength / 86000) .. ' Hours ('.. p_StartingTime ..' Seconds)')


	self.m_FirstRun = true
	self:Run()

	if p_IsStatic ~= true then
		--self.m_SystemRunning = true
		print("Time System Activated")
	end

	self:UpdateSunPosition(self.m_ClientTime)
	VisualEnvironmentManager:SetSunRotationX(self.m_SunPosX)
	VisualEnvironmentManager:SetSunRotationY(self.m_SunPosY)
	self:SetCloudSpeed()
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
	local s_SunPosY = self.m_SunPosY
	if not self.m_IsDay then
		-- Night (180 - 360)
		s_SunPosY = 360 - s_SunPosY
	end
	
	-- Check if still in curent presets
	if self.m_CurrentPreset + 1 > #self.m_SortedDynamicPresetsTable then
		if s_SunPosY >= 360 then
			self.m_CurrentPreset = 1
		end
	else
		if s_SunPosY >= self.m_SortedDynamicPresetsTable[self.m_CurrentPreset+1][2] then
			self.m_CurrentPreset = self.m_CurrentPreset+1
		end
	end
	-- Calc next preset
	local s_NextPreset = self.m_CurrentPreset % #self.m_SortedDynamicPresetsTable + 1

	--local s_VisibilityFadeInID = self.m_SortedDynamicPresetsTable[s_NextPreset][1]
	--local s_VisibilityFadeOutID = self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][1]
	local s_VisibilityFactorFadeIn = nil
	if s_NextPreset == 1 then
		s_VisibilityFactorFadeIn = (s_SunPosY - self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2])  / (360 + self.m_SortedDynamicPresetsTable[s_NextPreset][2] - self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2])
	else
		s_VisibilityFactorFadeIn = (s_SunPosY - self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2])  / (self.m_SortedDynamicPresetsTable[s_NextPreset][2] - self.m_SortedDynamicPresetsTable[self.m_CurrentPreset][2])
	end
	if s_VisibilityFactorFadeIn > 1 then
		s_VisibilityFactorFadeIn = 1
	end

	local s_VisibilityFactorFadeOut = 1 - s_VisibilityFactorFadeIn

	print(s_VisibilityFactorFadeIn)
	print(s_VisibilityFactorFadeOut)

	for l_Index, l_Preset in ipairs(self.m_SortedDynamicPresetsTable) do
		local s_ID = l_Preset[1]
		print(s_ID)
		local s_Factor = 0
		if l_Index == self.m_CurrentPreset then
			if s_NextPreset == 1 then
				s_Factor = s_VisibilityFactorFadeOut
			else
				s_Factor = 1
			end
		elseif l_Index == s_NextPreset then
			if s_NextPreset == 1 then
				s_Factor = 1
			else
				s_Factor = s_VisibilityFactorFadeIn
			end
		end
		
		if self.m_FirstRun then
			print(s_Factor)
			g_VEManagerClient:SetVisibility(s_ID, s_Factor)
		else
			g_VEManagerClient:UpdateVisibility(s_ID, l_Index + 10, s_Factor)
			if s_Factor ~= 0 then
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