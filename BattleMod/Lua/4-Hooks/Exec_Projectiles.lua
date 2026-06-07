local B = CBW_Battle

--Player v player projectile
addHook("ShouldDamage", function(target,inflictor,source,something,idk)
	if gamestate ~= GS_LEVEL then return end -- won't work outside a level
	if not(target.player and inflictor and inflictor.valid and source and source.valid and source.player)
	return end
	
	if inflictor.type == MT_SPINFIRE
	and not(target.player.powers[pw_shield]&SH_PROTECTFIRE)
	and not(target.player.powers[pw_flashing] or target.player.powers[pw_super] or target.player.powers[pw_invulnerability])
	and not(B.MyTeam(target.player,source.player))
		return true
	end
end,MT_PLAYER)

--Player v player projectile
for n = 1, #mobjinfo-1 do
	
	local mt = n-1
	local info = mobjinfo[mt]
	
	if info.flags & MF_MISSILE == 0
		continue
	end
	
	addHook("MobjMoveCollide", function(tmthing,thing)
		if not(tmthing and tmthing.valid and tmthing.flags&MF_MISSILE
			and tmthing.target and tmthing.target.valid
			and tmthing.target.player and tmthing.target.player.valid
			and thing and thing.valid and thing.player and thing.player.valid)
			
			return
		end
		--Fix for teammates interacting at all with teammate projectiles
		if B.MyTeam(tmthing.target.player,thing.player)
			and not tmthing.cantouchteam
			return false
		end
		--Projectile intangibility
		if thing.player.intangible
			return false
		end
	end, mt)
	
	addHook("MobjThinker",function(mo) 
		if not(mo and mo.valid and mo.flags & MF_MISSILE) then return end
		--Master underwater/2D check
		B.UnderwaterMissile(mo)
		B.TwoDMissile(mo)
	end, mt)
	
end



--Sonic ground pound
local gp = function(mo)
	mo.hit_sound = sfx_hit00
	mo.block_stun = 4
	mo.block_sound = sfx_s3k49
	mo.block_hthrust = 2
	mo.block_vthrust = 6
end
addHook("MobjSpawn", gp, MT_GROUNDPOUND)
addHook("MobjSpawn", gp, MT_GP_SHOCKWAVE)
B.InstaFlip2 = function(inst)
	if inst.target then
		if (inst.target.eflags & MFE_VERTICALFLIP) then
			inst.rollangle = ANGLE_180
		else
			inst.rollangle = 0
		end
	end
end
local gpshockwavethinker = function(mo)
	B.InstaFlip2(mo)
	B.SafeRadiusIncrease(mo, 48*FRACUNIT)
end
addHook("MobjThinker", gpshockwavethinker, MT_GP_SHOCKWAVE)
addHook("MobjThinker", function(mo) B.SafeRadiusIncrease(mo, 48*FRACUNIT) end, MT_GROUNDPOUND)

--Tails Projectiles
addHook("MobjThinker",function(mo)
	if not(mo.flags&MF_SPECIAL) then return end

	-- aircutter circling thingy
	local t = mo.target
	local x = mo.x
	local y = mo.y
	local aircutter = t and t.player and t.player.aircutter and mo == t.player.aircutter
	if aircutter then
		local p = t.player
		local distancescaling = mo.cutterspeed*2/5
		local BOOMERANGTIME = max(6,distancescaling/2/FRACUNIT)
		
		p.pflags = $ | PF_STASIS
		if p.actiontime > BOOMERANGTIME then
			local returnfactor = p.actiontime <= BOOMERANGTIME+2 and 1 or 2
			p.aircutter_distance = max(1,$-(distancescaling*returnfactor))
		else
			p.aircutter_distance = $+distancescaling
		end
		
		mo.radius = mobjinfo[MT_SONICBOOM].radius
		if P_MobjFlip(mo) > 0 then
			P_MoveOrigin(mo, t.x, t.y, t.z + (t.height/2))
		else
			P_MoveOrigin(mo, t.x, t.y, t.z)
		end

		local angle = ANGLE_45 * p.actiontime
		local dist = p.aircutter_distance
		x = t.x+P_ReturnThrustX(mo,angle,dist)
		y = t.y+P_ReturnThrustY(mo,angle,dist)
		local thrust = max(FRACUNIT*60, R_PointToDist2(mo.x, mo.y, x, y))
		P_InstaThrust(mo, R_PointToAngle2(mo.x, mo.y, x, y), thrust)

		B.SafeRadiusIncrease(mo, 32*FRACUNIT, mobjinfo[MT_SONICBOOM].radius, true)
	else
		B.SafeRadiusIncrease(mo, 32*FRACUNIT)
		-- keep it fast, sliding along walls if needed
		if FixedHypot(mo.momx, mo.momy) < FixedMul(mo.scale, mobjinfo[MT_SONICBOOM].speed) then
			mo.momx = $ * 6/5
			mo.momy = $ * 6/5
		end
	end

	local transition = (aircutter and 5 or 10)
	if mo.fuse == transition then
		mo.destscale = 0
		mo.scalespeed = FRACUNIT/transition
	end
	
	-- vfx
	local col = SKINCOLOR_SKY
	if t and not(t.color == SKINCOLOR_ORANGE) then
		col = t.color
	end
	mo.color = col

	local ghost = P_SpawnGhostMobj(mo) --P_SpawnMobj(x, y, mo.z, MT_GHOST)
	P_MoveOrigin(ghost, x, y, mo.z)
	ghost.colorized = true
	ghost.color = col
	ghost.fuse = TICRATE/3
	ghost.destscale = (aircutter and mo.fuse >= transition) and ghost.scale*3/2 or ghost.scale*5/4
	ghost.scalespeed = ghost.destscale/ghost.fuse
	ghost.frame = mo.frame | FF_FULLBRIGHT 

	local s = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SPARK)
	s.scale = $*3/4
	if P_RandomRange(0,1) then
		s.colorized = true
		s.color = col
	end
	local radius = mo.radius/FRACUNIT
	local r = do
		return P_RandomRange(-radius,radius)*FRACUNIT
	end
	x = x+(r())
	y = y+(r())
	local z1 = (s.flags2 & MF2_OBJECTFLIP) and s.ceilingz or s.floorz
	P_MoveOrigin(s, x, y, mo.z)
	local z2 = (s.flags2 & MF2_OBJECTFLIP) and s.ceilingz or s.floorz
	if abs(z1 - z2) > mo.height then
		s.flags2 = $ | MF2_DONTDRAW
	end
