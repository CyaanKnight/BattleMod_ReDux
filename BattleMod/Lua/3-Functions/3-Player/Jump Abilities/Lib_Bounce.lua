local B = CBW_Battle

local air_to_bounce = {
	[S_FANG_AIRSHOT] = S_FANG_BCESHOT,
	[S_FANG_AIRSHOT_FINISH] = S_FANG_BCESHOT
}

B.FastBounce = function(player, mo)
    if player.pflags&PF_THOKKED then return true end
    if air_to_bounce[mo.state] then
        mo.state = air_to_bounce[mo.state]
    end
    mo.state = S_PLAY_BOUNCE
    player.pflags = $|(PF_THOKKED|PF_BOUNCING) & ~(PF_JUMPED|PF_NOJUMPDAMAGE|PF_STARTJUMP)
    if (mo.momz*P_MobjFlip(mo)) > 0 then
        mo.momz = $/2
    end
    return true
end