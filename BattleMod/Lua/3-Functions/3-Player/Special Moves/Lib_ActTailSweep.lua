local B = CBW_Battle
local state_sweep = 1
local state_dash = 2
local state_charging = 3
local state_didthrow = 4
local cooldown_sweep = TICRATE*7/5 --1.4s
local cooldown_dash = TICRATE*2
local cooldown_throw = cooldown_dash
local cooldown_cancel = TICRATE*2/3 --0.66s
local cooldown_spinswipe = TICRATE * 2
local sideangle = ANG30 - ANG10
local throw_strength = 30
local throw_lift = 10
local throw_enemystuntime = TICRATE*2/3
local thrustpower = 16
local threshold1 = TICRATE/3 --0.3s
local threshold2 = threshold1+(TICRATE*3/2) --minimum charging time + 1.5s
local flightdash_satk = 2 -- grab only happens if opponent's def is lower

B.Action.TailSwipe_Priority = function(player)
	local mo = player.mo
	if not (mo and mo.valid) return end

	local tailswipereq = (player.mo.state == S_PLAY_SPINDASH and player.dashspeed > (player.maxdash/5*3))

	if not(tailswipereq) and player.textflash_flashing then
		player.actiontext = B.TextFlash(player.actiontext, true, player)
	end
	
	if player.actionstate == state_charging
		B.SetPriority(player,0,0,nil,0,0,"tail sweep chargeup")
	elseif player.actionstate == state_sweep
		B.SetPriority(player,1,1,nil,1,1,"tail sweep")
	elseif player.actionstate == state_dash or player.actionstate == state_didthrow
		B.SetPriority(player,0,0,"amy_melee",0,1,"flight dash") --also see: flightdash_satk
	end
end

B.Tails_PreCollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if pain[n1] or (plr[n2] and plr[n2].actionstate) or not(plr[n1] and plr[n1].valid)
		return
	end
	if plr[n1].actionstate == state_dash and (B.MyTeam(mo[n1], mo[n2]) or (def[n2] < flightdash_satk and not (plr[n2] and plr[n2].nodamage)))
		plr[n1].tailsmarker = 1
	elseif B.MyTeam(mo[n1], mo[n2])
		plr[n1].tailsmarker = -1
	end
end

B.Tails_Collide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if not (plr[n1] and plr[n1].tailsmarker and plr[n2])
		return false
	end
	if plr[n1].tailsmarker < 0
		return true
	end
	if plr[n1].actionstate == state_dash
		plr[n1].actionstate = 0
		plr[n1].powers[pw_tailsfly] = TICRATE*8
		mo[n1].state = S_PLAY_FLY
		plr[n1].pflags = $ &~ (PF_JUMPED|PF_NOJUMPDAMAGE|PF_SPINNING|PF_STARTDASH)
		plr[n1].pflags = $|PF_CANCARRY
		local flip = P_MobjFlip(mo[n1])
		P_SetOrigin(mo[n1],mo[n1].x,mo[n1].y,mo[n2].z+(mo[n2].height*flip))
		plr[n2].powers[pw_carry] = CR_NONE
		B.CarryState(plr[n1],plr[n2])
		P_SetObjectMomZ(mo[n1],FRACUNIT*7)
		S_StartSound(mo[n1], sfx_s3ka0)
		if not B.MyTeam(plr[n1], plr[n2])
			plr[n2].customstunbreaktics = 5
			plr[n2].customstunbreakcost = 35
			plr[n2].airdodge = -1
			B.ApplyCooldown(plr[n1], cooldown_dash)
		else
			plr[n1].actioncooldown = cooldown_cancel
		end
		plr[n2].powers[pw_nocontrol] = max($,TICRATE/7)
		plr[n2].jumpstasistimer = TICRATE/7 --prevent accidental jumps
		return true
	elseif plr[n1].actionstate == state_sweep
		P_InstaThrust(mo[n2], angle[n2], mo[n1].scale*3)
		P_InstaThrust(mo[n1], angle[n1], mo[n1].scale*3)
	end
end

B.Tails_PostCollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1] and plr[n1].tailsmarker
		plr[n1].tailsmarker = nil
		if (plr[n1].pflags & PF_CANCARRY)
			return true
		end
	end
end

