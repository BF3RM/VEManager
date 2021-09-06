class "CinetoolsServer"

function CinetoolsServer:__init()
	print('Initializing Cinetools-Server')
	self:RegisterVars()
	self:RegisterEvents()
end


function CinetoolsServer:RegisterVars()
	-- Initialise variables
	print('[Cinetools-Server]: Registered Vars')
end


function CinetoolsServer:RegisterEvents()
	print('[Cinetools-Server]: Registered Events')
    self.m_DataClientToServer = NetEvents:Subscribe('CinematicTools:CollaborationData', self, self.SendToClients)
	self.m_ColorCorrectionChange = NetEvents:Subscribe('CinematicTools:ColorCorrection', self, self.ChangeColorCorrection)

	if VEM_CONFIG.DEV_ENABLE_CHAT_COMMANDS then
		Events:Subscribe('Player:Chat', self, self.ChatCommands) -- Uncomment to enable chat commands in VEManager
	end
end


function CinetoolsServer:SendToClients(p_Player, p_Path, p_Value)
	print('Received Collab Data: .. ' .. p_Path .. ' with Value: ' .. tostring(p_Value))
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

-- Singleton.
if g_CinetoolsServer == nil then
	g_CinetoolsServer = CinetoolsServer()
end

return g_CinetoolsServer
















