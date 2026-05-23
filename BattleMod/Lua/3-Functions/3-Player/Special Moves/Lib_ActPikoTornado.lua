local B = CBW_Battle

local ground_special = 1
local air_special = 9
local piko_special = 11
local cooldown = TICRATE * 4/2
local swirl1 = S_LHRT
local swirl2 = S_LHRT
local min_tornado_speed = 6

local st_idle = 0
local st_hold = 1
local st_release = 2
local st_jump = 3

B.Action.PikoTornado_Priority = function(player)
	local pikowavereq = (player.actionstate == piko_special or (player.melee_state == st_hold and player.melee_charge >= FRACUNIT))

	if not(pikowavereq) and player.textflash_flashing then
		player.actiontext = B.TextFlash(player.actiontext, true, player)
	end

	if player.actionstate == ground_special then
		B.SetPriority(player,1,2,"tails_fly",1,0,"piko spin")
	end
	if player.actionstate == air_special then
		B.SetPriority(player,2,1,"tails_fly",1,0,"piko tornado twirl")
	end
end

local function sparkle(mo)
	local spark = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
	if spark and spark.valid then
		local z1 = (spark.flags2 & MF2_OBJECTFLIP) and spark.ceilingz or spark.floorz
		B.AngleTeleport(spark,{mo.x,mo.y,mo.z},mo.player.drawangle,0,mo.scale*64)
		spark.scale = mo.scale
		local z2 = (spark.flags2 & MF2_OBJECTFLIP) and spark.ceilingz or spark.floorz
		if abs(z1 - z2) > spark.height then
			spark.flags2 = $ | MF2_DONTDRAW
		end
	end
end

local function spinhammer(mo, stnd)
	local sprite = (stnd and SPR2_TWRL) or SPR2_ATWR
	local numframes = skins[mo.skin].sprites[sprite].numframes-1
	if not(stnd) then
		mo.amy_spinanimtimer = ($!=nil and (($+1 <= numframes) and $+1)) or 0
	else
		if mo.player.actiontime > 16 then
			mo.amy_spinanimtimer = ($!=nil and (($+1 <= numframes) and $+1)) or 0
		else
			mo.amy_spinanimtimer = ($!=nil and (mo.player.actiontime)%4 and (($+1 <= numframes) and $+1)) or ((($!=nil and ($+1 <= numframes)) and $) or 0)
		end
	end
	mo.state = stnd and S_PLAY_STND or S_PLAY_MELEE
	mo.sprite2 = sprite
	mo.frame = 0
	mo.frame = mo.amy_spinanimtimer
end