local function sbvars_swipe(m,pmo)
	if m and m.valid then
		m.fuse = TICRATE*3/4
		m.flags = $ &~ MF_MISSILE
		S_StartSound(m,sfx_s3kb8)
	end
end

local function sbvars_sweep(m, pmo)
	local chargepercentage = min(100,pmo.player.actiontime*100/threshold2)
	m.fuse = (threshold1/2)+(min(threshold2, pmo.player.actiontime)/5)
	m.cutterspeed = pmo.scale*(chargepercentage/2)
	m.flags = $ &~ MF_MISSILE
	S_StartSound(m,sfx_s3kb8)
end

local function domissiles(mo,thrustfactor)
	//Projectile
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle,0)
	sbvars_swipe(m,mo)
	//Do Side Projectiles
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle-sideangle,0)
	sbvars_swipe(m,mo)
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle+sideangle,0)
	sbvars_swipe(m,mo)
	//Thrust
	if not(P_IsObjectOnGround(mo))
		P_InstaThrust(mo,mo.angle+ANGLE_180,thrustfactor*5)
	else
		P_Thrust(mo,mo.angle+ANGLE_180,thrustfactor*10)
	end
end

local function dodust(mo)
	if P_IsObjectOnGround(mo)
		local player = mo.player
		local dust = P_SpawnMobjFromMobj(mo,0,0,0,MT_DUST)
		P_InstaThrust(dust,player.drawangle,mo.scale*12)
	end
end

local function dosweep(mo,thrustfactor)
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle,0)
	sbvars_sweep(m,mo)
	--m.radius = 0
	m.flags = $ &~ MF_GRENADEBOUNCE
	mo.player.aircutter = m
end

local uncolorize = B.Uncolorize

B.CarryStun = function(otherplayer, strugglerings, struggletime, noshake, nostunbreak, nopain)
	//gameplay
	strugglerings = $ or 5
	struggletime = $ or TICRATE/3 -- player can only struggle again after this time is over
	otherplayer.strugglerings = -strugglerings --for hud... lmao...
	otherplayer.airdodge = -1
	otherplayer.jumpstasistimer = 2 -- because giving PF_JUMPSTASIS doesnt work apparently
	otherplayer.landlag = otherplayer.powers[pw_nocontrol]
	local pressed = (otherplayer.realbuttons & BT_JUMP)
	local tapped = pressed and not (otherplayer.holdingjump)
	local holdmashspeed = TICRATE*2/5 -- if holding down the button, mash every 0.4s
	local held = pressed and (leveltime % holdmashspeed == 0)
	if pressed then -- IM SO SORRY but i hate messing with inputs when pw_nocontrol is going on
		otherplayer.holdingjump = true
	else
		otherplayer.holdingjump = false
	end
	local struggled = (tapped or held) and not(otherplayer.powers[pw_nocontrol])
	if struggled then
		S_StartSound(otherplayer.mo, sfx_s3kd7s)
		otherplayer.customstunbreakcost = max(0,$-strugglerings)
		if not (otherplayer.customstunbreakcost) then
			otherplayer.canstunbreak = 2
			B.StunBreak(otherplayer, true)
			return
		end
		otherplayer.powers[pw_nocontrol] = max($,struggletime)
		otherplayer.canstunbreak = 0
		B.ApplyHitstun(otherplayer.mo, otherplayer.powers[pw_nocontrol])
		if not noshake then
			local shake = P_SpawnMobjFromMobj(otherplayer.mo, 0, 0, 0, MT_THOK)
			shake.state = S_SHAKE
			otherplayer.shakemobj = shake
		end
	elseif not (otherplayer.powers[pw_nocontrol] or nostunbreak) then
		otherplayer.canstunbreak = max($,2)
	end
	//shake vfx follows
	if otherplayer.shakemobj and otherplayer.shakemobj.valid then
		P_MoveOrigin(otherplayer.shakemobj, otherplayer.mo.x, otherplayer.mo.y, otherplayer.mo.z + (otherplayer.mo.height/2))
	end
	//pain animation
	if nopain then
		return struggled
	end
	if otherplayer.followmobj
		if otherplayer.mo.skin == "tails"
			otherplayer.followmobj.state = S_TAILSOVERLAY_PAIN
		elseif otherplayer.mo.skin == "tailsdoll"
			P_SetMobjStateNF(otherplayer.followmobj,S_NULL)
		end
	end
	otherplayer.mo.state = S_PLAY_PAIN
	return struggled
