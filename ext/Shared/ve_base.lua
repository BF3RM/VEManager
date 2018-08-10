class "ve_base"
local table = [[
{
    "Name": "ve_base",
    "Priority": "1",
    "Visibility": "1",
    "OutdoorLight": {
        "Realm": "nil",
        "Enable": "true",
        "SunRotationX": "90.57800292969",
        "SunRotationY": "46.397998809814",
        "SunColor": "(3.000000, 2.756000, 1.896000)",
        "SkyColor": "(0.153000, 0.235000, 0.415000)",
        "GroundColor": "(0.135000, 0.154000, 0.121000)",
        "SkyLightAngleFactor": "0.0",
        "SunSpecularScale": "1.0",
        "SkyEnvmapShadowScale": "1.0",
        "SunShadowHeightScale": "0.5",
        "CloudShadowEnable": "true",
        "CloudShadowTexture": "sol.sol::detail::unique_usertype<VeniceEXT::Classes::Shared::DataContainer>: 40E32890",
        "CloudShadowSpeed": "(0.000000, 0.000000)",
        "CloudShadowSize": "35000.0",
        "CloudShadowCoverage": "1.0",
        "CloudShadowExponent": "1.0",
        "TranslucencyAmbient": "0.0",
        "TranslucencyScale": "0.0",
        "TranslucencyPower": "8.0",
        "TranslucencyDistortion": "0.10000000149012"
    }
}
]]


function ve_base:GetPreset()
  return table
end

return ve_base