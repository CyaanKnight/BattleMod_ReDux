local PR = CBW_PowerCards

local spawntime = TICRATE*4

freeslot(
	"SPR_CAPJ",
	"MT_POWERCARDCAPSULE",
	"MT_POWERCARDCAPSULE_SPAWNPOINT",
	"S_GGCAPSULE",
	"S_GGCAPSULE_JUNK"
)

mobjinfo[MT_POWERCARDCAPSULE] = {
	doomednum = -1,
	spawnstate = S_GGCAPSULE,
	painstate = S_GGCAPSULE,
	deathstate = S_GGCAPSULE,
	spawnhealth = 1,
	radius = 72*FRACUNIT,
	height = 144*FRACUNIT,
-- 	flags = MF_NOGRAVITY|MF_NOCLIPTHING
	flags = MF_NOGRAVITY|MF_SPECIAL|MF_SHOOTABLE
}

mobjinfo[MT_POWERCARDCAPSULE_SPAWNPOINT] = {
	//$Name "Power Card Capsule"
	//$Sprite CAPSA0
	//$Category "BattleMod Power Card Spawns"
	doomednum = 3589,
	spawnstate = S_NULL,
	spawnhealth = 1,
	radius = 72*FRACUNIT,
	height = 144*FRACUNIT,
	flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP
}

states[S_GGCAPSULE] = {SPR_CAPS, A, -1, nil, 0, 0, S_NULL}
states[S_GGCAPSULE_JUNK] = {SPR_CAPJ, A, TICRATE, nil, 0, 0, S_NULL}

local capsuleflags = MF_NOGRAVITY|MF_SPECIAL|MF_SHOOTABLE

-- addHook("MapThingSpawn", function(mo, mt)
-- 	if (mt.options & MTF_OBJECTSPECIAL)
-- 		mo.state = S_GGCAPSULE
-- 		mo.flags = capsuleflags
-- 		mo.flags2 = $1|MF2_INVERTAIMABLE
-- 	end

-- 	if (mt.options & MTF_AMBUSH)
-- 		mo.z = $1 + 80*FRACUNIT
-- 	end

-- 	mo.movefactor = mo.z
-- end, MT_POWERCARDCAPSULE)

local function ItemBubble(spawner)
	local bubble = P_SpawnMobjFromMobj(spawner,0,0,0,MT_ITEM_BUBBLE)
	if not(bubble and bubble.valid) return end
	bubble.fuse = 20*TICRATE
	//Flip Object
	if spawner.flags2&MF2_OBJECTFLIP then
		bubble.flags2 = $|MF2_OBJECTFLIP
		bubble.z = $-bubble.height-FRACUNIT
	end
	bubble.flags = ($|MF_BOUNCE)&~MF_NOCLIPHEIGHT
	if P_RandomChance(FRACUNIT/4)
		bubble.flags = $&~MF_NOGRAVITY
		bubble.buoyancy = true
		bubble.balltype = 2
		CBW_Battle.ZLaunch(bubble,FRACUNIT*6)
	end
	P_Thrust(bubble, FixedAngle(P_RandomRange(0,360)*FRACUNIT),FRACUNIT*4)

	local t = P_RandomRange(-4,3)
	if t < 1
		bubble.item = 1
	end
	//Roulette
	if t == 1 then
		bubble.item = 3
		bubble.roulettetype = 1
	end
	//S3 Roulette
	if t == 2 then
		bubble.item = 9
		bubble.roulettetype = 1
	end
	//Hyper Roulette
	if t == 3 then
		bubble.item = 0
		bubble.roulettetype = 2
	end
	
	return bubble
end


addHook("MobjThinker", function(mo)

	mo.shadowscale = FRACUNIT

	if (mo.extravalue2 > 0)
		mo.fuse = -1
		mo.extravalue2 = $1 - 1

		if (mo.extravalue2 & 1)
			local dustx = P_RandomRange(-64,64) * mo.scale
			local dusty = P_RandomRange(-64,64) * mo.scale
			local dustz = P_RandomRange(8,136) * mo.scale

			local dust = P_SpawnMobjFromMobj(mo, dustx, dusty, dustz, MT_EXPLODE)
			S_StartSound(dust, sfx_s3k3d)
		end

		if (mo.extravalue2 <= 0)
			for i = 0,3
				local junk = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_BOSSJUNK)
				junk.angle = P_RandomRange(0,15) * ANGLE_22h
				junk.state = S_GGCAPSULE_JUNK
				junk.frame = $1 + i

				local hspd = 4*junk.scale
				local vspd = 8*junk.scale
				if (i >= 2)
					local temp = hspd
					hspd = vspd
					vspd = temp
				end

				P_Thrust(junk, junk.angle, hspd)
				P_SetObjectMomZ(junk, vspd, true)
			end

			for i = 0,23
				local flx = P_RandomRange(-64,64) * mo.scale
				local fly = P_RandomRange(-64,64) * mo.scale
				local flz = P_RandomRange(8,136) * mo.scale

				local flickydust = P_SpawnMobjFromMobj(mo, flx, fly, flz, MT_EXPLODE)
				flickydust.state = S_XPLD_EGGTRAP

