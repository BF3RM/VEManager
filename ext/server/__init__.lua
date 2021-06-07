local TimeServer = class('TimeServer')


function TimeServer:__init()
    print('Initializing Time Server')
    self.RegisterVars()
    self.RegisterEvents()
end


function TimeServer:RegisterEvents()
    Events:Subscribe('TimeServer:AddTime', self, self.AddTime)
end


function TimeServer:RegisterVars()
    self.m_serverDayTime = 0.0
    self.m_engineUpdateTimer = 0.0
end


function TimeServer:RegisterEvents()
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
end


function TimeServer:AddTime(startingTime, totalDayLength, isStatic, serverUpdateFrequency)
    self.m_serverDayTime = startingTime * 36
    self.m_totalDayLength = totalDayLength
    self.m_isStatic = isStatic
    self.m_serverUpdateFrequency = serverUpdateFrequency
end


function TimeServer:Run(deltaTime)
    if self.m_isStatic ~= true then
        self.m_serverDayTime = self.m_serverDayTime + deltaTime
        self.m_engineUpdateTimer = self.m_engineUpdateTimer + deltaTime
        self.m_totalServerTime = self.m_totalServerTime + deltaTime

        if self.m_serverDayTime <= m_totalDayLength then
            self.m_serverDayTime = 0
        end

        if self.m_engineUpdateTimer < self.m_serverUpdateFrequency then
            return
        end

        self.engineUpdateTimer = 0

        TimeServer:Broadcast()
    end
end


function TimeServer:Broadcast()
    NetEvents:Broadcast('TimeServer:Sync', self.m_serverDayTime, self.m_totalServerTime)
end
