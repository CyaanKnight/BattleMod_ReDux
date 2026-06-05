local PR = CBW_PowerCards
-- local capturesfx = sfx_nxdone
local capturesfx = sfx_ncitem
local failsfx = sfx_adderr

addHook("MobjSpawn",function(mo)
	CBW_Battle.ZLaunch(mo,FRACUNIT*8)
	P_InstaThrust(mo, FixedAngle(P_RandomRange(0,359)*FRACUNIT), FRACUNIT*5)
end,MT_POWERCARDDEATHPROP)

addHook("MobjThinker",function(mo)
	mo.flags2 = $^^MF2_DONTDRAW
	mo.angle = $+ANG20
	if P_IsObjectOnGround(mo) and P_MobjFlip(mo)*mo.momz <= 0
		P_RemoveMobj(mo)
	end
end,MT_POWERCARDDEATHPROP)

PR.DiscardDeath = function(mo,player)
	local prop = P_SpawnMobjFromMobj(mo,0,0,0,MT_POWERCARDDEATHPROP)
	if prop and prop.valid
		prop.state = mo.state
	end
	P_KillMobj(mo)
end

PR.RewardDeath = function(mo,player)
	local item = PR.Item[mo.item]
	//FX
	P_SpawnMobjFromMobj(mo,0,0,0,MT_SPARK)
	P_SpawnMobjFromMobj(mo.target,0,0,0,MT_SPARK)
	local amb = P_SpawnMobjFromMobj(mo,0,0,0,1)
	S_StartSound(amb,capturesfx)
	amb.fuse = TICRATE*4
	amb.flags2 = MF2_DONTDRAW
	local width = FRACUNIT*512
	local z = mo.z+FixedMul(mo.height-mobjinfo[MT_BOXSPARKLE].height,mo.scale>>2)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,0,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,ANGLE_22h,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,ANGLE_45,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,ANGLE_67h,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,ANGLE_112h,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,ANGLE_135,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,MT_BOXSPARKLE,ANGLE_157h,nil,true)
	P_KillMobj(mo)
end

PR.FailureDeath = function(mo,player)
	local amb = P_SpawnMobjFromMobj(mo,0,0,0,1)
	S_StartSound(amb,failsfx)	
	amb.fuse = TICRATE*2
	amb.flags2 = MF2_DONTDRAW
	P_SpawnMobjFromMobj(mo,0,0,0,MT_SMOKE)
	P_KillMobj(mo)
end

addHook("MobjDeath",function(mo)
	local player = mo.target and mo.target.valid and mo.target.player or nil
	if PR.Item[mo.item].func_expire(mo,player)
		PR.LoseOwner(mo)
		return
	end
	if mo.target
		if mo.target.valid and mo.target.health and mo.target.player

		else

		end
	end
	PR.LoseOwner(mo)
end,MT_POWERCARD)