local B = CBW_Battle

-- A Humming Top-esque move for Sonic

B.Console.HTop_Commit = CV_RegisterVar({
	name = "htop_committics",
	defaultvalue = 10,
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_Natural
})


local COMMIT_TIME = 10
local ZTHRUST = 7
local ARROW_DIST = 55

local NOTEAM_COLOR = SKINCOLOR_SILVER
local REDTEAM_COLOR = SKINCOLOR_APRICOT
local BLUETEAM_COLOR = SKINCOLOR_SKY

local function windcolor(player)
	if G_GametypeHasTeams() and player.ctfteam then

		local redcolor = skincolor_redteam
		local bluecolor = skincolor_blueteam

		if skincolor_redteam == SKINCOLOR_RED then
			redcolor = REDTEAM_COLOR
		end

		if skincolor_blueteam == SKINCOLOR_BLUE then
			bluecolor = BLUETEAM_COLOR
		end

		return ({redcolor, bluecolor})[player.ctfteam]
	else
		local color = player.skincolor

		if color == skins["sonic"].prefcolor then
			color = SKINCOLOR_SKY
		elseif color == SKINCOLOR_RED then
			color = SKINCOLOR_APRICOT
		end

		return color
	end
end
		
local state_startup = 1
local state_spinning = 2

local applyFlip = function(mo1, mo2)
	if mo1.eflags & MFE_VERTICALFLIP then
		mo2.eflags = $|MFE_VERTICALFLIP
	else
		mo2.eflags = $ & ~MFE_VERTICALFLIP
	end
	
	if mo1.flags2 & MF2_OBJECTFLIP then
		mo2.flags2 = $|MF2_OBJECTFLIP
	else
		mo2.flags2 = $ & ~MF2_OBJECTFLIP
	end
end

local getMiddle = function(ref, mo_height)
	if P_MobjFlip(ref) == -1 then
		return (ref.z+ref.height+mo_height)-(ref.height/2)
	else
		return ref.z+(ref.height/2)
	end
end

local spawncircle = function(mo)
    local circle = P_SpawnMobjFromMobj(mo, 0, 0, P_MobjFlip(mo)*(mo.scale * 24), MT_THOK)
    circle.sprite = SPR_STAB
    circle.frame = TR_TRANS50|FF_PAPERSPRITE|A
    circle.angle = mo.angle + ANGLE_90
    circle.fuse = 7
    circle.scale = mo.scale / 3
    circle.colorized = true
    circle.color = mo.color
    return circle
end

local function charParam(player)
	return (player and player.mo and player.mo.valid and (player.charability == CA_JUMPTHOK) and (B.GetSkinVarsFlags(player) & SKINVARS_HUMMINGTOP))
end

local function cancelHummingTop(player, sound, flag)
	player.mo.hummingtop_state = nil
	
	
	if player.mo.hummingtop_overlay and player.mo.hummingtop_overlay.valid then
		P_RemoveMobj(player.mo.hummingtop_overlay)
		player.mo.hummingtop_overlay = nil
	end
	if player.mo.hummingtop_arrow and player.mo.hummingtop_arrow.valid then
		P_RemoveMobj(player.mo.hummingtop_arrow)
		player.mo.hummingtop_arrow = nil
	end
	player.mo.hummingtop_angle = nil
	player.mo.hummingtop_drawangle = nil
	player.mo.hummingtop_marker = nil
	player.glidetime = 0
	if player.mo.state == S_SONIC_HUMMINGTOP then
		if P_IsObjectOnGround(player.mo) then
			player.mo.state = S_PLAY_WALK
		else
			player.mo.state = S_PLAY_FALL
		end
	end
	player.pflags = $ & ~PF_STASIS
	if flag then
		B.ZLimit(player.mo, 10*FRACUNIT) -- Worth about 125% of Sonic's jump
		B.XYLimit(player.mo, player.normalspeed*5/4) -- 125% of Top speed
	end
	player.mo.hummingtop_beyblade_pick = nil
	
end

local function cancelDropDash(mo)
	mo.dropdash_actionable = nil
	mo.dropdash_prep = nil
	mo.dropdash_momz = nil
end


