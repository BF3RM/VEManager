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
end


function CinetoolsServer:SendToClients(p_Player, p_Path, p_Value)
	print('Received Collab Data: .. ' .. p_Path .. ' with Value: ' .. tostring(p_Value))
    NetEvents:Broadcast('CinematicTools:DataToClient', p_Path, p_Value, true)
end

-- Singleton.
if g_CinetoolsServer == nil then
	g_CinetoolsServer = CinetoolsServer()
end

return g_CinetoolsServer
















