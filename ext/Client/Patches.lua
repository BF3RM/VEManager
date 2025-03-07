---@class Patches
---@overload fun():Patches
---@diagnostic disable-next-line: assign-type-mismatch
Patches = class('Patches')

local m_PatchDatatable = require('EmitterMeshPatchDatatable')

---@type VEMLogger
local m_VEMLogger = VEMLogger("Patches", false)

function Patches:__init()
	m_VEMLogger:Write("Initializing Patches")

	-- Patch Menu Background
	ResourceManager:RegisterInstanceLoadHandler(Guid("3A3E5533-4B2A-11E0-A20D-FE03F1AD0E2F"),
		Guid("F26B7ECE-A71D-93AC-6C49-B6223BF424D6"), self, self._OnMenuBGLoaded)
end

---@param p_Instance DataContainer
local function _PatchMeshAsset(p_Instance)
	if m_PatchDatatable.meshes[p_Instance.partition.name] then
		local s_Mesh = MeshAsset(p_Instance)

		for _, l_Material in pairs(s_Mesh.materials) do
			l_Material:MakeWritable()
			l_Material.shader.shader = nil
		end
	end
end

---@param p_Instance DataContainer
local function _PatchMeshMaterialVariation(p_Instance)
	if m_PatchDatatable.variations[p_Instance.partition.name] then
		local s_Variation = MeshMaterialVariation(p_Instance)
		s_Variation:MakeWritable()
		s_Variation.shader.shader = nil
	end
end

---@param p_Instance DataContainer
local function _PatchEffectEntityData(p_Instance)
	if m_PatchDatatable.effects[p_Instance.partition.name] then
		local s_Effect = EffectEntityData(p_Instance)
		s_Effect:MakeWritable()
		s_Effect.components:clear()
	end
end

---@param p_Instance DataContainer
local function _PatchSkyComponentData(p_Instance)
	local s_Sky = SkyComponentData(p_Instance)
	s_Sky:MakeWritable()

	if s_Sky.partition.name == 'levels/mp_subway/lighting/ve_mp_subway_subway_01' then
		local s_PartitionGuid = Guid('36536A99-7BE3-11E0-8611-A913E18AE9A4') -- levels/sp_paris/lighting/sp_paris_static_envmap
		local s_InstanceGuid = Guid('64EE680C-405E-2E81-E327-6DF58605AB0B') -- TextureAsset

		ResourceManager:RegisterInstanceLoadHandlerOnce(s_PartitionGuid, s_InstanceGuid, function(p_LoadedInstance)
			s_Sky.staticEnvmapTexture = TextureAsset(p_LoadedInstance)
		end)
	end
end


---@param p_Instance DataContainer
local function _PatchEmitterTemplateData(p_Instance)
	if m_PatchDatatable.emitters[p_Instance.partition.name] then
		local s_emitter = EmitterTemplateData(p_Instance)
		s_emitter:MakeWritable()
		s_emitter.emissive = false
	end
end

---@param p_Instance DataContainer
local function _PatchLensFlareEntityData(p_Instance)
	local s_Flares = LensFlareEntityData(p_Instance)
	s_Flares:MakeWritable()

	for _, l_Element in pairs(s_Flares.elements) do
		l_Element.size = l_Element.size * 0.3
	end
end

---@param p_Instance DataContainer
local function _ApplyLightSmoothening(p_Instance)
	local s_PatchedLight = LocalLightEntityData(p_Instance)
	s_PatchedLight:MakeWritable()
	s_PatchedLight.radius = s_PatchedLight.radius * 1.25
	s_PatchedLight.intensity = s_PatchedLight.intensity * 0.65
	s_PatchedLight.attenuationOffset = s_PatchedLight.attenuationOffset * 17.5
	-- if p_Instance.typeInfo.name == 'SpotLightEntityData' then
	-- 	PatchSpotlights(p_Instance)
	-- end
end

local function _PatchSpotlights(p_Instance)
	p_Instance = SpotLightEntityData(p_Instance)
	p_Instance:MakeWritable()

	p_Instance.castShadowsEnable = true
	p_Instance.castShadowsMinLevel = 3
	p_Instance.coneInnerAngle = p_Instance.coneInnerAngle * 1
	p_Instance.coneOuterAngle = p_Instance.coneOuterAngle * 2