function B.HummingTop_AbilitySpecial(player)
	if charParam(player) then --If we're valid

		local exhaust = (player.exhaustmeter <= 0)
	
		if (player.pflags & PF_THOKKED) then --And didn't already do this
			return
		end

		if player.gotflagdebuff then
			return
		end

		if exhaust then
			S_StartSound(player.mo, sfx_s3k8c)
			S_StartSound(player.mo, sfx_pudpud)
			return true
		end

		player.pflags = $|(PF_THOKKED) --We've officially thokked
		
		player.mo.hummingtop_angle = player.mo.angle
		player.mo.hummingtop_drawangle = player.mo.hummingtop_angle
		player.canguard = false
		--We should be completely vulnerable
		--if player.mo.state != S_PLAY_SPRING then
			--player.mo.state = S_PLAY_SPRING --Upwards air state
		--end
		player.pflags = $ & ~(PF_JUMPED|PF_SPINNING|PF_STARTDASH) --But it's as if we were falling
		player.mo.momz = 0 -- Stall Z-Momentum
		player.glidetime = 1


		local current_speed = FixedHypot(player.mo.momx, player.mo.momy)
		local actionspd = FixedMul(player.mo.scale, player.actionspd) / B.WaterFactor(player.mo)
		local normalspeed = FixedMul(player.mo.scale, player.normalspeed) / B.WaterFactor(player.mo)
		
		local thrust = max(max(current_speed, actionspd), normalspeed)
		
		--player.powers[pw_strong] = $|STR_ANIM|STR_ATTACK
		P_InstaThrust(player.mo, player.mo.hummingtop_angle, thrust)
		cancelDropDash(player.mo)
		if player.gotflagdebuff then
			B.ZLimit(player.mo, 10*FRACUNIT) -- Worth about 125% of Sonic's jump
			B.XYLimit(player.mo, player.normalspeed*5/4) -- 125% of Top speed
		end
		--P_SetObjectMomZ(player.mo, FixedMul(player.mo.scale, B.Console.HTop_ZThrust.value), false)
		player.mo.momz = 0
		S_StopSoundByID(player.mo, sfx_thok)
		S_StartSound(player.mo, sfx_thok)
		if thrust > actionspd then
			spawncircle(player.mo)
			S_StartSound(player.mo, sfx_dash)
		end
		
		--Delete the existing variable, if it exists ofc
		if player.mo.hummingtop_overlay then
			if (type(player.mo.hummingtop_overlay) == "userdata") and (userdataType(player.mo.hummingtop_overlay) == "mobj_t") then
				if player.mo.hummingtop_overlay.valid then
					P_RemoveMobj(player.mo.hummingtop_overlay)
				end
			end
			player.mo.hummingtop_overlay = nil
		end

		player.mo.hummingtop_overlay = P_SpawnMobj(player.mo.x, player.mo.y, getMiddle(player.mo, mobjinfo[MT_DUST].height), MT_DUST)
		player.mo.hummingtop_overlay.state = S_INVISIBLE
		player.mo.hummingtop_overlay.sprite = SPR_NULL
		player.mo.hummingtop_overlay.renderflags = $|RF_FULLBRIGHT
		player.mo.hummingtop_overlay.blendmode = AST_ADD
		player.mo.hummingtop_overlay.dispoffset = 3
		applyFlip(player.mo, player.mo.hummingtop_overlay)
		player.mo.hummingtop_overlay.target = player.mo
		player.mo.hummingtop_overlay.fuse = 2
		player.mo.hummingtop_overlay.scale = (player.mo.scale) + (player.mo.scale)/2
		--player.mo.hummingtop_overlay.colorized = G_GametypeHasTeams()
		player.mo.hummingtop_overlay.color = windcolor(player)
		player.mo.state = S_PLAY_FALL
		player.canguard = false
		
		/*player.mo.hummingtop_arrow = P_SpawnMobj(player.mo.x+cos(player.mo.hummingtop_angle)*ARROW_DIST, player.mo.y+sin(player.mo.hummingtop_angle)*ARROW_DIST, getMiddle(player.mo, mobjinfo[MT_DUST].height), MT_DUST)
		applyFlip(player.mo, player.mo.hummingtop_arrow)
		player.mo.hummingtop_arrow.angle = player.mo.hummingtop_angle
		player.mo.hummingtop_arrow.fuse = (B.Console.HTop_Commit.value)
		player.mo.hummingtop_arrow.colorized = true
		player.mo.hummingtop_arrow.color = player.skincolor
		player.mo.hummingtop_arrow.state = S_INVISIBLE
		player.mo.hummingtop_arrow.sprite = SPR_LCKN
		player.mo.hummingtop_arrow.frame = _G["C"]|FF_PAPERSPRITE
		player.mo.hummingtop_arrow.rollangle = ANGLE_90
		player.mo.hummingtop_arrow.renderflags = RF_FULLBRIGHT*/
		--This function is just a trigger for the main hook
		player.mo.hummingtop_state = state_spinning
		return true
	end
end


local state_superspinjump = 1
local state_groundpound_rise = 2
local state_groundpound_fall = 3
local state_superspinwave = 10 // new

