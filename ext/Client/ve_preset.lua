class "ve_preset"
local table = [[
{
    "Name": "ve_preset",
    "Priority": "1",
    "ColorCorrection": {
        "Brightness": "(0.000000, 1.000000, 1.000000)"
    }
}
]]


function ve_preset:GetPreset()
  return table
end

return ve_preset