-- 				A_FlickySpawn(flickydust, 0, 0)
			end


			//CBW - Item spawning code
			local gift = P_RandomRange(0,5)
-- 			local gift = 5
			local momz = FRACUNIT*5
			local momxy = mo.scale*5
			//Create invisible prop so we can produce a sound from it
			local amb = P_SpawnMobjFromMobj(mo,0,0,0,1)
			amb.flags2 = $|MF2_DONTDRAW
			amb.fuse = TICRATE*3
			if gift == 0 //Several items, different type
				S_StartSound(amb,sfx_ideya)
				for n = 1, P_RandomRange(2,4)
					PR.SpawnItem(PR.GetRandomType(nil, PCF_CONTAINER|PCF_EVENT), mo.mapthing, function(card)
						P_TeleportMove(card, mo.x, mo.y, mo.z)
						CBW_Battle.ZLaunch(card,momz)
						P_Thrust(card,FixedAngle(P_RandomRange(0,360)*FRACUNIT), momxy)
					end, true)
				end
			elseif gift == 1 //Several items, same type
				S_StartSound(amb,sfx_ideya)
				local item = PR.GetRandomType(nil, PCF_CONTAINER|PCF_EVENT)
				for n = 1, P_RandomRange(2,4)
					PR.SpawnItem(item, mo.mapthing, function(card)
						P_TeleportMove(card, mo.x, mo.y, mo.z)
						CBW_Battle.ZLaunch(card,momz)
						P_Thrust(card,FixedAngle(P_RandomRange(0,360)*FRACUNIT), momxy)
					end, true)
				end
			elseif gift == 2 //Event item
				S_StartSound(amb,sfx_ideya)
				PR.SpawnItem(PR.GetRandomType(PCF_EVENT, PCF_CONTAINER), mo.mapthing, function(card)
					P_TeleportMove(card, mo.x, mo.y, mo.z)
					CBW_Battle.ZLaunch(card,momz)
					P_Thrust(card,FixedAngle(P_RandomRange(0,360)*FRACUNIT), momxy)
				end, true)
			elseif gift == 3 //Item Bubbles
				S_StartSound(amb,sfx_nxdone)
				for n = 1,P_RandomRange(3,6)
					ItemBubble(mo)
				end
			elseif gift == 4 //Rings
				S_StartSound(amb,sfx_cdfm67)
				local t = {1,10,24,32,32,32,32,64,100}
				for n = 1, t[P_RandomRange(1,#t)]
					local ring = P_SpawnMobjFromMobj(mo,0,0,0,MT_FLINGRING)
					if ring and ring.valid
						P_Thrust(ring,FixedAngle(P_RandomRange(0,360)*FRACUNIT), P_RandomRange(5,12)*mo.scale)
						CBW_Battle.ZLaunch(ring,P_RandomRange(5,15)*FRACUNIT)
						ring.fuse = 8*TICRATE
						ring.flags = ($|MF_BOUNCE)&~MF_NOGRAVITY
					end
				end
			elseif gift == 5 //Bombs
				S_StartSound(amb,sfx_cdfm42)
				for n = 1, 8
					local bomb = P_SpawnMobjFromMobj(mo,0,0,0,MT_FBOMB)					
					P_Thrust(bomb,FixedAngle(45*n*FRACUNIT), P_RandomRange(2,8)*mo.scale)
					CBW_Battle.ZLaunch(bomb,P_RandomRange(5,10)*FRACUNIT)
-- 					bomb.flags = $|MF_BOUNCE|MF_GRENADEBOUNCE
-- 					bomb.fuse = P_RandomRange(2*TICRATE,3*TICRATE)
-- 					bomb.staticfuse = true
-- 					bomb.bombtype = 2
				end
			end

			P_RemoveMobj(mo)
			return
		end
	else
		local pi = 22*FRACUNIT/7
		local speed = 2*TICRATE
		local amp = 16

		local z = mo.movefactor
		local flip = P_MobjFlip(mo)
		local startz
		if flip == 1
			startz = mo.ceilingz-FixedMul(mo.height,mo.scale)
		else
			startz = mo.floorz
		end
		
		local lerpamt = mo.extravalue1*FRACUNIT/spawntime
		lerpamt = FixedMul($,$)
		
		if (mo.extravalue1 > 0)
-- 			z = $1 + ((mo.extravalue1 * mo.extravalue1) * mo.scale)
			z = CBW_Battle.FixedLerp(z,startz,lerpamt)
			mo.extravalue1 = $1 - 1
		end

		mo.z = z + FixedMul(amp * sin((2*pi*speed) * leveltime), mo.scale) 
	end
	if mo.fuse < TICRATE*3 and mo.fuse > 0
		mo.flags2 = $^^MF2_DONTDRAW
	else
		mo.flags2 = $&~MF2_DONTDRAW
	end
end, MT_POWERCARDCAPSULE)

addHook("TouchSpecial", function(mo, toucher)
	local player = toucher.player

	if toucher and toucher.valid and player then
		if (P_PlayerCanDamage(player, mo))
			S_StopSound(mo)
			P_KillMobj(mo, toucher, toucher)
			mo.extravalue2 = 3*TICRATE/2
		end
		if (mo.extravalue2) then
			

			if (P_MobjFlip(toucher) * toucher.momz < 0)
			and not (player.charability2 == CA2_MELEE and player.panim == PA_ABILITY2)
				toucher.momz = -$1
			end

			--[[
			if (player.pflags & PF_BOUNCING)
				P_DoAbilityBounce(player, false)
			end
			--]]

			toucher.momx = -$1
			toucher.momy = -$1

			if (player.charability == CA_FLY and player.panim == PA_ABILITY)
				toucher.momz = (-$1) / 2
			elseif (player.pflags & PF_GLIDING and not P_IsObjectOnGround(toucher))
				player.pflags = $1 & ~(PF_GLIDING|PF_JUMPED|PF_NOJUMPDAMAGE)
				toucher.state = S_PLAY_FALL
				toucher.momz = $1 + (P_MobjFlip(toucher) * (player.speed >> 3))
				toucher.momx = 7 * $1 / 8
				toucher.momy = 7 * $1 / 8
			elseif (player.dashmode >= 3*TICRATE
			and (player.charflags & (SF_DASHMODE|SF_MACHINE)) == (SF_DASHMODE|SF_MACHINE)
			and player.panim == PA_DASH)
				P_DoPlayerPain(player, mo, mo)
			end

			--[[
			if (player.charability == CA_TWINSPIN and player.panim == PA_ABILITY)
				P_TwinSpinRejuvenate(player, player.thokitem)
			end
			--]]
		end
	end

	return true
end, MT_POWERCARDCAPSULE)

addHook("MobjDeath", function(mo)
	mo.extravalue2 = 3*TICRATE/2
end, MT_POWERCARDCAPSULE)

addHook("ShouldDamage", function(mo, inf, src)
	if (inf and inf.valid)
		if (inf.type == MT_PLAYER)
			return true
		end
	end

	if (src and src.valid)
		if (src.type == MT_PLAYER)
			return true
		end
	end
	
	return false
end, MT_POWERCARDCAPSULE)

addHook("MobjSpawn",function(mo)
	S_StartSound(mo,sfx_ebufo)
	mo.extravalue1 = spawntime
-- 	mo.flags = capsuleflags
	mo.flags2 = $1|MF2_INVERTAIMABLE
	mo.movefactor = min(max(mo.z,mo.floorz+mo.scale*48),mo.ceilingz-FixedMul(mo.height,mo.scale)-mo.scale*48)
	local s = mo.scale
	mo.scale = s>>4
	mo.destscale = s
end,MT_POWERCARDCAPSULE)


table.insert(CBW_PowerCardQueue,{
	name 		= "Capsule",
	chance		= 4,
	flags		= PCF_CUSTOM|PCF_CONTAINER,
	mobj		= MT_POWERCARDCAPSULE,
	mapthing	= MT_POWERCARDCAPSULE_SPAWNPOINT,
})