class('VEManagerClient')
night = require "night"
morning = require "morning"
noon = require "noon"
evening = require "evening"
easing = require "easing"


function VEManagerClient:__init()
    print('Initializing VEManagerClient')
    self:RegisterVars()
    self:RegisterEvents()
	self:RegisterModules()
end


function VEManagerClient:RegisterVars()
    self.m_RawPresets = {}
	self.m_RawPresets["Testing1"] = json.decode(night:GetPreset())
	self.m_RawPresets["Testing2"] = json.decode(morning:GetPreset())
	self.m_RawPresets["Testing3"] = json.decode(noon:GetPreset())
	self.m_RawPresets["Testing4"] = json.decode(evening:GetPreset())
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
    Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded)
	Events:Subscribe('Level:Destroy', self, self.RegisterVars)

    Events:Subscribe('VEManager:RegisterPreset', self, self.RegisterPreset)
    Events:Subscribe('VEManager:EnablePreset', self, self.EnablePreset)
    Events:Subscribe('VEManager:DisablePreset', self, self.DisablePreset)
    Events:Subscribe('VEManager:SetVisibility', self, self.SetVisibility)
	Events:Subscribe('VEManager:UpdateVisibility', self, self.UpdateVisibility)
    Events:Subscribe('VEManager:FadeIn', self, self.FadeIn)
    Events:Subscribe('VEManager:FadeTo', self, self.FadeTo)
    Events:Subscribe('VEManager:FadeOut', self, self.FadeOut)
    Events:Subscribe('VEManager:Lerp', self, self.Lerp)
	Events:Subscribe('VEManager:Crossfade', self, self.Crossfade)
	Events:Subscribe('VEManager:AddTime', self, self.AddTime)
	Events:Subscribe('VEManager:RemoveTime', self, self.AddTime)
end


function VEManagerClient:RegisterModules()
	require 'modules/time'
	Time:__init()
	require 'modules/DebugGUI'
	require 'modules/cinematictools'
	CinematicTools:__init()
end


--[[

	User Functions

]]


function VEManagerClient:RegisterPreset(id, preset)
	self.m_RawPresets[id] = json.decode(preset)
end


function VEManagerClient:EnablePreset(id)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	print("Enabling preset: " .. tostring(id))
	self.m_Presets[id]["logic"].visibility = 1
	self.m_Presets[id]["ve"].visibility = 1
	self.m_Presets[id]["ve"].enabled = true
	self.m_Presets[id].entity:FireEvent("Enable")
end


function VEManagerClient:DisablePreset(id)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	print("Disabling preset: " .. tostring(id))
	self.m_Presets[id]["logic"].visibility = 1
	self.m_Presets[id]["ve"].visibility = 0
	self.m_Presets[id]["ve"].enabled = false
	self.m_Presets[id].entity:FireEvent("Disable")
end


function VEManagerClient:SetVisibility(id, visibility)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	self.m_Presets[id]["logic"].visibility = visibility
	self.m_Presets[id]["ve"].visibility = visibility

	self:Reload(id)
end


function VEManagerClient:UpdateVisibility(id, priority, visibilityFactor)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	local s_states = VisualEnvironmentManager:GetStates()
	VisualEnvironmentManager:SetDirty(true)
	local s_fixedPriority = 10000000 + priority

	for _, state in pairs(s_states) do
		if state.priority == s_fixedPriority then
			state.visibility = visibilityFactor
		end
	end
end


function VEManagerClient:FadeIn(id, time)
	self:FadeTo(id, 1, time)
end

