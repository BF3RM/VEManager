---@class VEEditorServer
VEEditorServer = class "VEEditorServer"

---@type Logger
local m_Logger = Logger("VEEditorServer", false)

function VEEditorServer:__init()
	m_Logger:Write('Initializing VEEditor-Server')
	self:RegisterVars()
	self:RegisterEvents()
end

function VEEditorServer:RegisterVars()
	-- Initialise variables
	m_Logger:Write('[VEEditor-Server]: Registered Vars')
end

function VEEditorServer:RegisterEvents()
	m_Logger:Write('[VEEditor-Server]: Registered Events')
	self.m_DataClientToServer = NetEvents:Subscribe('VEEditor:CollaborationData', self, self.SendToClients)
	self.m_ColorCorrectionChange = NetEvents:Subscribe('VEEditor:ColorCorrection', self, self.ChangeColorCorrection)

	if VEM_CONFIG.DEV_ENABLE_CHAT_COMMANDS then
		Events:Subscribe('Player:Chat', self, self.ChatCommands) -- Uncomment to enable chat commands in VEManager
	end
end

function VEEditorServer:SendToClients(p_Player, p_Path, p_Value)
	m_Logger:Write('Received Collab Data: .. ' .. p_Path .. ' with Value: ' .. tostring(p_Value))
	NetEvents:Broadcast('VEEditor:DataToClient', p_Path, p_Value, true)
end

function VEEditorServer:ChatCommands(p_Player, recipientMask, message)
	if message:match('^!cinetools show') then
		NetEvents:SendTo('VEEditor:ShowUI', p_Player)
	elseif message:match('^!cinetools hide') then
		NetEvents:SendTo('VEEditor:HideUI', p_Player)
	end
end

function VEEditorServer:ChangeColorCorrection(p_Player, p_Boolean)
	RCON:SendCommand('vu.ColorCorrectionEnabled', {tostring(p_Boolean)})
end

return VEEditorServer()
