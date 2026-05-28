local B = CBW_Battle
local cooldown = TICRATE * 3
local cooldown_bigjump = TICRATE * 4
local cancelcooldown = TICRATE
local state_digging = 1
local state_drilldive = 2
local state_burrowed = 3
local state_rising = 4
local setburrowtime = TICRATE/2 //Time in tics before the player can move after burrowing
local rockblasttime_x = 25 //Time in tics before horizontal rockblast disappears
local rockblasttime_y = 32 //Time in tics before vertical rockblast disappears
local zthreshold = 8 //Z Distance from ground (in fracunits) that will cause Knuckles to resurface


local kb_stunbreakcost = 30

B.Action.Dig_Priority = function(player)
	if player.actionstate == state_drilldive then
		B.SetPriority(player,1,1,"fang_springdrop",2,1,"drill dive")
	end
	if player.actionstate == state_rising then
		B.SetPriority(player,0,2,"tails_fly",0,2,"Knuckle Buster")
	end
end

local rock_properties = function(rock,rockblasttime)
	rock.fuse = rockblasttime
	if G_GametypeHasTeams() and rock.target and rock.target.valid and rock.target.player then
		rock.color = rock.target.player.skincolor
		rock.colorflash = true
	end
end

local shootrock_grounded = function(mo,ang1,ang2,scale,rockblasttime)
	local rock = P_SPMAngle(mo,MT_ROCKBLAST,0,0)
	if rock and rock.valid then
		B.InstaThrustZAim(rock,ang1,ang2*P_MobjFlip(mo),scale)
		rock_properties(rock,rockblasttime)
	end
end

local shootrock_sidewall = function(mo,ang1,ang2,scale,rockblasttime)
	local rock = P_SPMAngle(mo,MT_ROCKBLAST,0,0)
	if rock and rock.valid then
		B.InstaThrustSpread(rock,mo.angle,ang1,ang2,scale)
		rock_properties(rock,rockblasttime)
	end
end


local rockblast = function(mo,grounded)
	if grounded then
		//Do horizontal debris burst
		//Anti-air Layer
		local m = 4
		for n = 0,m
			shootrock_grounded(mo,(360/m)*n*ANG1,85*ANG1,mo.scale*18,rockblasttime_y)
		end
		//Second Layer
		local m = 6
		for n = 0,m
			shootrock_grounded(mo,(360/m)*n*ANG1,80*ANG1,mo.scale*14,rockblasttime_y)
		end
		//Third Layer
		local m = 8
		for n = 0,m
			shootrock_grounded(mo,(360/m)*n*ANG1,75*ANG1,mo.scale*11,rockblasttime_y)
		end
		//Ground Layer
		local m = 24
		for n = 0,m
			shootrock_grounded(mo,(360/m)*n*ANG1,1*ANG10,mo.scale*12,rockblasttime_x)
		end
	else
		//Do vertical debris burst
		for n = 0,7
			shootrock_sidewall(mo,30,45*n,mo.scale*20,rockblasttime_y)
		end
		//Second Layer
		for n = 0,15
			shootrock_sidewall(mo,60,225*n/10,mo.scale*15,rockblasttime_y)
		end
	end
end