function VEManagerClient:FadeTo(id, visibility, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = 0 -- Fade in should always start from 0
	self.m_Presets[id]['EndValue'] = visibility -- this doesn't allow for a preset to have a visibility ~= 0. The basic visibility of each preset needs to be indipendent of the current visibility (aka opacity).
	self.m_Lerping[#self.m_Lerping + 1] = id
end

--[[
function VEManagerClient:FadeIn(id, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = self.m_Presets[id]["logic"].visibility
	self.m_Presets[id]['EndValue'] = 1
	self.m_Lerping[#self.m_Lerping +1] = id
end
]]

function VEManagerClient:FadeOut(id, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end

	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = self.m_Presets[id]["logic"].visibility
	self.m_Presets[id]['EndValue'] = 0

	self.m_Lerping[#self.m_Lerping +1] = id
end

function VEManagerClient:Lerp(id, value, time)
	if self.m_Presets[id] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id))
		return
	end
	self.m_Presets[id]['time'] = time
	self.m_Presets[id]['startTime'] = SharedUtils:GetTimeMS()
	self.m_Presets[id]['startValue'] = self.m_Presets[id]["logic"].visibility
	self.m_Presets[id]['EndValue'] = value

	self.m_Lerping[#self.m_Lerping +1] = id
end


--[[function VEManagerClient:Crossfade(id1, id2, time)
    if self.m_Presets[id1] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id1))
		return
	elseif self.m_Presets[id2] == nil then
		error("There isn't a preset with this id or it hasn't been parsed yet. Id: ".. tostring(id2))
		return
	end

    self:FadeTo(id1, self.m_Presets[id2]["logic"].visibility, time) -- Fade id1 to id2 visibility
    self:FadeTo(id2, self.m_Presets[id1]["logic"].visibility, time) -- Fade id2 to id1 visibility

end]]

function VEManagerClient:AddTime(startingTime, lengthOfDayInMinutes, isStatic, serverUpdateFrequency) -- Add Time System to Map | To be called on Level:Loaded | time in 24hr format (0-23)
	local s_currentMap = SharedUtils:GetLevelName()
	Time:Add(s_currentMap, startingTime, lengthOfDayInMinutes, isStatic, serverUpdateFrequency)
end

function VEManagerClient:RemoveTime()
	Time:Remove()
end


--[[

	Internal functions

]]


function VEManagerClient:GetMapPresets(mapName) -- gets all Main Map Environments for Day-Night Cycle
	local map = mapName:match('/[^/]+'):sub(2)
	for i, s_Preset in pairs(VEManagerClient.m_Presets) do
		if s_Preset.Map[map] then
            print(i)
			return i
		end
	end
end


function VEManagerClient:GetState(...)
	--Get all visual environment states
	local args = { ... }
	local states = VisualEnvironmentManager:GetStates()
	--Loop through all states
	for _, state in pairs(states) do

		for i,priority in pairs(args) do

			if state.priority == priority then
				return state
			end

		end

	end
	return nil
end


function VEManagerClient:InitializePresets()
	for i, s_Preset in pairs(self.m_Presets) do
		--print(s_Preset["logic"])
		s_Preset["entity"] = EntityManager:CreateEntity(s_Preset["logic"], LinearTransform())

		if s_Preset["entity"] == nil then
			print("Could not spawn preset.")
			return
		end

		s_Preset["entity"]:Init(Realm.Realm_Client, true)
		VisualEnvironmentManager:SetDirty(true)
		print("Spawned Preset: " .. i)
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

		-- Generate our VisualEnvironment
		local s_IsBasePreset = s_Preset.Priority == 1
		-- print("IsBasePreset: " .. tostring(s_IsBasePreset))

		--Not sure if we need the LogicelVEEntity, but :shrug:
		local s_LVEED = self:CreateEntity("LogicVisualEnvironmentEntityData")
		self.m_Presets[s_Preset.Name] = {}
		self.m_Presets[s_Preset.Name]["logic"] = s_LVEED
		s_LVEED.visibility = 1

		local s_VEB = self:CreateEntity("VisualEnvironmentBlueprint")
		s_VEB.name = s_Preset.Name
		s_LVEED.visualEnvironment = s_VEB
		self.m_Presets[s_Preset.Name]["blueprint"] = s_VEB

		local s_VE = self:CreateEntity("VisualEnvironmentEntityData")
		s_VEB.object = s_VE
		print("Preset Name: " .. s_Preset.Name)
		print("Preset Type: " .. s_Preset.Type)
		print("Preset Priority: " .. s_Preset.Priority)
		s_VE.enabled = true
		s_VE.priority = tonumber(s_Preset.Priority)
		s_VE.visibility = 1

		self.m_Presets[s_Preset.Name]["ve"] = s_VE
		self.m_Presets[s_Preset.Name]["type"] = s_Preset.Type

		--Foreach class
		local componentCount = 0
		for _, l_Class in pairs(self.m_SupportedClasses) do

			if(s_Preset[l_Class] ~= nil) then

				-- Create class and add it to the VE entity.
				local s_Class =  _G[l_Class.."ComponentData"]()
				-- print("")
				-- print("CLASS:")
				-- print(l_Class)
				-- print("")
				s_Class.excluded = false
				s_Class.isEventConnectionTarget = 3
				s_Class.isPropertyConnectionTarget = 3
				s_Class.indexInBlueprint = componentCount
				s_Class.transform = LinearTransform()

				-- Foreach field in class
				for _, l_Field in ipairs(s_Class.typeInfo.fields) do

					-- Fix lua types
					local s_FieldName = l_Field.name

					if(s_FieldName == "End") then
						s_FieldName = "EndValue"
					end

					-- Get type
					local s_Type = l_Field.typeInfo.name --Boolean, Int32, Vec3 etc.
					-- print("Field: " .. tostring(s_FieldName) .. " | " .. " Type: " .. tostring(s_Type))

					-- If the preset contains that field
					if s_Preset[l_Class][s_FieldName] ~= nil then

						local s_Value

						if IsBasicType(s_Type) then
							s_Value = self:ParseValue(s_Type, s_Preset[l_Class][s_FieldName])
						elseif l_Field.typeInfo.enum then
							s_Value = tonumber(s_Preset[l_Class][s_FieldName])
						elseif l_Field.typeInfo.array then
							error("Found unexpected array")
							return
						else
							error("Found unexpected DataContainer")
							return
						end

						if (s_Value ~= nil) then
							s_Class[firstToLower(s_FieldName)] = s_Value
						else

							local s_Value = self:GetDefaultValue(l_Class, l_Field)
							if (s_Value == nil) then
                                print("Failed to fetch original value: " .. tostring(l_Class) .. " | " .. tostring(s_FieldName))
							else

								-- print("Setting default value for field " .. s_FieldName .. " of class " .. l_Class .. " | " ..  tostring(s_Value))
								if (IsBasicType(s_Type)) then
									s_Class[firstToLower(s_FieldName)] = self:ParseValue(s_Type, s_Value)
								elseif (l_Field.typeInfo.enum) then
									s_Class[firstToLower(s_FieldName)] = tonumber(s_Value)
								elseif (s_Type == "TextureAsset") then
									if --[[s_FieldName == "PanoramicTexture" or s_FieldName == "PanoramicAlphaTexture" or]] s_FieldName == "StaticEnvmapTexture" then
										s_Class[firstToLower(s_FieldName)] = nil --todo needs to be included in another way to keep it out of the VEManager itself
									elseif s_FieldName == "CloudLayer2Texture" then
										s_Class[firstToLower(s_FieldName)] = TextureAsset(_G['g_Stars'])
										print("Added Stars")
									else
										--print("Added FieldName: " .. s_FieldName)
										s_Class[firstToLower(s_FieldName)] = TextureAsset(s_Value)
									end
								elseif l_Field.typeInfo.array then
									print("Found unexpected array, ignoring")
								else
									-- Its a DataContainer
									s_Class[firstToLower(s_FieldName)] = _G[s_Type](s_Value)
								end

							end

						end

					else
						--print("Getting Default Value for: " .. tostring(l_Class) .. " | " .. tostring(s_FieldName))
						local s_Value = self:GetDefaultValue(l_Class, l_Field)

						if (s_Value == nil) then
							print("Failed to fetch original value: " .. tostring(l_Class) .. " | " .. tostring(s_FieldName))
						else

							-- print("Setting default value for field " .. s_FieldName .. " of class " .. l_Class .. " | " ..  tostring(s_Value))
							if (IsBasicType(s_Type)) then
								s_Class[firstToLower(s_FieldName)] = s_Value
							elseif (l_Field.typeInfo.enum) then
								s_Class[firstToLower(s_FieldName)] = tonumber(s_Value)
							elseif (s_Type == "TextureAsset") then
								if --[[s_FieldName == "PanoramicTexture" or s_FieldName == "PanoramicAlphaTexture" or]] s_FieldName == "StaticEnvmapTexture" then
									s_Class[firstToLower(s_FieldName)] = nil --todo needs to be included in another way to keep it out of the VEManager itself
								elseif s_FieldName == "CloudLayer2Texture" then
									s_Class[firstToLower(s_FieldName)] = TextureAsset(_G['g_Stars'])
									print("Added Stars")
								else
									--print("Added FieldName: " .. s_FieldName)
									s_Class[firstToLower(s_FieldName)] = TextureAsset(s_Value)
								end
							elseif l_Field.typeInfo.array then
								print("Found unexpected array, ignoring")
							else
								-- Its a DataContainer
								s_Class[firstToLower(s_FieldName)] = _G[s_Type](s_Value)
							end

						end

					end

				end

			componentCount = componentCount + 1
			s_VE.components:add(s_Class)
			end

		end

		s_VE.runtimeComponentCount = componentCount
		s_VE.visibility = 0
		s_VE.enabled = false
		s_LVEED.visibility = 0

	end

	self:InitializePresets()
	Events:Dispatch("VEManager:PresetsLoaded")
	print("Presets loaded")
end


function VEManagerClient:OnLevelLoaded(p_MapPath, p_GameModeName)
	self:LoadPresets()
end


function VEManagerClient:GetDefaultValue(p_Class, p_Field)
	if (p_Field.typeInfo.enum) then

		if (p_Field.typeInfo.name == "Realm") then
			return Realm.Realm_Client
		else
			print("Found unhandled enum, "..p_Field.typeInfo.name)
			return
		end

	end

	local s_States = VisualEnvironmentManager:GetStates()

	for i, s_State in ipairs(s_States) do
		--print(">>>>>> state:")
		--print(s_State.entityName)

		if(s_State.entityName == "Levels/Web_Loading/Lighting/Web_Loading_VE") then
			goto continue
		end

		if s_State.entityName ~= 'EffectEntity' then

			local s_Class = s_State[firstToLower(p_Class)] --colorCorrection

			if (s_Class == nil) then
				goto continue
			end

			-- print("Sending default value: " .. tostring(p_Class) .. " | " .. tostring(p_Field.typeInfo.name) .. " | " .. tostring(s_Class[firstToLower(p_Field.typeInfo.name)]))
			-- print(tostring(s_Class[firstToLower(p_Field.name)]) .. ' | ' .. tostring(p_Field.typeInfo.name))
			return s_Class[firstToLower(p_Field.name)] --colorCorrection Contrast

		end

		::continue::
	end
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


function VEManagerClient:SetLerpPriority(id)
	if self.m_Presets[id].type ~= 'Time' then
		return
	end
end


function VEManagerClient:OnUpdateInput(p_Delta, p_SimulationDelta)


	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F1) then
		self:LoadPresets()
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F2) then
		--self:FadeIn("Testing1", 5000)
		self:AddTime(0, 0.5, false, 30)
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F3) then
		self:AddTime(0, 2, false, 30)
		--self:FadeIn("Testing2", 5000)
		--self:FadeOut("Testing1", 5000)
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F4) then
		self:RemoveTime()
		--self:FadeIn("Testing3", 5000)
		--self:FadeOut("Testing2", 5000)
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F5) then
		--self:FadeIn("Testing4", 5000)
		--self:FadeOut("Testing3", 5000)
		CinematicTools:CreateGUI()
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F6) then
		--self:DisablePreset("Testing1")
		--self:DisablePreset("Testing2")
		--self:DisablePreset("Testing3")
		--self:DisablePreset("Testing4")

		local s_states = VisualEnvironmentManager:GetStates()
		VisualEnvironmentManager:SetDirty(true)
		local s_fixedPriority = 10000000 + 100015

		local found = false
		for _, state in pairs(s_states) do
			if state.priority == s_fixedPriority then
				found = true

				state.visibility = visibilityFactor
				print('VISIBILITY: ' .. tostring(state.visibility))
				print('PRIORITY: ' .. tostring(state.priority))
			end
		end

		if found == false then
			print('Not found')
		end
	end

	if InputManager:WentKeyDown(InputDeviceKeys.IDK_F7) then
		self:Lerp("ve_base", 0.5, 1000)
	end

	if(#self.m_Lerping > 0 ) then
		self:UpdateLerp(p_Delta)
	end

end


--[[

	Utils

]]


function VEManagerClient:ParseValue(p_Type, p_Value)
	-- This seperates Vectors. Let's just do it to everything, who cares?
	if (p_Type == "Boolean") then
		if(p_Value == "true") then
			return true
		else
			return false
		end
	elseif p_Type == "CString" then
		return tostring(p_Value)

	elseif  p_Type == "Float8" or
			p_Type == "Float16" or
			p_Type == "Float32" or
			p_Type == "Float64" or
			p_Type == "Int8" or
			p_Type == "Int16" or
			p_Type == "Int32" or
			p_Type == "Int64" or
			p_Type == "Uint8" or
			p_Type == "Uint16" or
			p_Type == "Uint32" or
			p_Type == "Uint64" then
		return tonumber(p_Value)

	elseif (p_Type == "Vec2") then -- Vec2
		local s_Vec = HandleVec(p_Value)
		return Vec2(tonumber(s_Vec[1]), tonumber(s_Vec[2]))

	elseif (p_Type == "Vec3") then -- Vec3
		local s_Vec = HandleVec(p_Value)
		return Vec3(tonumber(s_Vec[1]), tonumber(s_Vec[2]), tonumber(s_Vec[3]))

	elseif (p_Type == "Vec4") then -- Vec4
		local s_Vec = HandleVec(p_Value)
		return Vec4(tonumber(s_Vec[1]), tonumber(s_Vec[2]), tonumber(s_Vec[3]), tonumber(s_Vec[4]))
	else
		print("Unhandled type: " .. p_Type)
		return nil
	end
end


function h()
    local vars = {"A","B","C","D","E","F","0","1","2","3","4","5","6","7","8","9"}
    return vars[math.floor(MathUtils:GetRandomInt(1,16))]..vars[math.floor(MathUtils:GetRandomInt(1,16))]
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

function IsBasicType( typ )
	if typ == "CString" or
	typ == "Float8" or
	typ == "Float16" or
	typ == "Float32" or
	typ == "Float64" or
	typ == "Int8" or
	typ == "Int16" or
	typ == "Int32" or
	typ == "Int64" or
	typ == "Uint8" or
	typ == "Uint16" or
	typ == "Uint32" or
	typ == "Uint64" or
	typ == "LinearTransform" or
	typ == "Vec2" or
	typ == "Vec3" or
	typ == "Vec4" or
	typ == "Boolean" or
	typ == "Guid" then
		return true
	end
	return false
end

g_VEManagerClient = VEManagerClient()


