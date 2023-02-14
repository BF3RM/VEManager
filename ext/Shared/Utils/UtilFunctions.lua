-- General Utility Functions
---@class UtilityFunctions
---@overload fun():UtilityFunctions
UtilityFunctions = class 'UtilityFunctions'

---@type Logger
local m_Logger = Logger("UtilityFunctions", false)

function UtilityFunctions:__init()
	m_Logger:Write('Initializing UtilityFunctions')
	self:RegisterVars()
	self:RegisterEvents()
end

function UtilityFunctions:RegisterVars()

end

function UtilityFunctions:RegisterEvents()

end

--#region Local Methods

---@param p_String string
---@param p_Pattern string
---@return table<string>
local function _SplitString(p_String, p_Pattern)
	local s_Table = {} -- NOTE: use {n = 0} in Lua-5.0
	local s_FPattern = "(.-)" .. p_Pattern
	local s_LastEnd = 1
	local s_Start, s_End, s_Captured = p_String:find(s_FPattern, 1)
	while s_Start do
		if s_End ~= 1 or s_Captured ~= "" then
			table.insert(s_Table, s_Captured)
		end
		s_LastEnd = s_End + 1
		s_Start, s_End, s_Captured = p_String:find(s_FPattern, s_LastEnd)
	end
	if s_LastEnd <= #p_String then
		s_Captured = p_String:sub(s_LastEnd)
		table.insert(s_Table, s_Captured)
	end
	return s_Table
end

---@param p_VectorString string
local function _HandleVector(p_VectorString)
	local s_FixedContents = string.gsub(p_VectorString, "%(", "")
	s_FixedContents = string.gsub(s_FixedContents, "%)", "")
	s_FixedContents = string.gsub(s_FixedContents, ", ", ":")
	return _SplitString(s_FixedContents, ":")
end

--#endregion

-- Initialize a Frostbite Type
---@param p_Class string
---@param p_Guid Guid|nil
function UtilityFunctions:InitEngineType(p_Class, p_Guid)
    -- Check if exists
    if not _G[p_Class] then
        m_Logger:Error("Provided Frostbite type does not exist")
    end

	-- Create the instance
	local s_Entity = _G[p_Class]()

	if not p_Guid then
		-- Clone the instance and return the clone with a randomly generated Guid
		return _G[p_Class](s_Entity:Clone(MathUtils:RandomGuid()))
	else
		return _G[p_Class](s_Entity:Clone(p_Guid))
	end
end

function UtilityFunctions:IsBasicType(p_Type)
	if p_Type == "CString" or
		p_Type == "Float8" or
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
		p_Type == "Uint64" or
		p_Type == "LinearTransform" or
		p_Type == "Vec2" or
		p_Type == "Vec3" or
		p_Type == "Vec4" or
		p_Type == "Boolean" or
		p_Type == "Guid" then
		return true
	end
	return false
end

function UtilityFunctions:ParseValue(p_Type, p_Value)
	-- This separates Vectors. Let's just do it to everything, who cares?
	if p_Type == "Boolean" then
		if p_Value == "true" then
			return true
		else
			return false
		end
	elseif p_Type == "CString" then
		return tostring(p_Value)

	elseif p_Type == "Float8" or
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

	elseif p_Type == "Vec2" then -- Vec2
		local s_Vec = _HandleVector(p_Value)
		return Vec2(tonumber(s_Vec[1]), tonumber(s_Vec[2]))

	elseif p_Type == "Vec3" then -- Vec3
		local s_Vec = _HandleVector(p_Value)
		return Vec3(tonumber(s_Vec[1]), tonumber(s_Vec[2]), tonumber(s_Vec[3]))

	elseif p_Type == "Vec4" then -- Vec4
		local s_Vec = _HandleVector(p_Value)
		return Vec4(tonumber(s_Vec[1]), tonumber(s_Vec[2]), tonumber(s_Vec[3]), tonumber(s_Vec[4]))

	else
		m_Logger:Write("Unhandled type: " .. p_Type)
		return nil
	end
end

---@param p_Name string
---@return TextureAsset|nil
function UtilityFunctions:GetTexture(p_Name)
	local s_TextureAsset = ResourceManager:SearchForDataContainer(p_Name)

	if s_TextureAsset == nil then
		return nil
	else
		return TextureAsset(s_TextureAsset)
	end
end

---@param p_String string
function UtilityFunctions:FirstToLower(p_String)
	return (p_String:gsub("^%L", string.lower))
end

---@param p_Class string
---@param p_Field FieldInformation
function UtilityFunctions:GetFieldDefaultValue(p_Class, p_Field)
	if p_Field.typeInfo.enum then

		if p_Field.typeInfo.name == "Realm" then
			return Realm.Realm_Client
		else
			m_Logger:Write("\t- Found unhandled enum, " .. p_Field.typeInfo.name)
			return
		end
	end

	local s_States = VisualEnvironmentManager:GetStates()

	for _, l_State in ipairs(s_States) do
		--m_Logger:Write(">>>>>> state:" .. l_State.entityName)

		if l_State.entityName == "Levels/Web_Loading/Lighting/Web_Loading_VE" then
			goto continue

		elseif l_State.entityName ~= 'EffectEntity' then
			local s_Class = l_State[self:FirstToLower(p_Class)] --colorCorrection

			if s_Class == nil then
				goto continue
			end

			--m_Logger:Write("Sending default value: " .. tostring(p_Class) .. " | " .. tostring(p_Field.typeInfo.name) .. " | " .. tostring(s_Class[firstToLower(p_Field.typeInfo.name)]) .. " (" .. tostring(type(s_Class[firstToLower(p_Field.typeInfo.name)])) .. ")")
			--m_Logger:Write(tostring(s_Class[firstToLower(p_Field.name)]) .. ' | ' .. tostring(p_Field.typeInfo.name))
			return s_Class[self:FirstToLower(p_Field.name)] --colorCorrection Contrast
		end

		::continue::
	end
end

-- Returns public functions of a class - this automatically throws an error if someone tries to use a non public functions from outside a class
---@param p_Class table
---@return table
function UtilityFunctions:InitializeClass(p_Class)
    -- Initialize
    p_Class()

    local s_PublicFunctionTable = {}

    print(p_Class.name)

    --print("Class: " .. p_Class)
    for l_MethodName, l_Method in pairs(p_Class.__declaredMethods) do
        -- check if public and a function
        if type(l_Method) == "function" and string.sub(l_MethodName, 1, 1) ~= "_" then
            s_PublicFunctionTable[l_MethodName] = l_Method

            if l_MethodName == "isInstanceOf" then
                print("- Added Public MiddleClass Method: " .. l_MethodName)
            else
                print("- Added Public Method: " .. l_MethodName)
            end
        end
    end

    return s_PublicFunctionTable
end

return UtilityFunctions:InitializeClass(UtilityFunctions)


