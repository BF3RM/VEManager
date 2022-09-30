---@class LiveEntityHandler
LiveEntityHandler = class "LiveEntityHandler"

local m_Logger = Logger("LiveEntityHandler", false)
local m_StoredEntities = nil
local m_Queue = {}

function LiveEntityHandler:__init()
    m_Logger:Write("LiveEntityHandler init.")
    self:RegisterVars()
    self:RegisterEvents()
end

function LiveEntityHandler:RegisterVars()
    self.SupportedTypes = {
        -- EntityType | EntityEvents
        ["ClientEmitterEntity"] = {"Start", "Stop"},
        ["SpotLightEntity"] = {"Enable", "Disable"},
        ["PointLightEntity"] = {"Enable", "Disable"},
        ["LensFlareEntity"] = {"Enable", "Disable"},
    }

    m_StoredEntities = nil
    m_Queue = {}
end

function LiveEntityHandler:RegisterEvents()
    Events:Subscribe('Level:LoadResources', self, self.OnLoadResources)
end

function LiveEntityHandler:OnLoadResources()
    self:RegisterVars()
end

---@param p_Category string
---@param p_Visible boolean
function LiveEntityHandler:SetVisibility(p_Category, p_Visible)
    if p_Category == nil or p_Visible == nil then
        m_Logger:Error("Search Criteria or Set Boolean is nil")
        return
    end

    if #m_Queue ~= 0 then
        m_Queue = {}
    end

    if m_StoredEntities == nil then
        m_StoredEntities = {}
        for l_ID, l_Preset in pairs(CLIENT.m_RawPresets) do
            if l_Preset.LiveEntities ~= nil then
                for _, l_EntityDataGuid in ipairs(l_Preset.LiveEntities) do
                    --m_Logger:Write('*Found GUID in LIVEENTITIES: ' .. tostring(l_EntityDataGuid))
                    l_EntityDataGuid = Guid(l_EntityDataGuid)
                    local s_EntityData = ResourceManager:SearchForInstanceByGuid(l_EntityDataGuid)
                    local s_EntityName = s_EntityData.typeInfo.name:gsub("%Data", "")
                    local s_Iterator = EntityManager:GetIterator(s_EntityName)

                    local s_Entity = s_Iterator:Next()
                    while s_Entity ~= nil do
                        if s_Entity.data.instanceGuid == l_EntityDataGuid then
                            table.insert(m_StoredEntities, {s_Entity, l_ID})
                            --m_Logger:Write('Stored ' .. s_Entity.typeInfo.name)
                        end
                        s_Entity = s_Iterator:Next()
                    end
                end
            end
        end
    end

    for _, l_EntityTable in pairs(m_StoredEntities) do
        if l_EntityTable[2] == p_Category then
            if p_Visible then
                table.insert(m_Queue, {l_EntityTable[1], p_Visible})
            elseif not p_Visible then
                table.insert(m_Queue, {l_EntityTable[1], p_Visible})
            end
        end
    end
end

local s_Counter = 0
local s_UpdatedEntites = 0
local s_EntitiesPerUpdate = 10
function LiveEntityHandler:OnUpdateManagerPreSim(p_DeltaTime)
    if #m_Queue <= 0 then
        return
    end

    for l_Index, l_EntityTable in ipairs(m_Queue) do
        m_Logger:Write('Entity: ' .. l_EntityTable[1].typeInfo.name)
        if l_EntityTable[2] then
            if self.SupportedTypes[l_EntityTable[1].typeInfo.name] ~= nil then
                l_EntityTable[1]:FireEvent(self.SupportedTypes[l_EntityTable[1].typeInfo.name][1])
            else
                m_Logger:Error('Entity Type not supported')
            end
        elseif not l_EntityTable[2] then
            if self.SupportedTypes[l_EntityTable[1].typeInfo.name] ~= nil then
                l_EntityTable[1]:FireEvent(self.SupportedTypes[l_EntityTable[1].typeInfo.name][2])
            else
                m_Logger:Error('Entity Type not supported')
            end
        end
        s_Counter = s_Counter + 1
        s_UpdatedEntites = s_UpdatedEntites + 1
        table.remove(m_Queue, l_Index)
        m_Logger:Write('Changed Visibility')

        if s_UpdatedEntites > s_EntitiesPerUpdate then
            s_UpdatedEntites = 0
            break
        end
    end

    m_Logger:Write('Still in Queue: ' .. #m_Queue)

    if #m_Queue > 0 then
        return
    end

    m_Logger:Write('Queue Empty. Changed ' .. s_Counter .. ' Entities')
    s_Counter = 0
end

return LiveEntityHandler()
