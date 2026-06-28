
local state_startup = 1
local state_spinning = 2

addHook("PlayerCanDamage", function(player, mo)
	if (player.mo and player.mo.valid and player.mo.state == S_SONIC_HUMMINGTOP) and not(mo.player) then
        return true
	end
end)