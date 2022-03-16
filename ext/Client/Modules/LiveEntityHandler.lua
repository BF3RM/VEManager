---@class LiveEntityHandler
LiveEntityHandler = class "LiveEntityHandler"

local m_Logger = Logger("LiveEntityHandler", true)

function LiveEntityHandler:__init()
    m_Logger:Write("LiveEntityHandler init.")
end

local m_StoredEntities = {}
-- to prevent crash
local m_Queue = {}

---@param p_Category string
---@param p_Visible boolean
function LiveEntityHandler:SetVisibility(p_Category, p_Visible)
    if p_Category == nil or p_Visible == nil then
        m_Logger:Error("Search Criteria or Set Boolean is nil")
        return
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

local s_Category = 'Night'
Console:Register('Entity', 'Changes Entity Visibility', function(args)
    if #args == 1 and args[1] == '1' then
        LiveEntityHandler:SetVisibility(s_Category, true)
    elseif #args == 1 and args[1] == '0' then
        LiveEntityHandler:SetVisibility(s_Category, false)
    end
end)

local s_GuidTable = {
    -- https://github.com/EmulatorNexus/Venice-EBX/blob/master/Levels/XP3_Valley/Objects/Prefabs/Lights/LampPost_Wood_Lights.txt
    ['Night'] = {
        Guid('0A230C4A-64DA-404D-89D2-72C4360465B5'),
        Guid('A6C6C9B9-2466-43C8-843B-86339BC9EAC2'),
        Guid('42F032CC-84D1-4A69-AF3B-F57F0FF70037')
    }
}

function LiveEntityHandler:OnEntityCreate(p_HookCtx, p_EntityData, p_Transform)
    for l_Category, l_GuidTable in pairs(s_GuidTable) do 
        for _, l_Guid in ipairs(l_GuidTable) do
            if p_EntityData.instanceGuid == l_Guid then 
                local s_CreatedEntity = p_HookCtx:Call()
                table.insert(m_StoredEntities, {s_CreatedEntity, l_Category})
                m_Logger:Write('Stored Entity')
            end
        end
    end
end

local s_Timer = 0
local s_LastUpdate = 0
local s_Counter = 0
local s_UpdateEveryS = 0.25
function LiveEntityHandler:OnUpdateManagerPreSim(p_DeltaTime)
    if m_Queue[1] == nil then
        return
    end

    s_Timer = s_Timer + p_DeltaTime

    if s_Timer >= s_LastUpdate + s_UpdateEveryS then
        s_LastUpdate = s_Timer
        local s_UpdateAllowed = true
        for l_Index, l_EntityTable in ipairs(m_Queue) do
            if s_UpdateAllowed then
                m_Logger:Write('Entity: ' .. tostring(l_EntityTable[1]))
                s_UpdateAllowed = false

                if l_EntityTable[2] then
                    l_EntityTable[1]:FireEvent('Enable')
                else
                    l_EntityTable[1]:FireEvent('Disable')
                end
                s_Counter = s_Counter + 1
                m_Queue[l_Index] = nil
                m_Logger:Write('Changed Visibility')
                break
            end
        end
        s_Timer = 0
    end

    if m_Queue[1] ~= nil then
        return
    end

    s_Counter = 0
    m_Logger:Write('Queue Empty. Changed ' .. s_Counter .. ' Entities')
end

return LiveEntityHandler()
