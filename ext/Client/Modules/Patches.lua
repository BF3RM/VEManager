---@class Patches
Patches = class('Patches')

local m_PatchDatatable = require('Modules/PatchDatatable')
local m_Easing = require('Modules/Easing')

---@type Logger
local m_Logger = Logger("Patches", true)

local m_MenuBgGuids = {
	partition = Guid("3A3E5533-4B2A-11E0-A20D-FE03F1AD0E2F", "D"),
	instance = Guid("F26B7ECE-A71D-93AC-6C49-B6223BF424D6", "D")
}

local m_RelevantColorCorrection = {
	-- https://github.com/EmulatorNexus/Venice-EBX/blob/master/FX/VisualEnviroments/Fullscreen/VE_FS_DmgHitEffect.txt
	dmgHitEffect = {partition = Guid("1C1B3484-6B73-40D8-B147-0EC4526D62A0"), instance = Guid("26F0FAD2-B92A-4D20-AFA5-8F4E2AAB98DE"), multiplier = { contrast = Vec3(1.1, 1.1, 1.1), saturation = Vec3(0.442, 0.002, 0.002)}}
}

function Patches:__init()
	m_Logger:Write("Initializing Patches")

	-- Patches based on GUIDs
	ResourceManager:RegisterInstanceLoadHandler(m_MenuBgGuids.partition, m_MenuBgGuids.instance, self, self.onMenuBgLoaded)
end

---@param p_LevelName string
---@param p_GameMode string
---@param p_IsDedicatedServer boolean
function Patches:OnLevelLoaded(p_LevelName, p_GameMode, p_IsDedicatedServer)
	-- Disable Vanilla Explosion VEs
	if VEM_CONFIG.PATCH_EXPLOSIONS_COLOR_CORRECTION then
		self:DisableExplosionVisualEnvironments()
	end
end

---@param p_CurrentColorCorrection ColorCorrectionComponentData|nil
function Patches:OverwriteBaseColorCorrection(p_CurrentColorCorrection)
	local s_NewBase = p_CurrentColorCorrection:Clone()

	for _, l_ModificationTable in pairs(m_RelevantColorCorrection) do
		local s_ModifiedColorCorrection = ResourceManager:FindInstanceByGuid(l_ModificationTable["partition"], l_ModificationTable["instance"])

		if s_ModifiedColorCorrection ~= nil and s_NewBase ~= nil then
			s_ModifiedColorCorrection = s_NewBase
			s_ModifiedColorCorrection = ColorCorrectionComponentData(s_ModifiedColorCorrection)
			s_ModifiedColorCorrection:MakeWritable()
			s_ModifiedColorCorrection.contrast = s_ModifiedColorCorrection.contrast * l_ModificationTable["multiplier"].contrast
			s_ModifiedColorCorrection.saturation = s_ModifiedColorCorrection.saturation * l_ModificationTable["multiplier"].saturation
			m_Logger:Write("Modified Base Color Correction & Applied Original CC Factors")
		end
	end
end

---@param p_Partition DatabasePartition
function Patches:Components(p_Partition)
	if p_Partition.primaryInstance:Is("MeshAsset") then
		self:MeshAsset(p_Partition.primaryInstance)
	elseif p_Partition.primaryInstance:Is("ObjectVariation") then
		for _, l_Instance in pairs(p_Partition.instances) do
			if l_Instance:Is('MeshMaterialVariation') then -- ObjectVariation is the primary instance
				self:MeshMaterialVariation(l_Instance)
			end
		end
	elseif p_Partition.primaryInstance:Is("Blueprint") then
		for _, l_Instance in pairs(p_Partition.instances) do
			if l_Instance:Is('LensFlareEntityData') then -- PrefabBlueprint is the primary instance
				self:LensFlareEntityData(l_Instance)
			elseif l_Instance:Is('LocalLightEntityData') then -- Blueprint is the primary instance
				self:LightSmoothening(l_Instance)
			-- elseif l_Instance:Is('SkyComponentData') then -- VisualEnvironmentBlueprint is the primary instance
				-- self:SkyComponentData(l_Instance)
			-- elseif l_Instance:Is('EffectEntityData') then -- EffectBlueprint is the primary instance
				-- self:EffectEntityData(l_Instance)
			end
		end
	end
