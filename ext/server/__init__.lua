local TimeServer = class('TimeServer')


function TimeServer:__init()
    print('Initializing Time-Server')
    self:RegisterVars()
    self:RegisterEvents()
end

function TimeServer:RegisterVars()
    print('[Time-Server]: Registered Vars')
    self.m_ServerDayTime = 0.0
    self.m_TotalServerTime = 0.0
    self.m_EngineUpdateTimer = 0.0
    self.m_TotalDayLength = 0.0
    self.m_IsStatic = nil
    self.m_ServerTickrate = SharedUtils:GetTickrate()
    self.m_UpdateThreshold = 0.5
    self.m_SyncTickrate = 1 / self.m_ServerTickrate * self.m_UpdateThreshold
    self.m_SystemRunning = false
end


function TimeServer:RegisterEvents()
    print('[Time-Server]: Registered Events')
    self.m_AddTimeEvent = Events:Subscribe('TimeServer:AddTime', self, self.AddTime)
    self.m_AddTimeNetEvent = NetEvents:Subscribe('TimeServer:ApplyTime', self, self.AddTimeNet)
    self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
    self.m_LevelLoadedEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
    self.m_LevelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
    self.m_PlayerRequestEvent = NetEvents:Subscribe('TimeServer:PlayerRequest', self, self.OnPlayerRequest)
end


function TimeServer:OnLevelLoaded()
    self:AddTime(8, false, 2, self.m_SyncTickrate) -- debug only
end


function TimeServer:OnLevelDestroy()
    self:RegisterVars()
    Events:Dispatch('VEManager:RemoveTime')
end


function TimeServer:AddTimeNet(p_Player, p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes)
    print('[Time-Server]: Time Event Called by ' .. p_Player.name)
    self:AddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes)
end


function TimeServer:AddTime(p_StartingTime, p_IsStatic, p_LengthOfDayInMinutes)
    if self.m_SystemRunning == true then
        self:RegisterVars()
    end

    print('[Time-Server]: Received Add Time Event')
    print(tostring(p_StartingTime) .. " | "  .. tostring(p_IsStatic) .. " | "  .. tostring(p_LengthOfDayInMinutes) .. " | "  .. tostring(p_ServerUpdateFrequency))

    if p_LengthOfDayInMinutes <= 1 then
        self.m_TotalDayLength = 86000
    else
        self.m_TotalDayLength = p_LengthOfDayInMinutes * 60
    end
    print('[Time-Server]: Length of Day: ' .. self.m_TotalDayLength .. ' Seconds')

    self.m_ServerDayTime = p_StartingTime * 3600 * (self.m_TotalDayLength / 86000)
    print('[Time-Server]: Starting at Time: ' .. p_StartingTime .. ' Hours')

    self.m_IsStatic = p_IsStatic

    NetEvents:Broadcast('VEManager:AddTimeToClient', p_StartingTime, p_IsStatic, self.m_TotalDayLength, p_ServerUpdateFrequency)

    self.m_SystemRunning = true
end


function TimeServer:Run(p_DeltaTime, p_SimulationDeltaTime)
    if self.m_SystemRunning == true and self.m_IsStatic == false then

        self.m_ServerDayTime = self.m_ServerDayTime + p_DeltaTime
        self.m_EngineUpdateTimer = self.m_EngineUpdateTimer + p_DeltaTime

        if self.m_TotalServerTime == 0.0 then
            self.m_TotalServerTime = self.m_TotalServerTime + self.m_ServerDayTime
        end
        self.m_TotalServerTime = self.m_TotalServerTime + p_DeltaTime

        if self.m_EngineUpdateTimer <= self.m_SyncTickrate then
            return
        end

        self.m_EngineUpdateTimer = 0
        self:Broadcast()

        if self.m_ServerDayTime >= self.m_TotalDayLength then
            print('[Time-Server]: Reset Day')
            self.m_ServerDayTime = 0
        end

    end
end


function TimeServer:OnPlayerRequest(player)
    print('[Time-Server]: Received Request by Player')
    if self.m_SystemRunning == true and self.m_IsStatic == false then
        print('[Time-Server]: Calling Sync Broadcast')
        NetEvents:SendTo('VEManager:AddTimeToClient', player, self.m_ServerDayTime, self.m_IsStatic, self.m_TotalDayLength, self.m_ServerUpdateFrequency)
    end
end


function TimeServer:PauseContinue()
    if self.m_SystemRunning == true then
        self.m_SystemRunning = false
        NetEvents:Broadcast('TimeServer:Pause', false)
    elseif self.m_SystemRunning == false then
        self.m_SystemRunning = true
        NetEvents:Broadcast('TimeServer:Pause', true)
    end
end


function TimeServer:Broadcast()
    --print('[Time-Server]: Syncing Players')
    NetEvents:BroadcastUnreliable('TimeServer:Sync', self.m_ServerDayTime, self.m_TotalServerTime)
end


TimeServer:__init()

