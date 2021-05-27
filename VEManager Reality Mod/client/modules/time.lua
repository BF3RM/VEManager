local Time = class 'Time'
local Settings = require the settings file if not existent => hard-code


function Time:__init()

    ClientTime:RegisterVars()
    ClientTime:GetVE()

end 


function Time:RegisterVars()

    self.m_transitionFactor = nil
    self.m_clientTime = 0 
    self.m_previousFactor = nil 
    
    self.m_mapPresets = {}

end 


function Time:RegisterEvents()

    self.m_serverSyncEvent = NetEvents:Subscribe(NetMessage.S2C_SYNC_DAYTIME, self, self.ServerSync) -- Server Sync
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.OnEngineUpdate)
    self.m_levelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)

end 


function Time:OnLevelDestroy()

    self.m_engineUpdateEvent:Unsubscribe()

end 


-- ADD TIME TO MAP

function Time:Add(mapName, time) -- time in 24hr format

    -- get all presets associated with map
    table.insert(self.m_mapPresets, #self.m_mapPresets + 1, VEManagerClient:GetMapPresets(mapName))

    -- convert time to seconds
    local s_startingTime = time * 60
    self.m_clientTime = s_startingTime

    -- calculate visibilities and presets

    if s_startingTime <= (g_totalDayLength * 0.25) then  -- 00:00 to 6:00

        -- calculate visibility preset night
        local s_factorNight = s_startingTime / (g_totalDayLength * 0.25)
        -- calculate visibility preset morning
        local s_factorMorning = 1 - s_factorNight 

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_mapPresets.type['night'], s_factorNight)
        VEManagerClient:SetVisibility(self.m_mapPresets.type['morning'], s_factorMorning)

    elseif s_startingTime < (g_totalDayLength * 0.5) then -- 6:00 to 12:00

        -- calculate visibility preset morning
        local s_factorMorning = s_startingTime / (g_totalDayLength * 0.5)
        -- calculate visibility preset noon
        local s_factorNoon = 1 - s_factorMorning

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_mapPresets.type['morning'], s_factorMorning)
        VEManagerClient:SetVisibility(self.m_mapPresets.type['noon'], s_factorNoon)

    elseif s_startingTime < (g_totalDayLength * 0.75) then -- 12:00 to 18:00

        -- calculate visibility preset morning
        local s_factorNoon = s_startingTime / (g_totalDayLength * 0.75)
        -- calculate visibility preset noon
        local s_factorEvening = 1 - s_factorNoon

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_mapPresets.type['noon'], s_factorNoon)
        VEManagerClient:SetVisibility(self.m_mapPresets.type['evening'], s_factorEvening)

    elseif s_startingTime <= g_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset morning
        local s_factorEvening = s_startingTime / (g_totalDayLength * 0.75)
        -- calculate visibility preset noon
        local s_factorNight = 1 - s_factorNoon

        -- apply visibility factors
        VEManagerClient:SetVisibility(self.m_mapPresets.type['evening'], s_factorEvening)
        VEManagerClient:SetVisibility(self.m_mapPresets.type['night'], s_factorNight)

    end 

    Time:RegisterEvents()

end 




function Time:OnEngineUpdate(s_deltaTime)

    -- start counter
    self.m_clientTime = self.m_clientTime + s_deltaTime


    if m_clientTime <= (g_totalDayLength * 0.25) then -- 00:00 to 6:00

        -- calculate visibility preset night
        local s_factorNight = m_clientTime / (g_totalDayLength * 0.25)
        -- calculate visibility preset morning
        local s_factorMorning = 1 - s_factorNight 

        -- update visibility
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['night'], s_factorNight)
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['morning'], s_factorMorning)

    elseif m_clientTime <= (g_totalDayLength * 0.5) then -- 06:00 to 12:00

        -- calculate visibility preset morning
        local s_factorMorning = m_clientTime / (g_totalDayLength * 0.5)
        -- calculate visibility preset noon
        local s_factorNoon = 1 - s_factorMorning

        -- apply visibility factors
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['morning'], s_factorMorning)
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['noon'], s_factorNoon)

    elseif m_clientTime < (g_totalDayLength * 0.75) then -- 12:00 to 18:00

        -- calculate visibility preset morning
        local s_factorNoon = m_clientTime / (g_totalDayLength * 0.75)
        -- calculate visibility preset noon
        local s_factorEvening = 1 - s_factorNoon

        -- apply visibility factors
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['noon'], s_factorNoon)
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['evening'], s_factorEvening)

    elseif m_clientTime < g_totalDayLength then -- 18:00 to 00:00

        -- calculate visibility preset morning
        local s_factorEvening = m_clientTime / (g_totalDayLength * 0.75)
        -- calculate visibility preset noon
        local s_factorNight = 1 - s_factorNoon

        -- apply visibility factors
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['evening'], s_factorEvening)
        VEManagerClient:UpdateVisibility(self.m_mapPresets.type['night'], s_factorNight)

    elseif m_clientTime >= g_totalDayLength then 

        m_clientTime = 0.0

    end 


end 


















totalDayLength = 86400 --[sec]
morningLength = totalDayLength / 4
dayTimeLength = totalDayLength / 4
eveningLength = totalDayLength / 4
nightLength = totalDayLength / 4








return Time