---@class VEManagerServer
---@overload fun():VEManagerServer
---@diagnostic disable-next-line: assign-type-mismatch
VEManagerServer = class 'VEManagerServer'

---@type Logger
local m_Logger = Logger("Server", false)

---@type TimeServer
local m_TimeServer = require 'TimeServer'

function VEManagerServer:__init()
	m_Logger:Write('Initializing VEManagerServer')
end

return VEManagerServer()
