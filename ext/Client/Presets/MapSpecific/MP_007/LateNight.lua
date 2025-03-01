-- This exists to get rid of the annoying blueish background outlines for the mountains.
return json.decode([[
{
    "Name": "MP_007_Late_Night",
	"Type": "DefaultDynamic",
    "Priority": "10",
    "Visibility": "1",
    "CharacterLighting":{
       	"CharacterLightEnable":"false",
       	"FirstPersonEnable":"false",
       	"LockToCameraDirection":"true",
       	"CameraUpRotation":"27.482999801636",
       	"CharacterLightingMode":"0",
       	"BlendFactor":"1.0",
       	"TopLight":"(1.0, 1.0, 1.0)",
       	"BottomLight":"(1.0, 1.0, 1.0)",
       	"TopLightDirX":"0.0",
       	"TopLightDirY":"0.0"
    },
    "ColorCorrection":{
       	"Enable":"true",
       	"Brightness":"(1.0, 1.0, 1.0)",
       	"Contrast":"(1.1200000047684, 1.1200000047684, 1.1200000047684)",
       	"Saturation":"(0.72750002145767, 0.77249997854233, 0.92250001430511)",
       	"Hue":"0.0",
       	"ColorGradingEnable":"false"
    },
    "DynamicAO":{

    },
    "Enlighten":{
        "Realm": "0",
        "Enable": "false"
    },
    "Fog":{
        "Realm": "0",
		"Enable":"true",
        "FogDistanceMultiplier":"1.0",
        "FogGradientEnable":"true",
        "Start":"-50.0",
        "EndValue":"500.0",
        "FogColorEnable":"true",
        "FogColor":"(0.0020000000949949, 0.0020000000949949, 0.0020000000949949)",
        "FogColorStart":"0.0",
        "FogColorEnd":"1630.4348144531"
    },
    "OutdoorLight":{
       	"Enable":"true",
       	"SunRotationX": "150.0",
		"SunRotationY":"359.0",
       	"SunColor": "(0.04, 0.04, 0.07)",
        "SkyColor": "(0.01, 0.01, 0.01)",
        "GroundColor": "(0.03, 0.03, 0.03)",
        "SkyLightAngleFactor":"0.0",
       	"SunSpecularScale":"0.0",
       	"SkyEnvmapShadowScale":"0.25",
       	"SunShadowHeightScale":"0.0"
    },
    "Sky":{
       	"Enable":"true",
       	"BrightnessScale":"0.0037000000011176",
        "SunSize": "0.0005",
        "SunScale": "80",
        "StaticEnvmapScale": "0.09",
      	"CloudLayerSunColor": "(0, 0, 0)",
        "CloudLayer1SunLightIntensity": "0.1",
        "CloudLayer1SunLightPower": "0.1",
        "CloudLayer1AmbientLightIntensity": "0.1",
        "CloudLayer1Color": "(0.1, 0.1, 0.1)",
        "CloudLayer1AlphaMul": "0.5",
        "CloudLayer2Altitude": "5000000.0",
        "CloudLayer2TileFactor": "0.60000002384186",
        "CloudLayer2Rotation": "237.07299804688",
        "CloudLayer2Speed": "-0.0010000000474975",
        "CloudLayer2SunLightIntensity": "1.0",
        "CloudLayer2SunLightPower": "5.0",
        "CloudLayer2AmbientLightIntensity": "1",
        "CloudLayer2Color": "1:1:1:",
        "CloudLayer2AlphaMul": "0.3",
		"CloudLayer2Texture": "levels/testrange_lighting/sky/sky_07_starlayer_d"
    },
    "SunFlare":{
	    "Enable":"false",
        "Element1Size": "0.0:0.0:",
        "Element2Size": "0.0:0.0:",
        "Element3Size": "0.0:0.0:",
        "Element4Size": "0.0:0.0:",
        "Element5Size": "0.0:0.0:"
    },
    "Tonemap":{

    },
    "Vignette":{
       	"Enable":"true",
       	"Scale":"(2.0, 2.0)",
       	"Exponent":"1.5",
       	"Color":"(0.0, 0.0, 0.0)",
       	"Opacity":"0.2039999961853"
    },
    "Wind":{

    }
}]])
