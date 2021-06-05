local Time = class('Time')


function Time:__init()

    print('Initializing Time Module')
    Time:RegisterVars()
    Time:RegisterEvents()

end


function Time:RegisterVars()
    self.m_transitionFactor = nil
    self.m_clientTime = 0
    self.m_totalClientTime = 0
    self.m_previousFactor = nil
    self.m_timeAdded = false
    self.m_OriginalSunX = nil
    self.m_OriginalSunY = nil

    self.m_mapPresets = {}
end


function Time:RegisterEvents()
    self.m_partitionLoadedEvent = Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoad)
    self.m_serverSyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self.ServerSync) -- Server Sync
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
    self.m_levelLoadEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoad)
    self.m_levelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
end


function Time:OnPartitionLoad(partition)
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
end


function Time:OnLevelDestroy()
    self.m_engineUpdateEvent:Unsubscribe()
end


function Time:ServerSync(serverDayTime, totalServerTime)
    self.m_clientTime = serverDayTime
    self.m_totalClientTime = totalServerTime
end


function Time:SetSunPosition(currentTime) -- for smoother sun relative to time
    local factor = ( currentTime / self.m_totalDayLength )
    --print("Sun Pos Y: " .. ( 180 * factor ) )
    VisualEnvironmentManager:SetSunRotationX( 0 )
    VisualEnvironmentManager:SetSunRotationY( 180 * factor )
end


function Time:ResetSunPosition()
    VisualEnvironmentManager:SetSunRotationX(self.m_OriginalSunX)
    VisualEnvironmentManager:SetSunRotationY(self.m_OriginalSunY)
end


function Time:Remove()

    self.m_systemActive = false
    g_VEManagerClient:SetVisibility(self.m_currentNightPreset, 0)
    g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, 0)
    g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, 0)
    g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, 0)

    g_VEManagerClient:DisablePreset(self.m_currentNightPreset)
    g_VEManagerClient:DisablePreset(self.m_currentMorningPreset)
    g_VEManagerClient:DisablePreset(self.m_currentNoonPreset)
    g_VEManagerClient:DisablePreset(self.m_currentEveningPreset)
    Time:ResetSunPosition()
    self:RegisterVars()
    print("Removed Time System")

end


-- ADD TIME TO MAP
function Time:Add(mapName, time, totalDayLength, isStatic, serverUpdateFrequency) -- time in 24hr [e.g 1600] format

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

    -- Set Default to Nope
    local s_States = VisualEnvironmentManager:GetStates()

    for _, state in pairs(s_States) do
        if state.entityName ~= "EffectEntity" then
            state.visibility = 1
            state.priority = 1
            self.m_OriginalSunX = state.outdoorLight.sunRotationX
            self.m_OriginalSunY = state.outdoorLight.sunRotationY
            print('Set Default to Prio 1')
        end
    end

    -- save dayLength in Class
    if totalDayLength == 1 then
        self.m_totalDayLength = 86000
    else
        self.m_totalDayLength = ( totalDayLength * 60 )
    end
    print("Length of Day: " .. self.m_totalDayLength .. " Seconds")

    local s_startingTime = ( time * 3600 )
    self.m_clientTime = s_startingTime
    print("Starting at Time: " .. self.m_clientTime .. " Seconds")

    self:SetSunPosition(self.m_clientTime)

    -- calculate visibilities and presets

    if s_startingTime <= ( self.m_totalDayLength * 0.25 ) then  -- 00:00 to 6:00

        -- calculate visibility preset morning
        local s_factorMorning = ( s_startingTime / ( self.m_totalDayLength * 0.25 ) )
        -- calculate visibility preset night
        local s_factorNight = ( 1 - s_factorMorning )

        print("Night Visibility: " .. s_factorNight)
        print("Morning Visibility: " .. s_factorMorning)

        -- apply visibility factors
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)

    elseif s_startingTime < ( self.m_totalDayLength * 0.5 ) then -- 6:00 to 12:00  --todo divide into morning/noon so night is from 0:00 to 6:00 at visibility1

        -- calculate visibility preset noon
        local s_factorNoon = ( s_startingTime / ( self.m_totalDayLength * 0.5 ) )
        -- calculate visibility preset morning
        local s_factorMorning = ( 1 - s_factorNoon )

        print("Morning Visibility: " .. s_factorMorning)
        print("Noon Visibility: " .. s_factorNoon)

        -- apply visibility factors
        g_VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)

    elseif s_startingTime < ( self.m_totalDayLength * 0.75 ) then -- 12:00 to 18:00

        -- calculate visibility preset noon
        local s_factorEvening = ( s_startingTime / ( self.m_totalDayLength * 0.75 ) )
        -- calculate visibility preset morning
        local s_factorNoon = ( 1 - s_factorEvening )

        print("Noon Visibility: " .. s_factorNoon)
        print("Evening Visibility: " .. s_factorEvening)

        -- apply visibility factors
        g_VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)

    elseif s_startingTime <= self.m_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset noon
        local s_factorNight = ( s_startingTime / self.m_totalDayLength )
        -- calculate visibility preset morning
        local s_factorEvening = ( 1 - s_factorNight )

        print("Evening Visibility: " .. s_factorEvening)
        print("Night Visibility: " .. s_factorNight)

        -- apply visibility factors
        g_VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)
        g_VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)

    end

    if isStatic ~= true then
        self.m_systemActive = true
        print("Time System Activated")
    end

