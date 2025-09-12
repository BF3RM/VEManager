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
        "SunSpecularScale":"5.0",
        "SkyLightAngleFactor": "4",
        "SunShadowHeightScale":"1.0",
        "SunRotationX": "150.0",
        "SunRotationY": "90.0"
    },
    "Sky": {
        "Realm": "0",
        "Enable": "true",
        "SunSize": "0.01",
        "SunScale": "1.5",
		"BrightnessScale":"8",
        "CloudLayer1Color": "0:0:0"
    },
    "SunFlare": {

    },
    "Tonemap": {

    },
    "Wind": {

    },
    "Name": "MP_003_Noon",
    "Type": "DefaultDynamic",
    "Priority": "10",
    "Visibility": "1"
}]])
