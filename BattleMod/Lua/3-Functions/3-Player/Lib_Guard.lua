local B = CBW_Battle
local G = B.GuardFunc
local CV = B.Console

local nearground = function(mo,flip)
	if flip == 1
		return (mo.z-mo.floorz < mo.scale*8)
	else
		return (mo.ceilingz+mo.height-mo.z < mo.scale*8)
	end
end

B.GuardControl = function(player)
	if CV.Guard.value == 0 
	or G_TagGametype()
	or player.iseggrobo
	or player.isjettysyn
		player.canguard = false
	return end

	if B.GetSkinVarsFlags(player,SKINVARS_GUARD) then
		player.canguard = true
	else
		player.canguard = false
	end
end

B.Guard = function(player,buttonpressed)
	local mo = player.mo
	local flip = P_MobjFlip(mo)
	if mo and mo.valid and mo.guardflash then
		mo.colorized = false
		mo.color = player.skincolor
		mo.guardflash = false
	end
	if not(player.playerstate == PST_LIVE) or (player.spectator) then return end
	if P_PlayerInPain(player)
	or not(P_IsObjectOnGround(mo) or (player.guard and nearground(mo,flip)))
	or not(player.canguard)
	or player.tumble
	or player.actionstate
		if player.guard != 0 then
			if not(P_PlayerInPain(player)) and not(player.pflags&(PF_JUMPED|PF_SPINNING)) then
				mo.state = S_PLAY_FALL
				mo.coyoteTime = 0
			end
			player.guard = 0
		end
		return
	end
	//Neutral
	if (player.guard == 0) then
		if buttonpressed == 1 then
			player.pflags = $ &~ PF_JUMPED
			player.skidtime = 0
			if player.powers[pw_flashing] then
				player.powers[pw_flashing] = 0
				player.guardbuffer = 2
			end
			player.dashmode = 0 --You can't bump people with dashmode parry
			player.guard = 1
			S_StartSound(mo,sfx_cdfm39)
			player.guardtics = TICRATE*4/7 //20
			if not(player.actionsuper) then
				player.actionstate = 0
			end
			local i = P_SpawnMobj(mo.x,mo.y,mo.z,MT_INSTASHIELD)
			if i and i.valid
				i.target = mo
			end
		end
	end
	player.guardtics = $-1
	if player.guardbuffer and player.guardbuffer>0 then
		player.guardbuffer = $-1
	end
	if player.guard != 0 and (player.followmobj) then
		P_SetMobjStateNF(player.followmobj,S_NULL)
	end
	local guardframe
	if B.SkinVars[player.skinvars].guard_frame != nil then
		guardframe = B.SkinVars[player.skinvars].guard_frame
	else
		guardframe = B.SkinVars[-1].guard_frame
	end
	
	if player.guard != 0 then
		if flip == 1 then
			mo.z = mo.floorz
		else
			mo.z = mo.ceilingz-mo.height
		end
	end
	
	if player.guard == 1 then
		mo.state = S_PLAY_STND
		mo.sprite2 = SPR2_TRNS
		mo.frame = guardframe
		player.powers[pw_nocontrol] = 2
		if player.guardtics < 1 then
			player.guardtics = 20
			player.guard = -1
		else
			mo.guardflash = player.guardtics&2
			if mo.guardflash then
				mo.colorized = true
				mo.color = SKINCOLOR_WHITE
			end
		end
	end
	if player.guard <= -1
		mo.state = S_PLAY_STND
		mo.sprite2 = SPR2_TRNS
		mo.frame = guardframe
		player.powers[pw_nocontrol] = 2		
		if player.guardtics < 1 then
			player.guard = 0
			mo.sprite2 = SPR2_STND
			mo.frame = 0
		end
	end
	if player.guard == 2 then
-- 		mo.state = S_PLAY_STND
		player.powers[pw_nocontrol] = 0
		mo.sprite2 = SPR2_TRNS
		mo.frame = min(6,$+1)
		player.powers[pw_flashing] = TICRATE*3/4
		mo.flags2 = $&~MF2_DONTDRAW
		player.lockmove = true
-- 		if player.cmd.forwardmove or player.cmd.sidemove then
-- 			mo.sprite2 = SPR2_STAND
-- 			mo.frame = 0
-- 		end
		if player.guardtics < 1 
			player.guard = 0
			mo.frame = 0
			mo.state = S_PLAY_STND
			mo.sprite2 = SPR2_STND
		end
	end
end

local fx = function(mo)
	for n = 0, 16
		local dust = P_SpawnMobj(mo.x,mo.y,mo.z,MT_DUST)
		if dust and dust.valid then
			P_InstaThrust(dust,mo.angle+ANGLE_22h*n,mo.scale*36)
		end
	end
end


