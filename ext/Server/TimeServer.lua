---@class TimeServer
---@overload fun():TimeServer
---@diagnostic disable-next-line: assign-type-mismatch
TimeServer = class "TimeServer"

---@type VEMLogger
local m_VEMLogger = VEMLogger("TimeServer", true)

function TimeServer:__init()
	m_VEMLogger:Write('Initializing Time-Server')
	self:RegisterVars()
	self:RegisterEvents()
end

function TimeServer:RegisterVars()
	-- Initialise variables
	m_VEMLogger:Write('Registered Vars')
	---@type number
	self.m_ServerDayTime = 0.0
	---@type number
	self.m_TotalServerTime = 0.0
	---@type number
	self.m_EngineUpdateTimer = 0.0
	---@type number
	self.m_TotalDayLength = 0.0
	---@type boolean
	self.m_IsStatic = nil
	---@type number
	self.m_ServerTickrate = SharedUtils:GetTickrate()
	---@type number
	self.m_SyncTickrate = VEM_CONFIG.SERVER_SYNC_CLIENT_EVERY_TICKS / self.m_ServerTickrate --[Hz]
	---@type boolean
	self.m_SystemRunning = false
end

function TimeServer:RegisterEvents()
	m_VEMLogger:Write('Registered Events')

	---@type Event
	Events:Subscribe('Engine:Update', self, self._OnEngineUpdate)
	Events:Subscribe('Level:Destroy', self, self._OnLevelDestroy)
	Events:Subscribe('TimeServer:Enable', self, self._OnEnable)
	Events:Subscribe('TimeServer:Pause', self, self._OnPauseUnpause)
	Events:Subscribe('TimeServer:Disable', self, self._OnDisable)

	NetEvents:Subscribe('TimeServer:PlayerSync', self, self._OnPlayerSync)
end

function TimeServer:_OnLevelDestroy()
	self:RegisterVars()
end

---@param p_StartingTime number
---@param p_LengthOfDayInMinutes number
function TimeServer:_OnEnable(p_StartingTime, p_LengthOfDayInMinutes)
	if self.m_SystemRunning then
		-- reset
		self:RegisterVars()
	end

	-- set length of day
	if p_LengthOfDayInMinutes then
		self.m_TotalDayLength = p_LengthOfDayInMinutes * 60
		self.m_ServerDayTime = p_StartingTime * 3600 * (self.m_TotalDayLength / 86000)
		self.m_IsStatic = false
	else
		-- static if no day length is provided
		self.m_TotalDayLength = 86000
		self.m_ServerDayTime = p_StartingTime * 3600
		self.m_IsStatic = true
	end

	m_VEMLogger:Write('Received new time (Starting Time, Length of Day): ' ..
		p_StartingTime .. 'h, ' .. self.m_TotalDayLength .. 'sec')

	NetEvents:Broadcast('VEManager:AddTimeToClient', self.m_ServerDayTime, self.m_IsStatic, self.m_TotalDayLength)
	self.m_SystemRunning = true
end

---@param p_DeltaTime integer
---@param p_SimulationDeltaTime integer
function TimeServer:_OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
	if self.m_SystemRunning and not self.m_IsStatic then
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
		self:_Broadcast(self.m_ServerDayTime, self.m_TotalServerTime)

		if self.m_ServerDayTime >= self.m_TotalDayLength then
			m_VEMLogger:Write('A new day...')
			self.m_ServerDayTime = 0
		end
	end
end

---@param p_Player Player
function TimeServer:_OnPlayerSync(p_Player)
	if self.m_SystemRunning == true or self.m_IsStatic == true then
		m_VEMLogger:Write('Syncing Player with Server')
		NetEvents:SendTo('VEManager:AddTimeToClient', p_Player, self.m_ServerDayTime, self.m_IsStatic,
			self.m_TotalDayLength)
	end
end

---@param p_ServerDayTime number
---@param p_TotalServerTime number
function TimeServer:_Broadcast(p_ServerDayTime, p_TotalServerTime)
	NetEvents:BroadcastUnreliableOrdered('TimeServer:Sync', p_ServerDayTime, p_TotalServerTime)
end

function TimeServer:_OnPauseUnpause()
	-- Pause or Continue time
	self.m_SystemRunning = not self.m_SystemRunning
	m_VEMLogger:Write('Time system running: ' .. tostring(self.m_SystemRunning))
	NetEvents:Broadcast('ClientTime:Pause', self.m_SystemRunning)
end

function TimeServer:_OnDisable()
	self.m_SystemRunning = false
	NetEvents:Broadcast('ClientTime:Disable')
end

-- Chat Commands
---@param p_PlayerName string
---@param p_RecipientMask integer
---@param p_Message string
function TimeServer:ChatCommands(p_PlayerName, p_RecipientMask, p_Message)
	if p_Message:match('^!settime') then
		local hour, duration = p_Message:match('^!settime (%d+%.*%d*) (%d+%.*%d*)')

		if hour == nil then
			hour = 9
		end

		if duration == nil then
			duration = 0.5
		end

		m_VEMLogger:Write('Time Event called by ' .. p_PlayerName)
		self:_OnEnable(hour, duration)
	elseif p_Message == '!setnight' then
		m_VEMLogger:Write('Time Event called by ' .. p_PlayerName)
		self:_OnEnable(0, nil)
	elseif p_Message == '!setmorning' then
		m_VEMLogger:Write('Time Event called by ' .. p_PlayerName)
		self:_OnEnable(9, nil)
	elseif p_Message == '!setnoon' then
		m_VEMLogger:Write('Time Event called by ' .. p_PlayerName)
		self:_OnEnable(12, nil)
	elseif p_Message == '!setafternoon' then
		m_VEMLogger:Write('Time Event called by ' .. p_PlayerName)
		self:_OnEnable(15, nil)
	elseif p_Message == '!pausetime' or p_message == '!resumetime' then
		m_VEMLogger:Write('Time Pause called by ' .. p_PlayerName)
		self:_OnPauseUnpause()
	elseif p_Message == '!disabletime' then
		m_VEMLogger:Write('Time Disable called by ' .. p_PlayerName)
		self:_OnDisable()
	end
end

return TimeServer()
