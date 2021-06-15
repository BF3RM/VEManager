if self.m_clientTime < self.m_totalDayLength * self.m_presetTimings[1] or self.m_clientTime > self.m_presetTimings[#self.m_presetTimings] * self.m_totalDayLength then -- 00:00 to 6:00 or 21:00 to 00:00

    -- set visibility preset night
    local s_factorNight = 1

    if s_print_enabled then
        print("Night Visibility: " .. s_factorNight)
        if self.m_clientTime < self.m_presetTimings[1] * self.m_totalDayLength then
            print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[1] - self.m_clientTime))
        end
    end

    -- apply visibility factor
    g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_factorNight)
    g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, 0)

elseif self.m_clientTime < self.m_totalDayLength * self.m_presetTimings[2] then -- 6:00 to 9:00

    -- calculate visibility preset morning
    local s_factorMorning = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[1] )) / ( self.m_totalDayLength * ( self.m_presetTimings[2] - self.m_presetTimings[1] )) --todo change these multiplication values to variables later to calculate automatically
    -- calculate visibility preset night
    local s_factorNight = 1

    if s_print_enabled then
        print("Night Visibility: " .. s_factorNight)
        print("Morning Visibility: " .. s_factorMorning)
        print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[2] - self.m_clientTime))
    end
    -- update visibility
    g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_factorNight)
    g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, s_factorMorning)
    g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, 0)

elseif self.m_clientTime < ( self.m_totalDayLength * self.m_presetTimings[3] ) then -- 9:00 to 12:00

    -- calculate visibility preset noon
    local s_factorNoon = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[2] )) / ( self.m_totalDayLength * ( self.m_presetTimings[3] - self.m_presetTimings[2] ))
    -- calculate visibility preset morning
    local s_factorMorning = 1

    if s_print_enabled then
        print("Morning Visibility: " .. s_factorMorning)
        print("Noon Visibility: " .. s_factorNoon)
        print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[3] - self.m_clientTime))
    end

    -- update visibility
    g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, s_factorMorning)
    g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, s_factorNoon)
    g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, 0)


elseif self.m_clientTime < ( self.m_totalDayLength * self.m_presetTimings[4] ) then -- 12:00 to 18:00

    -- calculate visibility preset evening
    local s_factorEvening = ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[3] )) / ( self.m_totalDayLength * ( self.m_presetTimings[4] - self.m_presetTimings[3] ))
    -- calculate visibility preset noon
    local s_factorNoon = 1

    if s_print_enabled then
        print("Noon Visibility: " .. s_factorNoon)
        print("Evening Visibility: " .. s_factorEvening)
        print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[4] - self.m_clientTime))
    end

    -- update visibility
    g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, s_factorNoon)
    g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, s_factorEvening)


elseif self.m_clientTime < ( self.m_totalDayLength * self.m_presetTimings[5] ) then -- 18:00 to 21:00
    -- Night preset has a lower visibility, thus we change evening visibility back to 0
    -- calculate visibility preset night
    local s_factorNight = 1
    -- calculate visibility preset evening
    local s_factorEvening = 1 - ( self.m_clientTime - ( self.m_totalDayLength * self.m_presetTimings[4] )) / ( self.m_totalDayLength * ( self.m_presetTimings[5] - self.m_presetTimings[4] ))

    if s_print_enabled then
        print("Evening Visibility: " .. s_factorEvening)
        print("Night Visibility: " .. s_factorNight)
        print("Time Till Switch: " .. (self.m_totalDayLength * self.m_presetTimings[5] - self.m_clientTime))
    end

    -- update visibility
    g_VEManagerClient:UpdateVisibility(self.m_currentNightPreset, self.m_nightPriority, s_factorNight)
    g_VEManagerClient:UpdateVisibility(self.m_currentMorningPreset, self.m_morningPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentNoonPreset, self.m_noonPriority, 0)
    g_VEManagerClient:UpdateVisibility(self.m_currentEveningPreset, self.m_eveningPriority, s_factorEvening)

end