end

B.Action.TailSwipe = function(mo,doaction)
	local player = mo.player

	if (mo.eflags & MFE_SPRUNG)
	and player.actionstate
		uncolorize(mo)
		return
	end

	if not(B.CanDoAction(player)) 
		if mo.state == B.GetSVSprite(player,1)
		or P_PlayerInPain(player)
			B.ResetPlayerProperties(player,false,true)
			uncolorize(mo)
		end
	return end
	
	local flying = player.panim == PA_ABILITY and not player.actionstate
	local carrying = false
	--[[
		!! IMPORTANT NOTE ABOUT OPTIMIZATION:
		basically, the for block below makes every tails run through every single player
		in every single frame JUST to check which player is being grabbed by him.
		sounds pretty bad, right? but then consider the fact that we're also doing several
		IF statements in each one of them.
		with this in mind, this can be optimized in a number of ways. have this checklist:
		- [x] only run the search function at all that if he's flying (can't be carrying otherwise)
		- [x] change the order of the if statements by how rare they are, so it checks less on average
		- [ ] use a searchblockmap function instead of iterating through all players
		thank you for your attention
		~lumyni
		]]
	if flying
		for otherplayer in players.iterate
			if not(otherplayer.powers[pw_carry] == CR_PLAYER
			and otherplayer.mo and otherplayer.mo.valid
			and otherplayer.mo.tracer == mo)
			then //skip until we find someone that passes all of the conditions
				continue
			end
			if not B.MyTeam(otherplayer.mo, mo) then
				if B.CarryStun(otherplayer) and mo.momz * P_MobjFlip(mo) < 0 then
					mo.momz = 0 
				end
			end
			carrying = true 
			break //we carrying, dont even bother checking other players
		end
	end
	
	local chargepercentage = min(100,player.actiontime*100/threshold2)
	--local exhaust = max(0,200-(player.actiontime*100/threshold2))
	if player.actionstate == state_charging
		player.action2text = "Charge "..chargepercentage.."%"
		player.canguard = 2
		player.guardtext = "Cancel"
	end
	
	//Action triggers
	local swipetrigger = (player.mo.state == S_PLAY_SPINDASH and player.dashspeed > (player.maxdash/5*3) and player.actionstate == 0 and doaction == 1 and not(flying or carrying))
	local attackready = (not swipetrigger) and (player.actiontime >= threshold1 and player.actionstate == state_charging)
	--local charging = ((not(attackready)) and player.actionstate == state_charging)
	local sweeptrigger = attackready and (player.actiontime > threshold2*2 or B.ButtonCheck(player,player.battleconfig_special) == 0)
	local chargehold = (attackready and B.PlayerButtonPressed(player,player.battleconfig_special,true))
	local canceltrigger =
		not sweeptrigger
		and player.actionstate == state_charging
		and B.PlayerButtonPressed(player,player.battleconfig_guard,false)
	local thrusttrigger = (player.actionstate == 0 and doaction == 1 and flying and not(carrying))
	local throwtrigger = (player.actionstate == 0 and doaction == 1 and carrying)
	local chargetrigger = (not swipetrigger) and (player.actionstate == 0 and doaction == 1 and not (flying or carrying))
	local buffer = (player.cmd.buttons&player.battleconfig_special)

	//Get thrust speed multiplier
	local thrustfactor = mo.scale
	if mo.eflags&MFE_UNDERWATER
		thrustfactor = $>>1
	end
	if mo.flags2&MF2_TWOD or twodlevel
		thrustfactor = $>>1
	end
	
	player.actionrings = 10
	if player.mo.state == S_PLAY_SPINDASH and player.dashspeed > (player.maxdash/5*3) then
		if (player.textflash_flashing) then --wittle hacky
			if (leveltime % 8) == 0 then
				B.SpawnFlash(mo, 10, true)
			end
		else
			B.SpawnFlash(mo, 10, true)
			B.teamSound(mo, player, sfx_tswit, sfx_tswie, 255, false)
		end
		player.actiontext = B.TextFlash("Tail Swipe", (doaction == 1), player)
		B.DrawAimLine(player,mo.angle+sideangle)
		B.DrawAimLine(player,mo.angle)
		B.DrawAimLine(player,mo.angle-sideangle)
	elseif not(flying or player.actionstate == state_dash) then
		player.actiontext = "Tail Sweep"
	elseif not(carrying)
		player.actiontext = "Flight Dash"
	else
		player.actionrings = 0
		player.actiontext = "Power Throw"
	end
	
	if player.actionstate != 0 then
		player.actiontime = $+1
		--player.exhaustmeter = FRACUNIT
		player.actionbuffer = true
	elseif player.actionbuffer
		player.actiontime = 0
		player.actionbuffer = false
		uncolorize(mo)
		if P_IsObjectOnGround(mo) then
			player.pflags = $ &~ PF_JUMPED
		end
		if player.powers[pw_shield] == SH_WHIRLWIND
		and not (player.powers[pw_tailsfly] or P_IsObjectOnGround(mo))
			player.pflags = $|PF_SHIELDABILITY
		end
	end
	
	//Intercepted while charging
	if (player.actionstate == state_charging or player.actionstate == state_sweep) and player.powers[pw_nocontrol] then
		player.actionstate = 0
		B.ApplyCooldown(player,cooldown_cancel)
		uncolorize(mo)
		return
	end
	
	//Start charging attack
	if chargetrigger
		B.PayRings(player,player.actionrings)
		player.actionstate = state_charging
		player.actiontime = 0
		player.ledgemeter = (FRACUNIT*2) - (FRACUNIT/5)
		player.pflags = $&~(PF_SPINNING|PF_SHIELDABILITY)
		player.canguard = false
		B.teamSound(mo, player, sfx_chargt, sfx_charge, 255, true)
		if not(P_IsObjectOnGround(mo))
			mo.momz = $*2/3
		end
		local spark = P_SpawnMobj(mo.x,mo.y,mo.z+mo.height/2,MT_SUPERSPARK)
	end
	
	//Charging attack
	if charging or chargehold then
		local ang = (1+chargepercentage*ANG1)/3
		local spdrange = (1+player.speed)/(3*mo.scale)
		local chargerange = (1+chargepercentage)/16
		local range = spdrange + chargerange
		player.pflags = $&~(PF_SPINNING)
		if player.ledgemeter then
			player.ledgemeter = max(0,$-(FRACUNIT*2/(threshold2*2)))
			player.exhaustmeter = min($,player.ledgemeter)
		end

		//Speed Cap
		local speed = FixedHypot(mo.momx,mo.momy)
		if speed > mo.scale and player.actiontime >= threshold1 then
			local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
			P_InstaThrust(mo,dir,FixedMul(speed,mo.friction))
			if P_IsObjectOnGround(mo) and player.actiontime > threshold2 then
				mo.momx = $/2
				mo.momy = $/2
			end
		end
		
		//Do "skidding" effects
		if P_IsObjectOnGround(mo) and leveltime%3 == 1 and player.speed > 3*mo.scale then
			S_StartSound(mo,sfx_s3k7e)
			local r = mo.radius/FRACUNIT
			local dust = P_SpawnMobj(
				P_RandomRange(-r,r)*FRACUNIT+mo.x,
				P_RandomRange(-r,r)*FRACUNIT+mo.y,
				mo.z,
				MT_DUST
			)
			if dust and dust.valid then dust.scale = mo.scale end
		end
		
		//Powerup
		if chargehold then	
			if player.actiontime > threshold2 and (player.actiontime%6 < 2) then
				mo.colorized = true
				if player.actiontime%4 == 1
					mo.color = SKINCOLOR_SUPERGOLD3
				else
					mo.color = SKINCOLOR_SUPERGOLD5
				end
				if player.followmobj
					player.followmobj.colorized = true
					player.followmobj.color = mo.color
				end
			else
				uncolorize(mo)
			end
			if player.actiontime == threshold2 then
				S_StartSound(mo,sfx_s1c3)
			end
		end
		--player.actionsuper = true
	end
	
	//Oops
	if canceltrigger then
		B.ResetPlayerProperties(player,false,false)
		mo.state = P_IsObjectOnGround(mo) and S_PLAY_STND or S_PLAY_SPRING
		player.actionstate = 0
		player.actiontime = -1
		S_StartSound(mo,sfx_s3k7d)
		B.ApplyCooldown(player,cooldown_cancel)
		uncolorize(mo)
		player.buttonhistory = $ | player.battleconfig_guard
	end
	
	//Charging frame
	if player.actionstate == state_charging then
		mo.state = S_PLAY_EDGE
		player.pflags = ($|PF_SPINDOWN|PF_NOJUMPDAMAGE)&~(PF_THOKKED)
		--player.actionsuper = true
		if not (P_IsObjectOnGround(mo) or B.WaterFactor(mo) > 1) then
			P_SetObjectMomZ(mo,gravity/2,true) //Low grav
		end
		if leveltime%6 == 0 then
			//post vfx
			local g = P_SpawnGhostMobj(player.mo)
			g.colorized = true
			g.color = SKINCOLOR_SUPERGOLD3
			g.tics = 5
			g.frame = ($ & ~FF_TRANSMASK) | FF_TRANS50
			g.scale = $ * 8/7
			g.destscale = $ * 9/7
			g.scalespeed = FRACUNIT/2
			if g.tracer then
				g.tracer.colorized = true
				g.tracer.color = SKINCOLOR_SUPERGOLD3
				g.tracer.tics = 5
				g.tracer.frame = ($ & ~FF_TRANSMASK) | FF_TRANS50
				g.tracer.scale = $ * 8/7
				g.tracer.scalespeed = FRACUNIT/2
			end
		end
	elseif (player.actiontime == -1) then
		player.actiontime = 0
	end
	
	//Activate swipe
	if swipetrigger then
		B.PayRings(player)
		B.ApplyCooldown(player, cooldown_spinswipe)

		--Set state
		player.actionstate = state_sweep
		player.actiontime = 0
		player.pflags = $&~(PF_SPINNING|PF_JUMPED)

		--Missile attack
		domissiles(mo,thrustfactor)
		
		--Effects
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*64,12,MT_DUST,ANGLE_90,nil,true)
		S_StartSound(mo,sfx_spdpad)
	elseif sweeptrigger then
		--Set state
		player.actionstate = state_sweep

		--Missile attack
		dosweep(mo, 0)
		if player.aircutter and player.aircutter.valid then
			player.aircutter_distance = 0
			player.aircutter.scale = 5*mo.scale/4
		end
		
		--Physics
		if player.cmd.forwardmove or player.cmd.sidemove then 
			local actualcharge = min(threshold2, player.actiontime)
			P_Thrust(mo, B.GetInputAngle(player), actualcharge*mo.scale*2/3)
		end
		if player.cmd.buttons & BT_JUMP and not P_IsObjectOnGround(mo) then
			P_SetObjectMomZ(mo,max(mo.scale*5,abs(mo.momz)),false)
		end
		player.actiontime = 0

		--Effects
		uncolorize(mo)
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*64,12,MT_DUST,ANGLE_90,nil,true)
		S_StartSound(mo,sfx_spdpad)
		B.ApplyCooldown(player,cooldown_sweep)
	end

	//Activate thrust
	if thrusttrigger
		B.PayRings(player)
		--B.ApplyCooldown(player,cooldown_dash)
		//Set state
		player.powers[pw_tailsfly] = 0
		player.pflags = ($|PF_JUMPED|PF_THOKKED)
		player.actionstate = state_dash
		player.actiontime = 0
		mo.state = S_PLAY_ROLL
		// hitbox
		local hitbox = B.BattleHitboxSpawn(player, 18*player.mo.scale, 1*player.mo.scale, 2, S_TAILS_POUNCE, true, 0)
		hitbox.tics = TICRATE/2
		//Physics
		P_Thrust(mo,mo.angle,thrustfactor*thrustpower)
		P_SetObjectMomZ(mo,FRACUNIT*3,false)
		//Effects
		local radius = mo.radius/FRACUNIT
		local height = mo.height/FRACUNIT
		local r1 = do
			return P_RandomRange(-radius,radius)*FRACUNIT
		end
		local r2 = do
			return P_RandomRange(0,height)*FRACUNIT
		end
		for n = 1,16
			P_SpawnMobjFromMobj(mo,r1(),r1(),r2(),MT_DUST)
		end
		S_StartSound(mo,sfx_ngjump)
	end
	
	//Activate throw
	if throwtrigger 
		B.PayRings(player)
		B.ApplyCooldown(player,cooldown_throw)
		//Set state
		player.powers[pw_tailsfly] = 0
		player.pflags = ($|PF_JUMPED|PF_THOKKED)
		player.actionstate = state_didthrow
		player.actiontime = 0
		mo.state = S_PLAY_ROLL
	
		//Throw Partner
		for otherplayer in players.iterate
			if not(
				otherplayer.mo and otherplayer.mo.valid
				and otherplayer.mo.tracer == mo
				and otherplayer.powers[pw_carry] == CR_PLAYER
			)
				continue
			end
			otherplayer.pushed_creditplr = player
			otherplayer.tailsthrown = player
			otherplayer.powers[pw_carry] = 0
			otherplayer.pflags = $|PF_SPINNING|PF_THOKKED
			local partner = otherplayer.mo
			partner.tracer = nil
			partner.state = S_PLAY_ROLL
			local spd = max(throw_strength,1+player.speed/FRACUNIT)
			P_InstaThrust(partner,mo.angle,thrustfactor*spd)
			partner.momx = $ + mo.momx/2
			partner.momy = $ + mo.momy/2
			partner.momz = throw_lift*mo.scale*P_MobjFlip(mo) + mo.momz/2
			if B.MyTeam(player, otherplayer) == false
				otherplayer.airdodge = -1
				otherplayer.actioncooldown = max($,2*TICRATE)
				B.PlayerCreditPusher(otherplayer,player)
				if otherplayer.customstunbreakcost == nil then
					otherplayer.customstunbreakcost = 35 
				else
					otherplayer.customstunbreakcost = min($+15,35)
				end
				otherplayer.powers[pw_nocontrol] = max($, throw_enemystuntime)
			else
				B.ResetPlayerProperties(otherplayer, true, false)
			end
			otherplayer.powers[pw_nocontrol] = 0
			otherplayer.landlag = 0
		end
