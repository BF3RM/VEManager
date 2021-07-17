VEM_CONFIG = {
	-- DAY-NIGHT --
	DN_PRESET_TIMINGS = {0.25, 0.375, 0.5, 0.75, 0.875}, 	-- Always need to have the end time of the last preset in a day at the end
	DN_ENABLE_MOON = true, 									-- Use sun as moon during night

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