function B.HummingTop_MainHook(player)
	if charParam(player) then --If we're valid
	
		local mo = player.mo

		local exhaust_chunk = ((G_GametypeUsesLives() and B.ArenaGametype()) and ((FRACUNIT/2)+(FRACUNIT/8))/2) or ((FRACUNIT/2)+(FRACUNIT/8))

		local humming = (mo.hummingtop_state == state_spinning)
		local grounded = P_IsObjectOnGround(mo) or (mo.eflags & MFE_JUSTHITFLOOR)
		local hurt = P_PlayerInPain(player)
		local dead = (player.playerstate == PST_DEAD)
		local carry = (player.powers[pw_carry]) and ((player.powers[pw_carry] != CR_FAN) and (player.powers[pw_carry] != CR_BRAKGOOP))
		local gp = (player.actionstate == state_groundpound_rise) or (player.actionstate == state_groundpound_fall)
		local wave = (player.actionstate == state_superspinwave)
		local superspinjump = (player.actionstate == state_superspinjump)
		local airdodge = (player.airdodge >= 1)
		local ledge = (mo.state == S_PLAY_LEDGE_GRAB)
		local flag = player.gotflagdebuff
		local sprung = (mo.eflags & MFE_SPRUNG)
		local exhaust = (player.exhaustmeter <= 0)
		local tumble = player.tumble
		local dropdashable = (mo.dropdash_actionable~=nil) and not(humming)
		local dropdashing = (mo.dropdash_prep == 100)
		local inexhausted = (player.exhaustmeter > 0)
		local knux_grabbed = (mo and mo.tracer and mo.tracer.player and mo.tracer.player.kgrab and mo.tracer.player.kgrab.valid and (mo.tracer.player.kgrab == mo))
	

		local recoil = (((mo.recoilangle ~= nil) and (mo.recoilthrust ~= nil)) and true) or false
		local stasis_check = true

		if recoil then
			stasis_check = false
		end

		
		
		local recurlable = (mo.recurl_actionable == true)
		local spin = B.PlayerButtonPressed(player, BT_SPIN, false, stasis_check)
		local spin_held = B.PlayerButtonPressed(player, BT_SPIN, true, stasis_check)
		local jump = B.PlayerButtonPressed(player, BT_JUMP, false, stasis_check)

		local cancel = grounded or hurt or dead or carry or gp or wave or airdodge or ledge or exhaust or flag or tumble or knux_grabbed or (recoil and not(mo.hummingtop_hit))
		local dropdash_cancel = hurt or dead or carry or gp or airdodge or ledge or flag or tumble or knux_grabbed


		if flag or tumble or airdodge or carry or knux_grabbed then
			if humming then
				cancelHummingTop(player, false, player.gotflagdebuff)
				cancelDropDash(player.mo)
			end
			if dropdashing then
				cancelDropDash(player.mo)
			end
			return
		end


		if grounded or ledge then
			if dropdashing and not(dropdash_cancel) then
				mo.state = S_PLAY_ROLL
				player.pflags = $|PF_SPINNING
				S_StartSound(mo, sfx_zoom, player)
				local speed = abs(mo.dropdash_momz/2)+FixedHypot(player.rmomx,player.rmomy)
				local actionspd = player.actionspd+((player.actionspd/2)-3*FRACUNIT)
				if player.powers[pw_super] then
					actionspd = $*3/2
				end
				if mo.eflags&MFE_UNDERWATER then actionspd = $*2/3 end

				actionspd = FixedMul(mo.scale, $)

				P_InstaThrust(mo, mo.angle,max(actionspd,speed))

				if player.pflags & PF_ANALOGMODE then
					player.mo.angle = $
				end
				
				//Dust
				local function r(mo,value)
					local w = mo.radius/FRACUNIT/2
					return value+P_RandomRange(-w,w)*FRACUNIT
				end
				for n = 1,4
					local d = P_SpawnMobj(r(mo,mo.x),r(mo,mo.y),mo.z,MT_SPINDUST)
					d.extravalue1 = FRACUNIT
					d.extravalue2 = FRACUNIT
					if P_MobjFlip(mo) == -1 then
						d.eflags = $|MFE_VERTICALFLIP
					end
					P_SetObjectMomZ(d,FRACUNIT*2)
					local l = 90*n/4
					P_InstaThrust(d,mo.angle+ANGLE_135+l*ANG1,actionspd/2)
				end
			end
			cancelDropDash(mo)
			mo.recurl_actionable = nil
		end

		if humming then
			if cancel then
				cancelHummingTop(player, true, flag)
				cancelDropDash(mo)
				return
			end
			if recurlable and spin and inexhausted and not(cancel) then
				if not(mo.hummingtop_beyblade)
					player.exhaustmeter = max(1, $-exhaust_chunk)
				end
				cancelHummingTop(player, false, flag)
				player.pflags = ($|PF_JUMPED) & ~(PF_NOJUMPDAMAGE|PF_SPINNING|PF_THOKKED|PF_SHIELDABILITY)
				S_StartSound(mo, sfx_zoom)
				mo.state = S_PLAY_ROLL
				mo.dropdash_actionable = 0
				mo.recurl_actionable = nil
				mo.hummingtop_hit = nil
			end
		end

		if dropdashable and not(cancel) then
			if spin_held then
				if (mo.dropdash_prep or 0) < 100
					mo.dropdash_prep = ($==nil and 100/10) or $+100/10
					if mo.dropdash_prep >= 100
						S_StartSound(mo, sfx_drpdsh)
						mo.dropdash_prep = 100
					end
				end
				if (mo.dropdash_prep == 100) then
				
					local mo = mo

					local zheight = mo.z - FixedDiv(P_GetPlayerHeight(player) - mo.height, 3*FRACUNIT)
					if (mo.eflags & MFE_VERTICALFLIP)
						zheight = mo.z + mo.height + FixedDiv(P_GetPlayerHeight(player) - mo.height, 3*FRACUNIT) - FixedMul(mobjinfo[MT_THOK].height, mo.scale)
					end
					
					if (not (mo.eflags & MFE_VERTICALFLIP)
					and (zheight < mo.floorz)
					and not (mobjinfo[MT_THOK].flags & MF_NOCLIPHEIGHT))
						zheight = mo.floorz
					elseif (mo.eflags & MFE_VERTICALFLIP and zheight + FixedMul(mobjinfo[MT_THOK].height, mo.scale) > mo.ceilingz and not (mobjinfo[MT_THOK].flags & MF_NOCLIPHEIGHT))
						zheight = mo.ceilingz - FixedMul(mobjinfo[MT_THOK].height, mo.scale)
					end
					
					local trail = P_SpawnGhostMobj(mo)
					P_MoveOrigin(trail, trail.x, trail.y, zheight)
					trail.fuse = 30
					trail.state = S_THOK
					trail.frame = TR_TRANS70|A
					trail.destscale = 0
					trail.spritexscale = mo.spritexscale
					trail.spriteyscale = mo.spriteyscale

					mo.dropdash_momz = mo.momz
					mo.frame = 0
					mo.sprite = SPR_PLAY
					mo.sprite2 = SPR2_DRPD
					mo.dropdash_actionable = (($<(skins[mo.skin].sprites[SPR2_DRPD].numframes)-1) and $+1) or 0
					mo.frame = mo.dropdash_actionable
				end
				if humming or sprung then
					cancelDropDash(mo)
				end
			elseif spin
				mo.state = S_PLAY_JUMP
				player.pflags = $ & ~PF_SHIELDABILITY
				cancelDropDash(mo)
			else
				cancelDropDash(mo)
			end
		elseif cancel then
			cancelDropDash(mo)
			if not(grounded or ledge) then
				player.pflags = $|PF_THOKKED
			end
		end

			
		



			
		if mo.hummingtop_arrow and mo.hummingtop_arrow.valid then
			applyFlip(mo, mo.hummingtop_arrow)
			P_MoveOrigin(mo.hummingtop_arrow, mo.x+cos(mo.hummingtop_angle)*ARROW_DIST, mo.y+sin(mo.hummingtop_angle)*ARROW_DIST, getMiddle(mo, mo.hummingtop_arrow.height))
		end

		if mo.hummingtop_state == state_spinning then --Launching?
			--Launch forwards and upwards, so Sonic can't just thok into the ground

			if player.glidetime == 1 then
				player.glidetime = (B.Console.HTop_Commit.value)+2
			end

			if mo.hummingtop_overlay and mo.hummingtop_overlay.valid then
				mo.hummingtop_overlay.renderflags = $|RF_FULLBRIGHT
				mo.hummingtop_overlay.blendmode = AST_ADD
				applyFlip(mo, mo.hummingtop_overlay)
				mo.hummingtop_overlay.dispoffset = 3
				P_MoveOrigin(mo.hummingtop_overlay, mo.x, mo.y, getMiddle(mo, mobjinfo[MT_DUST].height))
				mo.hummingtop_overlay.fuse = max($, 2)
				mo.hummingtop_overlay.scale = (mo.scale) + (mo.scale)/2
				--mo.hummingtop_overlay.colorized = G_GametypeHasTeams()
				mo.hummingtop_overlay.color = windcolor(player)
				if mo.hummingtop_overlay.state != S_HUMMINGTOP then
					mo.hummingtop_overlay.state = S_HUMMINGTOP
				end
				if mo.state ~= S_SONIC_HUMMINGTOP then
					mo.state = S_SONIC_HUMMINGTOP
				end
				if not(player.hitbox) then
					local hitbox = B.BattleHitboxSpawn(player, 1*player.mo.scale, 12*player.mo.scale, 2, S_SONIC_HUMMINGTOP, true, 0)	
					hitbox.radius = 40*player.mo.scale
				end
				if mo.hummingtop_drawangle ~= nil then
					player.drawangle = mo.hummingtop_drawangle
					mo.hummingtop_drawangle = $-ANGLE_45
				end
			end
			
			if (player.glidetime > 2) and (player.glidetime <= (B.Console.HTop_Commit.value)+2) then
				player.pflags = $|PF_STASIS
				mo.momz = 0
				player.cmd.angleturn = player.realangleturn
				player.glidetime = $-1
			elseif player.glidetime == 2 then
				B.SpawnFlash(mo, 10, false)
				if mo.hummingtop_overlay and mo.hummingtop_overlay.valid then
					local ghost = P_SpawnGhostMobj(mo.hummingtop_overlay)
					ghost.tics = 10
					ghost.colorized = true
				end
				S_StartSound(mo, sfx_s3k42)
				player.glidetime = 0
				player.pflags = $ & ~PF_STASIS
			end
		end
	end
