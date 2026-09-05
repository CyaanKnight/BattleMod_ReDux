local B = CBW_Battle
local S = B.SkinVars
local cooldown = TICRATE + TICRATE/2
local cooldown2 = TICRATE * 3/2
local duration = 3 * TICRATE
local xythrust = 26
local zthrust = 9
local dropspeed = 20
local nojumpwindow = 8
local rollspeed = 38
local dodgeroll_time = 12
local dodgeroll_endlag = 10
local state_dodgeroll = 3
local state_fret = 4

B.Action.Slide = function(mo,doaction)
	local player = mo.player

	//Conditions
	local grounded = P_IsObjectOnGround(mo) or mo.eflags & MFE_JUSTHITFLOOR
	local water = B.WaterFactor(mo)
	local bouncing = player.pflags&PF_BOUNCING
	local activate = player.actiontime == 0 and doaction == 1
	local slide_trigger = activate and not(bouncing) and grounded
    local dodgeroll_trigger = activate and not(bouncing) and not(grounded)
	local springdrop_trigger = activate and bouncing
	local drop_state = player.actionstate == 1 and bouncing
		and P_MobjFlip(mo)*mo.momz < 0
	local sliding = player and (player.actionstate == 2 and player.actiontime)

	//Properties
	player.actiontext = "Slide"
	player.actionrings = 10
	if not grounded
		player.actiontext = "Dodge Roll"
	end
	if player.actionstate == 2
		player.actiontext = "Slide"
	end
	if player.actionstate == state_dodgeroll or player.actionstate == state_fret
		player.actiontext = "Dodge Roll"
	end
	if player.pflags&PF_BOUNCING
		player.actiontext = "Spring Drop"
	end
	
	//Perform Thrust
	if slide_trigger
		-- thrust player forward
		local speed = max(xythrust * mo.scale, FixedHypot(mo.momx - player.cmomx, mo.momy - player.cmomy) * 5 / 4)
		B.PayRings(player)
		local hitbox = B.BattleHitboxSpawn(player, 1*player.mo.scale, 12*player.mo.scale, 2, S_FANG_SLIDE, false, 0)
		hitbox.radius = 36*player.mo.scale

		P_InstaThrust(mo, mo.angle, speed)
		player.slidebouncex = mo.momx
		player.slidebouncey = mo.momy
		player.slidebouncez = abs(mo.momz)
		player.pflags = ($|PF_SPINNING) & ~(PF_THOKKED|PF_JUMPED|PF_BOUNCING)
		player.actionstate = 2
		player.actiontime = duration
		player.lockjumpframe = nojumpwindow
		mo.state = S_FANG_SLIDE
		S_StartSound(mo,sfx_zoom)
		for n = 0,3
			local dust = P_SpawnMobjFromMobj(mo,0,0,0,MT_SPINDUST)
			local angle = (180+P_RandomRange(-60,60))*ANG1+mo.angle
			local speed = mo.scale*P_RandomRange(5,10)
			P_InstaThrust(dust,angle,speed)
		end
	end
	
   //Perform dodge roll
	if dodgeroll_trigger
		B.PayRings(player)
		player.actionstate = state_dodgeroll
		player.actiontime = 0
		S_StartSound(mo,sfx_zoom)
		for n = 0,3
			local dust = P_SpawnMobjFromMobj(mo,0,0,0,MT_SPINDUST)
			local angle = (180+P_RandomRange(-60,60))*ANG1+mo.angle
			local speed = mo.scale*P_RandomRange(5,10)
			P_InstaThrust(dust,angle,speed)
		end
	end
	if player.actionstate == state_dodgeroll
	    if P_PlayerInPain(player) or (mo.eflags&MFE_SPRUNG) then
			player.actionstate = 0
			player.actiontime = 0
			B.ApplyCooldown(player, cooldown2)
			return
		end
		local angle = ((player.pflags & PF_ANALOGMODE) and player.thinkmoveangle) or mo.angle
		player.lockaim = true
		player.lockmove = true
		//Cancel dodgeroll and do slide on ground
		if P_IsObjectOnGround(mo) then
			player.actionstate = 2
			player.actiontime = duration
			player.lockjumpframe = nojumpwindow
			P_InstaThrust(mo,angle,rollspeed*mo.scale/water)
			player.drawangle = angle
			player.slidebouncex = mo.momx
			player.slidebouncey = mo.momy
			player.slidebouncez = abs(mo.momz)
			player.pflags = ($|PF_SPINNING)&~(PF_THOKKED|PF_JUMPED|PF_BOUNCING)
			mo.state = S_FANG_SLIDE
			S_StartSound(mo,sfx_zoom)
			return
		end
	    mo.state = S_PLAY_ROLL
		player.drawangle = angle
		P_InstaThrust(mo,angle,rollspeed*mo.scale/water)
		P_SetObjectMomZ(mo,0,false)
		P_SpawnGhostMobj(mo)
		if player.actiontime%3 == 1 and P_IsObjectOnGround(mo) then
			S_StartSound(mo, sfx_s3k7e, player)
			local r = mo.radius/FRACUNIT
			P_SpawnMobj(
				P_RandomRange(-r,r)*FRACUNIT + mo.x,
				P_RandomRange(-r,r)*FRACUNIT + mo.y,
				mo.z, MT_DUST
			)
		end
		player.actiontime = $+1
		if player.actiontime > dodgeroll_time
			//mo.momx = $/2
			//mo.momy = $/2
			//player.actionstate = state_fret
			if not(P_IsObjectOnGround(mo))
			    B.ApplyCooldown(player,cooldown)
				player.actionstate = 0
				player.actiontime = 0
			    mo.state = S_PLAY_FALL
				player.pflags = ($|PF_JUMPED)&~(PF_THOKKED|PF_SPINNING)
			else
			    //Just in case
				player.actionstate = 2
				player.actiontime = duration
				player.lockjumpframe = nojumpwindow
				player.slidebouncex = mo.momx
				player.slidebouncey = mo.momy
				player.slidebouncez = abs(mo.momz)
				player.pflags = ($|PF_SPINNING)&~(PF_THOKKED|PF_JUMPED|PF_BOUNCING)
				mo.state = S_FANG_SLIDE
				S_StartSound(mo,sfx_zoom)
			end
		end
	end
	if player.actionstate == state_fret
	    if P_PlayerInPain(player) or (mo.eflags&MFE_SPRUNG) then
			player.actionstate = 0
			player.actiontime = 0
			B.ApplyCooldown(player, cooldown)
			return
		end
		if player.actiontime < dodgeroll_endlag
			player.lockaim = true
			player.lockmove = true
			if P_IsObjectOnGround(mo)
				mo.state = S_PLAY_SKID
			else
				mo.state = S_PLAY_FALL
				mo.sprite2 = SPR2_EDGE
				mo.frame = (player.actiontime&7)/2
				player.pflags = ($|PF_JUMPED)&~PF_THOKKED
			end
			if P_IsObjectOnGround(mo) and player.speed > FRACUNIT*4 and player.actiontime%3 == 0
				P_SpawnMobjFromMobj(mo,0,0,0,MT_DUST)
			end
		else
			player.actionstate = 0
		end
		player.actiontime = $+1
	end
	
 	//Perform spring drop
	if springdrop_trigger
		//Apply cost, cooldown, state
		B.PayRings(player)
		player.actionstate = 1
		player.actiontime = 1
		mo.state = S_FANG_SPRINGDROP
		//Apply momentum
		//mo.momx = $/2
		//mo.momy = $/2
		B.ZLaunch(mo,-dropspeed*FRACUNIT,false)
		//Effects
		S_StartSound(mo,sfx_zoom)
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*128,16,MT_DUST,ANGLE_90,nil,true)
		return
	end
	if player.actionstate == 1
		player.actiontime = $+1
		P_SpawnGhostMobj(mo)
	end
	
	//Drop bombs
	if player.actionstate == 1
	and bouncing
	and ((mo.eflags & MFE_JUSTHITFLOOR) or P_IsObjectOnGround(mo))
		B.ApplyCooldown(player,cooldown)
		player.nobombjump = true
		if mo._fbomb and mo._fbomb.valid then
			mo._fbomb.fuse = min(1, $)
			if (mo._fbomb.fuse <= 0) then
				P_RemoveMobj(mo._fbomb)
			end
			mo._fbomb = nil
		end
		mo._fbomb = B.throwbomb(mo)
		if mo._fbomb and mo._fbomb.valid then
			mo._fbomb.momx = 0
			mo._fbomb.momy = 0
			P_SetObjectMomZ(mo._fbomb, mo.scale*10*P_MobjFlip(mo))
			mo._fbomb.flags = $|MF_BOUNCE|MF_GRENADEBOUNCE|MF_SHOOTABLE
			mo._fbomb.flags2 = $ & ~MF2_FRET
			mo._fbomb.scale = mo.scale*5/3
			mo._fbomb.bombtype = 0
			mo._fbomb.fuse = 9*TICRATE
		end
		player.actiontime = 0
		player.actionstate = 0
	elseif player.actionstate == 1
	and (not bouncing
	or mo.eflags & MFE_SPRUNG
	or mo.state == S_PLAY_BOUNCE_LANDING) then
	    B.ApplyCooldown(player,cooldown2)
		if P_IsObjectOnGround(mo)
			mo.state = S_PLAY_BOUNCE_LANDING
		else
			mo.state = S_PLAY_BOUNCE
		end
		player.actiontime = 0
		player.actionstate = 0
	end

	if sliding then
	    if P_PlayerInPain(player) or (mo.eflags&MFE_SPRUNG) or (player.pflags&PF_SLIDING) then
			player.pflags = $ & ~PF_SPINNING
			player.actionstate = 0
			player.actiontime = 0
			B.ApplyCooldown(player, cooldown2)
			return
		end
		player.actionsuper = false

		if grounded then
			player.actiontime = $-1
			if leveltime%8 then
				S_StartSound(mo,sfx_s3k7e,player)
				local r = mo.radius/mo.scale
				P_SpawnMobj(
					P_RandomRange(-r,r)*mo.scale+mo.x,
					P_RandomRange(-r,r)*mo.scale+mo.y,
					mo.z,
					MT_DUST
				)
			end
		else
			player.lockjumpframe = max(2, $)
		end

		if not(leveltime%3) then
			local ghost = P_SpawnGhostMobj(mo)
			if ghost and ghost.valid then
				ghost.colorized = true
				ghost.fuse = 10
			end
		end

		if player.pflags & PF_JUMPED then
			player.actionstate = 0
			player.actiontime = 0
			player.actionsuper = false
			B.ApplyCooldown(player, cooldown)
			return
		end

		player.pflags = ($|PF_SPINNING) & ~(PF_THOKKED|PF_JUMPED|PF_BOUNCING)

		if mo.eflags & MFE_JUSTHITFLOOR then
			mo.state = S_FANG_SLIDE
		end
		if mo.eflags & MFE_JUSTHITFLOOR then
			if player.slidebouncez >= 10 * mo.scale then
				P_SetObjectMomZ(mo, player.slidebouncez/2)
				S_StartSound(mo,sfx_mario1)
			end
			mo.momx = player.slidebouncex
			mo.momy = player.slidebouncey
		end

		-- custom friction
		local fric = FU - FU / 100
		mo.momx = FixedMul($, fric)
		mo.momy = FixedMul($, fric)

		player.slidebouncex = mo.momx
		player.slidebouncey = mo.momy
		player.slidebouncez = abs(mo.momz)

		if player.actiontime == 0
		or (B.PlayerButtonPressed(player, player.battleconfig_special, false) and not(player.lockjumpframe))
		or FixedHypot(mo.momx - player.cmomx, mo.momy - player.cmomy) < 4 * mo.scale
		or player.powers[pw_carry] then
	//	or not grounded then
			if P_IsObjectOnGround(mo) then
				mo.state = S_PLAY_STND
			else
				mo.state = S_PLAY_FALL
			end
			
			mo.momx = $/2
			mo.momy = $/2

            player.pflags = $ & ~PF_SPINNING
			player.actionstate = 0
			player.actionsuper = false
			B.ApplyCooldown(player, cooldown)
			return
		end
	end

	if not player.actionstate then
		-- for some reason this is being set to 9 upon spawn. why is it doing that
		player.actiontime = 0
		player.actionsuper = false
	end
