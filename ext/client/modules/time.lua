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
	self.m_totalClientTime = 0
	self.m_totalDayLength = 0
	self.m_originalSunX = nil
	self.m_originalSunY = nil
	self.m_mapPresets = {}
	self.m_nightPriority = 11
	self.m_morningPriority = 12
	self.m_noonPriority = 13
	self.m_eveningPriority = 14
	self.m_currentNightPreset = nil
	self.m_currentMorningPreset = nil
	self.m_currentNoonPreset = nil
	self.m_currentEveningPreset = nil
	self.m_LastPrintHours = -1
	self.m_FirstRun = false

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

function Time:OnPartitionLoad(partition)
	Patches:Components(partition)

	if partition.guid == Guid('6E5D35D9-D9D5-11DE-ADB5-9D4DBC23632A') then
		for _, instance in pairs(partition.instances) do
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
		self.m_totalClientTime = p_TotalServerTime
		self:Run()
	end
end

function Time:AddTimeToClient(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds) -- Add Time System to Map | To be called on Level:Loaded | time in 24hr format (0-23)
	self.m_IsStatic = p_IsStatic
	self:Add(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds)
end

function Time:SetSunPosition(p_ClientTime) -- for smoother sun relative to time
	local s_Factor = p_ClientTime / self.m_totalDayLength
	s_Factor = MathUtils:Clamp(s_Factor, 0, 1)
	local s_DaylightValue = 360 * (s_Factor / VEM_CONFIG.DN_SUN_TIMINGS[2])
	local s_SunOffset = -360 * VEM_CONFIG.DN_SUN_TIMINGS[1]
	local s_MoonX = 200 * s_Factor / 1

	local s_SunPosX = 275
	local s_SunPosY = 0
	if s_Factor <= VEM_CONFIG.DN_SUN_TIMINGS[1] and s_Factor > VEM_CONFIG.DN_SUN_TIMINGS[3] then
		s_SunPosY = s_SunOffset + s_DaylightValue
	elseif s_Factor <= VEM_CONFIG.DN_SUN_TIMINGS[2] then
		s_SunPosY = s_SunOffset + s_DaylightValue
	elseif s_Factor >= VEM_CONFIG.DN_SUN_TIMINGS[2] then
		s_SunPosX = s_MoonX
		s_SunPosY = 35 
	elseif s_Factor <= VEM_CONFIG.DN_SUN_TIMINGS[3] then
		s_SunPosX = s_MoonX
		s_SunPosY = 35 
	else
		print("Faulty ClientTime: " .. p_ClientTime)
	end

	s_SunPosY = MathUtils:Round(s_SunPosY * 100) / 100
	s_SunPosY = MathUtils:Clamp(s_SunPosY, 0, 180)
	VisualEnvironmentManager:SetSunRotationX(s_SunPosX)
	VisualEnvironmentManager:SetSunRotationY(s_SunPosY)
	VisualEnvironmentManager:SetDirty(true)
	return s_SunPosX, s_SunPosY
end

function Time:SetCloudSpeed()
	if VEM_CONFIG.DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH then
		self.m_CloudSpeed = 1 / (self.m_totalDayLength / 60 * 0.5)
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
	if self.m_currentNightPreset == nil or
		self.m_currentMorningPreset == nil or
		self.m_currentNoonPreset == nil or
		self.m_currentEveningPreset == nil then
		return
	end

	-- Disable time system if running
	self.m_SystemRunning = false

	-- Hide Presets
	g_VEManagerClient:SetVisibility(self.m_currentNightPreset, 0)
	g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, 0)
	g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, 0)
	g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, 0)
end

