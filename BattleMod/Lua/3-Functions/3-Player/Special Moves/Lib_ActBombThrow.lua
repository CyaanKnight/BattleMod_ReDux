local B = CBW_Battle

local state_bombthrow = 1
local state_bombjump = 10
local cooldown = TICRATE
local bombfuse = 8*TICRATE
local bjhorz = FRACUNIT*8 //bomb jump horizontal thrust
local bjvert = FRACUNIT*16 //bomb jump vertical thrust
//16
//12

B.throwbomb = function(mo)
	local player = mo.player
	local bomb = P_SPMAngle(mo,MT_FBOMB,mo.angle,0)
	local bombfuse
	if player.actiontype != "tageggrobo" then
		bombfuse = 5
	else
		bombfuse = 15
	end
	if bomb and bomb.valid then
		//Do skincolor
		bomb.state = S_COLORBOMB1
		bomb.color = player.skincolor
		
		//Do Physics
		local water = B.WaterFactor(mo)
		bomb.momz = bomb.scale*4*P_MobjFlip(mo)/water
		bomb.flags = $|MF_BOUNCE|MF_GRENADEBOUNCE
		bomb.fuse = bombfuse*TICRATE
		bomb.staticfuse = true
	end
	return bomb
end

B.Action.BombThrow=function(mo,doaction,throwring,tossflag)
	local player = mo.player
	if P_PlayerInPain(player) then
		player.actionstate = 0
	return end

	if not(B.CanDoAction(player)) then return end
	//Action info
	player.actiontext = "Throw Bomb"
	player.actionrings = 10

	player.actiontime = $+1
	
	//Weapon control
	if player.actionstate != 0 then
		player.weapondelay = max($, 2)
	end
	
	//Neutral
	if player.actionstate == 0 and not(player.weapondelay) then
		if not(player.actioncooldown) and doaction==1 then
			//Bomb Throw
			if not(player.pflags&PF_BOUNCING)
				player.actionstate = state_bombthrow
				player.actiontime = 0
			else //Bomb Drop
				local bomb = B.throwbomb(mo)
				if bomb and bomb.valid then
					P_InstaThrust(bomb,mo.angle,FRACUNIT/100)
				end
				B.ApplyCooldown(player,cooldown)
			end
			B.PayRings(player,player.actionrings)
		else return end
	end
	//Prep Bomb
	if player.actionstate == state_bombthrow then
		mo.state = S_PLAY_WALK
		mo.frame = 3
		player.drawangle = mo.angle
--		player.lockmove = true
		if player.actiontime < 3
			B.DrawSVSprite(player,3+player.actiontime/3)
--		else
--			player.actionstate = state_bombthrown
		end
-- 		player.drawangle = mo.angle-ANGLE_135
		if player.actiontime > 2 then
			mo.frame = 4
-- 			player.drawangle = mo.angle-ANGLE_90
		end
		if player.actiontime > 4 then
			mo.frame = 5
-- 			player.drawangle = mo.angle-ANGLE_45
		end
		if player.actiontime == 6 then
			player.actionstate = state_bombthrow+1
			player.actiontime = 0
			//Throw bomb
			B.throwbomb(mo)
			B.ApplyCooldown(player,cooldown)
		end
	end
	//Bomb thrown
	if player.actionstate == state_bombthrow+1 then
		mo.state = S_PLAY_WALK
		mo.frame = 6
		player.drawangle = mo.angle
		if player.actiontime > 12 then
			player.actionstate = 0
			player.actiontime = 0
		end
	return end
	//Bomb jump
	if player.actionstate == state_bombjump then
		if ((P_IsObjectOnGround(mo) or P_MobjFlip(mo)*mo.momz < 0) and player.actiontime > 1)
		or player.actiontime > TICRATE*4
		then
			player.actionstate = 0
			mo.state = S_PLAY_FALL
		return end
		player.actiontime = $+1
		mo.sprite2 = SPR2_EDGE
		mo.frame = (player.actiontime&7)/2
	return end
end



