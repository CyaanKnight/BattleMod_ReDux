local selfisenemy = false

local GLIDE_LAUNCH = sfx_kxgl1
local GLIDE_ACTIVE = sfx_kxgl2

local B = CBW_Battle

local isKnux = function(player)
    return player and player.mo and player.mo.valid and (B.GetSkinVarsFlags(player) & SKINVARS_GLIDESOUND)
end

B.GlideSound = function(player)
    if not(isKnux(player)) then
        return
    end


    local gliding = (player.pflags & PF_GLIDING)
    local glidelaunch = (gliding and not(player.mo.knux_glidelaunch))

    if gliding then

        // add hitbox
		if not player.battlehitbox then
			local hitbox = B.BattleHitboxSpawn(player, 18*player.mo.scale, 1*player.mo.scale, 2, player.mo.state, true, 0)
		end
        if glidelaunch then
            B.teamSound(player.mo, player, sfx_nullba, GLIDE_LAUNCH, 255, selfisenemy)
            player.mo.knux_glidelaunch = true
        end
        if not(S_SoundPlaying(player.mo, GLIDE_ACTIVE)) then
            B.teamSound(player.mo, player, sfx_nullba, GLIDE_ACTIVE, 255, selfisenemy)
        end
    else
        player.mo.knux_glidelaunch = nil
        S_StopSoundByID(player.mo, GLIDE_ACTIVE)
        S_StopSoundByID(player.mo, GLIDE_ACTIVE)
    end
end
