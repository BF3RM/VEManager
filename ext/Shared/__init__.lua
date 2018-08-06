class 'VEManagerClient'
json = require "__shared/json"
ve_base = require "__shared/ve_base"
ve_preset = require "__shared/ve_preset"

function VEManagerClient:__init()
	print("Initializing VEManagerClient")
	self:RegisterVars()
	self:RegisterEvents()
end


function VEManagerClient:RegisterVars()
	-- We don't have proper .json file support, so we need to include a whole new lua file.
	self.m_RawPresets = {}
	--self.m_RawPresets["preset"] = json.decode(ve_preset:GetPreset())
	self.m_RawPresets["base"] = json.decode(ve_base:GetPreset())

	self.m_SupportedTypes = {"Vec2", "Vec3", "Vec4", "Float32", "Boolean", "Int"}
	self.m_SupportedClasses = {
		"CameraParams",
		"CharacterLighting",
		"ColorCorrection",
		"DamageEffect",
		"Dof",
		"DynamicAO",
		"DynamicEnvmap",
		"Enlighten",
		"FilmGrain",
		"Fog",
		"LensScope",
		"MotionBlur",
		"OutdoorLight",
		"PlanarReflection",
		"ScreenEffect",
		"Sky",
		"SunFlare",
		"Tonemap",
		"Vignette",
		"Wind"}
	self.m_Presets = {}
	self.m_Instances = {}
end


function VEManagerClient:RegisterEvents()
	Hooks:Install('ClientEntityFactory:Create',999, self, self.OnEntityCreate)
	Hooks:Install("ServerEntityFactory:Create", 999, self, self.OnEntityCreate)
	--self.m_OnLoadedEvent = Events:Subscribe('ExtensionLoaded', self, self.OnLoaded)
	self.m_OnUpdateInputEvent = Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)
    Events:Subscribe('Level:LoadResources', self, self.OnLoadResources)
    Events:Subscribe('Client:LevelLoaded', self, self.OnClientLevelLoaded)
end


function VEManagerClient:OnLoadResources()
	self:LoadPresets()
end

function VEManagerClient:LoadPresets()

	print("Loading presets....")
	--Foreach preset
	print(self.m_RawPresets)
	for i, s_Preset in pairs(self.m_RawPresets) do
		
		-- Generate our Logical VE and the blueprint

		-- Not sure if we need the LogicelVEEntity, but :shrug:
		local s_LVEED = self:CreateEntity("LogicVisualEnvironmentEntityData")
		self.m_Presets[s_Preset.Name] = {}
		self.m_Presets[s_Preset.Name]["data"] = s_LVEED
		s_LVEED.visibility = 1

		local s_VEB = self:CreateEntity("VisualEnvironmentBlueprint")
		s_LVEED.visualEnvironment = s_VEB

		local s_VE = self:CreateEntity("VisualEnvironmentEntityData")
		s_VEB.object = s_VE

		s_VE.priority = s_Preset.Priority
		
		--Foreach class
		local componentCount = 0
		for _,l_Class in pairs(self.m_SupportedClasses) do

			if(s_Preset[l_Class] ~= nil) then
				componentCount = componentCount + 1 
				-- Create class and add it to the VE entity.
				local s_Class =  _G[l_Class.."ComponentData"]()
				s_VE.components:add(s_Class)

		
				-- Foreach field in class
				for _, l_Field in ipairs(s_Class.typeInfo.fields) do

					-- Fix lua types
					local s_Field = l_Field.name
					if(s_Field == "End") then
						s_Field = "EndValue"
					end

					-- Get type
					local s_Type = l_Field.typeInfo.name --Boolean, Int32, Vec3 etc.
					-- If the preset contains that field
					if s_Preset[l_Class][s_Field] ~= nil then
						local s_Value = self:ParseValue(s_Type, s_Preset[l_Class][s_Field])
						if(s_Value ~= nil) then
							s_Class[firstToLower(s_Field)] = s_Value
						end
					end 
				end
			end
		end
		s_VE.runtimeComponentCount = componentCount
		s_VE.visibility = 1 
		s_VE.priority = 100
		s_VE.enabled = true
	end
end

function VEManagerClient:OnClientLevelLoaded()

end