B.Action.PikoTornado = function(mo,doaction)
	local player = mo.player

	if P_PlayerInPain(player) or player.powers[pw_carry] then
		player.actionstate = 0
		player.actiontime = 0
		mo.amy_spinanimtimer = nil
	end
	if not(B.CanDoAction(player)) and not(player.actionstate) 
		if player.actiontime and mo.state == S_PLAY_MELEE_FINISH
			if mo.tics == -1
				mo.tics = 15
			else
				mo.tics = min($,15)
			end
			player.actiontime = 0
		end
		mo.amy_spinanimtimer = nil
	return end
	player.actiontime = $+1
	player.actionrings = 15
	//Action Info
	if player.actionstate == piko_special
	or (player.melee_state == st_hold and player.melee_charge >= FRACUNIT)
		--print(player.actiontime)
		player.actiontext = B.TextFlash("Piko Wave", (doaction == 1), player)
	elseif player.melee_state == st_release
		return
	elseif P_IsObjectOnGround(mo)
		player.actiontext = "Piko Tornado"
	else
		player.actiontext = "Tornado Jump"
		if mo.tornadocollide and mo.tornadocollide == leveltime
			local colors = {[0]="\x81", [1]="\x89", [2]="\x8E"} --magenta, purple, rosy
			player.actiontext = colors[leveltime % 3] .. $
		end
	end
	//Trigger
	if player.actionstate == 0 and (doaction == 1) then
		B.PayRings(player)
		player.actiontime = 0
		if player.melee_state == st_hold and player.melee_charge >= FRACUNIT then
			player.actionstate = piko_special
			player.cmd.buttons = $ &~ BT_SPIN
		elseif not(P_IsObjectOnGround(mo)) then
			player.actionstate = air_special
			player.pflags = $|PF_THOKKED
			P_SetObjectMomZ(mo,FixedMul(player.jumpfactor,FRACUNIT*10/B.WaterFactor(mo)),0)
			S_StartSound(mo,sfx_s3ka0)
		else //Ground
			local hitbox = B.BattleHitboxSpawn(player, 20*player.mo.scale, 1*player.mo.scale, TICRATE, S_UNKNOWN, true, 1)
			player.actionstate = ground_special
			mo.amy_spinanimtimer = 0
			B.ControlThrust(mo,mo.scale/4)
			S_StartSound(mo,sfx_s3ka0)
			player.melee_state = st_idle
		end
		player.melee_charge = 0
	end
	//Ground Special
	if player.actionstate == ground_special then
		B.analogkill(player, 2)
		player.pflags = $|PF_JUMPSTASIS
		spinhammer(mo, true)
		if player.actiontime < 16 then
			player.drawangle = mo.angle-ANGLE_22h*player.actiontime
			if player.actiontime == 8 then
				S_StartSound(mo,sfx_s3k42)
			end
		else
			player.drawangle = mo.angle-ANGLE_45*(player.actiontime&7)
			if player.actiontime&7 == 4 then
				S_StartSound(mo,sfx_s3k42)
			end
		end
		sparkle(mo)
		if not(player.actiontime > TICRATE) then return end
		mo.frame = 0
		mo.sprite2 = SPR2_MLEL
		player.actionstate = $+1
		player.actiontime = 0
		player.drawangle = mo.angle
		//Remove last missile, so it is replaced
		if (player.dustdevil and player.dustdevil.valid)
			P_RemoveMobj(player.dustdevil)
			player.dustdevil = nil
		end
		//Do Missile
		local missile = P_SPMAngle(mo,MT_DUSTDEVIL_BASE,mo.angle)
		if missile and missile.valid then
			missile.speed = max(min_tornado_speed*mo.scale,1+player.speed/2)
			missile.color = player.skincolor
			if not(player.mo.flags2&MF2_TWOD or twodlevel) then
				missile.fuse = TICRATE*4
			else
				missile.fuse = TICRATE*5/4
			end
			S_StartSound(missile,sfx_s3kb8)
			S_StartSound(missile,sfx_s3kcfl)	

			if G_GametypeHasTeams() then
				missile.color = mo.color
			end
	-- 		if P_MobjFlip(mo) == -1 then
	-- 			missile.z = $-missile.height
	-- 			missile.flags2 = $|MF2_OBJECTFLIP
	-- 			missile.eflags = $|MFE_VERTICALFLIP
	-- 		end
			if missile.tracer and missile.tracer.valid then
				missile.tracer.target = player.mo
				if P_MobjFlip(mo) == -1 then 
					missile.tracer.z = $-missile.tracer.height
					missile.tracer.flags2 = $|MF2_OBJECTFLIP|MF2_DONTDRAW
					missile.tracer.eflags = $|MFE_VERTICALFLIP
				end					
			end
			player.dustdevil = missile
		end
	end
	//End lag
	if player.actionstate == ground_special+1
		player.powers[pw_nocontrol] = max($,2)
		if player.actiontime < TICRATE return end
		//Neutral
		B.ApplyCooldown(player,cooldown)
		player.actionstate = 0
		player.actiontime = 0
		mo.state = S_PLAY_WALK
		return
	end
	//Air Special
	if player.actionstate == air_special then
		player.drawangle = mo.angle-ANGLE_45*(player.actiontime&7)
		if player.actiontime&7 == 4 then
			S_StartSound(mo,sfx_s3k7e)
		end
		spinhammer(mo)
		sparkle(mo)
		//Air control
		if (player.pflags&PF_JUMPDOWN or doaction) and not (player.cmd.buttons & BT_SPIN) then
			P_SetObjectMomZ(mo,FRACUNIT/8,1)
		end
		//Extra Projectiles
		if player.pflags&PF_JUMPED and not(player.pflags&PF_NOJUMPDAMAGE) then
			player.pflags = $ | PF_NOJUMPDAMAGE
			if mo.tornadocollide and mo.tornadocollide == leveltime then
				for n = 1,8 do
					B.SpawnWave(player, n*ANGLE_45, n>1, n%2==0)
				end
			else
				for n = 1,8 do
					local msl = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_LHRT)
					if msl and msl.valid then
						msl.target = mo
						msl.extravalue2 = FRACUNIT*95/100
						msl.fuse = 15
						msl.flags = $
						local speed = mo.scale * 20
						local xyangle = n*ANGLE_45
						local zangle = 0
						B.InstaThrustZAim(msl,xyangle,zangle,speed,false)		
						msl.momx = $ + mo.momx
						msl.momy = $ + mo.momy
						msl.momz = $ + mo.momz
						if G_GametypeHasTeams() then
							msl.color = player.ctfteam == 2 and SKINCOLOR_SKY or SKINCOLOR_ROSY
						else
							msl.color = mo.color
						end
						msl.colorized = true
					end
				end
			end
			S_StartSound(mo, sfx_hoop1)
		end
		//Neutral
		local nearground = B.NearGround(mo, nil, nil, mo.momz)
		if nearground or player.actiontime > TICRATE*3/2 or player.powers[pw_carry] then
			if (nearground or (player.cmd.buttons & BT_SPIN)) and not (player.powers[pw_carry]) then
				player.melee_state = st_release
				player.actionstate = air_special+1
			else
				mo.state = S_PLAY_FALL
				player.actionstate = 0
			end
			player.actiontime = 0
			B.ApplyCooldown(player,cooldown)
			player.drawangle = player.mo.angle
		end
		return
	end

	if player.actionstate == air_special+1
		local activeframes = player.actiontime < TICRATE-(TICRATE/3)
		local ihatedustdevils = mo.momz*P_MobjFlip(mo) > mo.scale*10
		if activeframes and not ihatedustdevils then 
			if P_IsObjectOnGround(mo) then
				mo.frame = 0
				mo.sprite2 = SPR2_MLEL
				player.powers[pw_nocontrol] = max($,2)
			else
				player.actiontime = $-1
			end
			return 
		end
		//Neutral
		--B.ApplyCooldown(player,cooldown)
		player.actionstate = 0
		player.actiontime = 0
		mo.state = (P_IsObjectOnGround(mo) and S_PLAY_WALK) or S_PLAY_SPRING
		return
	end
	--[[
	if player.actionstate == piko_special and P_IsObjectOnGround(mo) then
		--handled in Lib_Hammer
	end
	]]
