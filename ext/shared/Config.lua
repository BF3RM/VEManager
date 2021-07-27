VEM_CONFIG = {
	-- CLOUDS --
	CLOUDS_DEFAULT_SPEED = -0.0005, 						-- TODO: this needs to be based on the presets not in VEManager config.

	-- DAY-NIGHT --
	DN_SUN_TIMINGS = {0.222, 0.5, 0.833, 0.875, 0.125}, -- don´t change
	--DN_PRESET_TIMINGS = {0.222, 0.25, 0.29, 0.75, 0.833, 0.875}, 	-- Always need to have the end time of the last preset in a day at the end
	DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH = false, 	-- TODO: Equation should also be according to clouds speed

	-- DEV --
	DEV_ENABLE_CHAT_COMMANDS = false,
	DEV_ENABLE_TEST_KEYS = false,
	DEV_LOAD_CUSTOM_PRESET = false,
	DEV_LOAD_CINEMATIC_TOOLS = false,

	-- PRINT --
	PRINT_DN_TIME_AND_VISIBILITIES = true,	-- Print current time every hour along with the visibilities of the 4 presets

	-- SERVER --
	SERVER_SYNC_CLIENT_EVERY_TICKS = 2, 	-- Sync clients with the correct time ever X ticks
}
