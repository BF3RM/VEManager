VEM_CONFIG = {
    -- OTHER --
    PATCH_EXPLOSIONS_COLOR_CORRECTION = true, -- Disables color correction from explosions (explosions may cause a discontinue preset effect)

    -- DAY-NIGHT --
    DN_SUN_TIMINGS = { 5.328, 21 },                                -- Sun times in hours (float) [sunrise, sunset]
    DN_PRESET_TIMINGS = { 0.222, 0.25, 0.29, 0.75, 0.833, 0.875 }, -- Always need to have the end time of the last preset in a day at the end
    DN_CHANGE_CLOUDS_SPEED_BASED_ON_DAY_LENGTH = false,            -- Synchronizes cloud speed to game time (useful for timelapses)
    PATCH_DN_COMPONENTS = true,                                    -- Applies the needed Patches for Day-Night (removes bright meshes/textures meant for day)

    -- PRINT --
    PRINT_DN_TIME_AND_VISIBILITIES = true, -- Print current time every hour along with the visibilities of the 4 presets
    VEMLogger_ENABLED = true,              -- Enables the use of the VEMLogger Class [DEV]
    VEMLogger_PRINT_ALL = false,           -- Prints All VEMLogger Prints

    -- SERVER --
    SERVER_SYNC_CLIENT_EVERY_TICKS = 2, -- Sync clients with the correct time ever X ticks
    TIME = {
        ENABLED = true,
        DEFAULT_START_HOUR = 5,
        DEFAULT_DAY_DURATION = 1,    -- For testing purposes.
        ONLY_DYNAMIC_PRESETS = false -- If we only want to use Dynamic Presets and avoid de DefaultDynamics ( meaning: use some other presets being registered from another mod.)
    },

    -- DEV --
    ADMINS = { "GreatApo", "IllustrisJack", "FoolHen", "Beschutzer", "Dumpy" }, -- Players that can use the VEM chat commands
    DEV_ENABLE_CHAT_COMMANDS = true,                                            -- Enables the use of VEM Internal Chat Commands
}

MAPS_CONFIG = {
    -- Grand Bazaar
    ['MP_001'] = {
        START_HOUR = 5,
        DAY_DURATION = 28,
    },
    -- Teheran Highway
    ['MP_003'] = {
        START_HOUR = 17,
        DAY_DURATION = 28,
    },
    -- Caspian Border
    ['MP_007'] = {
        START_HOUR = 9,
        DAY_DURATION = 28,
    },
    -- Seine Crossing
    ['MP_011'] = {
        START_HOUR = 14,
        DAY_DURATION = 28,
    },
    -- Operation Firestorm
    ['MP_012'] = {
        START_HOUR = 20,
        DAY_DURATION = 28,
    },
    -- Damavand Peak
    ['MP_013'] = {
        START_HOUR = 3,
        DAY_DURATION = 28,
    },
    -- Noshahr Canals
    ['MP_017'] = {
        START_HOUR = 7,
        DAY_DURATION = 28,
    },
    -- Kharg Island
    ['MP_018'] = {
        START_HOUR = 13,
        DAY_DURATION = 28,
    },
    -- Operation Metro
    ['MP_Subway'] = {
        START_HOUR = 22,
        DAY_DURATION = 28,
    },
    -- Strike at Karkand
    ['XP1_001'] = {
        START_HOUR = 6,
        DAY_DURATION = 28,
    },
    -- Gulf of Oman
    ['XP1_002'] = {
        START_HOUR = 16,
        DAY_DURATION = 28,
    },
    -- Sharqi Peninsula
    ['XP1_003'] = {
        START_HOUR = 19,
        DAY_DURATION = 28,
    },
    -- Wake Island
    ['XP1_004'] = {
        START_HOUR = 11,
        DAY_DURATION = 28,
    },
    -- Donya Fortress
    ['XP2_Palace'] = {
        START_HOUR = 4,
        DAY_DURATION = 28,
    },
    -- Operation 928
    ['XP2_Office'] = {
        START_HOUR = 8,
        DAY_DURATION = 28,
    },
    -- Scrapmetal
    ['XP2_Factory'] = {
        START_HOUR = 0,
        DAY_DURATION = 28,
    },
    -- Ziba Tower
    ['XP2_Skybar'] = {
        START_HOUR = 23,
        DAY_DURATION = 28,
    },
    -- Alborz Mountains
    ['XP3_Alborz'] = {
        START_HOUR = 15,
        DAY_DURATION = 28,
    },
    -- Armored Shield
    ['XP3_Shield'] = {
        START_HOUR = 2,
        DAY_DURATION = 28,
    },
    -- Bandar Desert
    ['XP3_Desert'] = {
        START_HOUR = 21,
        DAY_DURATION = 28,
    },
    -- Death Valley
    ['XP3_Valley'] = {
        START_HOUR = 10,
        DAY_DURATION = 28,
    },
    -- Azadi Palace
    ['XP4_Parl'] = {
        START_HOUR = 5,
        DAY_DURATION = 28,
    },
    -- Epicenter
    ['XP4_Quake'] = {
        START_HOUR = 12,
        DAY_DURATION = 28,
    },
    -- Markaz Monolith
    ['XP4_FD'] = {
        START_HOUR = 1,
        DAY_DURATION = 28,
    },
    -- Talah Market
    ['XP4_Rubble'] = {
        START_HOUR = 18,
        DAY_DURATION = 28,
    },
    -- Operation Riverside
    ['XP5_001'] = {
        START_HOUR = 9,
        DAY_DURATION = 28,
    },
    -- Nebandan Flats
    ['XP5_002'] = {
        START_HOUR = 7,
        DAY_DURATION = 28,
    },
    -- Kiasar Railroad
    ['XP5_003'] = {
        START_HOUR = 16,
        DAY_DURATION = 28,
    },
    -- Sabalan Pipeline
    ['XP5_004'] = {
        START_HOUR = 11,
        DAY_DURATION = 28,
    }

}
