local B = CBW_Battle

-- Don't worry about using this function, it's mainly for bundled skincolors to avoid console warnings on load.
B.SafeFreeslot = function(...)
    local freeslots = {...}

    if not(freeslots and #freeslots) then
        return
    end

    for i = 1, #freeslots do
        local new = freeslots[i]
        if rawget(_G, tostring(new)) then
            --Freeslot already exists, do nothing
            continue
        else
            freeslot(tostring(new))
            continue
        end
    end
end