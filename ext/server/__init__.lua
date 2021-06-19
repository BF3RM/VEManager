class "TimeServer"

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
    self.m_SyncTickrate = 1 / (self.m_ServerTickrate * self.m_UpdateThreshold) --[Hz]
    self.m_SystemRunning = false
end


function TimeServer:RegisterEvents()
    print('[Time-Server]: Registered Events')
    Events:Subscribe('TimeServer:AddTime', self, self.AddTime)
    Events:Subscribe('TimeServer:Pause', self, self.PauseContinue)
    Events:Subscribe('TimeServer:Disable', self, self.DisableDynamicCycle)
    self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.Run)
    self.m_LevelLoadedEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
    self.m_LevelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
    self.m_PlayerRequestEvent = NetEvents:Subscribe('TimeServer:PlayerRequest', self, self.OnPlayerRequest)
	-- For Devs
	Events:Subscribe('Player:Chat', self, self.ChatCommands)
	--NetEvents:Subscribe('TimeServer:AddTime', self, self.AddTimeNet)
	--NetEvents:Subscribe('TimeServer:Pause', self, self.PauseNet)
	--NetEvents:Subscribe('TimeServer:Disable', self, self.DisableNet)
end


function TimeServer:OnLevelLoaded()
    --self:AddTime(0, 2) -- debug/testing only
end


function TimeServer:OnLevelDestroy()
    self.m_SystemRunning = false
end


function TimeServer:AddTime(p_StartingTime, p_LengthOfDayInMinutes)
    if self.m_SystemRunning == true then
        self:RegisterVars()
    end

    print('[Time-Server]: Received Add Time Event')
    --print(tostring(p_StartingTime) .. " | " .. tostring(p_LengthOfDayInMinutes))

    if p_LengthOfDayInMinutes ~= nil then
        self.m_TotalDayLength = p_LengthOfDayInMinutes * 60
        self.m_ServerDayTime = p_StartingTime * 3600 * (self.m_TotalDayLength / 86000)
        self.m_IsStatic = false
        print('[Time-Server]: New time (Starting Time, Length of Day): ' .. p_StartingTime .. 'h, '.. self.m_TotalDayLength .. 'sec')
    else
        self.m_TotalDayLength = 86000
        self.m_ServerDayTime = p_StartingTime * 3600
        self.m_IsStatic = true
    end

    NetEvents:Broadcast('VEManager:AddTimeToClient', self.m_ServerDayTime, self.m_IsStatic, self.m_TotalDayLength)
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
        self:Broadcast(self.m_ServerDayTime, self.m_TotalServerTime)

        if self.m_ServerDayTime >= self.m_TotalDayLength then
            print('[Time-Server]: New day cycle')
            self.m_ServerDayTime = 0
        end

    end
end

function TimeServer:OnPlayerRequest(player)
    if self.m_SystemRunning == true or self.m_IsStatic == true then
        print('[Time-Server]: Received Request by Player')
        print('[Time-Server]: Calling Sync Broadcast')
        NetEvents:SendTo('VEManager:AddTimeToClient', player, self.m_ServerDayTime, self.m_IsStatic, self.m_TotalDayLength)
    end
end

function TimeServer:Broadcast(p_ServerDayTime, p_TotalServerTime)
    --print('[Time-Server]: Syncing Players')
    NetEvents:BroadcastUnreliableOrdered('TimeServer:Sync', p_ServerDayTime, p_TotalServerTime)
end

function TimeServer:PauseContinue()
	-- Pause or Continue time
    self.m_SystemRunning = not self.m_SystemRunning
	print('[Time-Server]: Time system running: ' .. tostring(self.m_SystemRunning))
	NetEvents:Broadcast('ClientTime:Pause', self.m_SystemRunning)
end

function TimeServer:DisableDynamicCycle()
	self.m_SystemRunning = false
	NetEvents:Broadcast('ClientTime:Disable')
end


-- FOR DEVS --

function TimeServer:ChatCommands(p_Player, recipientMask, message)
	if message == '!settime' then
		print('[Time-Server]: Time Event called by ' .. p_Player.name)
		self:AddTime(9, 2)
	elseif message == '!pausetime' then
		print('[Time-Server]: Time Pause called by ' .. p_Player.name)
		self:PauseContinue()
	elseif message == '!disabletime' then
		print('[Time-Server]: Time Disable called by ' .. p_Player.name)
		self:DisableDynamicCycle()
	end
end

--[[
function TimeServer:AddTimeNet(p_Player, p_StartingTime, p_LengthOfDayInMinutes)
	print('[Time-Server]: Time Event called by ' .. p_Player.name)
	self:AddTime(p_StartingTime, p_LengthOfDayInMinutes)
end

function TimeServer:PauseNet(p_Player)
	print('[Time-Server]: Time Pause called by ' .. p_Player.name)
	self:PauseContinue()
end

function TimeServer:DisableNet(p_Player)
	print('[Time-Server]: Time Disable called by ' .. p_Player.name)
	self:DisableDynamicCycle()
end
]]

-- Singleton.
if g_TimeServer == nil then
	g_TimeServer = TimeServer()
end

return g_TimeServer