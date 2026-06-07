local B = CBW_Battle

local applied_all_stored = false

addHook("NetVars", function(n)
    applied_all_stored = n($)
end)

addHook("ThinkFrame", do
    if (G_GametypeHasTeams()) and (B.BattleGametype()) then 
        applied_all_stored = false
        for player in players.iterate do
            if (player.ctfteam < 1) then
                player.battle_oldskincolor = nil
                continue
            end

            if not(player.battle_oldskincolor) then
                player.battle_oldskincolor = player.skincolor
            end

            local color = ({skincolor_redteam, skincolor_blueteam})[player.ctfteam]

            player.skincolor = color
            if player.realmo and player.realmo.valid then
                player.realmo.color = color
            end
        end

    elseif not(applied_all_stored) then
        for player in players.iterate do
            if not(player.battle_oldskincolor) then continue end
            player.skincolor = player.battle_oldskincolor
            player.battle_oldskincolor = nil
        end
        applied_all_stored = true
    end
end)