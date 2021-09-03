---
--- Author:   Nikos Kapraras <nikos@kapraran.dev>
--- URL:      https://github.com/kapraran/vu-debug-gui
--- License:  https://choosealicense.com/licenses/mit/
---

DebugGUIControlType = {
  Button = 1,
  Checkbox = 2,
  Text = 3,
  Range = 4,
  Dropdown = 5,
  Number = 6,
  Vec2 = 7,
  Vec3 = 8,
  Vec4 = 9,
}

function SetDefaultNumOpts(numOpts, skipDefault)
  numOpts = numOpts or {}
  numOpts.Min = (numOpts.Min ~= nil and numOpts.Min) or 0
  numOpts.Max = (numOpts.Max ~= nil and numOpts.Max) or 1
  numOpts.Step = numOpts.Step

  if not skipDefault then
    numOpts.DefValue = numOpts.DefValue or numOpts.Min
  end

  return numOpts
end

function resolveVecOpts(options, defVector)
  if options == nil then
    return {defValue = defVector}
  elseif type(options.x) == 'number' then
    return {defValue = options}
  else
    return options
  end
end

function emitEvent(...)
  local args = {...}
  if SharedUtils:IsClientModule() then
    Events:Dispatch(table.unpack(args))
  else
    NetEvents:Broadcast(table.unpack(args))
  end
end

-- 
-- DebugGUIControl
-- 

class "DebugGUIControl"

DebugGUIControl.static.OrderIndex = 1

function DebugGUIControl:__init(_type, name, options, context, callback)
  if callback == nil then
    callback = context
    context = nil
  end

  self.id = MathUtils:RandomGuid()
  self.type = _type
  self.name = name
  self.options = options
  self.context = context
  self.callback = callback
  self.isClient = SharedUtils:IsClientModule()

  self.lastValue = options.DefValue
  self.folder = nil
  self.order = DebugGUIControl.OrderIndex

  DebugGUIControl.static.OrderIndex = DebugGUIControl.OrderIndex + 1
end

function DebugGUIControl:ExecuteCallback(value, player)
  self.lastValue = self:ConvertValue(value)

  if self.callback == nil then
    return
  end

  if self.context == nil then
    self.callback(self.lastValue, player)
  else
    self.callback(self.context, self.lastValue, player)
  end
end

function DebugGUIControl:ConvertValue(value)
  if self.type == DebugGUIControlType.Vec2 then
    return Vec2(value.x, value.y)
  elseif self.type == DebugGUIControlType.Vec3 then
    return Vec3(value.x, value.y, value.z)
  elseif self.type == DebugGUIControlType.Vec4 then
    return Vec4(value.x, value.y, value.z, value.w)
  end

  return value
end

function DebugGUIControl:Get()
  return self.lastValue
end

function DebugGUIControl:AsTable()
  return {
    Id = self.id:ToString("D"),
    Type = self.type,
    Name = self.name,
    Folder = self.folder,
    Options = self.options,
    IsClient = self.isClient,
  }
end

-- 
-- DebugGUIManager
-- 

class "DebugGUIManager"

function DebugGUIManager:__init()
  self.controls = {}

  self.__controlsRequested = false
  self.__addInFolder = nil

  self:RegisterEvents()
end

function DebugGUIManager:RegisterEvents()
  Events:Subscribe("DBGUI:RequestControls", self, self.OnRequestControls)
  NetEvents:Subscribe("DBGUI:RequestControls.Net", self, self.OnRequestControls)

  if SharedUtils:IsClientModule() then
    Events:Subscribe("DBGUI:OnChange", self, self.OnChange)
  else
    NetEvents:Subscribe("DBGUI:OnChange.Net", self, self.OnChangeNet)
  end
end

function DebugGUIManager:OnChange(id, value, player)
  local control = self.controls[id]

  if control == nil then
    return
  end

  control:ExecuteCallback(value, player)
end

function DebugGUIManager:OnChangeNet(player, id, value)
  self:OnChange(id, value, player)
end

function DebugGUIManager:Add(control)
  if control == nil then
    return nil
  end

  if self.__addInFolder ~= nil then
    control.folder = self.__addInFolder
  end

  self.controls[control.id:ToString("D")] = control

  if self.__controlsRequested then
    self.__controlsRequested = false
    self:Show(false)
  end

  return control
end

