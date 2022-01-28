class 'VEManagerServer'

function VEManagerServer:__init()
	print('Initializing VEManagerServer')
	self:RequireModules()
end


function VEManagerServer:RequireModules()
	require 'TimeServer'

	if VEM_CONFIG.DEV_LOAD_CINEMATIC_TOOLS == true then
		require 'VEEditorServer'
	end
end


-- Singleton.
if g_VEManagerServer == nil then
	g_VEManagerServer = VEManagerServer()
end


return g_VEManagerServer