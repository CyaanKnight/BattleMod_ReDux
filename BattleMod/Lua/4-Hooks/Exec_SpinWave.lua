local B = CBW_Battle
local CV = B.Console

//-------- spawn paper sprite effects for spin wave------------//
addHook("MobjSpawn", function(mo)
	
	if mo.rightwaves == nil and mo.target and mo.target.valid then
	S_StartSound(mo, sfx_s3k57)
	mo.centerwaves = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, MT_THOK)
	mo.centerwaves.state = S_SUPPERSPIN_WAVE1
	mo.centerwaves.angle = mo.angle
	mo.centerwaves.target = mo
	mo.centerwaves.color = SKINCOLOR_SKY
	mo.rightwaves = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, MT_THOK)
	mo.rightwaves.state = S_SUPPERSPIN_WALL1
	mo.rightwaves.angle = mo.angle
	mo.rightwaves.target = mo
	mo.rightwaves.color = SKINCOLOR_SKY
	mo.leftwaves = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, MT_THOK)
	mo.leftwaves.state = S_SUPPERSPIN_WALL1
	mo.leftwaves.angle = mo.angle
	mo.leftwaves.target = mo
	mo.leftwaves.color = SKINCOLOR_SKY
	end
end, MT_SUPERSPINWAVE)

//-------- spin wave thinker ------------//
addHook("MobjThinker", function(mo)

	if mo.rightwaves == nil and mo.target and mo.target.valid then
	S_StartSound(mo, sfx_s3k57)
	mo.centerwaves = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, MT_THOK)
	mo.centerwaves.state = S_SUPPERSPIN_WAVE1
	mo.centerwaves.angle = mo.angle
	mo.centerwaves.target = mo
	mo.centerwaves.color = SKINCOLOR_SKY
	mo.rightwaves = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, MT_THOK)
	mo.rightwaves.state = S_SUPPERSPIN_WALL1
	mo.rightwaves.angle = mo.angle
	mo.rightwaves.target = mo
	mo.rightwaves.color = SKINCOLOR_SKY
	mo.leftwaves = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, MT_THOK)
	mo.leftwaves.state = S_SUPPERSPIN_WALL1
	mo.leftwaves.angle = mo.angle
	mo.leftwaves.target = mo
	mo.leftwaves.color = SKINCOLOR_SKY
	end

		// prevent spawning into higher sectors!
	if mo.target and mo.target.valid and mo.spawntime <= 2  then
	local gravityflip = P_MobjFlip(mo)
	local ihatereversegravity = mo.target.z+mo.target.height
		if (gravityflip < 0 and mo.z+mo.height < ihatereversegravity) or (gravityflip > 0 and mo.z > ihatereversegravity) then
			P_RemoveMobj(mo)
			return
		end
	mo.spawntime = $+1
	elseif mo.target and mo.target.valid and mo.spawntime > 2 and mo.spawntime < 5  then
		mo.spawntime = 5
		P_Thrust(mo,mo.angle,mo.startingspeed)
		mo.flags = $|MF_MISSILE
	else
		mo.spawntime = $+1
	end
				
 if mo and mo.valid and mo.state == S_SUPPERSPIN_WAVE_ACTIVE  then
	mo.friction = 1*FRACUNIT

	local moveingspeed = FixedHypot(mo.momx, mo.momy)
	local forwardoffset = 20
	if mo.centerwaves and mo.centerwaves.valid and mo and mo.valid then
		local frontoffset = mo.radius/FRACUNIT
		A_CapeChase(mo.centerwaves, (0 * 65536)+0, (frontoffset * 65536)+0)
		mo.centerwaves.angle = (mo.angle-ANGLE_90)
		mo.centerwaves.color = mo.color
	end
	if mo.rightwaves and mo.rightwaves.valid and mo and mo.valid then
		local rightoffset = 20
		A_CapeChase(mo.rightwaves, (0 * 65536)+0, (forwardoffset * 65536)+rightoffset)
		mo.rightwaves.angle = mo.angle+ANG30
		mo.rightwaves.color = mo.color
	end
	if mo.leftwaves and mo.leftwaves.valid and mo and mo.valid then
		local leftoffset = -20
		A_CapeChase(mo.leftwaves, (0 * 65536)+0, (forwardoffset * 65536)+leftoffset)
		mo.leftwaves.angle = mo.angle-ANG30
		mo.leftwaves.color = mo.color
	end
	
	if moveingspeed < mo.startingspeed/2 and mo.spawntime >= 10 then
		P_KillMobj(mo, mo)
	end
	if mo.spawntime > 1*TICRATE and mo.spawntime < 50*TICRATE then
		P_KillMobj(mo, mo)
		mo.spawntime = 99*TICRATE
	end
 end
end, MT_SUPERSPINWAVE)

addHook("MobjMoveBlocked", function(mo,thing,line)
	if mo and mo.valid then
		if thing and thing.valid and thing.player and mo.target and mo.target.valid and mo.target.player then
			if B.MyTeam(mo.target.player, thing.player) then
			end
		end
		P_KillMobj(mo, mo)
	end
end, MT_SUPERSPINWAVE)

// make paper sprites play death animation //
addHook("MobjDeath", function(mo, inflictor, source, damagetype)
 if mo and mo.valid then
	if mo.centerwaves and mo.centerwaves.valid then
			mo.centerwaves.state = S_SUPPERSPIN_WAVE3
	end
	if mo.rightwaves and mo.rightwaves.valid then
			mo.rightwaves.state = S_SUPPERSPIN_WALL3
	end
	if mo.leftwaves and mo.leftwaves.valid then
			mo.leftwaves.state = S_SUPPERSPIN_WALL3
	end
 end
end, MT_SUPERSPINWAVE)

addHook("MobjRemoved", function(mo) // remove effects too
	if mo and mo.valid then
		if mo.centerwaves and mo.centerwaves.valid then
			P_RemoveMobj(mo.centerwaves)
			P_RemoveMobj(mo.rightwaves)
			P_RemoveMobj(mo.leftwaves)
			mo.centerwaves = false
			mo.rightwaves = false
			mo.leftwaves = false
		end
	end
end, MT_SUPERSPINWAVE)

addHook("MobjDamage", function(mo, inflictor, source, damage, damagetype) //spin wave make hit sound

	if inflictor and inflictor.valid and inflictor.type == MT_SUPERSPINWAVE then
	if mo.player and mo.player.valid and mo.player.guard >= 1 then else
		S_StartSound(mo, sfx_kc40)
		end
	end

end, MT_NULL)

//---------------------------------------------------------------//
local function SpinWaveObjCollide(mo, mobj)
	if mobj and mobj.valid and (mobj.flags & MF_SOLID) then
		if not (mo.z+(1*FRACUNIT) >= mobj.z+mobj.height)
		and not(mobj.z+(1*FRACUNIT) >= mo.z+mo.height) then
		if (mobj.type == MT_PLAYER and (mobj.player.powers[pw_flashing] or (mobj and mobj.valid and mobj.player and mo.target and mo.target.valid and mo.target.player and B.MyTeam(mobj.player, mo.target.player)))) then return false end
		if (mobj.flags & MF_MONITOR) or (mobj.type == MT_PLAYER) then return end
		P_KillMobj(mo, mo)
		end
	end
end

addHook("MobjMoveCollide", SpinWaveObjCollide, MT_SUPERSPINWAVE)
addHook("MobjCollide", SpinWaveObjCollide, MT_SUPERSPINWAVE)