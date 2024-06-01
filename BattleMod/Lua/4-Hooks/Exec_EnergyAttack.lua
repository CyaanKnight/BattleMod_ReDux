--Spike Breaking (Because battlemod nulls out STR_SPIKE)
addHook("MobjCollide", function(spike, pmo)
	if not (pmo.player and pmo.player.valid) then return end
	if pmo.z+pmo.height < spike.z or spike.z+spike.height < pmo.z then return end
	
	if player.energyattack_ringsparktimer then
		P_KillMobj(spike, pmo, pmo)
	end
end, MT_SPIKE)

addHook("MobjCollide", function(spike, pmo)
    if not (pmo.player and pmo.player.valid) then return end
    if (pmo.z > spike.z+spike.height*4) or (spike.z > pmo.z+pmo.height*2) then return end
	
	if player.energyattack_ringsparktimer then
		P_KillMobj(spike, pmo, pmo)
	end
end, MT_WALLSPIKE)