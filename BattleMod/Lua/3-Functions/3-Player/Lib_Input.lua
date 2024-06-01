local B = CBW_Battle
B.InputControl = function(player)
	player.thinkmoveangle = B.GetInputAngle(player)
	player.realbuttons = player.cmd.buttons
	player.realsidemove = player.cmd.sidemove
	player.realforwardmove = player.cmd.forwardmove
	player.realangleturn = player.cmd.angleturn
	
	if player.lockaim and player.mo then --Aim is being locked in place
		player.cmd.aiming = player.aiming>>16
		player.cmd.angleturn = player.mo.angle>>16
	end
	if player.pflags&PF_STASIS then
		--Failsafe for simple controls
		player.cmd.sidemove = 0
		player.cmd.forwardmove = 0
	end
	if player.lockmove then
		player.cmd.sidemove = 0
		player.cmd.forwardmove = 0
		player.cmd.buttons = 0
	end
	if player.melee_state then
		if player.melee_charge < FRACUNIT then
			player.cmd.forwardmove = $ / 3
			player.cmd.sidemove = $ / 3
		else
			player.cmd.forwardmove = 0
			player.cmd.sidemove = 0
		end
	end
	if (player.mo and player.mo.valid) and (player.mo.state == S_PLAY_FLY_TIRED
		or (player.mo.state == S_PLAY_FLY and player.cmd.buttons & BT_SPIN))
	then
--		player.cmd.forwardmove = $ / 2
--		player.cmd.sidemove = $ / 2
		if not P_IsObjectInGoop(player.mo) then
			P_SetObjectMomZ(player.mo, -gravity/2, true)
		end
	end
	if player.jumpstasistimer then
		player.jumpstasistimer = $-1
		player.cmd.buttons = $ &~ BT_JUMP
	end
end

B.GetInputAngle = function(player)
	local mo = player.mo
	if not mo then
		mo = player.truemo
	end
	
	if mo and mo.valid then
		if (mo.flags2&MF2_TWOD or twodlevel) then
			return mo.angle
		end
		local fw = player.cmd.forwardmove
		local sw = player.cmd.sidemove
		-- 	local pang = player.cmd.angleturn << 16--is this netsafe?
		local analog = player.pflags&PF_ANALOGMODE

		local pang = mo.angle

		if fw == 0 and sw == 0 then
			return pang
		end

		if analog then
			pang = player.cmd.angleturn<<FRACBITS
		end

		local c0, s0 = cos(pang), sin(pang)


		local rx, ry = fw*c0 + sw*s0, fw*s0 - sw*c0
		local retangle = R_PointToAngle2(0, 0, rx, ry)
		return retangle
	end
end

B.ButtonCheck = function(player,button)
	if player.cmd.buttons&button then
		if player.buttonhistory&button then
			return 2
		else
			return 1
		end
	end
	return 0
end