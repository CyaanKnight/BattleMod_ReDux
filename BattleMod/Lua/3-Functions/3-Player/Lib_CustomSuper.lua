
local B = CBW_Battle

-- "Super" form unrelated to in-game Chaos Emeralds

--If not set to "default", supermusic overrides the default music
local supermusic = "default"

local SUPER_TIME = TICRATE*20

-- ### Skin Definitions
-- SKINVARS_NOSUPERSPRITES
-- skindef flag to disable super sprites in battle

-- super_sound
-- skindef field to set default transformation sound

-- super_music
-- skindef field to set default super music

-- ### Object Variables

-- mo.battle_superstate - int
rawset(_G, "SS_NORMAL", 0) -- SS_NORMAL = 0, player is not super
rawset(_G, "SS_TRNS", 1) -- SS_TRNS   = 1, player is transforming
rawset(_G, "SS_MID", 2) -- SS_MID    = 2, player has just transformed, but the animation isn't over
rawset(_G, "SS_SUPER", 3) -- SS_SUPER  = 3, player has transformed and is now super

-- mo.battle_super - int
-- If positive, player is super
-- Will continue to count up until they are no longer super

-- mo.battle_supertime - int (timer)
-- Counts down until it reaches 0
-- When it reaches 0, the player de-transforms

-- mo.battle_nosupercolor - boolean
-- If set to true, this script will not modify the player's skincolor

-- mo.battle_supercolor - skincolor
-- If not set, supercolor picks skin's supercolor by default
-- Will cycle through 

-- ## Functions
-- Initial Super Transformation
function B.DoSuperOn(player)
    local mo = player.mo

    -- Enable Battle Super
    mo.battle_super = 1

    -- 30 Seconds of super
    mo.battle_supertime = SUPER_TIME

    -- Transformation Animation
    B.ResetPlayerProperties(player,false,false)
    mo.state = S_PLAY_SUPER_TRANS1
    mo.battle_superstate = SS_TRNS
end

-- Super De-Transformation
function B.DoSuperOff(player)
    local mo = player.mo

    -- Reset Variables
    mo.battle_super = 0
    mo.battle_supertime = 0
    mo.battle_superstate = SS_NORMAL

    mo.renderflags = $ & ~RF_FULLBRIGHT
    mo.eflags = $ & ~MFE_FORCESUPER

    --B.ResetPlayerProperties(player,(player.pflags & PF_JUMPED),(player.pflags & PF_THOKKED))


    mo.color = player.skincolor

    S_StartSound(nil, sfx_s1ca)

     for otherplayer in players.iterate do

        local ally = B.MyTeam(player, otherplayer)
        local self = (player == otherplayer)

        if self or (ally) then
            S_StartSound(nil, sfx_s1ca, otherplayer)
        else
            S_StartSound(nil, sfx_s3k66, otherplayer)
        end
    end

    player.powers[pw_sneakers] = 0
    player.powers[pw_invulnerability] = 0

    --player.shieldscale = FixedMul(skins[mo.skin].shieldscale, mo.scale)

    P_FlashPal(player, PAL_WHITE, 2)
end

-- Main Hook
function B.BattleSuper_ThinkFrame(player)

    if player.mo and player.mo.valid and player.mo.battle_super then
        local mo = player.mo

        local transform_frames = (mo.state >= S_PLAY_SUPER_TRANS1 and mo.state <= S_PLAY_SUPER_TRANS6)

        -- If we're transforming...
        if mo.battle_superstate == SS_TRNS then
            player.powers[pw_flashing] = max($, 2)
            -- And we're beyond the 4th frame already
            if mo.state >= S_PLAY_SUPER_TRANS3 then
                -- Now we have transformed, but our animation isn't over yet
                mo.battle_superstate = SS_MID

                -- Transformation Sound

                for otherplayer in players.iterate do

                    local ally = B.MyTeam(player, otherplayer)
                    local self = (player == otherplayer)

                    if self or not(ally) then
                        S_StartSound(nil, sfx_s3k9f, otherplayer)
                        P_FlashPal(otherplayer, PAL_WHITE, 2)
                    else
                        S_StartSound(nil, sfx_s3k46, otherplayer)
                    end
                end

                if (player.powers[pw_shield] & SH_NOSTACK) then
                    S_StartSound(mo, sfx_shattr)
                    local nega = P_SpawnMobjFromMobj(mo,0,0,0,MT_NEGASHIELD)
                    if nega and nega.valid then
                        nega.target = mo
                    end
                end

                player.shieldstock = {}
                P_RemoveShield(player)
            end
        end

        -- If we're not in transformation frames
        if not(transform_frames)
            mo.battle_superstate = SS_SUPER
            -- Start counting
            mo.battle_super = $+1
            mo.battle_supertime = $-1
        end

        if (mo.battle_superstate == SS_MID) or (mo.battle_superstate == SS_SUPER) then

            if not(B.GetSkinVarsFlags(player)&SKINVARS_NOSUPERSPRITES) then
                mo.eflags = $|MFE_FORCESUPER
            end

            player.powers[pw_sneakers] = mo.battle_supertime
            player.powers[pw_invulnerability] = mo.battle_supertime

            if player.tumble or P_PlayerInPain(player) then
                player.powers[pw_flashing] = max($, 2)
                player.powers[pw_invulnerability] = 0
            end
        end

        if (mo.battle_supertime <= 0) or (player.playerstate ~= PST_LIVE) then
            B.DoSuperOff(player)
        end
    end
end

-- PostThinkFrame
function B.BattleSuper_PostThinkFrame(player)
    if player.mo and player.mo.valid and player.mo.battle_super then
        local mo = player.mo

        -- Wait until transformation actually starts (4th frame, typically)
        if mo.battle_superstate == SS_SUPER then
            -- Force Super sprites

            if not(B.GetSkinVarsFlags(player)&SKINVARS_NOSUPERSPRITES) then
                mo.eflags = $|MFE_FORCESUPER
            end

            -- Force full brightness
            mo.renderflags = $|RF_FULLBRIGHT
        end

        -- Cycle Super color
        if (mo.battle_superstate == SS_MID) or (mo.battle_superstate == SS_SUPER) then
            if not(mo.battle_nosupercolor) then
                local color = mo.battle_supercolor or skins[mo.skin].supercolor
                --mo.color = color + abs( ( (mo.battle_super >>1 % 9) - 4))
            end
        end
    end
end


    



