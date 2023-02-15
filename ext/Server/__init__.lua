---@class VEManagerServer
---@overload fun():VEManagerServer
VEManagerServer = class 'VEManagerServer'

---@type Logger
local m_Logger = Logger("Server", false)

---@type TimeServer
local m_TimeServer = require 'TimeServer'

function VEManagerServer:__init()
	m_Logger:Write('Initializing VEManagerServer')
end

return UtilityFunctions:InitializeClass(VEManagerServer)