end

local function _DisableExplosionVisualEnvironments()
	-- get entityData
	local s_ExplosionVisualEnvironments = {
		blackoutVE = ResourceManager:FindInstanceByGuid(Guid("0A0EB8EE-5849-4C88-B4B9-92A9C2AA6402"),
			Guid("7B728DE9-327D-45E2-9309-1E602DEDFA2D")),
		blastMediumVE = ResourceManager:FindInstanceByGuid(Guid("CD2CD917-DA8F-11DF-98D7-E3FCCF5294D0"),
			Guid("FA601D0C-F768-F778-6C3C-EF9667C4A7A4")),
		blastLargeVE = ResourceManager:FindInstanceByGuid(Guid("EB5AFBB4-ED86-421E-88AE-5E0CE8B27C85"),
			Guid("DD94E869-9E43-43E6-B7CF-D4A9B017C693")),
		blastGasMediumVE = ResourceManager:FindInstanceByGuid(Guid("D9BFDE03-6E38-4638-87BD-C79A34FBE598"),
			Guid("3A65A77C-10BB-4D06-8589-04C29AF89560"))
	}

	for _, l_EntityData in pairs(s_ExplosionVisualEnvironments) do
		if l_EntityData ~= nil then
			l_EntityData = GameEntityData(l_EntityData)
			l_EntityData:MakeWritable()
			l_EntityData.enabled = false
		end
	end
end

---@param p_LevelName string
---@param p_GameMode string
---@param p_IsDedicatedServer boolean
function Patches:OnLevelLoaded(p_LevelName, p_GameMode, p_IsDedicatedServer)
	-- Disable Vanilla Explosion VEs
	if VEM_CONFIG.PATCH_EXPLOSIONS_COLOR_CORRECTION then
		_DisableExplosionVisualEnvironments()
	end
end

---@param p_Partition DatabasePartition
function Patches:PatchComponents(p_Partition)
	-- print('The partition: ' .. tostring(p_Partition))
	-- print('The partition primaryInstance typeinfo elementType: ' ..
	-- tostring(p_Partition.primaryInstance.typeInfo.elementType))
	-- print('The partition primaryInstance typeinfo name : ' .. tostring(p_Partition.primaryInstance.typeInfo.name))

	if not VEM_CONFIG.PATCH_DN_COMPONENTS then
		return
	end

	if p_Partition.primaryInstance:Is("MeshAsset") then
		_PatchMeshAsset(p_Partition.primaryInstance)
	elseif p_Partition.primaryInstance:Is("ObjectVariation") then
		for _, l_Instance in ipairs(p_Partition.instances) do
			if l_Instance:Is('MeshMaterialVariation') then -- ObjectVariation is the primary instance
				_PatchMeshMaterialVariation(l_Instance)
			end
		end
	elseif p_Partition.primaryInstance:Is("Blueprint") then
		for _, l_Instance in ipairs(p_Partition.instances) do
			if l_Instance:Is('LensFlareEntityData') then -- PrefabBlueprint is the primary instance
				_PatchLensFlareEntityData(l_Instance)
			elseif l_Instance:Is('LocalLightEntityData') then -- Blueprint is the primary instance
				_ApplyLightSmoothening(l_Instance)
				-- elseif l_Instance:Is('SkyComponentData') then -- VisualEnvironmentBlueprint is the primary instance
				-- self:SkyComponentData(l_Instance)
			elseif l_Instance:Is('SpotLightEntityData') then
				_PatchSpotlights(l_Instance)
			elseif l_Instance:Is('EffectEntityData') then -- EffectBlueprint is the primary instance
				_PatchEffectEntityData(l_Instance)
			end
		end
	elseif p_Partition.primaryInstance:Is("EmitterTemplateData") then
		_PatchEmitterTemplateData(p_Partition.primaryInstance)
	end
end

---@param p_Instance DataContainer
function Patches:_OnMenuBGLoaded(p_Instance)
	-- Increase priority of menu bg
	-- https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/UI/Assets/MenuVisualEnvironment.txt#L140
	local s_MenuBg = VisualEnvironmentEntityData(p_Instance)
	s_MenuBg:MakeWritable()
	s_MenuBg.priority = 100

	m_VEMLogger:Write("Menu background patched (priority increased)")
end

return Patches()
