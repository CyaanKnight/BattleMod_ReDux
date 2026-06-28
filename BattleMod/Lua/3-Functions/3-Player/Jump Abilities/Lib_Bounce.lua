local B = CBW_Battle

B.FastBounce = function(player, mo)
    if player.pflags&PF_THOKKED then return true end
    mo.state = S_PLAY_BOUNCE
    player.pflags = $|(PF_THOKKED|PF_BOUNCING) & ~(PF_JUMPED|PF_NOJUMPDAMAGE|PF_STARTJUMP)
    if (mo.momz*P_MobjFlip(mo)) > 0 then
        mo.momz = $/2
    end
    return true
end