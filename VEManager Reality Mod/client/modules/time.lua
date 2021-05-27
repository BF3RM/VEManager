local Time = class 'Time'
local Settings = require the settings file if not existent => hard-code


function Time:__init()

    ClientTime:RegisterVars()
    ClientTime:RegisterEvents()
    ClientTime:GetVE()
    ClientTime:FindSkyGradientTexture()

end 


function Time:RegisterVars()

    self.m_transitionFactor = nil
    self.m_clientDayLength = 0 
    self.m_previousFactor = nil 

end 


function Time:RegisterEvents()

    self.m_serverSyncEvent = NetEvents:Subscribe(NetMessage.S2C_SYNC_DAYTIME, self, self.ServerSync)
    self.m_engineUpdateEvent = Events:Subscribe('Engine:Update', self, self.OnEngineUpdate)

end 


function Time:OnEngineUpdate() -- can be swapped for Engine Update anywhere else

    if Settings.dayNightEnabled == true then 

        Time:Tick(deltaTime)

    end 

end 


function Time:Tick(id, dt) -- needs restructure if we want to lerp between 4 presets

        self.m_clientDayLength = self.m_clientDayLength + dt
        
        -- Offset seconds to 0:00 AM
        self.seconds = self.m_clientDayLength % Settings.dayLengthInSeconds 

        -- Offset seconds (0 is the middle of the night, but it should be the start of the night)
        self.seconds = self.seconds + Settings.pureNightDurationInSeconds / 2

        -- Check if it is night
        if self.seconds < Settings.pureNightDurationInSeconds / 2 then
            self.m_transitionFactor = 1.0
        
        -- Check if it is night -> day
        elseif self.seconds < Settings.dayLengthInSeconds / 2 - Settings.pureDayDurationInSeconds / 2 then
            self.m_transitionFactor = 1.0 - (self.seconds - Settings.pureNightDurationInSeconds / 2) / (Settings.dayLengthInSeconds / 2 - Settings.pureDayDurationInSeconds / 2 - Settings.pureNightDurationInSeconds / 2)
            
        -- Check if it is day
        elseif self.seconds < Settings.dayLengthInSeconds / 2 + Settings.pureDayDurationInSeconds / 2 then
            self.m_transitionFactor = 0.001
            
        -- Check if it is day -> night
        elseif self.seconds < Settings.dayLengthInSeconds - Settings.pureNightDurationInSeconds / 2 then
            self.m_transitionFactor = (self.seconds - Settings.dayLengthInSeconds / 2 - Settings.pureDayDurationInSeconds / 2) / (Settings.dayLengthInSeconds - Settings.pureNightDurationInSeconds / 2 - Settings.dayLengthInSeconds / 2 - Settings.pureDayDurationInSeconds / 2)
        
        -- Check if it is night
        else
            self.m_transitionFactor = 1.0
        end
        
        -- Update environment lighting

        if self.m_previousFactor ~= self.m_transitionFactor then
        VEManagerClient:UpdateVisibility(id, self.m_transitionFactor)
        end 

        self.m_transitionFactor = self.m_previousFactor

end 


return Time