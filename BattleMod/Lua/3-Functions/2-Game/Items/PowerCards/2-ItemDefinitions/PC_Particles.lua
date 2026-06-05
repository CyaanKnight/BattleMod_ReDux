local PR = CBW_PowerCards
local tumbler_frequency = 5
local tumbler_times = 6
local tumbler_range = 256*FRACUNIT
local tumbler_speed = 60*FRACUNIT
local tumbler_life = FixedDiv(tumbler_range,tumbler_speed)/FRACUNIT
local DoParticle = function(mo,time,particle,sound)
	if time%3 return end
	mo = mo.mo or $
	local range = mo.radius>>16
	local x = P_RandomRange(-range,range)*mo.scale
	local y = P_RandomRange(-range,range)*mo.scale
	local z = P_RandomRange(0,(mo.height - mobjinfo[particle].height)>>16) * mo.scale
	local p = P_SpawnMobjFromMobj(mo,x,y,z,particle)
	if sound
		S_StartSound(p,sound)
	end
	return p
end

local HoldFunc = function(mo,player)
	//Tumbler
	if mo.health > 1
		//Timer
		mo.health = $-1
		//Status effect
		if mo.health%tumbler_frequency == 0
			S_StartSound(player.mo,sfx_pixied)
			local ang_offset = FixedAngle(5*mo.health<<FRACBITS)
			for n = 1, tumbler_times
				local proj = MT_TUMBLEPARTICLE
				local m = P_SPMAngle(player.mo,proj,player.mo.angle,0)
				if m and m.valid
					local ang_xy = ang_offset+FixedAngle(CBW_Battle.FixedLerp(0,360*FRACUNIT,n*FRACUNIT/tumbler_times))
					local ang_z = -ang_offset+FixedAngle(CBW_Battle.FixedLerp(-90*FRACUNIT,90*FRACUNIT,n*FRACUNIT/tumbler_times))
					local spd = FixedMul(mobjinfo[proj].speed,m.scale)
					CBW_Battle.InstaThrustZAim(m,ang_xy,ang_z,spd,false)
					m.health = tumbler_life
				end
			end
		end
-- 		//Visual
-- 		local particle = DoParticle(player,mo.health,MT_GHOST)
-- 		if particle and particle.valid
-- 			particle.sprite = SPR_CPBS
-- 			particle.color = SKINCOLOR_GOLD
-- 			particle.destscale = $>>1
-- 			CBW_Battle.ZLaunch(particle,FRACUNIT*P_RandomRange(5,10))
-- 		end
	else
		PR.DiscardDeath(mo,player)
		return true
	end
end

//Bounce tumble mechanics
local BounceTumblerDamage = function(pmo,mo,source)
	local B = CBW_Battle
	if not(mo and mo.valid
		and mo.tumbler != nil
		and mo.flags&MF_MISSILE)
		return
	end
	if pmo.player and source and source.valid and source.player and not(B.MyTeam(source.player,pmo.player)) and not P_PlayerInPain(pmo.player)
		B.PlayerCreditPusher(pmo.player,source)
		
		local hthrust = mo.block_hthrust
		local vthrust = mo.block_vthrust
		local blockstun = mo.block_stun
		local sound = sfx_ssbbmp
		if mo.block_sound
			sound = mo.block_sound
		end
		
		B.ResetPlayerProperties(pmo.player,false,false)
		
		B.ZLaunch(pmo, mo.scale*vthrust, true)
		P_InstaThrust(pmo,mo.angle,mo.scale*hthrust / 2)
		
		S_StartSound(pmo,sound)
			
		//Do tumble
		local angle = R_PointToAngle2(0,0,pmo.momx,pmo.momy)
		local recoilthrust = FixedHypot(pmo.momx,pmo.momy)
		B.DoPlayerTumble(pmo.player, blockstun, angle, recoilthrust)
		P_RemoveMobj(mo)
		return false			
	end
end


//Projectile
freeslot('mt_tumbleparticle')

mobjinfo[MT_TUMBLEPARTICLE] = {
	spawnstate = S_JETBULLET1,
	spawnhealth = 1000,
	radius = 8*FRACUNIT,
	height = 16*FRACUNIT,
	speed = tumbler_speed,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_BOUNCE|MF_GRENADEBOUNCE
}


//** Hooks

addHook("MobjSpawn", function(mo)
	if mo.valid
		mo.tumbler = 1
		mo.block_stun = 30
		mo.block_sound = sfx_ssbbmp
		mo.block_hthrust = 12
		mo.block_vthrust = 10
		mo.colorized = true
		local t = {SKINCOLOR_RED,SKINCOLOR_BLUE,SKINCOLOR_YELLOW}
		mo.color = t[P_RandomRange(1,#t)]
		mo.fuse = tumbler_life
	end
end,MT_TUMBLEPARTICLE)

-- addHook("MobjThinker", function(mo)
-- 	local ghost = P_SpawnGhostMobj(mo)
-- 	if ghost and ghost.valid and mo.target and mo.target.valid
-- 		ghost.colorized = true
-- 		ghost.color = mo.target.color
-- 	end
-- end,MT_TUMBLEPARTICLE)

addHook("ShouldDamage", BounceTumblerDamage, MT_PLAYER)

//** Table

table.insert(CBW_PowerCardQueue, {
	name 		= "Particles",
	chance		= 6,
	health		= TICRATE*12,
	flags		= 0,
	state		= S_POWERCARD_PARTICLES,
	mapthing	= MT_POWERCARDSPAWN_PARTICLES,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= HoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil,
})