B.Action.Dig=function(mo,doaction)
	local player = mo.player
	local skin = skins[player.skin]
	local gray = "\x86"
	
	if not (player.gotflag or player.gotcrystal) and player.actionstate == 0 and player.slipping == false then //For digging state
		player.normalspeed = skin.normalspeed
		player.acceleration = skin.acceleration
		player.thrustfactor = skin.thrustfactor
	end	

	if P_PlayerInPain(player)
	or player.playerstate != PST_LIVE
	or (player.actionstate == state_drilldive and player.powers[pw_nocontrol])
	or player.climbing
		if P_PlayerInPain(player) and player.actionstate
			B.ResetPlayerProperties(player,false,false)
		end
	return end
	if not(B.CanDoAction(player))
		if B.GetSVSprite(player)
			B.ResetPlayerProperties(player,false,false)
		return end
	end

	local dojump = B.PlayerButtonPressed(player,BT_JUMP,false)
	local dospin = B.PlayerButtonPressed(player,BT_SPIN,false)
	local climbing = player.climbing
	local sludge = mo.eflags&MFE_GOOWATER
	local grounded = P_IsObjectOnGround(mo)
	local diggingstates = (player.actionstate == state_digging or player.actionstate == state_burrowed)
	local getcanceltics = player.actiontime
	
	//****/
	//Action properties &HUD
	
	player.actiontextflags = 0

	//Normal state; ready to dig
	if player.actionstate == 0 and not (player.climbing) then
		player.actiontext = "Dig"
		player.actionrings = 10
	//2 = downward air drill; disallow actions.
	elseif not(diggingstates)
		player.actiontext = nil
	//1 = digging, disallow actions. 3 = Burrowed; ready to resurface.
	else
		if player.actionstate == 1 then
			player.actiontextflags = 1

		end
		player.actiontext = "Knuckle Buster"
		player.actionrings = 0 
		if player.actionrings > player.rings then
			player.actiontextflags = 3
		end
		player.action2text = "Resurface "..player.exhaustmeter*100/FRACUNIT.."%"
	end
	
	//Check rings
	if (diggingstates and dojump) then
		doaction = 1
	end
	
	//Action triggers
	local trigger_dig =
		(doaction == 1 and not(sludge) and player.actionstate == 0 and (grounded))
		or (grounded and player.actionstate == state_drilldive and not(sludge))
	local trigger_drilldive = (not(grounded and not sludge) and doaction == 1 and player.actionstate == 0)
	local trigger_drilldive_cancel = (player.actionstate == state_drilldive and mo.momz*P_MobjFlip(mo) > 0)
	local trigger_eject =
		(player.exhaustmeter == 0)
		or (grounded and sludge)
		or (player.actionstate == state_burrowed and dospin)
		or not(B.NearGround(mo, zthreshold) or climbing)	
	
	
	//Execute dig
	if trigger_dig
		if player.actionstate == 0 and not climbing then
			B.PayRings(player)
		end
		player.actionstate = state_digging
		player.actiontime = 0
		player.exhaustmeter = min(FRACUNIT,$+FRACUNIT/4)
		mo.flags = $|MF_NOCLIPTHING
		mo.flags2 = $|MF2_DONTDRAW
		player.pflags = ($|PF_JUMPSTASIS) & ~PF_SPINNING
		player.normalspeed = skins[mo.skin].normalspeed*3/5
		S_StartSound(mo,sfx_s3kccs)
		player.canguard = 0
		return
	end
	
	//Execute downward air drill
	if trigger_drilldive
		B.PayRings(player)
		player.actionstate = state_drilldive
		player.battlehitbox = false
		mo.state = S_PLAY_ROLL
		local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
		local speed = FixedHypot(mo.momx,mo.momy)
		B.InstaThrustZAim(mo,dir,ANGLE_11hh,min(speed,mo.scale*60))
		mo.momz = min(-12*mo.scale,$*P_MobjFlip(mo))*P_MobjFlip(mo)
		player.pflags = $|(PF_JUMPED|PF_THOKKED)&~(PF_GLIDING)
		S_StartSound(mo,sfx_zoom)
		return
	end
	
	//Drill dive
	if player.actionstate == state_drilldive then
		player.actiontime = $+1
		B.DrawSVSprite(player,1+player.actiontime%4)
		P_SpawnGhostMobj(mo)

		local hitbox = B.BattleHitboxSpawn(player, 1*player.mo.scale, -24*player.mo.scale, 2, player.mo.state, false, 0)

		if B.ButtonCheck(player, BT_JUMP) == 1 and player.exhaustmeter
			B.ResetPlayerProperties(player,true,false)
			B.ApplyCooldown(player,cancelcooldown)
			
			mo.momz = $ / 3
			
			local glidespeed = FixedMul(player.actionspd, player.mo.scale)
			local playerspeed = player.speed

			if (player.mo.eflags & MFE_UNDERWATER)
				glidespeed = $ >> 1
				playerspeed = 2*playerspeed/3
				if (!(player.powers[pw_super] or player.powers[pw_sneakers]))
					player.mo.momx = (2*(player.mo.momx - player.cmomx)/3) + player.cmomx
					player.mo.momy = (2*(player.mo.momy - player.cmomy)/3) + player.cmomy
				end
			end
			
			player.pflags = $ | PF_GLIDING|PF_THOKKED
			player.glidetime = 0

			player.mo.state  = S_PLAY_GLIDE
			if (playerspeed < glidespeed)
				P_Thrust(player.mo, player.mo.angle, glidespeed - playerspeed)
			end
			player.pflags = $ & ~(PF_SPINNING|PF_STARTDASH)
		end
	end
	//Cancel drill dive
	if trigger_drilldive_cancel then
		mo.state = S_PLAY_FALL
		B.ResetPlayerProperties(player,false,false)
		B.ApplyCooldown(player,cancelcooldown)
	end
	
	//Drill rise
	if player.actionstate == state_rising
		player.actiontime = $+1
		B.DrawSVSprite(player,(player.actiontime/2)%4+5)
		player.pflags = $|PF_THOKKED
		//End rising state
		if P_MobjFlip(mo)*mo.momz <= 0 or P_IsObjectOnGround(mo)
			B.ResetPlayerProperties(player,false,false)
			player.exhaustmeter = FRACUNIT / 3 + 1
		end
	end
	
	if player.kgrab and player.kgrab.valid and not player.actionstate then
		player.kgrab.flags = $&~MF_NOCLIPTHING
		player.mo.flags = $&~MF_NOCLIPTHING
		player.kgrab = nil
	end
	
	if player.actionstate == 20 and player.kgrab and player.kgrab.valid --Studied Austin's grab script to get this where I wanted it to be. Thanks! -JoJo
		player.actiontime = $+1
		B.DrawSVSprite(player,(player.actiontime/2)%4+5)
		P_SetObjectMomZ(mo,(-mo.scale*2/B.WaterFactor(mo)),true)
		local x = mo.x
		local y = mo.y
		local oldz = player.kgrab.z