//Successful guard action
B.GuardTrigger = function(target, inflictor, source, damage, damagetype)
	if not(target.valid and target.player) then return false end
	if target.player.guardbuffer then
		B.ResetPlayerProperties(target.player,false,true)
		target.player.guard = 0
		S_StopSoundByID(target, sfx_cdfm39)
		S_StartSound(target, sfx_shattr)
		local nega = P_SpawnMobjFromMobj(target,0,0,0,MT_NEGASHIELD)
		nega.target = target
	end
	if target.player.guard > 0
		if B.SkinVars[target.player.skinvars].func_guard_trigger then
			B.SkinVars[target.player.skinvars].func_guard_trigger(target,inflictor,source,damage,damagetype)
		elseif B.SkinVars[-1].func_guard_trigger then
			B.SkinVars[-1].func_guard_trigger(target,inflictor,source,damage,damagetype)
		end
	return true end
end

//Standard parry trigger action
G.Parry = function(target, inflictor, source, damage, damagetype)
	if target.player.guard == 1 and inflictor and inflictor.valid 
		S_StartSound(target,sfx_cdpcm9)
		S_StartSound(target,sfx_s259)
		target.player.guard = 2
		target.player.guardtics = TICRATE/4 //9
		B.ControlThrust(target,FRACUNIT/2)
		//Do graphical effects
		local sh = P_SpawnMobjFromMobj(target,0,0,0,MT_BATTLESHIELD)
		sh.target = target
		fx(target)
		P_SpawnMobjFromMobj(inflictor,0,0,0,MT_EXPLODE)
		//Affect source
		if source and source.valid and source.health and source.player and source.player.powers[pw_flashing]
			source.player.powers[pw_flashing] = 0
			local nega = P_SpawnMobjFromMobj(source,0,0,0,MT_NEGASHIELD)
			nega.target = source
		end
		// Affect projectile's source if within range
		if source and source.valid then
		local parrytumblerange = P_GetPlayerHeight(target.player)*3
		local parrydistance = R_PointToDist2(target.x, target.y, source.x, source.y)
			if parrydistance <= parrytumblerange and source.z <= target.z+parrytumblerange and source.z >= target.z-parrytumblerange then
				inflictor = source // set inflictor to the source for the rest of the parry to effect them
			end
		end
		//Affect attacker
		if inflictor.player
			if inflictor.player.powers[pw_invulnerability]
				inflictor.player.powers[pw_invulnerability] = 0
				P_RestoreMusic(inflictor.player)
			end
			local angle = R_PointToAngle2(target.x-target.momx,target.y-target.momy,inflictor.x-inflictor.momx,inflictor.y-inflictor.momy)
			local thrust = FRACUNIT*10
			if twodlevel then thrust = B.TwoDFactor($) end
			P_SetObjectMomZ(inflictor,thrust)
			B.DoPlayerTumble(inflictor.player, 45, angle, inflictor.scale*3, true, true)	-- prevent stun break
		else
			P_DamageMobj(inflictor,target,target)
		end
	end
end


//flip instashield stuff if the player is flipped

B.InstaFlip = function(inst)
	if inst.target
		inst.eflags = ((inst.target.eflags & MFE_VERTICALFLIP) and ($1|MFE_VERTICALFLIP) or ($1 & ~MFE_VERTICALFLIP))
	end
end

B.BattleShieldThinker = function(mobj)
	if not mobj.target return end
	mobj.scale = FixedMul(skins[mobj.target.skin].shieldscale, mobj.target.scale*3/2)*2
	P_MoveOrigin(mobj, mobj.target.x, mobj.target.y, mobj.target.z+(mobj.target.height/2))
	
	mobj.colorized = true
	mobj.color = SKINCOLOR_WHITE
	
	//After-effects
	local ghost = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_GHOST)
	if ghost and ghost.valid then
		ghost.scale = mobj.scale
		ghost.sprite = mobj.sprite
		ghost.fuse = TICRATE/4
		ghost.frame = mobj.frame
		ghost.frame = $|FF_FULLBRIGHT|TR_TRANS50
		//Rainbow flash
		ghost.colorized = true
		ghost.color = B.Choose(SKINCOLOR_WHITE,SKINCOLOR_YELLOW,SKINCOLOR_ROSY,SKINCOLOR_GREEN,SKINCOLOR_ORANGE,SKINCOLOR_BLUE,SKINCOLOR_PURPLE)
	end
end

B.NegaShieldThinker = function(mobj)
	if not mobj.target return end
	mobj.scale = FixedMul(skins[mobj.target.skin].shieldscale, mobj.target.scale*3/2)*2
	P_MoveOrigin(mobj, mobj.target.x, mobj.target.y, mobj.target.z+(mobj.target.height/2))
	mobj.colorized = true
	mobj.color = SKINCOLOR_BLACK
	mobj.flags2 = $^^MF2_DONTDRAW
end
