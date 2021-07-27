class 'Weather'

function Weather:__init()
	print('Initializing Weather Module')
	Weather:RegisterVars()
	Weather:RegisterEvents()
end

function Weather:RegisterVars()
	-- Initialise variables
	print('[Client Weather Module] Registered Vars')

    -- Systems
	self.m_ServerSyncEvent = nil

    -- Presets
	self.m_nightPriority = 11
	self.m_morningPriority = 12
	self.m_noonPriority = 13
	self.m_eveningPriority = 14
	self.m_currentNightPreset = nil
	self.m_currentMorningPreset = nil
	self.m_currentNoonPreset = nil
	self.m_currentEveningPreset = nil

    -- Clouds
	self.m_CloudSpeed = VEM_CONFIG.CLOUDS_DEFAULT_SPEED

    -- Fog
	self.fogValues = {}

	self.fogValues.startValue = MathUtils:GetRandom(0.1, 1.0)
	self.fogValues.EndValue = 0.0
	self.fogValues.startTime = 0
	self.fogValues.time = 0
	self.fogValues.class = "fog"
	self.fogValues.values = {"start", "endValue", "fogColorStart", "fogColorEnd", "transparencyFadeStart", "transparencyFadeEnd"}
	self.fogValues.lastEndValue = 0
	self.fogValues.standardFogEndValue = 0
end

function Weather:SetStandard()
    local states = VisualEnvironmentManager:GetStates()
    --Loop through all states
    for _, state in pairs(states) do
        if state.entityName ~= "EffectEntity" then --sets main ve to 1
            state.priority = 1
			self.fogValues.standardFogEndValue = state.fog.endValue
        end
    end

	print("Standard priority set to 1")
end

function Weather:RegisterEvents()
	--self.m_PartitionLoadedEvent = Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoad)
	--self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.RunWeather)
	self.m_LevelLoadEvent = Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
	self.m_LevelDestroyEvent = Events:Subscribe('Level:Destroy', self, self.OnLevelDestroy)

	--NetEvents:Subscribe('WeatherServer:Sync', self, self.ServerSync)
	--NetEvents:Subscribe('ClientWeather:Pause', self, self.PauseContinue)
	--NetEvents:Subscribe('ClientWeather:Disable', self, self.Disable)
end

function Weather:OnLevelLoaded()
	if VEM_CONFIG.WEATHER_SYSTEM_ENABLED == true then
		self:SetStandard()

		self.m_ServerSyncEvent = NetEvents:Subscribe('WeatherServer:Sync', self, self.ServerSync) -- Server Sync
		self:RequestWeather()
	end
end

function Weather:OnLevelDestroy()
	if VEM_CONFIG.WEATHER_SYSTEM_ENABLED == true and self.m_ServerSyncEvent ~= nil then
		self.m_ServerSyncEvent:Unsubscribe() -- Server Sync
	end
end

function Weather:RequestWeather()
	print('[Weather-System] Request WeatherSync')
	NetEvents:Send('WeatherServer:PlayerRequest')
end

function Weather:ServerSync(p_EndValue, p_Time, p_StartValue)
		self.fogValues.lastEndValue = self.fogValues.EndValue
		self.fogValues.startValue = p_StartValue
		self.fogValues.EndValue = p_EndValue
		self.fogValues.time = p_Time
		self.fogValues.startTime = SharedUtils:GetTimeMS()

		g_VEManagerClient.m_LerpingSingleValues[#g_VEManagerClient.m_LerpingSingleValues + 1] = self.fogValues

	print("[Weather-System] Server sync recieved! [Start Value: " .. tostring(p_StartValue) .. "] [EndValue: " .. tostring(p_EndValue) .. "] [Lerp Time: " .. tostring(p_Time) .. "]")
end

-- Singleton.
if g_Weather == nil then
	g_Weather = Weather()
end

return g_Weather