end,MT_SONICBOOM)
addHook("TouchSpecial",B.SwipeTouch,MT_SONICBOOM)

local slasheffect = function(target)
	local slash = P_SpawnMobjFromMobj(target, 0, 0, (target.height/2)*P_MobjFlip(target), MT_THOK)
	slash.state = S_SLASH
	slash.dispoffset = 2
	slash.scale = $*3/2
	S_StartSound(target, sfx_hit02)
end

addHook("MobjSpawn",function(mo)
	mo.hit_sound = slasheffect
end,MT_SONICBOOM)

addHook("MobjMoveCollide",function(mover,collide)
	if ((collide.flags & MF_MONITOR) or (collide.flags & MF_ENEMY) or (collide.flags & MF_BOSS))
	and B.ZCollide(mover, collide)
	then
		slasheffect(collide)
		P_DamageMobj(collide, mover, mover.target)
	end
	if not(collide.battleobject) then return end
	B.SwipeTouch(mover,collide)
end,MT_SONICBOOM)


--Knux rocks
addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_hit00
	mo.blockable = 1
	mo.block_stun = 2
	mo.block_sound = sfx_s3k49
	mo.block_hthrust = 3
	mo.block_vthrust = 3
end,MT_ROCKBLAST)

local hearteffect = function(target)
	local heart = P_SpawnMobjFromMobj(target, 0, 0, target.height*P_MobjFlip(target), MT_THOK)
	if heart and heart.valid then
		heart.state = S_LHRT
		local g = P_SpawnGhostMobj(heart)
		if g and g.valid then
			g.fuse = TICRATE*2/3
			g.blendmode = AST_ADD
			g.destscale = g.scale * 2
			g.scalespeed = FRACUNIT/8
			g.colorized = true
			g.color = SKINCOLOR_PITCHROSY
		end
		P_RemoveMobj(heart)
	end
	S_StartSound(target, sfx_hit03)
end
--Amy love hearts
addHook("MobjSpawn",function(mo)
	if mo.valid
		mo.hit_sound = hearteffect
		mo.cantouchteam = true
		mo.blockable = 1
		mo.block_stun = 3
		--mo.block_sound = sfx_s3kb5
		mo.block_hthrust = 6
		mo.block_vthrust = 2
		mo.spawnfire = true
	end
end,MT_LHRT)
addHook("MobjThinker",function(mo)
	if mo.cusval then
		P_SpawnGhostMobj(mo)
		P_SetObjectMomZ(mo, gravity/2, true)
	end
end,MT_LHRT)
addHook("MobjSpawn",function(mo)
	if mo.valid
		mo.hit_sound = sfx_hit03
		mo.cantouchteam = true
		mo.blockable = 1
		mo.block_stun = 6
		--mo.block_sound = sfx_s3kb5
		mo.block_hthrust = 7
		mo.block_vthrust = 5
		mo.spawnfire = true
	end
end,MT_PIKOWAVEHEART)
addHook("MobjMoveCollide", function(mover,collide) if collide and (collide.battleobject or not(collide.flags&MF_SOLID)) then return end end, MT_PIKOWAVE)
addHook("MobjMoveBlocked", function(mo)
	--mo.fuse = max(1, $ - 9)
	S_StartSound(mo,sfx_nbmper)
end, MT_PIKOWAVE)
addHook("MobjThinker", function(mo)
	if mo.grow
		mo.scale = $ + FRACUNIT/45
	end
	mo.momx = $ * mo.friction / 100
	mo.momy = $ * mo.friction / 100
	mo.momz = $ - (P_MobjFlip(mo) * mo.scale/2)
end, MT_PIKOWAVEHEART)
addHook("MobjThinker", B.PikoWaveThinker, MT_PIKOWAVE)


