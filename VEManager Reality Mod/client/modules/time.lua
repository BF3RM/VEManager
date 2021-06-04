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

    self.m_mapPresets = {}
end


function Time:RegisterEvents()
    self.m_partitionLoadedEvent = Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoad)
    self.m_serverSyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self.ServerSync) -- Server Sync
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
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


function Time:OnLevelDestroy()
    self.m_engineUpdateEvent:Unsubscribe()
end


function Time:ServerSync(serverDayTime, totalServerTime)
    self.m_clientTime = serverDayTime
    self.m_totalClientTime = totalServerTime
end


function Time:SetSunPosition(currentTime) -- for smoother sun
    local factor = ( currentTime / self.m_totalDayLength )
    --print("Sun Pos Y: " .. ( 180 * factor ) )
    VisualEnvironmentManager:SetSunRotationX( 0 )
    VisualEnvironmentManager:SetSunRotationY( 180 * factor )
end


-- ADD TIME TO MAP
function Time:Add(mapName, time, totalDayLength, isStatic, serverUpdateFrequency) -- time in 24hr [e.g 1600] format

    -- Set Default to Nope
    local s_States = VisualEnvironmentManager:GetStates()

    for _, state in pairs(s_States) do
        if state.entityName ~= "EffectEntity" then
            state.visibility = 0
            state.sky.panoramicUVMinX = 0
            state.sky.panoramicUVMaxX = 1
            state.sky.panoramicUVMinY = 0
            state.sky.panoramicUVMaxY = 0.5
            state.sky.panoramicTileFactor = 1.0
            state.sky.panoramicRotation = 260
            state.outdoorLight.sunColor = Vec3(1, 0.6, 0.21)
            state.outdoorLight.groundColor = Vec3(0.34, 0.24, 0.18)
            state.outdoorLight.skyColor = Vec3(0.38, 0.34, 0.21)
            state.outdoorLight.sunRotationX = 0
            state.outdoorLight.sunRotationY = 90
            state.priority = 1
            print('Set Default to NOPE')
        end
	end

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

    -- save dayLength in Class
    if totalDayLength == 1 then
        self.m_totalDayLength = 86000
    else
        self.m_totalDayLength = ( totalDayLength * 60 )
    end
    print("Length of Day: " .. self.m_totalDayLength)

    local s_startingTime = ( time * 3600 )
    self.m_clientTime = s_startingTime
    print("Starting at Time: " .. self.m_clientTime)

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

    elseif s_startingTime < ( self.m_totalDayLength * 0.5 ) then -- 6:00 to 12:00

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
    --print(self.m_clientTime)

    if self.m_clientTime <= ( self.m_totalDayLength * 0.25 ) then -- 00:00 to 6:00

        -- calculate visibility preset morning
        local s_factorMorning = ( self.m_clientTime / ( self.m_totalDayLength * 0.25 ) )
        -- calculate visibility preset night
        local s_factorNight = ( 1 - s_factorMorning )

        print("Night Visibility: " .. s_factorNight)
        print("Morning Visibility: " .. s_factorMorning)

        -- update visibility
        g_VEManagerClient:FadeTo(self.m_currentNightPreset, s_factorNight, deltaTime)
        g_VEManagerClient:FadeTo(self.m_currentMorningPreset, s_factorMorning, deltaTime)


    elseif self.m_clientTime < (self.m_totalDayLength * 0.5) then -- 06:00 to 12:00

        -- calculate visibility preset noon
        local s_factorNoon = ( self.m_clientTime / ( self.m_totalDayLength * 0.5 ) )
        -- calculate visibility preset morning
        local s_factorMorning = ( 1 - s_factorNoon )

        print("Morning Visibility: " .. s_factorMorning)
        print("Noon Visibility: " .. s_factorNoon)

        -- apply visibility factors
        g_VEManagerClient:FadeTo(self.m_currentMorningPreset, s_factorMorning, deltaTime)
        g_VEManagerClient:FadeTo(self.m_currentNoonPreset, s_factorNoon, deltaTime)

    elseif self.m_clientTime < (self.m_totalDayLength * 0.75) then -- 12:00 to 18:00

        -- calculate visibility preset noon
        local s_factorEvening = ( self.m_clientTime / ( self.m_totalDayLength * 0.75 ) )
        -- calculate visibility preset morning
        local s_factorNoon =  ( 1 - s_factorEvening )

        print("Noon Visibility: " .. s_factorNoon)
        print("Evening Visibility: " .. s_factorEvening)

        -- apply visibility factors
        g_VEManagerClient:FadeTo(self.m_currentNoonPreset, s_factorNoon, deltaTime)
        g_VEManagerClient:FadeTo(self.m_currentEveningPreset, s_factorEvening, deltaTime)

    elseif self.m_clientTime < self.m_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset noon
        local s_factorNight = ( self.m_clientTime / ( self.m_totalDayLength * 0.75 ) )
        -- calculate visibility preset morning
        local s_factorEvening =  ( 1 - s_factorNight )

        print("Evening Visibility: " .. s_factorEvening)
        print("Night Visibility: " .. s_factorNight)

        -- apply visibility factors
        g_VEManagerClient:FadeTo(self.m_currentEveningPreset, s_factorEvening, deltaTime)
        g_VEManagerClient:FadeTo(self.m_currentNightPreset, s_factorNight, deltaTime)

    elseif self.m_clientTime >= self.m_totalDayLength then

        self.m_clientTime = 0.0

    end


end


return Time