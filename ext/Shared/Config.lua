VEM_CONFIG = {
	-- CLOUDS --
	CLOUDS_DEFAULT_SPEED = -0.0005, 						-- TODO: this needs to be based on the presets not in VEManager config.

	--[[ OTHER --
	PATCH_EXPLOSIONS_COLOR_CORRECTION = false,]]						-- Disables color correction from explosions (explosions may cause a discontinue preset effect)

	-- DAY-NIGHT --
	DN_SUN_TIMINGS = {5.328, 21}, 									-- Sun times in hours (float) [sunrise, sunset]
	DN_PRESET_TIMINGS = {0.222, 0.25, 0.29, 0.75, 0.833, 0.875}, 	-- Always need to have the end time of the last preset in a day at the end
	DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH = false, 			-- Synchronizes cloud speed to game time (useful for timelapses)
	DN_APPLY_PATCHES = true,										-- Applies the needed Patches for Day-Night (removes bright meshes/textures meant for day)

	-- DEV --
	ADMINS = {"GreatApo", "IllustrisJack"},							-- Players that can use the VEM chat commands
	DEV_ENABLE_CHAT_COMMANDS = true,								-- Enables the use of VEM Internal Chat Commands
	DEV_ENABLE_TEST_KEYS = true,									-- Enables the use of VEM Internal Testing Keybinds
	DEV_SHOW_HIDE_CINEMATIC_TOOLS_KEY = InputDeviceKeys.IDK_F8,		-- The Key that shows/hides the Cinematic Tools
	DEV_LOAD_CINEMATIC_TOOLS = false,								-- Enables/Disables Cinematic Tools (should be loaded always can be called via Event)
	DEV_SHOW_CINEMATIC_TOOLS_ON_LEVEL_LOAD = false,					-- Enables/Disables Automatic Show on Level Load of Cinematic Tools
	DEV_SEARCH_PARAMETERS_FOR_TEXTURES = {							-- Defines the Search Parameters for the Cinematic Tools Texture Tool
		"cloud",
		"panoramic",
		"alpha",
		"/visualenviroments/",
		"/sky/",
		"/lighting/"
	},

	-- PRINT --
	PRINT_DN_TIME_AND_VISIBILITIES = false,							-- Print current time every hour along with the visibilities of the 4 presets
	LOGGER_ENABLED = true, 											-- Enables the use of the Logger Class [DEV]
	LOGGER_PRINT_ALL = false,										-- Prints All Logger Prints

	-- SERVER --
	SERVER_SYNC_CLIENT_EVERY_TICKS = 2, 							-- Sync clients with the correct time ever X ticks
}
