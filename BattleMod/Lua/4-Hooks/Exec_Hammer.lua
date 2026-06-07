addHook("PlayerCanDamage", function(player, mo)
    if mo and mo.player then return end
    if player and player.mo and player.mo.valid and player.mo.melee_hammertwirl then
        player.pflags = $ & ~PF_THOKKED
    end
end)