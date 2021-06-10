local Time = class('Time')
local Patches = require('modules/patches')


function Time:__init()
    print('Initializing Time Module')
    self:RegisterVars()
    self:RegisterEvents()
end


function Time:RegisterVars()
    self.m_systemActive = false
    self.m_IsStatic = nil
    self.m_clientTime = 0
    self.m_totalClientTime = 0
    self.m_totalDayLength = 0
    self.m_originalSunX = nil
    self.m_originalSunY = nil
    self.m_nightPriority = 100005
    self.m_morningPriority = 100010
    self.m_noonPriority = 100015
    self.m_eveningPriority = 100020
    self.m_mapPresets = {}
self.m_presetTimings = {0.225, 0.30, 0.4, 0.75, 0.875} --Always need to have the end time of the last preset in a day at the end
    self.m_currentPresetTimingIndex = 1
end


function Time:RegisterEvents()
    self.m_partitionLoadedEvent = Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoad)
    self.m_serverSyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self.ServerSync) -- Server Sync
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
    self.m_levelLoadEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoad)
    self.m_levelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
    self.m_AddTimeToClientEvent = NetEvents:Subscribe('VEManager:AddTimeToClient', self, self.AddTimeToClient)
	self.m_RemoveTimeEvent = Events:Subscribe('VEManager:RemoveTime', self, self.RemoveTime)
    self.m_PauseContinueEvent = NetEvents:Subscribe('TimeServer:Pause', self, self.PauseContinue)
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


function Time:OnLevelLoad()
    self:__init()
    self:RequestTime()
end


function Time:OnLevelDestroy()
    if self.m_IsStatic ~= nil then
        self:RemoveTime()
    end
end


function Time:ServerSync(p_ServerDayTime, p_TotalServerTime)
    if self.m_clientTime ~= p_ServerDayTime then
        --print('Server Sync:' .. 'Current Time: ' .. p_ServerDayTime .. ' | ' .. 'Total Time:' .. p_TotalServerTime)
        self.m_clientTime = p_ServerDayTime
        self.m_totalClientTime = p_TotalServerTime
    end
end


function Time:RequestTime()
    NetEvents:Send('TimeServer:PlayerRequest')
end


function Time:AddTimeToClient(p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds, p_ServerUpdateFrequency) -- Add Time System to Map | To be called on Level:Loaded | time in 24hr format (0-23)
	local s_CurrentMap = SharedUtils:GetLevelName()
    self.m_IsStatic = p_IsStatic
	self:Add(s_CurrentMap, p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds, p_ServerUpdateFrequency)
end


function Time:SetSunPosition(p_CurrentTime) -- for smoother sun relative to time
    local factor = ( p_CurrentTime / self.m_totalDayLength )
    --print("Sun Pos Y: " .. ( -90 + ( 360 * factor )))
    VisualEnvironmentManager:SetSunRotationX(260)
    VisualEnvironmentManager:SetSunRotationY( -90 + ( 360 * factor ))
end


function Time:ResetSunPosition()
    VisualEnvironmentManager:SetSunRotationX(0)
    VisualEnvironmentManager:SetSunRotationY(70)
end


function Time:CallPauseContinue()
    NetEvents:Send('TimeServer:CallPauseContinue')
end


function Time:PauseContinue(p_Pause)
    if p_Pause == true then
        self.m_SystemRunning = false
    elseif p_Pause == false then
        self.m_SystemRunning = true
    else
        error('Failed to receive Pause Bool')
    end
end


function Time:RemoveTime()
    self.m_engineUpdateEvent:Unsubscribe()
    self.m_systemActive = false
    g_VEManagerClient:DisablePreset(self.m_currentNightPreset)
    g_VEManagerClient:DisablePreset(self.m_currentMorningPreset)
    g_VEManagerClient:DisablePreset(self.m_currentNoonPreset)
    g_VEManagerClient:DisablePreset(self.m_currentEveningPreset)
    self:ResetSunPosition()
    self:RegisterVars()
    print("Removed Time System")
end