B.FBombThink=function(mo)
	if mo.radius < (24*FRACUNIT) then
		mo.radius = $+FRACUNIT
	end

	// add ghost objects here to prevent them from getting stuck in pending removal
	if mo.sprite == SPR_FBOM or mo.sprite == SPR_CBOM then
	local ghost = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_GHOST)
		ghost.color = mo.color
		ghost.fuse = TICRATE/4
		ghost.state = mo.state
		ghost.sprite = mo.sprite
		ghost.frame =  mo.frame
		ghost.frame = $|TR_TRANS50 
		ghost.tics = -1
	end
			
	//Bomb jump
	if mo.state == S_FBOMB_EXPL1 and mo.tics == 1 then
		if not(mo.target and mo.target.valid and mo.target.player and not mo.target.player.nobombjump) then return end
		local dist = FixedHypot(mo.z+mo.height/2-(mo.target.z+mo.target.height/2),R_PointToDist2(mo.x,mo.y,mo.target.x,mo.target.y))
		local radius = FRACUNIT*96
		if dist < radius then
			local angle = R_PointToAngle2(mo.x,mo.y,mo.target.x,mo.target.y)
			mo.target.player.actionstate = state_bombjump
			mo.target.player.actiontime = 0
			mo.target.player.pflags = $&~(PF_JUMPED|PF_THOKKED|PF_BOUNCING)
			mo.target.state = S_PLAY_FALL
			P_SetObjectMomZ(mo.target,bjvert,1)
			P_Thrust(mo.target,angle,bjhorz)
		end
	end
	
	//Bomb physics
	if not(mo.flags&MF_MISSILE) then 
		mo.shadowscale = 0
	return end
	mo.shadowscale = FRACUNIT/2
	if mo.flags&(MF_MISSILE|MF_GRENADEBOUNCE) and P_IsObjectOnGround(mo) then
		P_SetObjectMomZ(mo,FRACUNIT*4)
	end
	//Set collision properties
	local vthreshold = mo.scale*12
	local hthreshold = mo.scale*8
	if mo.bombtype == 1 then
		if abs(mo.momz) > vthreshold then
			mo.flags = $&~MF_GRENADEBOUNCE
		else
			mo.flags = $|MF_GRENADEBOUNCE
		end
		if FixedHypot(mo.momx,mo.momz) > hthreshold then
			mo.flags = $&~MF_BOUNCE
		else
			mo.flags = $|MF_BOUNCE
		end
	end

	if mo.fuse <= TICRATE then
		if mo.fuse == TICRATE then
			S_StartSoundAtVolume(mo, sfx_fgfb, 80)
		end
		if (leveltime/2)%2 then
			local ghost = P_SpawnGhostMobj(mo)
			if ghost and ghost.valid then
				ghost.fuse = TICRATE/2
				ghost.destscale = mo.scale*2
				ghost.colorized = true
				ghost.dispoffset = mo.dispoffset+1
				ghost.blendmode = AST_ADD
			end
		end
	end

end

B.FBombDetonate=function(mo)
	mo.momx = 0
	mo.momy = 0
	mo.momz = 0
	S_StartSound(mo,sfx_s3k4e)
	P_KillMobj(mo)
	return true
end

B.FBombSpawn = function(mo)
	mo.fuse = bombfuse
	mo.bombtype = 1
end

B.PlayerBombDamage = function(pmo,mo,source)
	if mo and mo.valid and mo.type == MT_FBOMB and mo.fuse and pmo and pmo.valid and pmo.player and source and source.valid and source.player
		and B.PlayerCanBeDamaged(pmo.player) and not(B.MyTeam(pmo.player,source.player))
		then mo.fuse = 1
	end
end

local S = B.SkinVars

local function fanghop(player)
	local mo = player.mo
	B.ZLaunch(mo, 8 * mo.scale, false)
	B.ApplyCooldown(player, cooldown)
	mo.state = S_PLAY_FALL
	--mo.momx = $ * -1/6
	--mo.momy = $ * -1/6
	player.actionstate = 0
	player.actiontime = 0
	player.pflags = ($ | (PF_JUMPED | PF_STARTJUMP | PF_NOJUMPDAMAGE)) & ~PF_THOKKED
	player.powers[pw_nocontrol] = 10
end

B.BombCollide = function(bomb,mo)
	if mo and mo.valid and bomb and bomb.valid and bomb.fuse > 1 
	and B.ZCollide(bomb,mo)
		then
		if mo.player and (B.MyTeam(mo.player, bomb.target.player) or mo.player == bomb.target.player) then
			local skin = S[mo.skin] or S[-1]
			local sliding = skin.special == B.Action.Slide and mo.player.actionstate == 2
			local dodgerolling = skin.special == B.Action.Slide and mo.player.actionstate == 3

			if sliding or dodgerolling then
				local angle = R_PointToAngle2(mo.x, mo.y, bomb.x, bomb.y)
				local mospeed = FixedHypot(mo.momx, mo.momy)
				
				local bomb_minspeed = (mo.scale * 26)
				local player_bump = (mo.scale * 7)
				

				P_InstaThrust(mo, angle+ANGLE_180, player_bump)
				P_InstaThrust(bomb, angle, (sliding and max(bomb_minspeed, mospeed)) or min(bomb_minspeed, mospeed))
				S_StartSound(mo, sfx_s3k5d)
				if dodgerolling then
					fanghop(mo.player)
				end
			end
		end
		if bomb.target == mo then return end
		if not(mo.flags&(MF_MISSILE|MF_ENEMY|MF_BOSS|MF_MONITOR)) then return end
		bomb.fuse = 1
		if mo.flags&MF_MONITOR 
		and not(G_GametypeHasTeams() and bomb.target and bomb.target.player
			and (
				(mo.type == MT_RING_REDBOX and bomb.target.player.ctfteam == 2)
				or (mo.type == MT_RING_BLUEBOX and bomb.target.player.ctfteam == 1)
			)
		)

		

		
		P_KillMobj(mo,bomb,bomb.target) end
	end
end
