local Patches = class('Patches')
local PatchData = require('modules/patchdatatable')


function Patches:Components(partition)
    for _, instance in pairs(partition.instances) do

        if instance:Is('MeshAsset') then
            Patches:MeshAsset(instance)
        elseif instance:Is('MeshMaterialVariation') then
            Patches:MeshMaterialVariation(instance)
        elseif instance:Is('LensFlareEntityData') then
            Patches:LensFlareEntityData(instance)
        elseif instance:Is('LocalLightEntityData') then
            Patches:LightSmoothening(instance)
	    end

    end
end


function Patches:MeshAsset(instance)
    if PatchData.meshs[instance.partition.name] then
        local mesh = MeshAsset(instance)

        for _, value in pairs(mesh.materials) do
            value:MakeWritable()
            value.shader.shader = nil
        end
    end
end


function Patches:MeshMaterialVariation(instance)
    if PatchData.variations[instance.partition.name] then
        local variation = MeshMaterialVariation(instance)
        variation:MakeWritable()
        variation.shader.shader = nil
    end
end


function Patches:EffectEntityData(instance)
    if PatchData.effects[instance.partition.name] then
        local effect = EffectEntityData(instance)
        effect:MakeWritable()

        effect.components:clear()
    end
end


function Patches:SkyComponentData(instance)
    local sky = SkyComponentData(instance)
    sky:MakeWritable()

    sky.brightnessScale = 0.01
    sky.sunSize = 0.01
    sky.sunScale = 1

    sky.cloudLayer1SunLightIntensity = 0.01
    sky.cloudLayer1SunLightPower = 0.01
    sky.cloudLayer1AmbientLightIntensity = 0.01

    sky.cloudLayer2SunLightIntensity = 0.01
    sky.cloudLayer2SunLightPower = 0.01
    sky.cloudLayer2AmbientLightIntensity = 0.01

    sky.staticEnvmapScale = 0.1
    sky.skyEnvmap8BitTexScale = 0.8

    if PatchData.envmaps[sky.partition.name] then
        sky.staticEnvmapScale = 0.01
    end

    if sky.partition.name == 'levels/mp_subway/lighting/ve_mp_subway_subway_01' then

        local partitionGuid = Guid('36536A99-7BE3-11E0-8611-A913E18AE9A4') -- levels/sp_paris/lighting/sp_paris_static_envmap
        local instanceGuid = Guid('64EE680C-405E-2E81-E327-6DF58605AB0B') -- TextureAsset

        ResourceManager:RegisterInstanceLoadHandlerOnce(partitionGuid, instanceGuid, function(loadedInstance)
            sky.staticEnvmapTexture = TextureAsset(loadedInstance)
        end)

    end

end


function Patches:LensFlareEntityData(instance)
    local flares = LensFlareEntityData(instance)
    flares:MakeWritable()
    for _, element in pairs(flares.elements) do

        element.size = element.size * 0.3

    end
end


function Patches:LightSmoothening(instance)
    local BetterLight = LocalLightEntityData(instance)
    BetterLight:MakeWritable()
    BetterLight.radius = BetterLight.radius * 1.25
    BetterLight.intensity = BetterLight.intensity * 0.65
    BetterLight.enlightenColorMode = 0
    BetterLight.enlightenEnable = true
    BetterLight.attenuationOffset = BetterLight.attenuationOffset * 17.5
end


return Patches