end

B.DustDevilThinker = function(mo)
	local owner = mo.target
	local hurtbox = mo.tracer
	if not(owner and owner.valid and hurtbox and hurtbox.valid) then 
		P_RemoveMobj(mo)
	return end

	B.SafeRadiusIncrease(mo, 32*FRACUNIT)
	
	mo.angle = R_PointToAngle2(0,0,mo.momx,mo.momy)
-- 	local p = B.GetNearestPlayer(owner,nil,-1,nil,false)
-- 	if p then
-- 		mo.angle = R_PointToAngle2(mo.x,mo.y,p.mo.x,p.mo.y)
-- 	end
	if not mo.speed then mo.speed = min_tornado_speed*mo.scale end
	local speed = FixedMul(mo.speed,mo.scale)/B.WaterFactor(mo)
	if twodlevel or mo.flags2&MF2_TWOD then
		speed = $/2
	end
	hurtbox.angle = mo.angle
	hurtbox.hurtheight = min(FRACUNIT,$+FRACUNIT/35)
	P_Thrust(mo,mo.angle,speed)
	B.ControlThrust(mo,FRACUNIT,speed)
	if P_MobjFlip(mo) == 1 then
		P_SetOrigin(hurtbox,mo.x,mo.y,mo.z)
	else
		P_SetOrigin(hurtbox,mo.x,mo.y,mo.z+mo.height-hurtbox.height)
	end
	if hurtbox and hurtbox.valid then
		hurtbox.fuse = mo.fuse
	end
	if not(leveltime&3) then
		for n = 1, 4
			local swirl = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SWIRL)
			if swirl and swirl.valid then
				swirl.target = hurtbox
				swirl.angle = mo.angle+ANGLE_90*n
				swirl.color = B.Choose(mo.color,SKINCOLOR_SILVER)
				if P_MobjFlip(mo) == -1 then 
					swirl.flags2 = $|MF2_OBJECTFLIP
					swirl.eflags = $|MFE_VERTICALFLIP
				end
				if n&1 then
					swirl.swirltype = 1
					swirl.state = swirl1
					swirl.scale = $/4