end
		
		
--Rebound Dash Bounce
--This addon is marked as reusable, so do what you want with it. ~Krabs

--Dash
local DASHSPD = 48 * FRACUNIT
local DASHLENGTH = 24
local DASHZPERCENT = 50

--Factors
local WATERFACTOR = FRACUNIT * 2/3
local SUPERFACTOR = FRACUNIT * 7/4

--Wall bounce vertical
local WALLBOUNCEZ = 11 * FRACUNIT
local WEAKWALLBOUNCEZ = 4 * FRACUNIT
local NOCLWALLBOUNCEZ = 3 * FRACUNIT
local SECONDBOUNCEZMULT = 118

--Wall bounce thrust in wall direction
local WALLTHRUST = 5 * FRACUNIT
local WEAKWALLTHRUST = FRACUNIT / 5
local NOCLIMBWALLTHRUST = 3 * FRACUNIT

--Wall bounce horizontal
local BOUNCEPERCENT = 17
local WEAKBOUNCEPERCENT = 3

--FixedLerp
local function FixedLerp(a, b, w)
    return FixedMul((FRACUNIT - w), a) + FixedMul(w, b)
end

--Functions needed to do the bounce calculations (these could also be used to allow bounces off of sloped terrain, but I don't think we need to do that for this ability)
local function SphereToCartesian(alpha, beta)
	local t = {}

	t.x = FixedMul(cos(alpha), cos(beta))
	t.y = FixedMul(sin(alpha), cos(beta))
	t.z = sin(beta)

	return t
end

local function FixedDotProduct3D(a, b)
	return FixedMul(a.x, b.x) + FixedMul(a.y, b.y) + FixedMul(a.z, b.z)
end

local function FixedScalar3D(vect, scalar)
	local vect2 = {}
	vect2.x = FixedMul(vect.x, scalar)
	vect2.y = FixedMul(vect.y, scalar)
	--vect2.z = FixedMul(vect.z, scalar)
	vect2.z = vect.z
	
	return vect2
end

local function Percent3D(vect, percent)
	local vect2 = {}
	vect2.x = vect.x * percent / 100
	vect2.y = vect.y * percent / 100
	--vect2.z = FixedMul(vect.z, scalar)
	vect2.z = vect.z
	
	return vect2
end

local function VectAdd3D(vecta, vectb)
	local vsum = {}
	vsum.x = vecta.x + vectb.x
	vsum.y = vecta.y + vectb.y
	vsum.z = vecta.z + vectb.z
	
	return vsum
end

local function VectorBounce(mo,vmom,vslopenorm,percent)
	local player = mo.player
	if (player == nil) or (player.playerstate != PST_LIVE) return end
	
	local vbounce = Percent3D(VectAdd3D(FixedScalar3D(FixedScalar3D(vslopenorm, FixedDotProduct3D(vmom,vslopenorm)), -2 * FRACUNIT), vmom), percent)
	
	mo.momx = vbounce.x
	mo.momy = vbounce.y
	mo.momz = vbounce.z
end

local param = function(player)
	return player 
	and player.mo 
	and player.mo.valid 
	and (
			(player.mo.hummingtop_state == state_spinning)
		 --or (player.actionstate == state_superspinjump)
	)
end

B.Sonic_HTopLineCollide = function(mo, line)
	local player = mo.player
	if (player == nil) or (player.playerstate != PST_LIVE) return end
	if not (param(player)) return end
	
	--Horizon line
	if line.special == 41 return end
	
	--Set the bounceline so we can bounce off it later in case that line actually blocked the player from moving
	local side = P_PointOnLineSide(mo.x,mo.y,line)
	local sector = nil
	
	--One-sided walls
	if line.backsector == nil
		player.bounceline = line
		player.bounceside = 0
		return
	end
	if line.frontsector == nil
		player.bounceline = line
		player.bounceside = 1
		return
	end
	
	--Which side are we hitting the wall from?
	if side == 1
		sector = line.frontsector
	else
		sector = line.backsector
	end
	
	--Impassible line
	if (line.flags & ML_IMPASSIBLE) and line.frontside.midtexture
		player.bounceline = line
		player.bounceside = side
		return
	end
	
	if sector == nil return end
	
	--Polyobject
	for i = 0, #sector.lines
		local li = sector.lines[i]
		if li == nil continue end
		
		if li.special == 20--First line of polyobject
			local topheight = sector.ceilingheight
			local bottomheight = sector.floorheight
			
			if (topheight < mo.z)
				return
			end

			if (bottomheight > mo.z + mo.height)
				return
			end

			player.bounceline = line
			player.bounceside = side
			return
		end
	end
	
	--Standard
	local ceilz = sector.ceilingheight
	if sector.c_slope
		ceilz = P_GetZAt(sector.c_slope, mo.x, mo.y)
	end
	if (ceilz < mo.z + mo.height)
		if sector.ceilingpic != "F_SKY1"
			player.bounceline = line
			player.bounceside = side
		end
		return
	end
	local floorz = sector.floorheight
	if sector.f_slope
		floorz = P_GetZAt(sector.f_slope, mo.x, mo.y)
	end
	if (floorz > mo.z)
		player.bounceline = line
		player.bounceside = side
		return
	end
	
	--FOF
	for rover in sector.ffloors()
		if not (rover.flags & FF_EXISTS) or not (rover.flags & FF_BLOCKPLAYER)
			continue
		end

		local topheight = rover.topheight
		local bottomheight = rover.bottomheight

		if (rover.t_slope)
			topheight = P_GetZAt(rover.t_slope, mo.x, mo.y)
		end
		if (rover.b_slope)
			bottomheight = P_GetZAt(rover.b_slope, mo.x, mo.y)
		end

		if (topheight < mo.z)
			continue
		end

		if (bottomheight > mo.z + mo.height)
			continue
		end
	
		player.bounceline = line
		player.bounceside = side
		if (rover.flags & FF_BUSTUP) and not (rover.flags & FF_STRONGBUST)
			player.bustsector = sector
			player.bustrover = rover
		end
		break
	end
	
	--Solid midtexture
	--TODO: once textures[] is exposed to lua, change this so it properly checks the height of a solid midtexture and decides if it's blocking the player or not.
	if (line.flags & ML_EFFECT4) and line.frontside.midtexture
		player.bounceline = line
		player.bounceside = side
		return
	end
end--, MT_PLAYER)

