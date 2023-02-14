---@class VisualEnvironmentHandler
---@overload fun():VisualEnvironmentHandler
VisualEnvironmentHandler = class 'VisualEnvironmentHandler'

---@type Logger
local m_Logger = Logger("VisualEnvironmentHandler", false)

function VisualEnvironmentHandler:__init()
	m_Logger:Write('Initializing VisualEnvironmentHandler')
	self:RegisterVars()
	self:RegisterEvents()
end

function VisualEnvironmentHandler:RegisterVars()
	-- Table of visual environment objects
	---@type table<VisualEnvironmentObject>
	self.m_VisualEnvironmentObjects = {}
	-- Table of currently lerping visual environments
	self.m_Lerping = {}
end

function VisualEnvironmentHandler:RegisterEvents()

end

---@param p_Object table<VisualEnvironmentObject>
function VisualEnvironmentHandler:RegisterVisualEnvironmentObject(p_Object)

end

---@return number
function VisualEnvironmentHandler:GetTotalVEObjectCount()
	return #self.m_VisualEnvironmentObjects
end

---@param p_ID string
---@return boolean
function VisualEnvironmentHandler:CheckIfExists(p_ID)
	if not LEVEL_LOADED then
		return false
	end

	if p_ID == nil then
		m_Logger:Error("\nThe VE object ID provided is nil.")
	elseif self.m_VisualEnvironmentObjects[p_ID] == nil then
		m_Logger:Error("\nThere isn't a VE object with this id or it hasn't been parsed yet. Id: " .. tostring(p_ID))
	end

	return true
end

---@param p_ID string
---@param p_Visibility number
---@return boolean IsInitialized
---@return boolean DoesAlreadyExist
function VisualEnvironmentHandler:InitializeVE(p_ID, p_Visibility)
	---@param l_Index integer
	---@param l_Object VisualEnvironmentObject
	for l_Index, l_Object in ipairs(self.m_VisualEnvironmentObjects) do
		if l_Index == p_ID then
			m_Logger:Write("Spawning VE: ")

			if l_Object.entity then
				m_Logger:Warning("- " .. tostring(l_Index) .. ", already exists.")
				self:SetVisibility(p_ID, 1.0)
				return false, true
			end

			---@type VisualEnvironmentEntity|nil
			local s_Entity = EntityManager:CreateEntity(l_Object["logic"], LinearTransform())
			l_Object.entity = s_Entity

			-- check if entity creation was successful
			if not l_Object.entity then
				m_Logger:Warning("- " .. tostring(l_Index) .. ", could not be spawned.")
				return false, false
			end

			l_Object["logic"].visibility = p_Visibility or 1.0
			l_Object["ve"].visibility = p_Visibility or 1.0

			l_Object.entity:Init(Realm.Realm_Client, true)
			l_Object.entity:FireEvent("Enable")
			VisualEnvironmentManager:SetDirty(true)

			m_Logger:Write("- " .. l_Object["blueprint"].name)
			return true, false
		end
	end
	return false, false
end

---@param p_ID string
---@return boolean wasSuccessful
function VisualEnvironmentHandler:DestroyVE(p_ID)
	m_Logger:Write("Attemting to destroy VE preset with id " .. p_ID .. "...")

	local s_Object = self.m_VisualEnvironmentObjects[p_ID]

	if s_Object == nil then
		m_Logger:Warning("Tried to destroy a preset that does not exist")
		return false
	end

	if not s_Object.entity then
		m_Logger:Warning("Preset entity does not exist. Do you really want to destroy at this point?.")
		return true
	end

	-- destroy entity
	self.m_Lerping[p_ID] = nil
	s_Object.entity:Destroy()
	s_Object.entity = nil
	VisualEnvironmentManager:SetDirty(true)

	s_Object["logic"].visibility = 0.0
	s_Object["ve"].visibility = 0.0

	m_Logger:Write("- " .. tostring(s_Object))
	return true
end

function VisualEnvironmentHandler:ResetLerps()
	-- Only reset base (main) visual environment lerps
	for l_ID, _ in pairs(self.m_Lerping) do
		---@type VisualEnvironmentObject
		local s_Object = self.m_VisualEnvironmentObjects[l_ID]

		-- check if alive
		if s_Object and s_Object.entity and s_Object.ve.priority == 1 then
			self:DestroyVE(l_ID)
		end
	end

	self.m_Lerping = {}
end

-- Initialize
VisualEnvironmentHandler()

-- Only Expose Public Functions
return {
    InitializeVE = VisualEnvironmentHandler.InitializeVE,
	GetVEObjectCount = VisualEnvironmentHandler.GetTotalVEObjectCount,
	RegisterVisualEnvironmentObject = VisualEnvironmentHandler.RegisterVisualEnvironmentObject,
	CheckIfExists = VisualEnvironmentHandler.CheckIfExists,
	ResetLerps = VisualEnvironmentHandler.ResetLerps
}