-- ADD TIME TO MAP
-- Add(Map name, starting hour (24h), day length (min), static time = true/false, server update frequency)
function Time:Add(p_MapName, p_StartingTime, p_IsStatic, p_LengthOfDayInSeconds, p_ServerUpdateFrequency)
    if self.m_systemActive == true then
        self:RegisterVars()
    end

    -- get all presets associated with map and remove unused textures
    for id, s_Preset in pairs(g_VEManagerClient.m_Presets) do

        if g_VEManagerClient.m_Presets[id].type == 'Night' then
            self.m_currentNightPreset = id
        elseif g_VEManagerClient.m_Presets[id].type == 'Morning' then
            self.m_currentMorningPreset = id
        elseif g_VEManagerClient.m_Presets[id].type == 'Noon' then
            self.m_currentNoonPreset = id
        elseif g_VEManagerClient.m_Presets[id].type == 'Evening' then
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

	--[[
    -- Set Default to Nope
    local s_States = VisualEnvironmentManager:GetStates()

    for _, state in pairs(s_States) do
        if state.entityName ~= "EffectEntity" then
            state.visibility = 1
            print('Set Default to Prio 1')
        end
    end
	]]

    -- save dayLength in Class (minutes -> seconds)
    self.m_totalDayLength = p_LengthOfDayInSeconds
    print('[Time-Client]: Length of Day: ' .. self.m_totalDayLength .. ' Seconds')
    self.m_clientTime = p_StartingTime
    print('[Time-Client]: Starting at Time: ' .. p_StartingTime .. ' Hours ('.. p_StartingTime * 3600 ..' Seconds)')


	-- Set Priorities
	g_VEManagerClient.m_Presets[self.m_currentNightPreset]["ve"].priority = self.m_nightPriority
	g_VEManagerClient.m_Presets[self.m_currentMorningPreset]["ve"].priority = self.m_morningPriority
	g_VEManagerClient.m_Presets[self.m_currentNoonPreset]["ve"].priority = self.m_noonPriority
	g_VEManagerClient.m_Presets[self.m_currentEveningPreset]["ve"].priority = self.m_eveningPriority


    --PLEASE LOOP THIS CODE
    -- calculate visibilities and presets
    if self.m_clientTime < self.m_totalDayLength * self.m_presetTimings[1] or self.m_clientTime > self.m_presetTimings[#self.m_presetTimings] * self.m_totalDayLength then -- 00:00 to 6:00 or 21:00 to 00:00
        -- set visibility preset night
        local s_factorNight = 1
        local s_factorMorning = 0

        print("Night Visibility: " .. s_factorNight)

        -- apply visibility factor
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, 0)
    elseif self.m_clientTime <= self.m_totalDayLength * self.m_presetTimings[2] then -- 6:00 to 9:00
        -- calculate visibility preset morning
        local s_factorMorning = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[2] )) / ( self.m_totalDayLength * ( self.m_presetTimings[2] - self.m_presetTimings[1] )) --todo change these multiplication values to variables later to calculate automatically
        -- calculate visibility preset night
        local s_factorNight = 1

        print("Night Visibility: " .. s_factorNight)
        print("Morning Visibility: " .. s_factorMorning)

        -- update visibility
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, 0)
    elseif self.m_clientTime <= self.m_totalDayLength * 0.5 then -- 9:00 to 12:00
        -- calculate visibility preset noon
        local s_factorNoon = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[2] )) / ( self.m_totalDayLength * ( self.m_presetTimings[3] - self.m_presetTimings[2] ))
        -- calculate visibility preset morning
        local s_factorMorning = 1

        print("Morning Visibility: " .. s_factorMorning)
        print("Noon Visibility: " .. s_factorNoon)

        -- update visibility
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, 0)
    elseif self.m_clientTime <= self.m_totalDayLength * self.m_presetTimings[4] then -- 12:00 to 18:00
        -- calculate visibility preset evening
        local s_factorEvening = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[3] )) / ( self.m_totalDayLength * ( self.m_presetTimings[4] - self.m_presetTimings[3] ))
        -- calculate visibility preset noon
        local s_factorNoon = 1

        print("Noon Visibility: " .. s_factorNoon)
        print("Evening Visibility: " .. s_factorEvening)

        -- update visibility
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)
    elseif self.m_clientTime <= self.m_totalDayLength * self.m_presetTimings[5] then -- 18:00 to 21:00
		-- Night preset has a lower visibility, thus we change evening visibility back to 0

        -- calculate visibility preset night
        local s_factorNight = 1
        -- calculate visibility preset evening
        local s_factorEvening = 1 - ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[4] )) / ( self.m_totalDayLength * ( 1 - self.m_presetTimings[5] ))

        print("Evening Visibility: " .. s_factorEvening)
        print("Night Visibility: " .. s_factorNight)

        -- update visibility
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, 0)
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)
    else
        error("Critical Time System Error")
    end

    if p_IsStatic ~= true then
        self.m_systemActive = true
        print("Time System Activated")
    end

    self:SetSunPosition(self.m_clientTime)

