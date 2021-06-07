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
    self.m_ServerDayTime = 0.0
    self.m_EngineUpdateTimer = 0.0
    self.m_TotalDayLength = nil
    self.m_IsStatic = nil
    self.m_ServerUpdateFrequency = 30
end


function TimeServer:RegisterEvents()
    self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
end


function TimeServer:AddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes, p_ServerUpdateFrequency)

    if self.m_TotalDayLength <= 1 then
        self.m_TotalDayLength = 86000
    else
        self.m_TotalDayLength = p_LengthOfDayInMinutes * 60
    end
    print("Length of Day: " .. self.m_TotalDayLength .. " Seconds")

    self.m_ServerDayTime = p_StartingTime * 3600 -- to sec
    print("Starting at Time: " .. ( self.m_ServerDayTime / 60 / 60 ) .. " Hours")

    self.m_IsStatic = p_IsStatic
    self.m_ServerUpdateFrequency = p_ServerUpdateFrequency
end


function TimeServer:Run(deltaTime)
    if self.m_IsStatic == false then
        self.m_ServerDayTime = self.m_ServerDayTime + deltaTime
        self.m_EngineUpdateTimer = self.m_EngineUpdateTimer + deltaTime
        self.m_TotalServerTime = self.m_TotalServerTime + deltaTime

        if self.m_ServerDayTime <= self.m_TotalDayLength then
            self.m_ServerDayTime = 0
        end

        if self.m_EngineUpdateTimer < self.m_ServerUpdateFrequency then
            return
        end

        self.EngineUpdateTimer = 0

        self:Broadcast()
    end
end


function TimeServer:Broadcast()
    NetEvents:Broadcast('TimeServer:Sync', self.m_serverDayTime, self.m_totalServerTime)
end


TimeServer:__init()