-- ADD TIME TO MAP
-- Add(Map name, starting hour (24h), day length (min))
function Time:Add(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds)
	if self.m_SystemRunning == true or self.m_FirstRun == true then
		self:RegisterVars()
	end

	-- Get all dynamic presets (TODO: associated with map)
	for id, s_Preset in pairs(g_VEManagerClient.m_Presets) do

		if g_VEManagerClient.m_Presets[id].type == 'Night' or
		(g_VEManagerClient.m_Presets[id].type == 'DefaultNight' and self.m_currentNightPreset == nil) then
			self.m_currentNightPreset = id

		elseif g_VEManagerClient.m_Presets[id].type == 'Morning' or
		(g_VEManagerClient.m_Presets[id].type == 'DefaultMorning' and self.m_currentMorningPreset == nil) then
			self.m_currentMorningPreset = id

		elseif g_VEManagerClient.m_Presets[id].type == 'Noon' or
		(g_VEManagerClient.m_Presets[id].type == 'DefaultNoon' and self.m_currentNoonPreset == nil) then
			self.m_currentNoonPreset = id

		elseif g_VEManagerClient.m_Presets[id].type == 'Evening' or
		(g_VEManagerClient.m_Presets[id].type == 'DefaultEvening' and self.m_currentEveningPreset == nil) then
			self.m_currentEveningPreset = id
		end
	end

	if self.m_currentNightPreset == nil or
		self.m_currentMorningPreset == nil or
		self.m_currentNoonPreset == nil or
		self.m_currentEveningPreset == nil then
		print('Failed to Load Presets for Time')
		return
	end

	-- Save dayLength in Class (minutes -> seconds)
	self.m_totalDayLength = p_LengthOfDayInSeconds
	print('[Time-Client]: Length of Day: ' .. self.m_totalDayLength .. ' Seconds')
	self.m_ClientTime = p_StartingTime
	print('[Time-Client]: Starting at Time: ' .. p_StartingTime / 3600 / (self.m_totalDayLength / 86000) .. ' Hours ('.. p_StartingTime ..' Seconds)')

	-- Set Priorities
	g_VEManagerClient.m_Presets[self.m_currentNightPreset]["ve"].priority = self.m_nightPriority
	g_VEManagerClient.m_Presets[self.m_currentMorningPreset]["ve"].priority = self.m_morningPriority
	g_VEManagerClient.m_Presets[self.m_currentNoonPreset]["ve"].priority = self.m_noonPriority
	g_VEManagerClient.m_Presets[self.m_currentEveningPreset]["ve"].priority = self.m_eveningPriority

	self.m_FirstRun = true
	self:Run()

	if p_IsStatic ~= true then
		self.m_SystemRunning = true
		print("Time System Activated")
	end

	self:SetSunPosition(self.m_ClientTime)
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

	local s_print_enabled = false
	local s_h_time = MathUtils:Round(self.m_ClientTime / self.m_totalDayLength * 24)

	if s_h_time ~= self.m_LastPrintHours  then
		s_print_enabled = true
		self.m_LastPrintHours = s_h_time
	end

	-- Default visibility factors
	local s_FactorNight = 0
	local s_FactorMorning = 0
	local s_FactorNoon = 0
	local s_FactorEvening = 0
	local s_timeToChange = -1

	local s_SunPosX, s_SunPosY = self:SetSunPosition(self.m_ClientTime)

	if s_SunPosY == 0 or s_SunPosY == 180 then
		s_FactorNight = 1
		s_FactorEvening = 0
		--print('Factor Night: ' .. s_FactorNight)
		--print('Factor Evening: ' .. s_FactorEvening)
	elseif s_SunPosY <= 10 then
		s_FactorMorning = s_SunPosY / 10
		s_FactorNight = 1 - s_FactorMorning
		--print('Factor Morning: ' .. s_FactorMorning)
		--print('Factor Night: ' .. s_FactorNight)
	elseif s_SunPosY <= 15 then 
		s_FactorMorning = 1
	elseif s_SunPosY <= 25 then
		s_FactorNoon = (s_SunPosY - 15) / 10
		s_FactorMorning = 1 - s_FactorNoon
		--print('Factor Noon: ' .. s_FactorNoon)
		--print('Factor Morning: ' .. s_FactorMorning)
	elseif s_SunPosY <= 160 then
		s_FactorNoon = 1
	elseif s_SunPosY <= 170 then
		s_FactorEvening = (s_SunPosY - 160) / 10
		s_FactorNoon = 1 - s_FactorEvening
		--print('Factor Evening: ' .. s_FactorEvening)
		--print('Factor Noon: ' .. s_FactorNoon)
	elseif s_SunPosY <= 165 then
		s_FactorEvening = 1
	elseif s_SunPosY < 180 then
		s_FactorNight = (s_SunPosY - 165) / 15
		s_FactorEvening = 1 - s_FactorNight
		--print('Factor Night: ' .. s_FactorNight)
		--print('Factor Evening: ' .. s_FactorEvening)
	end

	s_FactorNight = MathUtils:Clamp(s_SunPosY, 0, 1)
	s_FactorMorning = MathUtils:Clamp(s_FactorMorning, 0, 1)
	s_FactorNoon = MathUtils:Clamp(s_FactorNoon, 0, 1)
	s_FactorEvening = MathUtils:Clamp(s_FactorEvening, 0, 1)

	if s_print_enabled and VEM_CONFIG.PRINT_DN_TIME_AND_VISIBILITIES then
		print("Visibilities (Night, Morning, Noon, Evening): " .. MathUtils:Round(s_FactorNight*100) .. "%, " .. MathUtils:Round(s_FactorMorning*100) .. "%, " .. MathUtils:Round(s_FactorNoon*100) .. "%, " .. MathUtils:Round(s_FactorEvening*100) .. "% | Current time: " .. s_h_time .. "h")
		--print("Time Till Switch: " .. MathUtils:Round(s_timeToChange) .. "sec")
	end

	-- Apply visibility factor
	if self.m_FirstRun then
		g_VEManagerClient:SetVisibility(self.m_currentNightPreset, s_FactorNight)
		g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_FactorMorning)
		g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_FactorNoon)
		g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_FactorEvening)
		self.m_FirstRun = false
	else
		g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_FactorNight)
		g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, s_FactorMorning)
		g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, s_FactorNoon)
		g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, s_FactorEvening)
		g_VEManagerClient:SetSingleValue(self.m_currentNightPreset, self.m_nightPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		g_VEManagerClient:SetSingleValue(self.m_currentMorningPreset, self.m_morningPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		g_VEManagerClient:SetSingleValue(self.m_currentNoonPreset, self.m_noonPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
		g_VEManagerClient:SetSingleValue(self.m_currentEveningPreset, self.m_eveningPriority, 'sky', 'cloudLayer1Speed', self.m_CloudSpeed)
	end

end

-- Singleton.
if g_Time == nil then
	g_Time = Time()
end

return g_Time
