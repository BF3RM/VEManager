class "ve_base"
local table = [[
{
    "LensScope": {
        "Enable": "true",
        "BlurScale": "1",
        "BlurCenter": "0.5:0.5:",
        "ChromaticAberrationColor1": "0.01:0.73:0.73:",
        "ChromaticAberrationColor2": "0.72:0.02:0.73:",
        "ChromaticAberrationStrengths": "0.24:0.23:",
        "ChromaticAberrationDisplacement1": "0.03:0.01:",
        "ChromaticAberrationDisplacement2": "0.02:0.01:",
        "RadialBlendDistanceCoefficients": "4.16:-0.44:"
    },
    "Vignette": {
        "Enable": "false",
        "Scale": "2:2:",
        "Exponent": "0.47",
        "Opacity": "1",
        "Color": "0.74:0.74:0.73:"
    },
    "ColorCorrection": {
        "Brightness": "(0.000000, 1.000000, 1.000000)"
    },
    "Sky": {
        "SunSize": "1",
        "SunScale": "200"
    },
    "Name": "ve_base",
    "Priority": "500",
    "Visibility": "1"
}
]]


function ve_base:GetPreset()
  return table
end

return ve_base  