end

local function fanghop(player)
	local mo = player.mo
	B.ZLaunch(mo, 8 * mo.scale, false)
	B.ApplyCooldown(player, cooldown)
	mo.state = S_PLAY_JUMP
	mo.momx = $ * -1/6
	mo.momy = $ * -1/6
	player.actionstate = 0
	player.actiontime = 0
	player.pflags = ($ | (PF_JUMPED | PF_STARTJUMP | PF_NOJUMPDAMAGE)) & ~PF_THOKKED
	player.powers[pw_nocontrol] = 10
end

local function isSlide(player)
	if not (player and player.valid and player.playerstate == PST_LIVE)
	or not player.mo
	or not player.mo.health
	or (player.actionstate ~= 2 and player.actionstate ~= state_dodgeroll) then
		return false
	end
	if player.actionstate == state_dodgeroll then
		if not (player.actiontime and (player.mo.state == S_PLAY_ROLL or player.mo.state == S_FANG_SLIDE)) then
			return false
		end
	end
	return true
end

B.Fang_PreCollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if isSlide(plr[n1]) then
		plr[n1].fangmarker = true
	end
end

B.Fang_PostCollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1] and plr[n1].fangmarker then
		plr[n1].fangmarker = nil
	end
end

B.Fang_Collide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	//Spring Drop
	if plr[n1] and plr[n1].actionstate == 1 and plr[n1].pflags&PF_BOUNCING and not P_IsObjectOnGround(mo[n1]) then
		plr[n1].pflags = $|PF_BOUNCING
		mo[n1].state = S_PLAY_BOUNCE
		plr[n1].actionstate = 0
		plr[n1].actiontime = 0
		plr[n1].nobombjump = true
		B.ApplyCooldown(plr[n1],cooldown)
		S_StartSound(mo[n1], sfx_boingf)
		if mo._fbomb and mo._fbomb.valid then
			mo._fbomb.fuse = min(1, $)
			if (mo._fbomb.fuse <= 0) then
				P_RemoveMobj(mo._fbomb)
			end
			mo._fbomb = nil
		end
		mo._fbomb = B.throwbomb(mo[n1])
		if mo._fbomb and mo._fbomb.valid then
			mo._fbomb.momx = 0
			mo._fbomb.momy = 0
			P_SetObjectMomZ(mo._fbomb, mo[n1].scale*8*P_MobjFlip(mo[n1]))
			mo._fbomb.flags = $|MF_SHOOTABLE & ~(MF_GRENADEBOUNCE)
			mo._fbomb.flags2 = $ & ~MF2_FRET
			mo._fbomb.scale = mo[n1].scale*5/3
			mo._fbomb.bombtype = 0
			mo._fbomb.fuse = 9*TICRATE
		end
	end

	if not (plr[n1] and plr[n1].fangmarker) then
		return false
	end

	if (hurt != 1 and n1 == 1) or (hurt != -1 and n1 == 2) then
	    if atk[n2] > 1 or def[n2] > 1 then
			plr[n1].actionstate = 0
			plr[n1].actiontime = 0
			B.ApplyCooldown(plr[n1], cooldown)
			return false
		end
		//Dodgeroll
		if plr[n1].actionstate == state_dodgeroll then
			if not (plr[n2] and plr[n2].fangmarker) then
				fanghop(plr[n1])
			end
			if plr[n2] then
				B.DoPlayerTumble(plr[n2], 28, angle[n1], mo[n1].scale*3, true, true)
			end
			P_InstaThrust(mo[n2], angle[n2], mo[n1].scale * 5)
			B.ZLaunch(mo[n2], 8 * mo[n2].scale, false)
			return true
		end

		//Slide
		if P_IsObjectOnGround(mo[n1]) then
			mo[n1].momx = $/3
			mo[n1].momy = $/3
		else
			P_InstaThrust(mo[n1], angle[n2], -15 * mo[n1].scale)
			P_SetObjectMomZ(mo[n1], 13 * mo[n1].scale)
			mo[n1].angle = angle[n2]
			plr[n1].drawangle = angle[n2]
			plr[n1].actionstate = 0
			plr[n1].actiontime = 0
			plr[n1].pflags = ($|PF_JUMPED|PF_STARTJUMP) & ~PF_SPINNING
			plr[n1].mo.state = S_PLAY_FALL
			plr[n1].lockjumpframe = 0
		end
		if plr[n2] then
			B.DoPlayerTumble(plr[n2], 28, angle[n1], mo[n1].scale*3, true, true)
		end
		P_InstaThrust(mo[n2], angle[n2], -mo[n1].scale * 5)
		B.ZLaunch(mo[n2], 8 * mo[n2].scale, false)
		return true
	end
end

B.Action.Slide_Priority = function(player)
	local mo = player.mo
	if not (mo and mo.valid) return end
	
	local bouncing = player.pflags&PF_BOUNCING
	local drop_state = player.actionstate == 1 and bouncing
		and P_MobjFlip(mo)*mo.momz < 0
	local sliding = player.actionstate == 2
		and player.actiontime
	
	if player.actionstate == 1 then
		B.SetPriority(player,0,1,"fang_springdrop",2,3,"spring drop")
	elseif player.actionstate == 2 then
		B.SetPriority(player,0,1,nil,0,1,"slide")
	elseif player.actionstate == state_dodgeroll then
		B.SetPriority(player,0,1,nil,0,1,"dodge roll")
	end
end

B.Fang_SlideJump = function(player)
	local mo = player.mo
	if not (mo and mo.valid) then return end

	local skin = S[mo.skin]

	if skin and skin.special and skin.special ~= B.Action.Slide then return end
	if player.actionstate ~= 2 then return end
	if not P_IsObjectOnGround(mo) then return end

	P_DoJump(player)
	player.mo.state = S_PLAY_ROLL
	player.pflags = $ & ~PF_NOJUMPDAMAGE
	P_Thrust(mo,mo.angle,5*mo.scale)
	return true
end
