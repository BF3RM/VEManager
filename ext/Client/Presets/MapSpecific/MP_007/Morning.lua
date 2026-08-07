-- This exist only to add those missing SunFlares for this map.
return json.decode([[
{
    "CharacterLighting": {

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
        "SkyLightAngleFactor": "4",
        "SunSpecularScale": "5",
        "SunShadowHeightScale":"1.0",
        "SunColor": "(5.0, 1.7, 1.0)",
        "GroundColor": "(0.0, 0.0, 0.0)",
        "SunRotationX": "150.0",
        "SunRotationY": "10"
    },
    "Sky": {
        "Realm": "0",
        "Enable": "true",
        "BrightnessScale": "5",
        "SunSize": "0.01",
        "SunScale": "2",
        "CloudLayerSunColor": "(1, 0.16, 0.06)",
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
        "Element1Size": "0.10:0.10:",
        "Element2Size": "0.10:0.10:",
        "Element3Size": "0.10:0.10:",
        "Element4Size": "0.10:0.10:",
        "Element5Size": "0.10:0.10:"
    },
    "Tonemap": {

    },
    "Wind": {

    },
    "Name": "MP_007_Morning",
    "Type": "DefaultDynamic",
    "Priority": "10",
    "Visibility": "1"
}
]])
