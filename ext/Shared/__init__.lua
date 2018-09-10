class 'VEManagerClient'
json = require "__shared/json"
-- ve_base = require "__shared/ve_base"
easing = require "__shared/easing"

function VEManagerClient:__init()
	print("Initializing VEManagerClient")
	self:RegisterVars()
	self:RegisterEvents()
end


function VEManagerClient:RegisterVars()
	-- We don't have proper .json file support, so we need to include a whole new lua file.
	self.m_RawPresets = {}
	-- self.m_RawPresets["base"] = json.decode(ve_base:GetPreset())
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
	self.m_Lerping = {}
	self.m_Instances = {}
end


function VEManagerClient:RegisterEvents()

	self.m_OnUpdateInputEvent = Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)
    Events:Subscribe('Client:LevelLoaded', self, self.OnClientLevelLoaded)

    Events:Subscribe('VEManager:RegisterPreset', self, self.RegisterPreset)
    Events:Subscribe('VEManager:EnablePreset', self, self.EnablePreset)
    Events:Subscribe('VEManager:DisablePreset', self, self.DisablePreset)
    Events:Subscribe('VEManager:SetVisibility', self, self.SetVisibility)
    Events:Subscribe('VEManager:FadeIn', self, self.FadeIn)
    Events:Subscribe('VEManager:FadeOut', self, self.FadeOut)
    Events:Subscribe('VEManager:Lerp', self, self.Lerp)
end



--[[

	User Functions

]]
function VEManagerClient:RegisterPreset(id, preset)
	self.m_RawPresets[id] = json.decode(preset)
end

function VEManagerClient:EnablePreset(id)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: "..id)
		return
	end

	self.m_Presets[id]["data"].visibility = 1

	self:Reload(id)
end
function VEManagerClient:DisablePreset(id)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: "..id)
		return
	end

	self.m_Presets[id]["data"].visibility = 0
	self:Reload(id)
end

function VEManagerClient:SetVisibility(id, visibility)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: "..id)
		return
	end

	self.m_Presets[id]["data"].visibility = visibility
	self:Reload(id)
end

function VEManagerClient:FadeIn(id, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: "..id)
		return
	end

	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = self.m_Presets[id]["data"].visibility
	self.m_Presets[id]['EndValue'] = 1
	self.m_Lerping[#self.m_Lerping +1] = id
end

function VEManagerClient:FadeOut(id, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: "..id)
		return
	end

	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = self.m_Presets[id]["data"].visibility
	self.m_Presets[id]['EndValue'] = 0

	self.m_Lerping[#self.m_Lerping +1] = id
end

function VEManagerClient:Lerp(id, value, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: "..id)
		return
	end
	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = self.m_Presets[id]["data"].visibility
	self.m_Presets[id]['EndValue'] = value

	self.m_Lerping[#self.m_Lerping +1] = id
end

--[[

	Internal functions

]]

function VEManagerClient:InitializePresets()
	for i, s_Preset in pairs(self.m_Presets) do
		s_Preset["entity"] = EntityManager:CreateClientEntity(s_Preset["data"], LinearTransform())

		if s_Preset["entity"] == nil then
			print("Could not spawn preset.")
			return
		end
		s_Preset["entity"]:Init(Realm.Realm_Client, true)
		s_Preset["entity"]:FireEvent("Enable")
		VisualEnvironmentManager.dirty = true
	end
end

function VEManagerClient:Reload(id)
	self.m_Presets[id].entity:FireEvent("Disable")
	self.m_Presets[id].entity:FireEvent("Enable")
end



function VEManagerClient:LoadPresets()

	print("Loading presets....")
	--Foreach preset
	-- print(self.m_RawPresets)
	for i, s_Preset in pairs(self.m_RawPresets) do
		
		-- Generate our Logical VE and the blueprint

		-- Not sure if we need the LogicelVEEntity, but :shrug:
		local s_LVEED = self:CreateEntity("LogicVisualEnvironmentEntityData")
		self.m_Presets[s_Preset.Name] = {}
		self.m_Presets[s_Preset.Name]["data"] = s_LVEED
		s_LVEED.visibility = 1

		local s_VEB = self:CreateEntity("VisualEnvironmentBlueprint")
		s_VEB.name = s_Preset.Name
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
		s_VE.enabled =  true
	end
	self:InitializePresets()
end

function VEManagerClient:OnClientLevelLoaded()
	self:LoadPresets()
end

-- This one is a little dirty.
function VEManagerClient:CreateEntity(p_Class, p_Guid)
	-- Create the instance
	local s_Entity = _G[p_Class]()

	if(p_Guid == nil) then
		-- Clone the instance and return the clone with a randomly generated Guid
		return _G[p_Class](s_Entity:Clone(GenerateGuid()))
	else 
		return _G[p_Class](s_Entity:Clone(p_Guid))
	end
end

function VEManagerClient:UpdateLerp(percentage)
	for i,preset in pairs(self.m_Lerping) do

		local TimeSinceStarted = SharedUtils:GetTimeMS() - self.m_Presets[preset].startTime
		local PercentageComplete = TimeSinceStarted / self.m_Presets[preset].time
		--local lerpValue = self.m_Presets[preset].startValue + (self.m_Presets[preset].EndValue - self.m_Presets[preset].startValue) * PercentageComplete

	-- t = elapsed time
	-- b = begin
	-- c = change == ending - beginning
	-- d = duration (total time)
		local t = TimeSinceStarted
		local b = self.m_Presets[preset].startValue
		local c = self.m_Presets[preset].EndValue - self.m_Presets[preset].startValue
		local d = self.m_Presets[preset].time

		local transition = "linear"
		if(self.m_Presets[preset].transition ~= nil) then
			transition = self.m_Presets[preset].transition
		end
		
		local lerpValue = easing[transition](t,b,c,d)

		if(PercentageComplete >= 1 or PercentageComplete < 0) then
			self:SetVisibility(preset, self.m_Presets[preset].EndValue)
			self.m_Lerping[i] = nil
		else
			self:SetVisibility(preset, lerpValue)
		end
	end

end
function VEManagerClient:OnUpdateInput(p_Delta, p_SimulationDelta)

	--[[
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F1) then
		self:LoadPresets()
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F2) then
		self:EnablePreset("ve_base")
	end
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F3) then
		self:DisablePreset("ve_base")
		
	end
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F4) then
		self:SetVisibility("ve_base", 0.5)
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F5) then
		print("oy")
		self:FadeIn("ve_base", 10000)
	end
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F6) then
		self:FadeOut("ve_base", 10000)
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F7) then
		self:Lerp("ve_base", 0.5, 1000)
	end
	--]]
	if(#self.m_Lerping > 0 ) then
		self:UpdateLerp(p_Delta)
	end
end




--[[

	Utils

]]

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

function GenerateGuid() 
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

