class "WeatherServer"



function WeatherServer:__init()
	print('Initializing Time-Server')
	self:RegisterVars()
	self:RegisterEvents()
end

function WeatherServer:RegisterVars()
	-- Initialise variables
	print('[Weather-Server]: Registered Vars')
	self.m_TotalServerTime = 0.0
	self.m_EngineUpdateTimer = 0.0
	self.m_IsStatic = nil
	self.m_ServerTickrate = SharedUtils:GetTickrate()
	self.m_SyncTickrate = VEM_CONFIG.SERVER_SYNC_CLIENT_EVERY_TICKS / self.m_ServerTickrate --[Hz]
	self.m_SystemRunning = false
	self.m_WeatherGenTime = 60
	self.m_LastWeatherGenTime = SharedUtils:GetTime()

	self.fogValues = {}
	self.fogValues.startValue = MathUtils:GetRandom(0.1, 1.0)
	self.fogValues.EndValue = 0.0
	self.fogValues.startTime = 0
	self.fogValues.time = 0
	self.fogValues.lastEndValue = 0
end

function WeatherServer:RegisterEvents()
	print('[Weather-Server]: Registered Events')
	--Events:Subscribe('WeatherServer:AddTime', self, self.AddTime)
	--Events:Subscribe('WeatherServer:Pause', self, self.PauseContinue)
	--Events:Subscribe('WeatherServer:Disable', self, self.DisableDynamicCycle)
	self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.RunWeather)
	self.m_LevelLoadedEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
	--self.m_LevelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)
	self.m_PlayerRequestEvent = NetEvents:Subscribe('WeatherServer:PlayerRequest', self, self.OnPlayerRequest)
	self.Sync = NetEvents:Subscribe('ClientWeather:m_ServerSyncEvent', self, self.Fog)

	--if VEM_CONFIG.DEV_ENABLE_CHAT_COMMANDS then
		--Events:Subscribe('Player:Chat', self, self.ChatCommands) -- Uncomment to enable chat commands in VEManager
	--end
end

function WeatherServer:RunWeather()
    --if self.m_SystemRunning == true and self.m_IsStatic == false then
        if self.m_LastWeatherGenTime + self.m_WeatherGenTime <= SharedUtils:GetTime() then
			print('[Weather-Server]: New weather cycle')
            self:Fog()

            self.m_LastWeatherGenTime = SharedUtils:GetTime()
        end
    --end
end

function WeatherServer:Fog()
	self.fogValues.startTime = SharedUtils:GetTimeMS()
	self.fogValues.startValue = self.fogValues.EndValue
	self.fogValues.EndValue = MathUtils:GetRandom(0.1, 1.0)
	self.fogValues.time = self.m_WeatherGenTime * 1000

	if(PlayerManager:GetPlayerCount() > 0) then
		local sentSyncs = 0
		for k,player in pairs(PlayerManager:GetPlayers()) do
			NetEvents:SendTo('WeatherServer:Sync', player, self.fogValues.EndValue, self.fogValues.time, self.fogValues.startValue)
			sentSyncs = sentSyncs + 1
		end
		--print("[Weather-Server] Sent sync event to " .. tostring(sentSyncs) .. " out of " .. tostring(PlayerManager:GetPlayerCount()) .. " players!")
	end
end

function WeatherServer:OnPlayerRequest(player)
	--if self.m_SystemRunning == true or self.m_IsStatic == true then
		print('[Weather-Server]: Received Request by player: ' .. tostring(player.name))
		print('[Weather-Server]: Calling Sync Broadcast')
		NetEvents:SendTo('WeatherServer:Sync', player, self.fogValues.EndValue, ((self.m_LastWeatherGenTime + self.m_WeatherGenTime) - SharedUtils:GetTime()) * 1000, self.fogValues.startValue)
	--end
end

function WeatherServer:OnLevelLoaded()
	self.m_SystemRunning = true
	self:Fog()
end

function WeatherServer:OnLevelDestroy()
	self.m_SystemRunning = false
end

-- Singleton.
if g_WeatherServer == nil then
	g_WeatherServer = WeatherServer()
end

return g_WeatherServer