function DebugGUIManager:Folder(name, context, callback)
  -- avoid nested folders
  if self.__addInFolder ~= nil then
    return
  end

  -- swap callback-context if needed
  if callback == nil then
    if context == nil then
      return
    end

    callback = context
    context = nil
  end

  self.__addInFolder = name
  callback(context)
  self.__addInFolder = nil
end

function DebugGUIManager:OnRequestControls()
  self.__controlsRequested = true
  self:Show(false)
end

function DebugGUIManager:Show(clear)
  if not self.__controlsRequested then
    return
  end

  clear = not (not clear)

  -- convert to array
  local controlsOrdered = {}
  for _, control in pairs(self.controls) do
    table.insert(controlsOrdered, control)
  end

  -- sort based on .order
  table.sort(controlsOrdered, function(controlA, controlB)
    return controlA.order < controlB.order
  end)

  local data = {}
  for _, control in ipairs(controlsOrdered) do
    table.insert(data, control:AsTable())
  end

  if SharedUtils:IsClientModule() then
    Events:Dispatch("DBGUI:Show", clear, data)
  else
    NetEvents:Broadcast("DBGUI:Show.Net", clear, data)
  end
end

function DebugGUIManager:ShowUI()
  emitEvent("DBGUI:ShowUI")
end

function DebugGUIManager:HideUI()
  emitEvent("DBGUI:HideUI")
end

local debugGUIManager = DebugGUIManager()

-- 
-- DebugGUI
-- 

class "DebugGUI"

function DebugGUI.static:Button(name, context, callback)
  local control = DebugGUIControl(
    DebugGUIControlType.Button,
    name,
    {},
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI.static:Checkbox(name, defValue, context, callback)
  local control = DebugGUIControl(
    DebugGUIControlType.Checkbox,
    name,
    {
      DefValue = defValue
    },
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI.static:Text(name, defValue, context, callback)
  local control = DebugGUIControl(
    DebugGUIControlType.Text,
    name,
    {
      DefValue = defValue
    },
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI.static:Number(name, defValue, context, callback)
  local control = DebugGUIControl(
    DebugGUIControlType.Number,
    name,
    {
      DefValue = defValue
    },
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI.static:Range(name, options, context, callback)
  options = options or {}

  -- defaults
  options = SetDefaultNumOpts(options)

  local control = DebugGUIControl(
    DebugGUIControlType.Range,
    name,
    options,
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI.static:Dropdown(name, options, context, callback)
  options = options or {}

  -- defaults
  options.Values = (options.Values ~= nil and options.Values) or {0}
  options.DefValue = options.DefValue or 0

  local control = DebugGUIControl(
    DebugGUIControlType.Dropdown,
    name,
    options,
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI:Vector(name, options, context, callback)
  local vector = options.DefValue

  -- defaults
  options.x = SetDefaultNumOpts(options.x, true)
  options.y = SetDefaultNumOpts(options.y, true)

  if not options.Type == DebugGUIControlType.Vec2 then
    options.z = SetDefaultNumOpts(options.z, true)
  elseif not options.Type == DebugGUIControlType.Vec3 then
    options.w = SetDefaultNumOpts(options.w, true)
  end

  local control = DebugGUIControl(
    options.Type,
    name,
    {
      DefValue = options.DefValue
    },
    context,
    callback
  )

  return debugGUIManager:Add(control)
end

function DebugGUI.static:Vec2(name, options, context, callback)
  local options = resolveVecOpts(options, Vec2(0, 0))
  options.Type = DebugGUIControlType.Vec2

  return self:Vector(name, options, context, callback)
end

function DebugGUI.static:Vec3(name, options, context, callback)
  local options = resolveVecOpts(options, Vec3(0, 0, 0))
  options.Type = DebugGUIControlType.Vec3

  return self:Vector(name, options, context, callback)
end

function DebugGUI.static:Vec4(name, options, context, callback)
  local options = resolveVecOpts(options, Vec4(0, 0, 0, 0))
  options.Type = DebugGUIControlType.Vec4

  return self:Vector(name, options, context, callback)
end

function DebugGUI.static:Print(str)
  -- TODO
end

function DebugGUI.static:Folder(name, context, callback)
  debugGUIManager:Folder(name, context, callback)
end

function DebugGUI.static:Show(clear)
  debugGUIManager:Show(clear)
end

function DebugGUI.static:ShowUI()
  debugGUIManager:ShowUI()
end

function DebugGUI.static:HideUI()
  debugGUIManager:HideUI()
end
