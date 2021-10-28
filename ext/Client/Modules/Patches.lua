local Patches = class('Patches')
local PatchData = require('modules/patchdatatable')

local m_Logger = Logger("Patches", false)

local m_MenuBgGuids = {
	partition = Guid("3A3E5533-4B2A-11E0-A20D-FE03F1AD0E2F", "D"),
	instance = Guid("F26B7ECE-A71D-93AC-6C49-B6223BF424D6", "D")
}

local m_ExplosionGuids = {
    Guid("0A0EB8EE-5849-4C88-B4B9-92A9C2AA6402"),
    Guid("D9BFDE03-6E38-4638-87BD-C79A34FBE598"),
    Guid("EB5AFBB4-ED86-421E-88AE-5E0CE8B27C85"),
    Guid("CD2CD917-DA8F-11DF-98D7-E3FCCF5294D0"),
    Guid("C2B0B503-7F38-4CF4-833F-0468EE51C7F2"),
}

g_TextureAssets = {}

function Patches:__init()
	m_Logger:Write("Initializing Patches")

	-- Patches based on GUIDs
	ResourceManager:RegisterInstanceLoadHandler(m_MenuBgGuids.partition, m_MenuBgGuids.instance, self, self.onMenuBgLoaded)
end

function Patches:Components(p_Partition)
	
	for _, l_Instance in pairs(p_Partition.instances) do
		if l_Instance:Is('MeshAsset') then
			Patches:MeshAsset(l_Instance)
		
		elseif l_Instance:Is('MeshMaterialVariation') then
			Patches:MeshMaterialVariation(l_Instance)
		
		--elseif l_Instance:Is('EffectEntityData') then
		--    Patches:EffectEntityData(l_Instance)
		--elseif l_Instance:Is('SkyComponentData') then
		--    Patches:SkyComponentData(l_Instance)
		
		elseif l_Instance:Is('LensFlareEntityData') then
			Patches:LensFlareEntityData(l_Instance)
		
		elseif l_Instance:Is('LocalLightEntityData') then
			Patches:LightSmoothening(l_Instance)

		end
	end
end

function Patches:ExplosionsVE(p_Partition)
	
	isExplosionGuid = g_VEManagerClient.m_Easing.tableHasValue(m_ExplosionGuids, p_Partition.guid)
	
	for _, l_Instance in pairs(p_Partition.instances) do
		if isExplosionGuid and l_Instance:Is('ColorCorrectionComponentData') then
			local s_ComponentData = ColorCorrectionComponentData(l_Instance)
			s_ComponentData:MakeWritable()
			s_ComponentData.enable = false
			m_Logger:Write("*Disable Explosion CC Component")
		end
	end
end

function Patches:MeshAsset(p_Instance)
	if PatchData.meshes[p_Instance.partition.name] then
		local mesh = MeshAsset(p_Instance)

		for _, value in pairs(mesh.materials) do
			value:MakeWritable()
			value.shader.shader = nil
		end
	end
end

function Patches:MeshMaterialVariation(p_Instance)
	if PatchData.variations[p_Instance.partition.name] then
		local variation = MeshMaterialVariation(p_Instance)
		variation:MakeWritable()
		variation.shader.shader = nil
	end
end

function Patches:EffectEntityData(p_Instance)
	if PatchData.effects[p_Instance.partition.name] then
		local effect = EffectEntityData(p_Instance)
		effect:MakeWritable()

		effect.components:clear()
	end
end

function Patches:SkyComponentData(p_Instance)
	local sky = SkyComponentData(p_Instance)
	sky:MakeWritable()

	if sky.partition.name == 'levels/mp_subway/lighting/ve_mp_subway_subway_01' then
		local partitionGuid = Guid('36536A99-7BE3-11E0-8611-A913E18AE9A4') -- levels/sp_paris/lighting/sp_paris_static_envmap
		local instanceGuid = Guid('64EE680C-405E-2E81-E327-6DF58605AB0B') -- TextureAsset

		ResourceManager:RegisterInstanceLoadHandlerOnce(partitionGuid, instanceGuid, function(p_LoadedInstance)
			sky.staticEnvmapTexture = TextureAsset(p_LoadedInstance)
		end)
	end
end

function Patches:LensFlareEntityData(p_Instance)
	local flares = LensFlareEntityData(p_Instance)
	flares:MakeWritable()
	for _, element in pairs(flares.elements) do
		element.size = element.size * 0.3
	end
end

function Patches:LightSmoothening(p_Instance)
	local BetterLight = LocalLightEntityData(p_Instance)
	BetterLight:MakeWritable()
	BetterLight.radius = BetterLight.radius * 1.25
	BetterLight.intensity = BetterLight.intensity * 0.65
	BetterLight.attenuationOffset = BetterLight.attenuationOffset * 17.5
end

function Patches:onMenuBgLoaded(p_Instance)
	-- Increase priority of menu bg
	-- https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/UI/Assets/MenuVisualEnvironment.txt#L140
	local s_MenuBg = VisualEnvironmentEntityData(p_Instance)
	s_MenuBg:MakeWritable()
	s_MenuBg.priority = 100099
	
	m_Logger:Write("Menu background patched (priority increased)")
end

function Patches:LogComponents(p_Partition)
	if p_Partition.primaryInstance:Is('TextureAsset') then
		local name = p_Partition.name:lower()
		-- Save /sky/ or /Lighting/ textures
		for _, l_Parameter in pairs(VEM_CONFIG.DEV_SEARCH_PARAMETERS_FOR_TEXTURES) do

			if string.find(name, l_Parameter) then

				m_Logger:Write("Loaded TextureAsset: " .. name)
				-- Save texture in the list
				g_TextureAssets[name] = p_Partition.primaryInstance
			end
		end
	end
end

-- Singleton.
if g_Patches == nil then
	g_Patches = Patches()
end

return g_Patches