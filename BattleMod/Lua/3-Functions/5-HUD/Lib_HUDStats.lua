--[[
local B = CBW_Battle
local CV = B.Console

B.GetStartRings = function(player, beforedeath)
    if beforedeath then
        local previous = (player.ringpenalty or 0) - (player.lastpenalty or 0)
        return CV.StartRings.value - previous
    else
        return (CV.StartRings.value - (player.ringpenalty or 0)) or 0
    end
end

B.StatsHUD = function(v)
    if not (B.BattleGametype() and CV.RingPenalty.value) then
        return
    end
    local player
    for p in players.iterate do
        if p == displayplayer then
            player = p
            break
        end
    end
    if not player then
        return
    end
    -- Starting rings
    local patch = v.cachePatch("NRNG1")
    local x = 4
    local y = 4
    local flags = V_PERPLAYER|V_SNAPTOTOP|V_SNAPTOLEFT
    v.draw(x, y, patch, flags|V_HUDTRANSHALF)
    v.drawString(x+8, y+3, B.GetStartRings(player), flags|V_HUDTRANS, "center")
end

B.StartRingsHUD = function(v, player)
    if B.Exiting then
        return
    end
    if not (player.deadtimer
        and player.lastpenalty
        and CV.RingPenalty.value
        and B.BattleGametype()
        and B.GetStartRings(player, true) >= 0
    ) then
        return
    end
    local x = (320/2) - 6
    local y = (240/2)
    local flags = V_PERPLAYER|V_SNAPTOTOP
    local srflags = flags|V_YELLOWMAP
    local color = nil
    if player.deadtimer > TICRATE*3 then -- hide completely
        return
    elseif player.deadtimer > TICRATE*2 then -- fade and move out
        local time = player.deadtimer - TICRATE*2
        local progressrate = FRACUNIT / (TICRATE*2)
        x = ease.outcubic(time*progressrate, $, 40) --x = $ - time
        y = ease.outcubic(time*progressrate, $, 180) --y = $ + time
        local V_TIMETRANS = B.TIMETRANS(100 - (time*3)) or 0
        flags = $ | V_TIMETRANS
        srflags = $ | V_TIMETRANS
    elseif player.deadtimer > TICRATE then -- flash red and bounce
        srflags = ($ | V_REDMAP) &~ V_YELLOWMAP
        if (leveltime % 8 >= 4) then
            v.drawString(x+8, y+16, "-"..player.lastpenalty, srflags, "center")
        end
        flags = $ | V_INVERTMAP
        color = SKINCOLOR_RED
        local y2 = y - (TICRATE*5/2) + player.deadtimer*2
        x = $ + v.RandomRange(-1, 1)
        y = min($, y2)
    elseif player.deadtimer == TICRATE then -- sfx
        S_StartSound(nil, sfx_antiri, player)
    else -- fade in
        local V_TIMETRANS = B.TIMETRANS(player.deadtimer*3) or 0
        flags = $ | V_TIMETRANS
        srflags = $ | V_TIMETRANS
    end
    local patch = v.cachePatch("NRNG1")
    local spacing = 10
    local displayrings = B.GetStartRings(player, player.deadtimer < TICRATE)
    v.draw(x-spacing, y, patch, flags, v.getColormap(TC_RAINBOW, color))
    --v.drawString(x+8-spacing, y+4, "SR", srflags, "thin-center")
    v.drawString(x+8+spacing, y+4, displayrings, flags, "center")
end
]]