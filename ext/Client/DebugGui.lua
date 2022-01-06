require "__shared/Config"

local mouseDisabled = true

Events:Subscribe("Extension:Loaded", function()
	WebUI:Init()
	Events:DispatchLocal("DBGUI:RequestControls")
	Events:DispatchLocal("DBGUI:RequestControls.Net")
end)

Events:Subscribe("Level:Loaded", function()
	Events:Dispatch("DBGUI:RequestControls")
	Events:DispatchLocal("DBGUI:RequestControls.Net")
end)

Events:Subscribe("Player:UpdateInput", function()
	if InputManager:WentKeyDown(VEE_CONFIG.EDITOR_ENABLE_KEY) then --TODO: ADD TO VEE CONFIG
		mouseDisabled = not mouseDisabled

		if mouseDisabled then
			WebUI:ResetMouse()
			WebUI:ResetKeyboard()
		else
			WebUI:EnableMouse()
		end
	end
end)

Events:Subscribe("DBGUI:UIEvent", function(jsonData)
	local data = json.decode(jsonData)

	if data.isClient then
		Events:Dispatch("DBGUI:OnChange", data.id, data.value)
	else
		Events:DispatchLocal("DBGUI:OnChange.Net", data.id, data.value)
	end
end)

Events:Subscribe("DBGUI:ResetMKB", function(jsonData)
	mouseDisabled = true;

	WebUI:ResetMouse()
	WebUI:ResetKeyboard()
end)

local function OnShow(clear, data)
	WebUI:ExecuteJS("vext.addControls(" .. json.encode(data) ..")")
end

local function ShowUI()
	WebUI:ExecuteJS("vext.showUI()")
end

local function HideUI()
	WebUI:ExecuteJS("vext.hideUI()")
end

Events:Subscribe("DBGUI:ShowUI", ShowUI)
Events:Subscribe("DBGUI:HideUI", HideUI)
Events:Subscribe("DBGUI:Show", OnShow)
