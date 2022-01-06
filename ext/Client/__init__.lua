-- require editorLayer Preset
local m_EditorLayer = require('EditorLayer')

-- require VEEditor
local m_Editor = require('VEEditor')

-- Send Preset to VEManager
Events:Dispatch('VEManager:RegisterPreset', m_EditorLayer)