--Piko tornado
addHook("TouchSpecial",B.DustDevilTouch,MT_DUSTDEVIL)
addHook("MobjMoveCollide",function(mover,collide)
	if collide.flags & MF_MONITOR and B.ZCollide(mover, collide) then
		P_DamageMobj(collide, mover, mover.target)
	end
	if not(collide.battleobject) then return end
	B.DustDevilTouch(mover,collide)
end,MT_DUSTDEVIL)
addHook("MobjThinker",B.DustDevilThinker, MT_DUSTDEVIL_BASE)
addHook("MobjSpawn",B.SwirlSpawn,MT_SWIRL)
addHook("MobjThinker",B.SwirlThinker, MT_SWIRL)
addHook("MobjSpawn",B.DustDevilSpawn,MT_DUSTDEVIL_BASE)


--Fang
addHook("MobjSpawn",function(mo)
	if mo.valid
		mo.hit_sound = sfx_hit04
		mo.blockable = 1
		mo.block_stun = 10
		--mo.block_sound = sfx_s3kb5
		mo.block_hthrust = 10
		mo.block_vthrust = 5
		mo.spawnfire = true
	end
	return true --Overwrite default behavior so that corks won't damage invulnerable players
end,MT_CORK)
addHook("MobjThinker",function(mo)
	if mo.flags&MF_MISSILE and mo.target and mo.target.player then
		local ghost = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_GHOST)
		ghost.fuse = TICRATE/4
		ghost.state = mo.state
		ghost.angle = mo.angle
		ghost.sprite = mo.sprite
		ghost.frame = mo.frame
		ghost.frame = $|TR_TRANS50 
		ghost.tics = -1
		ghost.destscale = ghost.scale*4
		if not(gametyperules&GTR_FRIENDLY)
			ghost.colorized = true
			ghost.color = mo.target.player.skincolor
		end
		mo.corktime = (mo.corktime or 0)+1
		if mo.corktime >= TICRATE then
			mo.flags = $&~MF_NOGRAVITY
		end
	end
end,MT_CORK)


--Metal Sonic
addHook("MobjThinker",function(mo)
	mo.flags2 = $^^MF2_DONTDRAW
	-- If verticalflip is flipped on, keep claws flipped as well
	if (mo.eflags&MFE_VERTICALFLIP) then mo.flags2=$|MF2_OBJECTFLIP end
end,MT_SLASH)
addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_hit02
	mo.blendmode = AST_ADD
end,MT_SLASH)
local blasteffect = function(target)
	local zap = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_THOK)
	if zap and zap.valid then
		zap.state = S_CYBRAKDEMONELECTRICBARRIER_SPARK_RANDOM1 + P_RandomRange(0, 11)
		S_StopSound(zap)
		local g = P_SpawnGhostMobj(zap)
		if g and g.valid then
			P_SetOrigin(g, target.x, target.y, target.z)
			g.blendmode = AST_ADD
			g.destscale = g.scale * 3/2
			g.scalespeed = FRACUNIT/8
		end
	end
	S_StartSound(target, sfx_hit01)
end
addHook("MobjSpawn",function(mo)
	mo.hit_sound = blasteffect
end,MT_ENERGYBLAST)
addHook("MobjThinker",function(mo)
	B.SafeRadiusIncrease(mo, 24*FRACUNIT)

	if mo.tracer and mo.tracer.player then
		if not(S_SoundPlaying(mo, sfx_nblst)) then
			B.teamSound(mo, mo.tracer.player, sfx_nullba, sfx_nblst, 255, false)
		end
	end

end,MT_ENERGYBLAST)

addHook("MobjSpawn",function(mo)
	mo.flags2 = MF2_INVERTAIMABLE
end,MT_BOMBSPHERE)

--addHook("MobjCollide",B.BombSphereMissileCollide,MT_BOMBSPHERE)
--addHook("TouchSpecial",B.BombSphereTouch,MT_BOMBSPHERE)
addHook("MobjFuse",B.FBombDetonate,MT_FBOMB)
addHook("MobjMoveCollide",B.BombCollide,MT_FBOMB)
addHook("MobjSpawn",B.FBombSpawn,MT_FBOMB)
addHook("MobjThinker",B.FBombThink,MT_FBOMB)

--Other
addHook("MobjThinker",B.RockBlastObject,MT_ROCKBLAST)
addHook("MobjThinker",function(mo) if P_IsObjectOnGround(mo) and mo.valid then P_RemoveMobj(mo) return true end end,MT_ROCKCRUMBLE2)
addHook("ShouldDamage",B.PlayerCorkDamage,MT_PLAYER)
addHook("ShouldDamage",B.PlayerHeartCollision,MT_PLAYER)
addHook("ShouldDamage",B.PlayerBombDamage,MT_PLAYER)
addHook("ShouldDamage",B.PlayerRoboMissileCollision,MT_PLAYER)
addHook("MobjThinker",B.FireTrailThinker,MT_SPINFIRE)
addHook("ShouldDamage",B.FireTrailRingDrain, MT_PLAYER)
