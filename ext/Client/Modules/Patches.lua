local Patches = class('Patches')
local PatchData = require('modules/patchdatatable')

local m_Logger = Logger("Patches", false)


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
    BetterLight.attenuationOffset = BetterLight.attenuationOffset * 17.5
end

local m_MenuBgGuids = {
	partition = Guid("3A3E5533-4B2A-11E0-A20D-FE03F1AD0E2F", "D"),
	instance = Guid("F26B7ECE-A71D-93AC-6C49-B6223BF424D6", "D")
}

function Patches:__init()
    m_Logger:Write("Initializing Patches")

	-- Patches based on GUIDs
	ResourceManager:RegisterInstanceLoadHandler(m_MenuBgGuids.partition, m_MenuBgGuids.instance, self, self.onMenuBgLoaded)
end

-- https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/UI/Assets/MenuVisualEnvironment.txt#L140
function Patches:onMenuBgLoaded(p_Instance)
	-- Increase priority of menu bg
	local s_MenuBg = VisualEnvironmentEntityData(p_Instance)
    s_MenuBg:MakeWritable()
    s_MenuBg.priority = 100099
	
	m_Logger:Write("Menu bg patched")
end

-- Singleton.
if g_Patches == nil then
	g_Patches = Patches()
end

return g_Patches