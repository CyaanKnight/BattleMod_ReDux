local B = CBW_Battle
local G = B.Gametypes
local A = B.Arena

local spawnanim = function(player)
	local mo = player.mo
	//Aesthetic
	if leveltime%4==0 then
		P_SpawnMobj(mo.x,mo.y,mo.z,MT_IVSP)
	end
	//Thrust
	P_SetObjectMomZ(mo,FRACUNIT*2,false)
	//Intangibility
	mo.flags = $|MF_NOCLIPTHING
	player.powers[pw_flashing] = TICRATE*2
	player.nodamage = player.powers[pw_flashing]
	if B.RubyGametype() then player.powers[pw_flashing] = 0 end
	//Do State
	player.panim = PA_ROLL
	mo.state = (B.SkinVars[player.mo.skin] and B.SkinVars[player.mo.skin].spawnanim_state) or S_PLAY_ROLL
	//Do control
	player.cmd.forwardmove = 0
	player.cmd.sidemove = 0
	player.cmd.buttons = 0
end

B.PlayerBattleSpawnStart = function(player, forced)
	if player.spectator then return false end
	if not(player.playerstate == PST_LIVE) then return false end
	if not G.SpawnAnimation[gametype] and not forced then return false end

	player.battlespawning = 48
	player.mo.rubyrun_shielddespawn = nil
	S_StartSound(player.mo,sfx_s3kb8)
	spawnanim(player)
	if not player.revenge
		A.JettySynFlags(player,false)
		B.ResetPlayerProperties(player,false,false)
	end
	if not(player.powers[pw_shield]&SH_NOSTACK) then
		B.SpawnWithShield(player)
	end
	return true
end

B.PlayerBattleSpawning = function(player)
	if not(player.mo) then return false end
	if not(player.battlespawning) then return false end
	local mo = player.mo
	local dojump = B.PlayerButtonPressed(player,BT_JUMP,false,true) 
	local dospin = B.PlayerButtonPressed(player,BT_SPIN,false,true)
	local can_act = player.battlespawning < 25
	
	player.battlespawning = $-1
		
	//Spawning
	if player.battlespawning then
		spawnanim(player)
		if B.PreRoundWait() or not(can_act) then return true end
	end
	

	//Natural End Spawn
	if player.battlespawning == 0 then
		mo.flags = $&~MF_NOCLIPTHING
	return false end
	//Spawn Jump
	if dojump then
		player.pflags = ($|PF_STARTJUMP|PF_JUMPDOWN)&~(PF_SPINNING|PF_THOKKED)
		player.cmd.buttons = $|BT_JUMP
		player.buttonhistory = $|BT_JUMP
		P_DoJump(player,true)
		player.battlespawning = 0
		mo.flags = $&~MF_NOCLIPTHING
	return false end
	//Spawn Dash
	if dospin then
		P_Thrust(mo,mo.angle,mo.scale*24)
		S_StartSound(mo,sfx_zoom)
		player.cmd.buttons = $|BT_SPIN
		player.buttonhistory = $|BT_SPIN
		player.battlespawning = 0
		player.pflags = ($|PF_USEDOWN|PF_SPINNING)
		mo.flags = $&~MF_NOCLIPTHING
	return false end
	
	return true 
end