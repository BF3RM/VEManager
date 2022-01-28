VEM_CONFIG = {
	-- CLOUDS --
	CLOUDS_DEFAULT_SPEED = -0.0005, 						-- TODO: this needs to be based on the presets not in VEManager config.

	-- DAY-NIGHT --
	DN_SUN_TIMINGS = {5.328, 21}, 									-- Sun times in hours (float) [sunrise, sunset]
	DN_PRESET_TIMINGS = {0.222, 0.25, 0.29, 0.75, 0.833, 0.875}, 	-- Always need to have the end time of the last preset in a day at the end
	DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH = false, 			-- Synchronises cloud speed to game time (useful for timelapses)

	-- DEV --
	DEV_ENABLE_CHAT_COMMANDS = true,
	DEV_ENABLE_TEST_KEYS = true,
	-- TODO: Add config option for patches

	-- PRINT --
	PRINT_DN_TIME_AND_VISIBILITIES = false,							-- Print current time every hour along with the visibilities of the 4 presets
	LOGGER_ENABLED = true, 											-- Enables the use of the Logger Class [DEV]
	LOGGER_PRINT_ALL = false,										-- Prints All Logger Prints

	-- SERVER --
	SERVER_SYNC_CLIENT_EVERY_TICKS = 2, 							-- Sync clients with the correct time ever X ticks
}


VEE_CONFIG = {

	EDITOR_MOUSE_ENABLE_KEY = InputDeviceKeys.IDK_F9,
	EDITOR_TOGGLE_KEY = InputDeviceKeys.IDK_F8, 					--	Hides/Shows the editor and the editor visual environment
	SHOW_EDITOR_ON_LEVEL_LOAD = true,								-- 	Enables/Disables Automatic Show on Level Load of Cinematic Tools
	SEARCH_PARAMETERS_FOR_TEXTURES = {								-- 	Defines the Search Parameters for the Cinematic Tools Texture Tool
		"cloud",
		"panoramic",
		"alpha",
		"/visualenviroments/",
		"/sky/",
		"/lighting/"
	},

	DEV_ENABLE_CHAT_COMMANDS = true,								-- Enable Chat Commands
	LOGGER_ENABLED = true,											-- Enable Logger
	LOGGER_PRINT_ALL = true											-- Print Logger Output of All Files
}