--		local oldx = player.kgrab.x
--		local oldy = player.kgrab.y
		player.kgrab.z = mo.height+mo.z+mo.scale*12*P_MobjFlip(mo)
		if player.kgrab.valid
			if P_CheckPosition(player.kgrab,x,y)
				P_MoveOrigin(player.kgrab,x,y,player.kgrab.z+(mo.height/2))
			else 
				player.kgrab.z = oldz
			end
		end
		
		player.drawangle = player.mo.angle
		player.kgrab.momx = mo.momx
		player.kgrab.momy = mo.momy
		player.kgrab.momz = mo.momz
		
		if player.kgrab.valid and player.kgrab.player then
			player.kgrab.tracer = mo

			player.kgrab.player.canstunbreak = 1
			player.kgrab.player.customstunbreakcost = kb_stunbreakcost
			player.kgrab.player.customstunbreaktics = 0

			player.kgrab.player.actioncooldown = 2
			if player.kgrab.state ~= S_PLAY_PAIN then
				player.kgrab.state = S_PLAY_PAIN
			end
        end
		
		if P_IsObjectOnGround(mo) or player.actiontime > TICRATE*2 or sludge
			P_DamageMobj(player.kgrab,mo,mo)
			S_StartSoundAtVolume(mo,sfx_s3k49, 200)
			S_StartSound(player.kgrab,sfx_s3k5f)
			S_StartSound(mo,sfx_s3k59)
			player.actionstate = 0
			player.actiontime = 0
			mo.momx = $*3/2
			mo.momy = $*3/2
			mo.state = S_PLAY_GLIDE_LANDING
			player.kgrab.flags = $&~MF_NOCLIPTHING
			player.mo.flags = $&~MF_NOCLIPTHING
			player.kgrab = nil
			rockblast(mo,true) -- Use sparkles instead?
			P_StartQuake(FRACUNIT*5,TICRATE/3)
		end
	end
	
	//Gate: Digging states only
	if not(diggingstates)
		then return 
	end
	
	//Eject player from burrow state
	if trigger_eject then
		P_SetObjectMomZ(mo,FixedMul(FRACUNIT*6,player.jumpfactor),false)
		B.ResetPlayerProperties(player,false,false)
		mo.state = S_PLAY_FALL
		S_StartSound(mo,sfx_s3k82)
		for n = 0, 10
			B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(5,10))
		end
		//Apply cooldown
		player.airdodge = -1
		player.canguard = false
		B.ApplyCooldown(player,cancelcooldown)
		player.powers[pw_nocontrol] = 2
		player.actiontime = 0
		mo.momx = $ / 3
		mo.momy = $ / 3
		return
	end
	
	//Burrowed properties
	mo.flags = $|MF_NOCLIPTHING //Intangibility
	mo.flags2 = $|MF2_DONTDRAW //Invisibility
	player.charability2 = 0 //Disallow spindashing
	player.canguard = false //Disallow guarding
	if player.slipping == false
		player.normalspeed = skin.normalspeed*9/8
		player.acceleration = skin.acceleration*9/8
	end
	
	//Clip to ground
	if not(climbing) then
		if P_MobjFlip(mo) == 1 then
			mo.z = mo.floorz
		else
			mo.z = mo.ceilingz-mo.height
		end
	end
	
	//Timers
	player.actiontime = $+1
	if player.exhaustmeter and P_IsObjectOnGround(mo)
		player.exhaustmeter = max(0,$-FRACUNIT/TICRATE/3)
	end
	
	//Smoke
	if (player.exhaustmeter > FRACUNIT/3 and player.actiontime%TICRATE == 0)
	or (player.exhaustmeter <= FRACUNIT/3 and player.actiontime%(TICRATE/3) == 0)
		local smoke = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SMOKE)
		if G_GametypeHasTeams()
			smoke.colorized = true
			smoke.color = player.skincolor
		end
	end
	
	//Digging state
	if player.actionstate == state_digging
		player.pflags = $|PF_JUMPSTASIS//|PF_STASIS
		if player.actiontime >= setburrowtime
			player.actionstate = state_burrowed
		end
		B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(5,20))
		return
	end
	player.pflags = ($|PF_JUMPSTASIS)//&~PF_STASIS

	//Moving while burrowed
	if abs(player.cmd.forwardmove) or abs(player.cmd.sidemove) then
		if not(player.actiontime&3) then
			//Do Debris
			B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(3,5))
			S_StartSound(mo,sfx_s3k67)
		end
	end
	
	grounded = P_IsObjectOnGround(player.mo)
	//Rock blast attack
	if (doaction == 1)
		then
		player.exhaustmeter = 0
		B.PayRings(player)
		player.pflags = $&~PF_JUMPSTASIS
		P_DoJump(player,false)
		B.ZLaunch(mo, FRACUNIT*5/2, true)
		B.ResetPlayerProperties(player,true,true)
		if grounded
			player.actionstate = state_rising
			B.DrawSVSprite(player,5)
			local hitbox = B.BattleHitboxSpawn(player, 1*player.mo.scale, 12*player.mo.scale, 2, S_UNKNOWN, false, 0)
			hitbox.radius = 36*player.mo.scale
		end
		if player.cmd.buttons&BT_JUMP then
			mo.momx = $ / 3
			mo.momy = $ / 3
			player.pflags = $|PF_STARTJUMP|PF_JUMPDOWN
			B.ZLaunch(mo, FRACUNIT*9/2, true)
			B.ApplyCooldown(player,cooldown_bigjump)
			S_StartSound(mo, sfx_s3ka0)
		else
			B.ApplyCooldown(player,cooldown)
		end
		S_StartSound(mo,sfx_s3k59)
		for n = 0, 7
			B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(3,20))
		end
		--rockblast(mo,grounded)
	end