-- 					swirl.rotatespeed = $*2
				else
					swirl.state = swirl2
					swirl.colorized = true
	-- 				swirl.flags2 = MF2_SHADOW
				end
				if n&2
					swirl.reach = 32*mo.scale
				end

-- 				swirl.reach = P_RandomRange(32,64)*mo.scale
-- 				swirl.rotatespeed = P_RandomRange(10,30)*ANG1
			end
		end
	end
end

B.SwirlSpawn = function(mo)
-- 	mo.rotatespeed = ANG15
	mo.rotatespeed = ANG30
-- 	mo.fusetime = TICRATE*2
	mo.fusetime = TICRATE
	mo.scale = $*3/4
	mo.fuse = mo.fusetime
	mo.reach = 0
	mo.swirltype = 0
end

B.SwirlThinker = function(mo)
	if not(mo and mo.valid and mo.target and mo.target.valid) then 
		P_RemoveMobj(mo)
	return end
	
	//Blink
	if mo.target.fuse < TICRATE then
		mo.flags2 = $^^MF2_DONTDRAW
	end
	//Regulate State
	if mo.swirltype == 0 then
		mo.state = swirl2
	else
		mo.state = swirl1
	end
	//Do swirl
	mo.angle = $+mo.rotatespeed
	local time = FRACUNIT*(mo.fusetime-mo.fuse)/mo.fusetime 
	local dist = B.FixedLerp(mo.target.minradius,mo.reach+mo.target.radius,time)
	local x = P_ReturnThrustX(nil,mo.angle,dist)
	local y = P_ReturnThrustY(nil,mo.angle,dist)
	local z
	if P_MobjFlip(mo) == 1 then 
		z = B.FixedLerp(0,mo.target.height-mo.height,time)
	else
		z = B.FixedLerp(mo.target.height-mo.height,0,time)	
	end
	P_SetOrigin(mo,mo.target.x+x,mo.target.y+y,mo.target.z+z)
end

B.DustDevilSpawn = function(mo)
	mo.tracer = P_SpawnMobj(mo.x,mo.y,mo.z,MT_DUSTDEVIL)
	if mo.tracer and mo.tracer.valid then
		mo.tracer.scale = mo.scale*4
		mo.tracer.minradius = mo.tracer.radius/4
		mo.tracer.hurtheight = 0
		if P_MobjFlip(mo) == -1 then 
			mo.tracer.flags2 = $|MF2_OBJECTFLIP
			mo.tracer.eflags = $|MFE_VERTICALFLIP
		end
	end
end

