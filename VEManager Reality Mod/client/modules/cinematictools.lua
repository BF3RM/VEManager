class = 'CinematicTools'


function CinematicTools:__init()
    self:RegisterVars()
    self:RegisterEvents()
end


function CinematicTools:RegisterVars()
    self.m_CineState = nil
    self.m_PendingDirty = false
    self.m_CinePriority = 100000000
end


function CinematicTools:RegisterEvents()
    self.m_VisualStateAddedEvent = Events:Subscribe('VE:StateAdded', self, self.OnVisualStateAdded)
    self.m_EngineUpdateEvent = Events:Subscribe('Engine:Update', self, self.OnEngineUpdate)
end


function CinematicTools:GenericCallback(p_Path, p_Value)
    if m_CineState == nil then
        m_CineState = Tool:GetVisualEnvironmentState(m_CinePriority)
    end

    if m_CineState[p_Path] == value then
        return
    end

    m_CineState[p_Path] = value
    pendingDirty = true
end


function CinematicTools:CreateGUI()
    -- Sky
    DebugGUI:Folder("Sky", function ()

        DebugGUI:Range('Sky Brightness', {DefValue = 1, Min = 0, Max = 5, Step = 0.01}, function(value)
            self.GenericCallback("sky.brightnessScale", value)
        end)

        DebugGUI:Range('Sun Size', {DefValue = 0.01, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("sky.sunSize", value)
        end)

        DebugGUI:Range('Sun Scale', {DefValue = 5, Min = 0, Max = 100, Step = 0.1}, function(value)
            self.GenericCallback("sky.sunScale", value)
        end)

        DebugGUI:Range('Sun Rotation X', {DefValue = 90, Min = 0, Max = 359, Step = 1}, function(value)
            self.GenericCallback("outdoorLight.sunRotationX", value)
        end)

        DebugGUI:Range('Sun Rotation Y', {DefValue = 0, Min = 0, Max = 180, Step = 1}, function(value)
            self.GenericCallback("outdoorLight.sunRotationY", value)
        end)

        DebugGUI:Range('Sun Color Red', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.sunColor.x", value)
        end)

        DebugGUI:Range('Sun Color Green', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.sunColor.y", value)
        end)

        DebugGUI:Range('Sun Color Blue', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.sunColor.z", value)
        end)

    end)
    -- Environment
    DebugGUI:Folder("Environment", function ()

        DebugGUI:Range('Ground Color Red', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.groundColor.x", value)
        end)

        DebugGUI:Range('Ground Color Green', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.groundColor.y", value)
        end)

        DebugGUI:Range('Ground Color Blue', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.groundColor.z", value)
        end)

        DebugGUI:Range('Sky Color Red', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.skyColor.x", value)
        end)

        DebugGUI:Range('Sky Color Green', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.skyColor.y", value)
        end)

        DebugGUI:Range('Sky Color Blue', {DefValue = 1, Min = 0, Max = 1, Step = 0.01}, function(value)
            self.GenericCallback("outdoorLight.skyColor.z", value)
        end)

        DebugGUI:Range('Sky Light Angle', {DefValue = 0.85, Min = 0, Max = 1, Step = 0.001}, function(value)
            self.GenericCallback("outdoorLight.skyLightAngleFactor", value)
        end)

    end)
    -- Color Correction
    DebugGUI:Folder("Color Correction", function ()

        DebugGUI:Checkbox('Color Correction Enable', true, function(value)
            self.GenericCallback("colorCorrection.enable", value)
        end)

        DebugGUI:Range('Brightness Red', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.brightness.x", value)
        end)

        DebugGUI:Range('Brightness Green', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.brightness.y", value)
        end)

        DebugGUI:Range('Brightness Blue', {DefValue = 1, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.brightness.z", value)
        end)

        DebugGUI:Range('Contrast Red', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.contrast.x", value)
        end)

        DebugGUI:Range('Contrast Green', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.contrast.y", value)
        end)

        DebugGUI:Range('Contrast Blue', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.contrast.z", value)
        end)

        DebugGUI:Range('Saturation Red', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.saturation.x", value)
        end)

        DebugGUI:Range('Saturation Green', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.saturation.y", value)
        end)

        DebugGUI:Range('Saturation Blue', {DefValue = 1.0, Min = 0.0, Max = 1.5, Step = 0.01}, function(value)
            self.GenericCallback("colorCorrection.saturation.z", value)
        end)

    end)
    -- Tonemap
    DebugGUI:Folder("Tonemap", function ()

        DebugGUI:Range('Method', {DefValue = 2.0, Min = 0.0, Max = 3.0, Step = 1.0}, function(value)
            self.GenericCallback("tonemap.tonemapMethod", value)
        end)

        DebugGUI:Range('Minimum Exposure', {DefValue = 0.0, Min = 0.0, Max = 10.0, Step = 0.1}, function(value)
            self.GenericCallback("tonemap.minExposure", value)
        end)

        DebugGUI:Range('Maximum Exposure', {DefValue = 1.0, Min = 0.0, Max = 10.0, Step = 0.1}, function(value)
            self.GenericCallback("tonemap.maxExposure", value)
        end)

        DebugGUI:Range('Middle Gray ', {DefValue = 1.0, Min = 0.0, Max = 1.0, Step = 0.01}, function(value)
            self.GenericCallback("tonemap.middleGray", value)
        end)

        DebugGUI:Range('Exposure Adjust Time', {DefValue = 1.0, Min = 0.0, Max = 50.0, Step = 0.1}, function(value)
            self.GenericCallback("tonemap.exposureAdjustTime", value)
        end)

        DebugGUI:Range('Bloom Scale Red', {DefValue = 0.2, Min = 0.0, Max = 5.0, Step = 0.05}, function(value)
            self.GenericCallback("tonemap.bloomScale.x", value)
        end)

        DebugGUI:Range('Bloom Scale Green', {DefValue = 0.2, Min = 0.0, Max = 5.0, Step = 0.05}, function(value)
            self.GenericCallback("tonemap.bloomScale.y", value)
        end)

        DebugGUI:Range('Bloom Scale Blue', {DefValue = 0.2, Min = 0.0, Max = 5, Step = 0.05}, function(value)
            self.GenericCallback("tonemap.bloomScale.z", value)
        end)

    end)

    -- Fog
    DebugGUI:Folder("Fog", function ()

        DebugGUI:Range('Fog Start', {DefValue = 0.0, Min = -100.0, Max = 10000.0, Step = 10.0}, function(value)
            self.GenericCallback("fog.start", value)
        end)

        DebugGUI:Range('Fog End', {DefValue = 5000.0, Min = 0.0, Max = 15000.0, Step = 10.0}, function(value)
            self.GenericCallback("fog.endValue", value)
        end)

        DebugGUI:Range('Fog Distance Multiplier [doesn´t work on all maps]', {DefValue = 1.0, Min = 0.0, Max = 5.0, Step = 0.2}, function(value)
            self.GenericCallback("fog.fogDistanceMultiplier", value)
        end)