end

local last_print_h = -1
--ALSO LOOP THIS CODE PLEASE
function Time:Run(deltaTime)

    if self.m_systemActive ~= true then
        return
    end

    -- start counter
    --self.m_clientTime = ( self.m_clientTime + deltaTime )
	if self.m_clientTime > self.m_totalDayLength then
		self.m_clientTime =  self.m_clientTime - self.m_totalDayLength -- reset day
	end

    --self.m_totalClientTime = ( self.m_totalClientTime + deltaTime )

	local s_print_enabled = false
	local s_h_time = self.m_clientTime / ( self.m_totalDayLength / 24 )
	if s_h_time - last_print_h >= 1 then
		s_print_enabled = true
		last_print_h = s_h_time
	end

	if s_print_enabled then
        print("Current Time: " .. s_h_time .. " Hours.")
	end

    if self.m_clientTime < self.m_totalDayLength * self.m_presetTimings[1] or self.m_clientTime > self.m_presetTimings[#self.m_presetTimings] * self.m_totalDayLength then -- 00:00 to 6:00 or 21:00 to 00:00

        -- set visibility preset night
        local s_factorNight = 1

		if s_print_enabled then
			print("Night Visibility: " .. s_factorNight)
			if self.m_clientTime < self.m_presetTimings[1] * self.m_totalDayLength then
				print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[1] - self.m_clientTime))
			end
		end

        -- apply visibility factor
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, 0)

    elseif self.m_clientTime < self.m_totalDayLength * self.m_presetTimings[2] then -- 6:00 to 9:00

        -- calculate visibility preset morning
        local s_factorMorning = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[1] )) / ( self.m_totalDayLength * ( self.m_presetTimings[2] - self.m_presetTimings[1] )) --todo change these multiplication values to variables later to calculate automatically
        -- calculate visibility preset night
        local s_factorNight = 1

		if s_print_enabled then
			print("Night Visibility: " .. s_factorNight)
			print("Morning Visibility: " .. s_factorMorning)
			print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[2] - self.m_clientTime))
		end
        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, s_factorMorning)
        g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, 0)

    elseif self.m_clientTime < ( self.m_totalDayLength * self.m_presetTimings[3] ) then -- 9:00 to 12:00

        -- calculate visibility preset noon
        local s_factorNoon = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[2] )) / ( self.m_totalDayLength * ( self.m_presetTimings[3] - self.m_presetTimings[2] ))
        -- calculate visibility preset morning
        local s_factorMorning = 1

		if s_print_enabled then
    	    print("Morning Visibility: " .. s_factorMorning)
			print("Noon Visibility: " .. s_factorNoon)
			print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[3] - self.m_clientTime))
		end

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, s_factorMorning)
        g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, s_factorNoon)
        g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, 0)


    elseif self.m_clientTime < ( self.m_totalDayLength * self.m_presetTimings[4] ) then -- 12:00 to 18:00

        -- calculate visibility preset evening
        local s_factorEvening = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[3] )) / ( self.m_totalDayLength * ( self.m_presetTimings[4] - self.m_presetTimings[3] ))
        -- calculate visibility preset noon
        local s_factorNoon = 1

		if s_print_enabled then
			print("Noon Visibility: " .. s_factorNoon)
			print("Evening Visibility: " .. s_factorEvening)
			print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[4] - self.m_clientTime))
		end

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, s_factorNoon)
        g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, s_factorEvening)


    elseif self.m_clientTime < ( self.m_totalDayLength * self.m_presetTimings[5] ) then -- 18:00 to 21:00
		-- Night preset has a lower visibility, thus we change evening visibility back to 0
        -- calculate visibility preset night
        local s_factorNight = 1
        -- calculate visibility preset evening
        local s_factorEvening = 1 - ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[4] )) / ( self.m_totalDayLength * ( self.m_presetTimings[5] - self.m_presetTimings[4] ))

		if s_print_enabled then
			print("Evening Visibility: " .. s_factorEvening)
			print("Night Visibility: " .. s_factorNight)
			print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[5] - self.m_clientTime))
		end

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, 0)
        g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, s_factorEvening)

    else
		print('What?')
    end

    self:SetSunPosition(self.m_clientTime)

end


return Time
