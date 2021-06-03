# Changes made by the Darkness Unleashed Team



## Types
Presets get a new Type-Table:

Type = {
    Subtype = Name
}

This gives us the ability to differ between time-related presets, weather and other special presets.

Current Types:
Time, Weather

Current Subtypes:
Time = { Morning, Noon, Evening, Night }
Weather = { Foggy, Sandstorm }


## Additional Functionality

### Crossfade:
Allows linear crossfading between two given presets.
Gets the current visibility of the other preset ( e.g Preset 1 will fade to Preset 2 Visibility - Preset 2 will fade to Preset 1 Visibility )

Takes id1 ( id of 1st preset ),
id2 ( id of 2nd preset ),
time ( time of fade in ms ).


### AddTime:
Adds the "time system" to a map via Event.
Takes mapName ( automatic ),
time ( the time you want the cycle to start from in 24hr format, e.g 1230 for 12:30pm ),
totalDayLength ( dayLength in Seconds, "1" will convert to a full day in realtime ),
isStatic ( disables the dayNight Cycle if needed )