local function DoWallBounce(mo,player,wallnormangle,walltype,side,reflect,fxonly)
	--Wall type
	local bouncy = (walltype == 2)
	local hbouncy = (walltype == 3)
	local vbouncy = (walltype == 4)
	local nocl = (walltype == 1)

	--Hold jump button for better bounce, don't hold for small bounce
	local bigbounce = true--(player.pflags & PF_JUMPDOWN)
	local dropdash = (mo.dropdash_prep == 100)-- or (player.actionstate == state_superspinjump)
	
	--Calculate angle
	local vwallnorm = SphereToCartesian(wallnormangle, 0)
	
	--Noclimb wall
	if nocl
		bigbounce = false
		S_StartSound(mo,sfx_s3k9e)
	end
	
	--Bounce stats based on the situation
	local percent = BOUNCEPERCENT
	if not bigbounce
		percent = WEAKBOUNCEPERCENT
	end
	local bouncez = WEAKWALLBOUNCEZ
	
	--Hold jump button for better bounce, don't hold for small bounce
	if bigbounce and not nocl
		bouncez = FixedMul(mo.scale, WALLBOUNCEZ)
	elseif nocl
		bouncez = FixedMul(mo.scale, NOCLWALLBOUNCEZ)
	end
	
	--Screenshake
	if player == consoleplayer and (bigbounce or nocl) and not(dropdash or fxonly)
		local shake = 12
		local shaketics = 3
		if player.powers[pw_super]
			shake = 18
			shaketics = 5
		end
		P_StartQuake(shake * FRACUNIT, shaketics)
	end
	
	--mobj momentum vector
	local vmom = {}
	vmom.x = mo.momx
	vmom.y = mo.momy
	vmom.z = mo.momz
	
	--Reset jump flags
	player.pflags = $ & ~PF_JUMPED
	
	local weak = false
	if not bigbounce and not nocl and not dropdash then
		--Weak bump sfx
		S_StartSoundAtVolume(mo,sfx_s3k5d,155)
		weak = true
	end
	
	--Wallthrust (the strength of momentum applied in the direction of the wall norm)
	local wallth = FixedMul(mo.scale, WALLTHRUST)
	if not bigbounce
		wallth = FixedMul(mo.scale, WEAKWALLTHRUST)
	end
	if nocl
		wallth = FixedMul(mo.scale, NOCLIMBWALLTHRUST)
	end

	
	--Wall type
	
	if bouncy
		S_StartSound(mo,sfx_s3k87)
		bouncez = $ + 6*mo.scale
		percent = $ + 6
	end
	if hbouncy
		wallth = $ + 40*mo.scale
		S_StartSound(mo,sfx_cdfm74)
	end
	if vbouncy
		wallth = $ / 2
		percent = $ / 4
		bouncez = $ + 11*mo.scale
		S_StartSound(mo,sfx_cdfm62)
	end
	
	--Do the horizontal bounce
	if reflect == 1 and not(fxonly)
		VectorBounce(mo,vmom,vwallnorm,percent)
		if side == 1
			P_Thrust(mo, wallnormangle, wallth)
			player.drawangle = wallnormangle
		else
			P_Thrust(mo, wallnormangle, -wallth)
			player.drawangle = wallnormangle + ANGLE_180
		end
	end
	
	--Reset stuff
	player.bounceline = nil
	player.dashticsleft = nil
	
	--Vertical boost
	if mo.eflags & MFE_UNDERWATER
		bouncez = FixedMul($, WATERFACTOR)
	end
	if player.powers[pw_super]
		bouncez = FixedMul($, SUPERFACTOR)
	end

	if not(fxonly) then
		if mo.eflags & MFE_VERTICALFLIP
			mo.momz = min($,-bouncez)
		else
			mo.momz = max($,bouncez)
		end
	end
	
	--Wallbounce dust
	if nocl
		local dustcount = 6
		while dustcount > 0
			dustcount = $ - 1
			local dust = P_SpawnMobjFromMobj(mo, 0, 0, mo.scale * 18, MT_SPINDUST)
			dust.state = S_MINECARTSPARK
			dust.momx = (mo.momx * 3) + (P_RandomRange(-20,20) * FRACUNIT)
			dust.momy = (mo.momy * 3) + (P_RandomRange(-20,20) * FRACUNIT)
			dust.momz = P_RandomRange(-3,3) * FRACUNIT
			dust.scale = FRACUNIT * P_RandomRange(50,125) / 100
			dust.destscale = 0
			dust.angle = P_RandomRange(0,ANGLE_180)
			dust.fuse = 10
		end
	else
		local dustcount = 10
		if not bigbounce
			dustcount = 5
		end
		while dustcount > 0
			dustcount = $ - 1
			local dust = P_SpawnMobjFromMobj(mo, 0, 0, mo.scale * 18, MT_SPINDUST)
			dust.momx = (mo.momx * 2) + (P_RandomRange(-10,10) * FRACUNIT)
			dust.momy = (mo.momy * 2) + (P_RandomRange(-10,10) * FRACUNIT)
			dust.momz = P_RandomRange(-3,3) * FRACUNIT
			dust.scale = FRACUNIT * P_RandomRange(50,125) / 100
			dust.destscale = 0
			dust.color = mo.color
			dust.colorized = true
		end
	end
	
	if bigbounce
		--Wallbounce big puff of smoke
		local boom = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SPINDUST)
		boom.state = S_XPLD3
		boom.colorized = true
		boom.color = mo.color
	end
		
	--Wallbounce circle effect
	local circle = P_SpawnMobjFromMobj(mo, 0, 0, mo.scale * 19, MT_REBOUND)
	circle.angle = wallnormangle + ANGLE_90
	circle.fuse = 9
	circle.scale = 0
	circle.destscale = 10*FRACUNIT
	circle.color = mo.color
	circle.colorized = true
	
	if not bigbounce
		circle.fuse = 6
	end

	if not(fxonly) then
		player.glidetime = ($>2 and 2) or 0
		player.mo.recurl_actionable = true
		local exhaust_chunk = ((G_GametypeUsesLives() and B.ArenaGametype()) and ((FRACUNIT/2)+(FRACUNIT/8))/2) or ((FRACUNIT/2)+(FRACUNIT/8))
		player.exhaustmeter = max(0, $-exhaust_chunk)
		if player.mo.hummingtop_arrow and player.mo.hummingtop_arrow.valid then
			P_RemoveMobj(player.mo.hummingtop_arrow)
			player.mo.hummingtop_arrow = nil
		end
		cancelDropDash(mo)
	end
	S_StartSound(mo, sfx_bounc1)
