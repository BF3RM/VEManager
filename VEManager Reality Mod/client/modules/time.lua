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
    self.m_systemActive = false

    self.m_mapPresets = {}
    self.currentPreset = nil
    self.currentPresetFactor = 0.0
    self.targetPreset = nil
    self.targetPresetFactor = 0.0
end


function Time:RegisterEvents()

    self.m_serverSyncEvent = NetEvents:Subscribe('TimeServer:Sync', self, self.ServerSync) -- Server Sync
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
    self.m_levelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)

end


function Time:OnLevelDestroy()

    self.m_engineUpdateEvent:Unsubscribe()

end


function Time:ServerSync(serverDayTime, totalServerTime)

    self.m_clientTime = serverDayTime
    self.m_totalDayLength = totalServerTime

end


-- ADD TIME TO MAP

function Time:Add(mapName, time, totalDayLength, isStatic, serverUpdateFrequency) -- time in 24hr [e.g 1600] format

    if self.m_systemActive == true then
        self:RegisterVars()
    end

    -- get all presets associated with map
    table.insert(self.m_mapPresets, #self.m_mapPresets + 1, VEManagerClient:GetMapPresets(mapName))

    for id, s_Preset in pairs(self.m_mapPresets) do

        if s_Preset.Type == 'Night' then
            self.m_currentNightPreset = id
        elseif s_Preset.Type == 'Morning' then
            self.m_currentMorningPreset = id
        elseif s_Preset.Type == 'Noon' then
            self.m_currentNoonPreset = id
        elseif s_Preset.Type == 'Evening' then
            self.m_currentEveningPreset = id
        end

    end

    -- convert time to seconds
    local s_startingTime = ( time * 36 )
    self.m_clientTime = s_startingTime

    -- save dayLength in Class
    if totalDayLength == 1 then
        self.m_totalDayLength = 86000
    else
        self.m_totalDayLength = totalDayLength
    end

    -- calculate visibilities and presets

    if s_startingTime <= ( m_totalDayLength * 0.25 ) then  -- 00:00 to 6:00

        -- calculate visibility preset night
        local s_factorNight = ( 1 - s_factorMorning )
        -- calculate visibility preset morning
        local s_factorMorning = ( s_startingTime / ( m_totalDayLength * 0.25 ) )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)
        VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)

    elseif s_startingTime < ( m_totalDayLength * 0.5 ) then -- 6:00 to 12:00

        -- calculate visibility preset morning
        local s_factorMorning = ( 1 - s_factorNoon )
        -- calculate visibility preset noon
        local s_factorNoon = ( s_startingTime / ( m_totalDayLength * 0.5 ) )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)
        VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)

    elseif s_startingTime < ( m_totalDayLength * 0.75 ) then -- 12:00 to 18:00

        -- calculate visibility preset morning
        local s_factorNoon = ( 1 - s_factorEvening )
        -- calculate visibility preset noon
        local s_factorEvening = ( s_startingTime / ( m_totalDayLength * 0.75 ) )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)
        VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)

    elseif s_startingTime <= m_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset morning
        local s_factorEvening = ( 1 - s_factorNight )
        -- calculate visibility preset noon
        local s_factorNight = ( s_startingTime / m_totalDayLength )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)
        VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)

    end

    if isStatic ~= true then
        self.m_systemActive = true
    end

end


function Time:Run(s_deltaTime)

    if self.m_systemActive ~= true then
        return
    end

    -- start counter
    self.m_clientTime = ( self.m_clientTime + s_deltaTime )
    self.m_totalClientTime = ( self.m_totalClientTime + s_deltaTime )


    if m_clientTime <= ( m_totalDayLength * 0.25 ) then -- 00:00 to 6:00

        -- calculate visibility preset night
        local s_factorNight = ( 1 - s_factorMorning )
        -- calculate visibility preset morning
        local s_factorMorning = ( m_clientTime / ( m_totalDayLength * 0.25 ) )

        -- update visibility
        VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)
        VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)

    elseif m_clientTime <= (m_totalDayLength * 0.5) then -- 06:00 to 12:00

        -- calculate visibility preset morning
        local s_factorMorning = ( 1 - s_factorNoon )
        -- calculate visibility preset noon
        local s_factorNoon = ( m_clientTime / ( m_totalDayLength * 0.5 ) )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentMorningPreset, s_factorMorning)
        VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)

    elseif m_clientTime <= (m_totalDayLength * 0.75) then -- 12:00 to 18:00

        -- calculate visibility preset morning
        local s_factorNoon =  ( 1 - s_factorEvening )
        -- calculate visibility preset noon
        local s_factorEvening = ( m_clientTime / ( m_totalDayLength * 0.75 ) )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentNoonPreset, s_factorNoon)
        VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)

    elseif m_clientTime <= m_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset morning
        local s_factorEvening =  ( 1 - s_factorNight )
        -- calculate visibility preset noon
        local s_factorNight = ( m_clientTime / ( m_totalDayLength * 0.75 ) )

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_currentEveningPreset, s_factorEvening)
        VEManagerClient:SetVisibility(self.m_currentNightPreset, s_factorNight)

    elseif m_clientTime >= m_totalDayLength then

        m_clientTime = 0.0

    end


end



return Time