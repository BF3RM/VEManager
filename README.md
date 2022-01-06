# VEManager
A Visual Environment manager for Venice Unleashed.

It's used to create and manage VE presets. Presets can either be created with the  integrated tools/editor or by using the separate mod [CinematicTools](https://github.com/Powback/VEXT-CinematicTools).

## Youtube Tutorial Series
https://www.youtube.com/watch?v=QYPJ4MNQbos&list=PLqlU85EO4crIPxk10YXiKDXE67lU-dM4m

If you have questions contact IllustrisJack#5355 on Discord.

## Config Options (Shared/Config.lua):
	A number of features can be switched on/off from the config file located at Shared/Config.lua

	DEV_ENABLE_CHAT_COMMANDS = (true/false)							Enables the use of these chat command
 	DEV_ENABLE_TEST_KEYS = (true/false)								Enables the use of test keys / shortcuts
	DEV_SHOW_HIDE_CINEMATIC_TOOLS_KEY = InputDeviceKeys.IDK_F8		Cinematic tools will show/hide on pressing F8 (any other Key can be defined here)
	DEV_LOAD_CINEMATIC_TOOLS = (true/false)							Generally enable/disable cinematic tools
	DEV_SHOW_CINEMATIC_TOOLS_ON_LEVEL_LOAD = (true/false)			Load cinematic tools on level load if needed

	For more options, have a look in Shared/Config.lua.

### DEVELOPER CHAT COMMANDS
+   The following commands can be used: (provided that DEV_ENABLE_CHAT_COMMANDS is set to true)
>       !preset PRESET_NAME				Enables a preset of your choice
>       !cinetools						Shows/hides the cinematic tools edit UI and enables/disables the cinematic tools preset
>       !custompreset					Enables the cinematic tools preset
>       !setnight						Sets day-night cycle to night
>       !setmorning						Sets day-night cycle to morning
>       !setnoon						Sets day-night cycle to noon
>       !setafternoon					Sets day-night cycle to afternoon
>       !pausetime						Pauses day-night cycle time (pauses presets to current state)
>       !disabletime					Disables day-night cycle (reverts to initial preset)

