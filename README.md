# VEManager
A Visual Environment manager for Venice Unleashed.

It's used to create and manage VE presets. Presets can either be created with [VEEditor](https://github.com/BF3RM/VEEditor) or[CinematicTools](https://github.com/Powback/VEXT-CinematicTools).

## Youtube Tutorial Series
https://youtube.com/playlist?list=PLqlU85EO4crIPxk10YXiKDXE67lU-dM4m

If you have questions contact IllustrisJack#5355 on Discord.

## Config Options (Shared/Config.lua):
	A number of features can be switched on/off from the config file located at Shared/Config.lua

	DEV_ENABLE_CHAT_COMMANDS = (true/false)							Enables the use of these chat command
 	DEV_ENABLE_TEST_KEYS = (true/false)								Enables the use of test keys / shortcuts

	For more options, have a look in Shared/Config.lua.

### DEVELOPER CHAT COMMANDS
+   The following commands can be used: (provided that DEV_ENABLE_CHAT_COMMANDS is set to true)
>       !preset PRESET_NAME				Enables a preset of your choice
>       !setnight						Sets day-night cycle to night
>       !setmorning						Sets day-night cycle to morning
>       !setnoon						Sets day-night cycle to noon
>       !setafternoon					Sets day-night cycle to afternoon
>       !pausetime						Pauses day-night cycle time (pauses presets to current state)
>       !disabletime					Disables day-night cycle (reverts to initial preset)

