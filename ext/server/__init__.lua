local TimeServer = class('TimeServer')


function TimeServer:__init()
    print('Initializing Time Server')
    self:RegisterVars()
    self:RegisterEvents()
end

function TimeServer:RegisterVars()
    print('Registered Vars')
    self.m_ServerDayTime = 0.0
    self.m_TotalServerTime = 0.0
    self.m_EngineUpdateTimer = 0.0
    self.m_TotalDayLength = nil
    self.m_IsStatic = nil
    self.m_ServerUpdateFrequency = 30
    self.m_SystemRunning = false
end


function TimeServer:RegisterEvents()
    print('Registered Events')
    self.m_AddTimeEvent = Events:Subscribe('TimeServer:AddTime', self, self.AddTime)
    self.m_AddTimeNetEvent = NetEvents:Subscribe('TimeServer:AddTime', self, self.AddTimeNet)
    self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
    self.m_LevelLoadedEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
    self.m_LevelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
end


function TimeServer:OnLevelDestroy()
    TimeServer:RegisterVars()
end


function TimeServer:AddTimeNet(p_Player, p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes, p_ServerUpdateFrequency)
    print('Time Event Called by ' .. p_Player.name)
    self:AddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes, p_ServerUpdateFrequency)
end


function TimeServer:AddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes, p_ServerUpdateFrequency)
    print('Received Add Time Event')
    print(tostring(p_StartingTime) .. " | "  .. tostring(p_IsStatic) .. " | "  .. tostring(p_LengthOfDayInMinutes) .. " | "  .. tostring(p_ServerUpdateFrequency))
    if p_LengthOfDayInMinutes <= 1 then
        self.m_TotalDayLength = 86000
    else
        self.m_TotalDayLength = p_LengthOfDayInMinutes * 60
    end
    print("Length of Day: " .. self.m_TotalDayLength .. " Seconds")

    self.m_ServerDayTime = p_StartingTime * 3600 -- to sec
    print("Starting at Time: " .. ( self.m_ServerDayTime / 60 / 60 ) .. " Hours")

    self.m_IsStatic = p_IsStatic
    self.m_ServerUpdateFrequency = p_ServerUpdateFrequency

    NetEvents:Broadcast('VEManager:AddTimeToClient', p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes, p_ServerUpdateFrequency)

    self.m_SystemRunning = true
end


function TimeServer:Run(deltaTime)
    if self.m_SystemRunning == true and self.m_IsStatic == false then

        self.m_ServerDayTime = self.m_ServerDayTime + deltaTime
        self.m_EngineUpdateTimer = self.m_EngineUpdateTimer + deltaTime
        self.m_TotalServerTime = self.m_TotalServerTime + deltaTime

        if self.m_EngineUpdateTimer <= self.m_ServerUpdateFrequency then
            if self.m_EngineUpdateTimer == 0.5 * self.m_ServerUpdateFrequency then
                print('Time left till next server sync: ' .. ( self.m_ServerUpdateFrequency - self.m_EngineUpdateTimer ))
            end
            return
        end

        self.m_EngineUpdateTimer = 0

        self:Broadcast()

        if self.m_ServerDayTime >= self.m_TotalDayLength then
            print('Reset Day')
            self.m_ServerDayTime = 0
        end

    end
end


function TimeServer:Broadcast()
    print('Syncing Players')
    NetEvents:Broadcast('TimeServer:Sync', self.m_ServerDayTime, self.m_TotalServerTime)
end


TimeServer:__init()