end

B.Sonic_HTopMoveBlocked = function(mo)
	local player = mo.player
	if not (param(player)) return end
	local line = player.bounceline
	if not(line and line.valid) then return end

	--Noclimb walls result in a super weak bounce
	local nocl = player.bounceline.flags & ML_NOCLIMB
	
	--Bustable FOFs are busted
	if player.bustsector and player.bustrover then
		EV_CrumbleChain(player.bustsector, player.bustrover)
		player.bustsector = nil
		player.bustrover = nil
	end
	
	if nocl
		nocl = 1
	end
	local wallnormangle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y) + ANGLE_90
	DoWallBounce(mo,player,wallnormangle,nocl,player.bounceside,1)
end--, MT_PLAYER)

--unskinny hop hop hop
--all night and day

function B.Sonic_PreCollide(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1] and mo[n1] and mo[n1].valid and (mo[n1].hummingtop_state == state_spinning) then

		if not(mo[n1].hummingtop_marker) then
			mo[n1].hummingtop_marker = {}
		end

		mo[n1].hummingtop_marker.xyspeed = {mo[n1].momx, mo[n1].momy}

		if plr[n2] and mo[n2] and mo[n2].valid and (mo[n2].hummingtop_state == state_spinning) then
			if not(mo[n1].hummingtop_marker) then
				mo[n1].hummingtop_marker = {}
			end
			mo[n1].hummingtop_marker.beyblade = true
		end	
	end