-- 		//Free carry ID
-- 		player.carry_id = nil
		
		//Physics
		if not(P_IsObjectOnGround(mo))
			P_SetObjectMomZ(mo,FRACUNIT*5,false)
		end
		//Effects
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*64,12,MT_DUST,ANGLE_90,nil,true)
		S_StartSound(mo,sfx_spdpad)
	end
	
	//Swipe state
	if player.actionstate == state_sweep then
		B.analogkill(player, 2)
		player.laststate = state_sweep
		--if P_IsObjectOnGround(mo)
			--player.lockaim = true
		--end
		--player.lockmove = true
		player.pflags = $|PF_THOKKED|PF_SPINDOWN
		player.pflags = $&~(PF_SPINNING)
		player.charability2 = CA2_NONE
		--S_StopSoundByID(mo, sfx_spin)

		-- aircutter circling thingy
		-- NOTICE: code moved to Exec_Projectiles.lua

		--Anim states
		if player.actiontime < 6 then
			--Fast Spin anim
			player.drawangle = mo.angle-ANGLE_90*(player.actiontime-4)
			B.DrawSVSprite(player,1)
			P_SetMobjStateNF(player.followmobj,S_NULL)
			dodust(mo)
		elseif player.actiontime < 12 then
			--Medium Spin anim
			player.drawangle = mo.angle-ANGLE_45*(player.actiontime-4)
			B.DrawSVSprite(player,1)
			P_SetMobjStateNF(player.followmobj,S_NULL)
			dodust(mo)
		else
			--Teeter anim
			player.drawangle = mo.angle-ANGLE_45/2*(player.actiontime-4)
			mo.state = S_PLAY_EDGE
			mo.frame = 0
			mo.tics = 0
			--player.pflags = $&~(PF_SPINNING)
		end
		
		-- if we were interrupted mid swipe, we can actually reset our values
		-- they otherwise would be stuck, because we no longer were in the swipe state, 
		-- the code resetting the player's flags doesn't get called
		if player.laststate == state_sweep and player.actionstate ~= state_sweep then
			player.laststate = 0
			player.pflags = $ & ~(PF_THOKKED)
			--player.pflags = $ & ~(PF_FULLSTASIS)
			--player.pflags = $&~(PF_SPINNING)
			if P_IsObjectOnGround(mo) then
				player.pflags = $&~(PF_JUMPED)
			end

			player.pflags = $&~(PF_SPINNING)
			player.drawangle = mo.angle
			--mo.state = S_PLAY_WALK
			mo.frame = 0
			--mo.radius = radius
			if P_IsObjectOnGround(mo) then
				player.actionstate = 0
				player.drawangle = mo.angle
				mo.state = S_PLAY_WALK
				mo.frame = 0
			end
			player.actionstate = 0
		end
		
		--Reset to neutral
		if player.actiontime >= 22 then
			player.pflags = $&~(PF_THOKKED|PF_SPINNING)
			--player.pflags = $&~PF_FULLSTASIS
			player.drawangle = mo.angle
			mo.frame = 0
			if P_IsObjectOnGround(mo) then
				player.actionstate = 0
				player.drawangle = mo.angle
				mo.state = S_PLAY_WALK
				mo.frame = 0
				player.pflags = $&~PF_JUMPED
			else
				mo.state = S_PLAY_SPRING
				player.pflags = $|PF_JUMPED|PF_NOJUMPDAMAGE
			end
			player.actionstate = 0
			player.laststate = 0
		end
	else
		player.charability2 = CA2_SPINDASH
	end
	//Thrust state
	if player.actionstate == state_dash or player.actionstate == state_didthrow
		B.analogkill(player, 2)
		if player.actionstate == state_dash then
			player.mo.cantouchteam = 1
			local tail = player.followmobj
			if tail and tail.type == MT_TAILSOVERLAY then
				if tail.state != S_TAILSOVERLAY_RUN then
					tail.state = S_TAILSOVERLAY_RUN
				end
				tail.frame = B.Wrap(leveltime, 512, 515)
			end
		end
		if B.DrawSVSprite(player, player.actionstate == state_dash and 2 or 1) then
			if player.actionstate == state_dash then
				local tail = player.followmobj
				if tail and tail.type == MT_TAILSOVERLAY then
					tail.state = S_TAILSOVERLAY_RUN
				end
			else
				if player.followmobj then P_SetMobjStateNF(player.followmobj,S_NULL) end
				if not B.DrawSVSprite(player,1) then mo.state = S_PLAY_EDGE end
				player.drawangle = mo.angle-ANG60*player.actiontime
			end
		else
			mo.state = S_PLAY_EDGE
		end
		--player.drawangle = mo.angle-ANG60*player.actiontime
		local radius = mo.radius/FRACUNIT
		local height = mo.height/FRACUNIT
		local r1 = do
			return P_RandomRange(-radius,radius)*FRACUNIT
		end
		local r2 = do
			return P_RandomRange(0,height)*FRACUNIT
		end
		local s = P_SpawnMobjFromMobj(mo,r1(),r1(),r2(),MT_SPARK)
		s.colorized = true
		s.color = SKINCOLOR_WHITE
		s.scale = $/3
		s.momx = mo.momx/2
		s.momy = mo.momy/2
		s.momz = mo.momz/2
		s.flags2 = $|MF2_SHADOW
		player.canguard = 2
		player.guardtext = "Cancel"
		//Reset to neutral
		if P_IsObjectOnGround(mo)
		or B.PlayerButtonPressed(player,player.battleconfig_guard,false)
		or mo.momz*P_MobjFlip(mo) > mo.scale * 6
		then
			local throwed = player.actionstate == state_didthrow
			player.actionstate = 0
			player.drawangle = mo.angle
			player.pflags = $|PF_JUMPSTASIS
			mo.state = S_PLAY_WALK
			mo.frame = 0
			if not P_IsObjectOnGround(mo) then
				S_StartSound(mo,sfx_s251)
				player.buttonhistory = $ | player.battleconfig_guard
				B.ResetPlayerProperties(player,false,false)
				B.ApplyCooldown(player,cooldown_cancel)
				P_SpawnGhostMobj(mo)
			elseif not(throwed) then
				B.ApplyCooldown(player,cooldown_dash)
			end
		end
	end
end

B.SwipeTouch = function(swipe, collide)
	if not(collide.player and B.MyTeam(swipe.target,collide)) then
		if collide.battleobject then
			collide.target = swipe.target
		end
		P_DamageMobj(collide,swipe,swipe.target)
	end
	return true
end