end

B.DoDebris=function(mo,large,speed)
	local scale
	if large then scale = mo.scale/2
		else scale = mo.scale/3
	end
	local debris = P_SpawnMobj(mo.x,mo.y,mo.z,MT_ROCKCRUMBLE2)
	if debris and debris.valid then
		if G_GametypeHasTeams() and mo.player
			debris.colorized = true
			debris.color = mo.player.skincolor
		end
		debris.scale = scale
		debris.flags2 = $|(mo.flags2&MF2_OBJECTFLIP)
		debris.z = $+FRACUNIT
		if P_IsObjectOnGround(mo) then
			P_InstaThrust(debris,P_RandomRange(0,259)*ANG1,speed*scale)
			debris.momz = speed*scale*P_MobjFlip(mo)
		else
			B.InstaThrustZAim(debris,mo.angle+ANGLE_180+P_RandomRange(-89,89)*ANG1,P_RandomRange(-89,89)*ANG1,speed*scale)
		end
	end
	return debris
end

B.RockBlastObject = function(mo)
	if mo.colorflash == true then
		mo.colorized = (mo.fuse%8 == 0)
	end
end

B.Knuckles_PreCollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1] and plr[n1].actionstate == state_rising then
		plr[n1].rising = true
	else
		plr[n1].rising = false
		return false
	end
