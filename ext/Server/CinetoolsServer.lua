---@class CinetoolsServer
CinetoolsServer = class "CinetoolsServer"

---@type Logger
local m_Logger = Logger("CinetoolsServer", false)

function CinetoolsServer:__init()
	m_Logger:Write('Initializing Cinetools-Server')
	self:RegisterVars()
	self:RegisterEvents()
end

function CinetoolsServer:RegisterVars()
	-- Initialise variables
	m_Logger:Write('[Cinetools-Server]: Registered Vars')
end

function CinetoolsServer:RegisterEvents()
	m_Logger:Write('[Cinetools-Server]: Registered Events')
	self.m_DataClientToServer = NetEvents:Subscribe('CinematicTools:CollaborationData', self, self.SendToClients)
	self.m_ColorCorrectionChange = NetEvents:Subscribe('CinematicTools:ColorCorrection', self, self.ChangeColorCorrection)

	if VEM_CONFIG.DEV_ENABLE_CHAT_COMMANDS then
		Events:Subscribe('Player:Chat', self, self.ChatCommands) -- Uncomment to enable chat commands in VEManager
	end
end

function CinetoolsServer:SendToClients(p_Player, p_Path, p_Value)
	m_Logger:Write('Received Collab Data: .. ' .. p_Path .. ' with Value: ' .. tostring(p_Value))
	NetEvents:Broadcast('CinematicTools:DataToClient', p_Path, p_Value, true)
end

function CinetoolsServer:ChatCommands(p_Player, recipientMask, message)
	if message:match('^!cinetools show') then
		NetEvents:SendTo('CinematicTools:ShowUI', p_Player)
	elseif message:match('^!cinetools hide') then
		NetEvents:SendTo('CinematicTools:HideUI', p_Player)
	end
end

function CinetoolsServer:ChangeColorCorrection(p_Player, p_Boolean)
	RCON:SendCommand('vu.ColorCorrectionEnabled', {tostring(p_Boolean)})
end

return CinetoolsServer()