B.DustDevilTouch = function(dustdevil,collide)
	//Failsafe
	if dustdevil.hurtheight == nil then return end
	if not(dustdevil and dustdevil.valid and dustdevil.target and dustdevil.target.valid) then 
	return true end
	
	local push = false
	if collide.battleobject then push = true end
	local player = nil
	if collide.player then player = collide.player end
	
	//Get cone-like hit dimensions
	local w1 		= dustdevil.radius-dustdevil.minradius //Width of narrow end of cone
	local w2 		= dustdevil.radius //Width of wide end of cone
	local hurtheight	= max(FRACUNIT/35,FixedMul(dustdevil.hurtheight,dustdevil.height))
	
	local z,w //Nearest Z coordinate and its corresponding radius
	if not(dustdevil.flags2&MF2_OBJECTFLIP) then //Regular orientation
		//Z checks
		if dustdevil.z > collide.z+collide.height
		or collide.z > dustdevil.z+hurtheight
		return true end
		z	= //Get nearest z point
			min(dustdevil.z+hurtheight, //Max height: tornado base + hurtbox height
			max(dustdevil.z, //Min height: tornado base
			collide.z)) //Colliding object's lower z position
		w	= B.FixedLerp(w1,w2,FixedDiv(z-dustdevil.z,hurtheight)) //Get the interpolated width value corresponding to the nearest z point on hurtbox
	else //Flipped orientation
		if dustdevil.z+dustdevil.height < collide.z
		or collide.z+collide.height < dustdevil.z+dustdevil.height-hurtheight
		return true end
		z	= 
			min(dustdevil.z+dustdevil.height, //Max height: tornado base + "true" height 
			max(dustdevil.z+dustdevil.height-hurtheight, //Min height: tornado base + "true" height - hurtbox height
			collide.z+collide.height)) //Colliding object's upper z position
		w	= B.FixedLerp(w1,w2,-FixedDiv(z-dustdevil.z-dustdevil.height,hurtheight)) //flip args 1&2 to invert interpolation
	end
	local dist = R_PointToDist2(dustdevil.x,dustdevil.y,collide.x,collide.y)
	//No collision
	if dist > w then 
-- 		print("\x85"..hurtheight*100/dustdevil.height.."%..."..w*100/dustdevil.radius.."%..."..dist/FRACUNIT)
		return true
	end
-- 	print("\x83 "..hurtheight*100/dustdevil.height.."%..."..w*100/dustdevil.radius.."%..."..dist/FRACUNIT)
	//Self collision
	if dustdevil.target == collide and player
		collide.tornadocollide = leveltime
		if collide.player.actionstate == air_special then //Air-ground combo
			if not(S_SoundPlaying(collide,sfx_wdjump)) then
				S_StartSound(collide,sfx_wdjump)
				player.pflags = $|PF_STARTJUMP|PF_JUMPED
				player.mo.state = S_PLAY_JUMP
			end
			P_SetObjectMomZ(collide,FRACUNIT*24/B.WaterFactor(collide),0)
		end
	return true end
	
	local friendly = collide.player and B.MyTeam(dustdevil.target,collide)
	//Enemy collision
	if not(friendly) then
		local r = R_PointToAngle2(dustdevil.x,dustdevil.y,collide.x,collide.y)
-- 		local damagethrust = not(collide.player or collide.player.powers[pw_flashing]) //or B.PlayerCanBeDamaged(collide.player)
		P_DamageMobj(collide,dustdevil,dustdevil.target)
		if push then
			collide.target = dustdevil.target
		end
		if not(collide.player) or P_PlayerInPain(collide.player)
			P_SetObjectMomZ(collide,FRACUNIT*16/B.WaterFactor(collide),0)
			P_InstaThrust(collide,r,dustdevil.scale*6)
		end
	end
	if(friendly)
		B.AddPinkShield(collide.player,dustdevil.target.player, true)
	end
	return true
end