-- This one is a little dirty.
function VEManagerClient:CreateEntity(p_Class, p_Guid)
	-- Create the instance
	local s_Entity = _G[p_Class]()

	if(p_Guid == nil) then
		-- Clone the instance and return the clone with a randomly generated Guid
		return _G[p_Class](s_Entity:Clone(self:GenerateGuid()))
	else 
		return _G[p_Class](s_Entity:Clone(p_Guid))
	end
end

function VEManagerClient:OnEntityCreate(p_Hook, p_Data, p_Transform)
	print(p_Data.typeInfo.name .. " - " .. tostring(p_Data.instanceGuid))
	local x = p_Hook:Call()
	print(tostring(x.typeName))
		if(p_Data.typeInfo.name == "VisualEnvironmentEntityData") then
		
	end
end

function VEManagerClient:OnUpdateInput(p_Delta, p_SimulationDelta)

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F1) then
		if(#self.m_Presets == 0) then
			self:LoadPresets()
		end

		for i, s_Preset in pairs(self.m_Presets) do
			s_Preset["entity"] = EntityManager:CreateClientEntity(s_Preset["data"], LinearTransform())
			print("so far so good")

			if s_Preset["entity"] == nil then
				print("Could not spawn explosion")
				return
			end
			s_Preset["entity"]:Init(Realm.Realm_Client, true)
			s_Preset["entity"]:FireEvent("Enable")
			VisualEnvironmentManager.dirty = true
		end
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F2) then
		for i, s_Preset in pairs(self.m_Presets) do
			s_Preset["data"].visibility = s_Preset["data"].visibility - 0.1
			s_Preset["entity"]:FireEvent("Disable")
			s_Preset["entity"]:FireEvent("Enable")
		end
	end
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F3) then
		for i, s_Preset in pairs(self.m_Presets) do
			s_Preset["data"].visibility = s_Preset["data"].visibility + 0.1
			s_Preset["entity"]:FireEvent("Disable")
			s_Preset["entity"]:FireEvent("Enable")
		end
	end
end


function VEManagerClient:ParseValue(p_Type, p_Value)
	-- This seperates Vectors. Let's just do it to everything, who cares?
	if(p_Type == "Boolean") then
		if(p_Value == "true") then
			return true
		else
			return false
		end
	elseif(p_Type == "Enum") then -- Enum
		return tonumber(p_Value)

	elseif(p_Type == "Float32") then
		return tonumber(p_Value)

	elseif(p_Type == "Vec2") then -- Vec2
		local s_Vec = HandleVec(p_Value)
		return Vec2(tonumber(s_Vec[1]), tonumber(s_Vec[2]))

	elseif(p_Type == "Vec3") then -- Vec3
		local s_Vec = HandleVec(p_Value)
		return Vec3(tonumber(s_Vec[1]), tonumber(s_Vec[2]), tonumber(s_Vec[3]))

	elseif(p_Type == "Vec4") then -- Vec4
		local s_Vec = HandleVec(p_Value)
		return Vec4(tonumber(s_Vec[1]), tonumber(s_Vec[2]), tonumber(s_Vec[3]), tonumber(s_Vec[4]))
	else 
		print("Unhandled type: " .. p_Type)
		return
	end
end

function h() 
    local vars = {"A","B","C","D","E","F","0","1","2","3","4","5","6","7","8","9"}
    return vars[math.floor(SharedUtils:GetRandom(1,16))]..vars[math.floor(SharedUtils:GetRandom(1,16))]
end
function VEManagerClient:GenerateGuid() 
    return Guid(h()..h()..h()..h().."-"..h()..h().."-"..h()..h().."-"..h()..h().."-"..h()..h()..h()..h()..h()..h(), "D")
end

function HandleVec(vec)
	local s_fixedContents = string.gsub(vec, "%(", "")
	s_fixedContents = string.gsub(s_fixedContents, "%)", "")
	s_fixedContents = string.gsub(s_fixedContents, ", ", ":")
	return split(s_fixedContents, ":")
end
function firstToUpper(str)
	return (str:gsub("^%U", string.upper))
end

function firstToLower(str)
	return (str:gsub("^%L", string.lower))
end
function split(pString, pPattern)
	local Table = {} -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table,cap)
		end
		last_end = e+1
		s, e, cap = pString:find(fpat, last_end)
	end
	if last_end <= #pString then
		cap = pString:sub(last_end)
		table.insert(Table, cap)
	end
	return Table
end

function dump(o)
	if(o == nil) then
		print("tried to load jack shit")
	end
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end



g_VEManagerClient = VEManagerClient()