end

function B.Sonic_PostCollide(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1] and mo[n1] and mo[n1].valid and mo[n1].hummingtop_marker then

		local sonic_xyspeed = mo[n1].hummingtop_marker.xyspeed
		local beyblade = mo[n1].hummingtop_marker.beyblade
		mo[n1].hummingtop_marker = nil


		local bump = (hurt == 0)
		local hit = (hurt == 1)
		local clash = (hurt == 2)
		local fail  = (hurt == -1)


		if not(clash) then
			--Thrust sonic away
			P_InstaThrust(mo[n1], angle[n1], (mo[n1].scale*10) / B.WaterFactor(mo[n1]))
			B.ZLaunch(mo[n1], 7 * mo[n1].scale, false)
			if hit then
				DoWallBounce(mo[n1], plr[n1], angle[n2], 0, nil, nil, true)
				mo[n1].recurl_actionable = true
				mo[n1].air_recoilanim_override = true
				mo[n1].hummingtop_hit = true
				mo[n1].recoilthrust = nil
				mo[n1].recoilangle = nil
				plr[n1].powers[pw_nocontrol] = 0
				P_InstaThrust(mo[n2], angle[n2], FixedHypot(sonic_xyspeed[1], sonic_xyspeed[2])/3)
			elseif bump then
				if (plr[n2]) and not(beyblade) then
					cancelHummingTop(plr[n1], false, plr[n1].gotflagdebuff)
					mo[n1].hummingtop_hit = nil
					mo[n1].recurl_actionable = nil
					mo[n1].air_recoilanim_override = nil
					P_InstaThrust(mo[n2], angle[n2], FixedHypot(sonic_xyspeed[1], sonic_xyspeed[2])/3)
				else
					P_InstaThrust(mo[n2], angle[n2], FixedHypot(sonic_xyspeed[1], sonic_xyspeed[2])/3)
					mo[n1].hummingtop_hit = true
					mo[n1].recurl_actionable = true
					mo[n1].air_recoilanim_override = true
					DoWallBounce(mo[n1], plr[n1], angle[n2], 1, nil, nil, true)
					if beyblade then
						S_StartSound(mo[n1], sfx_tink)
						S_StartSound(mo[n1], sfx_htok)
						mo[n1].hummingtop_beyblade = true
						mo[n1].recurl_actionable = true
						mo[n1].air_recoilanim_override = true
						mo[n1].hummingtop_hit = true
						mo[n1].recoilthrust = nil
						mo[n1].recoilangle = nil
						plr[n1].powers[pw_nocontrol] = min($, 1)

						S_StartSoundAtVolume(mo[n1],sfx_s3k9b,70)


						if not(mo[n1].hummingtop_beyblade_pick) then
							local picks = {n1, n2}
							local pick = picks[P_RandomRange(1,#picks)]
							local vfx = P_SpawnMobjFromMobj(mo[pick], 0, 0, mo[pick].height/2, MT_SPINDUST)
							if vfx.valid
								vfx.scale = mo[pick].scale/2
								vfx.destscale = vfx.scale * 2
								vfx.colorized = true
								vfx.color = plr[pick].skincolor
								vfx.blendmode = AST_ADD
								vfx.state = S_BCEBOOM
							end
							mo[n1].hummingtop_beyblade_pick = true
							mo[n2].hummingtop_beyblade_pick = true
						end
					end
				end
			end

			plr[n1].glidetime = 2 --Commit time ends

			local exhaust_chunk = ((G_GametypeUsesLives() and B.ArenaGametype()) and ((FRACUNIT/2)+(FRACUNIT/8))/2) or ((FRACUNIT/2)+(FRACUNIT/8))
			if not(beyblade) then
				plr[n1].exhaustmeter = max(0, $-exhaust_chunk)
			end

			--collisiontype = (bump and 1) or 3
			mo[n1].hummingtop_marker = nil

		end
		return
	end
end
