local PR = CBW_PowerCards

local DoParticleExplosion = function(player)
	local mo = player.mo
	local type = MT_BOXSPARKLE
-- 	local state = S_LHRT
	local width = FRACUNIT*256
	local z = mo.z+FixedMul(mo.height-mobjinfo[type].height,mo.scale>>2)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,0,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_22h,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_45,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_67h,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_112h,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_135,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_157h,state,true)
end

local function HoldFunc(mo,player)
	if mo.health > 1
		mo.health = $-1
		if mo.health%TICRATE == 0
			local ghost = P_SpawnGhostMobj(player.mo)
			ghost.state = S_LHRT
			ghost.scale = $<<2
			if PR.FirstPerson(player)
				ghost.flags2 = $|MF2_DONTDRAW
			end
		end
	else
		if not(player) return end
		if not(player.isjettysyn)
			A_ExtraLife(mo)
		else
			CBW_Battle.Arena.Avenge(player)
		end
		DoParticleExplosion(player)
		//Destroy Item
		PR.RewardDeath(mo,player)
		return true
	end
end

table.insert(CBW_PowerCardQueue, {
	name 		= "Blessing",
	chance		= 1,
	health		= TICRATE*3+15,
	flags		= PCF_HUDWARNING,
	state		= S_POWERCARD_BLESSING,
	mapthing	= MT_POWERCARDSPAWN_BLESSING,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= HoldFunc,
	func_touch	= PR.HealCardSFX,
	func_drop 	= nil,
	func_expire	= nil,
})