end

B.Knuckles_Collide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1].rising == true
		if not ((hurt == 1 and n1 == 1) or (hurt == -1 and n1 == 2))
		and not ((hurt == 1 and n2 == 1) or (hurt == -1 and n2 == 2))
			if (plr[n2] and B.GetZCollideAngle(mo[n1],mo[n2]) <= -ANG30)  or (P_IsObjectOnGround(mo[n2]) or 
							((mo[n2].floorrover and mo[n2].z-mo[n1].floorz < 35*FRACUNIT) or (mo[n2].z-mo[n2].floorz < 35*FRACUNIT)))
							and (mo[n2].battleobject or plr[n1].battle_def > plr[n2].battle_def)
				plr[n1].kgrab = mo[n2]
				if mo[n2].battleobject then
					if #mo[n2].info == MT_SPARRINGDUMMY then
						-- Stop tails doll from attacking you, so they aren't bullshitting ya.
						mo[n2].attacking = 0
						mo[n2].ammo = 0
						mo[n2].cooldown = 3*TICRATE
					end
				else
					B.ResetPlayerProperties(plr[n1].kgrab.player,false,false)
				end
				plr[n1].actionstate = 20
				P_SetObjectMomZ(mo[n1],-mo[n1].scale*40/B.WaterFactor(mo[n1]),true)
				mo[n2].flags = $|MF_NOCLIPTHING
				--mo[n1].flags = $|MF_NOCLIPTHING
				plr[n1].pflags = $|PF_THOKKED
				return false
			end
		end
	elseif plr[n1] and mo[n1].health and not(pain[n1])
		and (plr[n1].pflags&PF_GLIDING or plr[n1].climbing 
			or (plr[n1].charability == CA_GLIDEANDCLIMB) and collisiontype > 1 and P_IsObjectOnGround(mo[n1]) and not(plr[n1].pflags&PF_SPINNING)
		) then
		plr[n1].pflags = $&~(PF_GLIDING|PF_JUMPED)
		if not(P_IsObjectOnGround(mo[n1])) and not(plr[n1].climbing) then
			plr[n1].panim = PA_FALL
			mo[n1].state = S_PLAY_FALL
			plr[n1].climbing = 0
			plr[n1].lastsidehit = -1
			plr[n1].lastlinehit = -1
			
			P_Thrust(mo[n1],mo[n1].angle + ANGLE_180, 6*FRACUNIT)
			P_SetObjectMomZ(mo[n1], 2*FRACUNIT/B.WaterFactor(mo[n1]), true)
		elseif (atk[n2])
			mo[n1].state = S_PLAY_GLIDE_LANDING
		end
	end
	return false
end


B.Knuckles_PostCollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1].rising == true
		plr[n1].rising = false
		return false
	end
	if plr[n1].kdive 
		B.ResetPlayerProperties(plr[n1],true,false)
		mo[n1].state = S_PLAY_FALL
		plr[n1].kdive = false
		plr[n1].kdunked = true
		B.ZLaunch(mo[n1], FRACUNIT*6, true)
	end
end

addHook("MobjDeath",function(monitor,knuckles)
	if monitor.valid and monitor.flags & MF_MONITOR
		if knuckles and knuckles.valid
			if not knuckles.player return end
			if knuckles.player.kdive
				B.ResetPlayerProperties(knuckles.player,true,false)
				knuckles.state = S_PLAY_FALL
				knuckles.player.kdive = false
				knuckles.player.kdunked = true
			end
		end
	end
end)