end


function Time:Run(deltaTime)

    if self.m_systemActive ~= true then
        return
    end

    -- start counter
    self.m_clientTime = ( self.m_clientTime + deltaTime )
    self.m_totalClientTime = ( self.m_totalClientTime + deltaTime )
    self:SetSunPosition(self.m_clientTime)
    --print("Current Time: " .. self.m_clientTime)

    if self.m_clientTime <= ( self.m_totalDayLength * 0.25 ) then -- 00:00 to 6:00

        -- calculate visibility preset morning
        local s_factorMorning = ( self.m_clientTime / ( self.m_totalDayLength * 0.25 ) )
        -- calculate visibility preset night
        local s_factorNight = ( 1 - s_factorMorning )

        --print("Night Visibility: " .. s_factorNight)
        --print("Morning Visibility: " .. s_factorMorning)

        -- set Priorities
        g_VEManagerClient.m_Presets[self.m_currentNightPreset]["ve"].priority = 100000
        g_VEManagerClient.m_Presets[self.m_currentMorningPreset]["ve"].priority = 100001

        local s_FadeInPrio = g_VEManagerClient.m_Presets[self.m_currentMorningPreset]["ve"].priority
        local s_FadeOutPrio = g_VEManagerClient.m_Presets[self.m_currentNightPreset]["ve"].priority

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, s_FadeOutPrio, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, s_FadeInPrio, s_factorMorning)


    elseif self.m_clientTime < (self.m_totalDayLength * 0.5) then -- 06:00 to 12:00

        -- calculate visibility preset noon
        local s_factorNoon = ( self.m_clientTime / ( self.m_totalDayLength * 0.5 ) )
        -- calculate visibility preset morning
        local s_factorMorning = ( 1 - s_factorNoon )

        --print("Morning Visibility: " .. s_factorMorning)
        --print("Noon Visibility: " .. s_factorNoon)

        -- set Priorities
        g_VEManagerClient.m_Presets[self.m_currentMorningPreset]["ve"].priority = 100001
        g_VEManagerClient.m_Presets[self.m_currentNoonPreset]["ve"].priority = 100002

        local s_FadeInPrio = g_VEManagerClient.m_Presets[self.m_currentNoonPreset]["ve"].priority
        local s_FadeOutPrio = g_VEManagerClient.m_Presets[self.m_currentMorningPreset]["ve"].priority

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, s_FadeOutPrio, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, s_FadeInPrio, s_factorMorning)

    elseif self.m_clientTime < (self.m_totalDayLength * 0.75) then -- 12:00 to 18:00

        -- calculate visibility preset noon
        local s_factorEvening = ( self.m_clientTime / ( self.m_totalDayLength * 0.75 ) )
        -- calculate visibility preset morning
        local s_factorNoon =  ( 1 - s_factorEvening )

        --print("Noon Visibility: " .. s_factorNoon)
        --print("Evening Visibility: " .. s_factorEvening)

        -- set Priorities
        g_VEManagerClient.m_Presets[self.m_currentNoonPreset]["ve"].priority = 100002
        g_VEManagerClient.m_Presets[self.m_currentEveningPreset]["ve"].priority = 100003

        local s_FadeInPrio = g_VEManagerClient.m_Presets[self.m_currentEveningPreset]["ve"].priority
        local s_FadeOutPrio = g_VEManagerClient.m_Presets[self.m_currentNoonPreset]["ve"].priority

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, s_FadeOutPrio, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, s_FadeInPrio, s_factorMorning)

    elseif self.m_clientTime < self.m_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset noon
        local s_factorNight = ( self.m_clientTime / ( self.m_totalDayLength * 0.75 ) )
        -- calculate visibility preset morning
        local s_factorEvening =  ( 1 - s_factorNight )

        --print("Evening Visibility: " .. s_factorEvening)
        --print("Night Visibility: " .. s_factorNight)

        -- set Priorities
        g_VEManagerClient.m_Presets[self.m_currentEveningPreset]["ve"].priority = 100003
        g_VEManagerClient.m_Presets[self.m_currentNightPreset]["ve"].priority = 100001

        local s_FadeInPrio = g_VEManagerClient.m_Presets[self.m_currentNightPreset]["ve"].priority
        local s_FadeOutPrio = g_VEManagerClient.m_Presets[self.m_currentEveningPreset]["ve"].priority

        -- update visibility
        g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, s_FadeOutPrio, s_factorNight)
        g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, s_FadeInPrio, s_factorMorning)

    elseif self.m_clientTime >= self.m_totalDayLength then

        self.m_clientTime = 0.0

    end


end


return Time