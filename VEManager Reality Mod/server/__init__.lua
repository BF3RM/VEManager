local TimeServer = class('TimeServer')


function TimeServer:__init()

    print('Initializing Time Server')
    self.RegisterVars()

end


function TimeServer:RegisterVars()

    self.m_serverDayTime = 0.0
    self.m_engineUpdateTimer = 0.0

end


function TimeServer:RegisterEvents()

    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)

end


function TimeServer:CalculateStart(time) -- time in 24hr format

    -- convert time to seconds
    local s_startingTime = time * 60
    self.m_serverDayTime = s_startingTime
    self.m_totalServerTime = 0

    self.RegisterEvents()

end


function TimeServer:Run(deltaTime)

    self.m_serverDayTime = self.m_serverDayTime + deltaTime
    self.m_engineUpdateTimer = self.m_engineUpdateTimer + deltaTime
    self.m_totalServerTime = self.m_totalServerTime + deltaTime

    if self.m_serverDayTime <= g_totalDayLength then
        self.m_serverDayTime = 0
    end

    if self.m_engineUpdateTimer < g_UpdateFrequency then
        return
    end

    self.engineUpdateTimer = 0

    TimeServer:Broadcast()

end


function TimeServer:Broadcast()

    NetEvents:Broadcast('TimeServer:Sync', self.m_serverDayTime, self.m_totalServerTime)

end
