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

    for _, l_EntityBusTable in pairs(m_StoredEntities) do
        if l_EntityBusTable[2] == p_Category then
            if p_Visible then
                table.insert(m_Queue, {l_EntityBusTable[1], p_Visible})
            elseif not p_Visible then
                table.insert(m_Queue, {l_EntityBusTable[1], p_Visible})
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
    ['Night'] = {
        -- https://github.com/EmulatorNexus/Venice-EBX/blob/master/Levels/XP3_Valley/Objects/Prefabs/Lights/LampPost_Wood_Lights.txt
        Guid('7858D9DB-0FF2-476B-9848-795F7944E537'),   -- blueprint
        --[[Guid('0A230C4A-64DA-404D-89D2-72C4360465B5'),   -- light
        Guid('A6C6C9B9-2466-43C8-843B-86339BC9EAC2'),   -- light
        Guid('42F032CC-84D1-4A69-AF3B-F57F0FF70037'),   -- light
        Guid('84C41922-73EA-4214-98C9-305A4DB9F715'),   -- fx
        Guid('E00AEC09-B077-4A4A-A027-610AB41395C6'),   -- fx]]
        -- https://github.com/EmulatorNexus/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/Levels/XP3_Valley/Objects/Prefabs/Lights/LampPost_Wood_LightsFlicker.txt
        Guid('6BFB01A5-C3F0-42C8-813E-24FA9E53FC5D'),   -- blueprint
        --Guid('B789AF38-1858-4682-AFB7-01E651333438'),   -- light
        -- https://github.com/EmulatorNexus/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/Levels/XP3_Valley/Objects/lightpostbig_valley_nongroupable_autogen.txt
        Guid('3FD227F1-4BC3-7974-4B10-AC08B19399A6'),   -- blueprint
        --[[Guid('DBBA79AA-18B8-4D7A-839D-4B5A701A61C1'),   -- lensflare
        Guid('49418EC5-AA67-437F-BBE9-640397CB2DDC'),   -- light 
        Guid('E7CFFC05-0FC0-405B-B715-4B29274C3EFD'),   -- light
        Guid('BCB0A9CA-8E50-41BF-9CD1-F10816673596'),   -- light
        Guid('EDC13FD3-ED09-4779-9A25-F0F689D3F5BD'),   -- light
        Guid('7C7206AB-20E7-4ED2-90BA-F7123E9A49CB'),   -- light]]
        -- https://github.com/EmulatorNexus/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/Levels/XP3_Valley/Objects/Prefabs/Lights/WallLamp_01_Destructible.txt
        Guid('2E704C0E-5063-4BB2-BEDA-8D55682F64B7'),   -- blueprint
        --Guid('437152F2-0E84-42E6-98F8-0FDF2B5EBBA2'),   -- light
        -- https://github.com/EmulatorNexus/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/Levels/XP3_Valley/Objects/StreetLight_01_Valley.txt
        Guid('D2CB0148-DBAD-4646-BAFF-CC6C103B4741'),    -- blueprint
        --Guid('D3EED736-D2DD-45C7-A9F4-DC9E095FA8A3'),   -- lensflare
        --Guid('93E30757-36D3-4F41-8C7D-7E73C64D5B25'),   -- lensflare mesh static model
        -- https://github.com/EmulatorNexus/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/Levels/XP3_Valley/Objects/Prefabs/lighttower_01_lit_nongroupable_autogen.txt
        Guid('139BA9B0-8AD5-088D-7286-68248806BFF3'),   -- blueprint
        --[[Guid('DF5EE1DE-414B-4196-8FF4-D62145896772'),   -- light
        Guid('42F2E121-A3CD-4C0B-A40A-03C2C6CEEE6B'),   -- light
        Guid('7444E2B0-18E0-4BAA-B4F1-73725274D336'),   -- light
        Guid('63ACC838-81F3-40C2-B9ED-3184255B6F87'),   -- light
        Guid('86E4B710-628D-4CA9-B1C9-BADDA81E0CB4'),   -- light]]
    }
}

function LiveEntityHandler:CreateFromBlueprint(p_HookCtx, p_Blueprint, p_Transform, p_Variation, p_ParentRepresentative)
    for l_Category, l_GuidTable in pairs(s_GuidTable) do 
        for _, l_Guid in ipairs(l_GuidTable) do
            if p_Blueprint.instanceGuid == l_Guid then 
                local s_CreatedEntityBus = p_HookCtx:Call()
                table.insert(m_StoredEntities, {s_CreatedEntityBus, l_Category})
                m_Logger:Write('Saved Object: ' .. Asset(p_Blueprint).name)
            end
        end
    end
end

local s_Timer = 0
local s_Counter = 0
function LiveEntityHandler:OnUpdateManagerPreSim(p_DeltaTime)
    if #m_Queue <= 0 then
        return
    end

    for l_Index, l_EntityBusTable in ipairs(m_Queue) do
        if l_EntityBusTable[1].entities ~= nil then
            for _, l_Entity in pairs(l_EntityBusTable[1].entities) do
                m_Logger:Write('Entity: ' .. l_Entity.typeInfo.name)
                if l_EntityBusTable[2] then
                    if l_Entity.typeInfo.name == 'ClientEmitterEntity' then
                        l_Entity:FireEvent('Start')
                    elseif l_Entity.typeInfo.name == 'ClientStaticModelEntity' then
                        l_Entity:PropertyChanged('Visible', true)
                    else
                        l_Entity:FireEvent('Enable')
                    end
                else
                    if l_Entity.typeInfo.name == 'ClientEmitterEntity' then
                        l_Entity:FireEvent('Stop')
                    elseif l_Entity.typeInfo.name == 'ClientStaticModelEntity' then
                        l_Entity:PropertyChanged('Visible', false)
                    else
                        l_Entity:FireEvent('Disable')
                    end
                end
            end
            s_Counter = s_Counter + 1
            table.remove(m_Queue, l_Index)
            m_Logger:Write('Changed Visibility')
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