end

---@param p_Instance MeshAsset|nil
function Patches:MeshAsset(p_Instance)
	if m_PatchDatatable.meshes[p_Instance.partition.name] then
		local mesh = MeshAsset(p_Instance)

		for _, value in pairs(mesh.materials) do
			value:MakeWritable()
			value.shader.shader = nil
		end
	end
end

---@param p_Instance MeshMaterialVariation|nil
function Patches:MeshMaterialVariation(p_Instance)
	if m_PatchDatatable.variations[p_Instance.partition.name] then
		local variation = MeshMaterialVariation(p_Instance)
		variation:MakeWritable()
		variation.shader.shader = nil
	end
end

---@param p_Instance EffectEntityData|nil
function Patches:EffectEntityData(p_Instance)
	if m_PatchDatatable.effects[p_Instance.partition.name] then
		local effect = EffectEntityData(p_Instance)
		effect:MakeWritable()

		effect.components:clear()
	end
end

---@param p_Instance SkyComponentData|nil
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

---@param p_Instance LensFlareEntityData|nil
function Patches:LensFlareEntityData(p_Instance)
	local flares = LensFlareEntityData(p_Instance)
	flares:MakeWritable()
	for _, element in pairs(flares.elements) do
		element.size = element.size * 0.3
	end
end

---@param p_Instance LocalLightEntityData|nil
function Patches:LightSmoothening(p_Instance)
	local BetterLight = LocalLightEntityData(p_Instance)
	BetterLight:MakeWritable()
	BetterLight.radius = BetterLight.radius * 1.25
	BetterLight.intensity = BetterLight.intensity * 0.65
	BetterLight.attenuationOffset = BetterLight.attenuationOffset * 17.5
end

---@param p_Instance VisualEnvironmentEntityData|nil
function Patches:onMenuBgLoaded(p_Instance)
	-- Increase priority of menu bg
	-- https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/UI/Assets/MenuVisualEnvironment.txt#L140
	local s_MenuBg = VisualEnvironmentEntityData(p_Instance)
	s_MenuBg:MakeWritable()
	s_MenuBg.priority = 100099

	m_Logger:Write("Menu background patched (priority increased)")
end

function Patches:DisableExplosionVisualEnvironments()
	-- get entityData
	local explosionVES = {
		blackoutVE = ResourceManager:FindInstanceByGuid(Guid("0A0EB8EE-5849-4C88-B4B9-92A9C2AA6402"), Guid("7B728DE9-327D-45E2-9309-1E602DEDFA2D")),
		blastMediumVE = ResourceManager:FindInstanceByGuid(Guid("CD2CD917-DA8F-11DF-98D7-E3FCCF5294D0"), Guid("FA601D0C-F768-F778-6C3C-EF9667C4A7A4")),
		blastLargeVE = ResourceManager:FindInstanceByGuid(Guid("EB5AFBB4-ED86-421E-88AE-5E0CE8B27C85"), Guid("DD94E869-9E43-43E6-B7CF-D4A9B017C693")),
		blastGasMediumVE = ResourceManager:FindInstanceByGuid(Guid("D9BFDE03-6E38-4638-87BD-C79A34FBE598"), Guid("3A65A77C-10BB-4D06-8589-04C29AF89560"))
	}

	for _, l_EntityData in pairs(explosionVES) do
		if l_EntityData ~= nil then
			l_EntityData = GameEntityData(l_EntityData)
			l_EntityData:MakeWritable()
			l_EntityData.enabled = false
		end
	end
end

return Patches()
