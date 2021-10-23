class 'VEManagerServer'

local m_Logger = Logger("Server", false)

function VEManagerServer:__init()
	m_Logger:Write('Initializing VEManagerServer')
	self:RequireModules()
	self:RegisterEvents()
end

function VEManagerServer:RequireModules()
	require 'TimeServer'

	if VEM_CONFIG.DEV_LOAD_CINEMATIC_TOOLS then
		require 'CinetoolsServer'
	end
end

function VEManagerServer:RegisterEvents()
	if VEM_CONFIG.DEV_ENABLE_CHAT_COMMANDS then
		Events:Subscribe('Player:Chat', self, self.ChatCommands)
	end
end

function VEManagerServer:ChatCommands(p_Player, p_RecipientMask, p_Message)
	if p_Player == nil or p_Player.name == nil or p_Message == nil then
		m_Logger:Write('Invalid message')
	end

	-- Check if admin
	s_IsAdmin = false
	for l_Admin in pairs(VEM_CONFIG.ADMINS) do
		if l_Admin == p_Player then
			s_IsAdmin = true
		end
	end

	if not s_IsAdmin then
		return
	then

	-- Check for commands
	if p_Message == '!vanillapreset' then
		-- TODO: enable original preset or disable all custom presets
		m_Logger:Write(p_Player.name .. ' wants to apply the vanilla preset')
		return
	
	elseif p_Message == '!custompreset' then
		m_Logger:Write(p_Player.name .. ' wants to apply the cinematic tools preset')
		NetEvents:Broadcast('VEManager:EnablePreset', 'CinematicTools')
		return
	
	elseif p_Message:match('^!preset') then
		--local presetID = p_Message:match('^!preset (%d+)')
		local presetID = p_Message:gsub("!preset ", ""):gsub("^%s*(.-)%s*$", "%1") -- The last gsub is trim
		m_Logger:Write(p_Player.name .. ' wants to apply the preset with ID: ' .. tostring(presetID))

		if presetID ~= nil then
			NetEvents:Broadcast('VEManager:EnablePreset', presetID)
		end
		return
	end

	-- Check if time server commands
	g_TimeServer:ChatCommands(p_Player, p_RecipientMask, p_Message)
end

-- Singleton.
if g_VEManagerServer == nil then
	g_VEManagerServer = VEManagerServer()
end


return g_VEManagerServer