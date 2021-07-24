class('basicshitthatshouldbeineveryfuckingprogramminglanguage')

-- I fucking hate LUA and it makes my blood boil

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end


-- Singleton.
if g_basicshitthatshouldbeineveryfuckingprogramminglanguage == nil then
	g_basicshitthatshouldbeineveryfuckingprogramminglanguage = basicshitthatshouldbeineveryfuckingprogramminglanguage()
end

return g_basicshitthatshouldbeineveryfuckingprogramminglanguage