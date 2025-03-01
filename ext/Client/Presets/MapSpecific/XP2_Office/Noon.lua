-- Teheran Highway (MP_003) is already a night map, therefore it needs some more editing for its noon preset.
return json.decode([[
{
    "CharacterLighting": {
        "CharacterLightEnable": "true",
        "FirstPersonEnable": "true",
        "LockToCameraDirection": "true",
        "CameraUpRotation": "27.482999801636",
        "CharacterLightingMode": "1",
        "BlendFactor": "0.02",
        "TopLight": "1:1:1:",
        "BottomLight": "1:1:1:",
        "TopLightDirX": "0",
        "TopLightDirY": "0.0"
    },
    "ColorCorrection": {

    },
    "DynamicAO": {

    },
    "Enlighten": {
        "Realm": "0",
        "Enable": "false"
    },
    "Fog": {

    },
    "OutdoorLight": {
        "Realm": "0",
        "Enable": "true",
	    "SunColor": "(5, 3.5870, 3.0435)",
        "SkyColor": "(0.3804, 0.2174, 0.2174)",
        "GroundColor": "(0.0, 0.0, 0.0)",
        "SkyLightAngleFactor": "4",
        "SunSpecularScale": "5",
        "SunShadowHeightScale":"1.0",
        "SunRotationX": "150.0",
        "SunRotationY": "90.0"
    },
    "Sky": {
        "Realm": "0",
        "Enable": "true",
        "SunSize": "0.01",
        "SunScale": "1.5",
		"BrightnessScale":"5",
        "StaticEnvmapScale":"0.0",
        "CloudLayer1Altitude": "500000.0",
        "CloudLayer1TileFactor": "0.25",
        "CloudLayer1Rotation": "223.52900695801",
        "CloudLayer1Speed": "-0.001",
        "CloudLayer1SunLightIntensity": "0.5",
        "CloudLayer1SunLightPower": "0.5",
        "CloudLayer1AmbientLightIntensity": "0.5",
        "CloudLayer1Color": "(0.3, 0.3, 0.3)",
        "CloudLayer1AlphaMul": "0.8",
        "CloudLayer2Altitude": "5000000.0",
        "CloudLayer2TileFactor": "0.60000002384186",
        "CloudLayer2Rotation": "237.07299804688",
        "CloudLayer2Speed": "-0.0010000000474975",
        "CloudLayer2SunLightIntensity": "0",
        "CloudLayer2SunLightPower": "0",
        "CloudLayer2AmbientLightIntensity": "0",
        "CloudLayer2Color": "0:0:0:",
        "CloudLayer2AlphaMul": "0.0",
		"CloudLayer2Texture": "levels/testrange_lighting/sky/sky_07_starlayer_d"
    },
    "SunFlare": {

    },
    "Tonemap": {

    },
    "Wind": {

    },
    "Name": "XP2_Office_Noon",
    "Type": "DefaultDynamic",
    "Priority": "10",
    "Visibility": "1"
}]])
