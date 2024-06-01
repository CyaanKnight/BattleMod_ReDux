local B = CBW_Battle
--Dashmode Overlay & SFX


addHook("MobjThinker", B.DashmodeOverlayThink, MT_DASHMODE_OVERLAY) --Pulse, Vars, & Teleport

addHook("PreThinkFrame", do
    for player in players.iterate do
        B.DashmodeResetter(player) --Reset dashmode to zero instead of decreasing
        B.DashmodeSFXPlayer(player) --Play SFX
        B.DashmodeOverlaySpawner(player) --Spawn indicator
    end
end)

addHook("PostThinkFrame", do
    for player in players.iterate do
        B.DashmodeColorizer(player) --Colorize instead of orange flashing (Kinda hacky but best we can do as of 2.2.13)
    end
end)