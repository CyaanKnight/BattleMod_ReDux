local PR = CBW_PowerCards
-- local capturetime = TICRATE*3
local hover_height = 32
local hover_thrust = FRACUNIT*3/4
local jump_thrust = FRACUNIT*5
local lerpamt = FRACUNIT>>3

local spinspeed1 = FixedAngle(5<<FRACBITS)
local spinspeed2 = FixedAngle(15<<FRACBITS)

//*** Effects

local DoSparkle = function(mo)
	local range = mo.radius>>18
	local x = P_RandomRange(-range,range)*mo.scale
	local y = P_RandomRange(-range,range)*mo.scale
	local z = P_RandomRange(0,(mo.height - mobjinfo[MT_BOXSPARKLE].height)>>17) * mo.scale
	return P_SpawnMobjFromMobj(mo,x,y,z,MT_BOXSPARKLE)
end

local ClaimingFX = function(mo)
	local ghost = P_SpawnGhostMobj(mo)
	if mo.target and mo.target.valid
		ghost.colorized = true
		ghost.color = mo.target.color
	end
-- 	ghost.destscale = $<<1
end

//*** Thinkers

-- local claimheight = 40
local ClaimedThinker = function(mo)
	local item = PR.Item[mo.item]
	local player = mo.target and mo.target.valid and mo.target.player or nil
	
	//Drop item if player is missing or injured
	if not(player and player.playerstate == PST_LIVE) or P_PlayerInPain(player)
		PR.DropItem(mo)
		return
	end

	//Align item to player properties
	mo.destscale = player.mo.destscale>>1
	if P_MobjFlip(player.mo) == -1
		mo.flags2 = $|MF2_OBJECTFLIP
	else
		mo.flags2 = $&~MF2_OBJECTFLIP
	end

	//Do item's active function
	if item.func_hold(mo,player)
		return
	end
	
	//Physics
-- 	local destz = mo.floorz + claimheight*mo.scale
-- 	if P_MobjFlip(mo) == -1
-- 		destz = mo.ceilingz-FixedMul(mo.height,mo.scale) - claimheight
-- 	end
-- 	mo.z = CBW_Battle.FixedLerp($,destz,FRACUNIT/10)
	
	if player
		local distxy = R_PointToDist2(mo.x,mo.y,mo.target.x,mo.target.y)-mo.target.scale*40
		local distz = mo.target.z-mo.z
		if P_MobjFlip(mo.target) == -1
			distz = $ + FixedMul(mo.target.height,mo.target.scale) - FixedMul(mo.height,mo.scale)
		end
		local dir = R_PointToAngle2(mo.x,mo.y,mo.target.x,mo.target.y)
		P_InstaThrust(mo,dir,FixedMul(distxy,lerpamt))
		mo.momz = FixedMul(lerpamt,distz)
	end	
	
	//Spin
	mo.angle = $+spinspeed2
	
	//FX
-- 	local spark = DoSparkle(mo)
-- 	P_Thrust(spark,R_PointToAngle2(mo.x,mo.y,spark.x,spark.y),P_RandomRange(0,10)*mo.scale)
-- 	P_SetObjectMomZ(spark,P_RandomRange(-4,10)*FRACUNIT,true)
	if not(mo.fuse%4)
		ClaimingFX(mo)
	end
end

local IdleThinker = function(mo)
	if not(mo.fuse%2)
		local spark = DoSparkle(mo)
		spark.scale = $>>P_RandomRange(0,2)
		P_Thrust(spark,R_PointToAngle2(mo.x,mo.y,spark.x,spark.y),P_RandomRange(0,1)*mo.scale>>1)
		P_SetObjectMomZ(spark,P_RandomRange(1,4)*FRACUNIT,true)
	end
	local item = PR.Item[mo.item]
	
	if item.func_idle(mo)
		return
	end
	
	if mo.flags&MF_SPECIAL
		if mo.dropped
			//Bounce physics
			if P_IsObjectOnGround(mo)
				CBW_Battle.ZLaunch(mo,jump_thrust,true)
			end
		else
			//Float physics
			if P_MobjFlip(mo) == 1 and mo.z-mo.floorz < mo.scale*hover_height
			or P_MobjFlip(mo) == -1 and mo.ceilingz-(mo.z+mo.height) < mo.scale*hover_height
				CBW_Battle.ZLaunch(mo,hover_thrust,true)
			end
			//Disallow XY movement
			P_InstaThrust(mo,0,0)
		end
		//Spin
		mo.angle = $+spinspeed1
	elseif P_IsObjectOnGround(mo)
		//Become tangible after landing
		mo.flags = $|MF_SPECIAL
		mo.flags2 = $&~MF2_DONTDRAW
		//Spin
		mo.angle = $+spinspeed1
	else
		//Spin fast
		mo.angle = $+spinspeed2
	end
	if mo.fuse < 3*TICRATE and mo.fuse != 0
	or not(mo.flags&MF_SPECIAL)
		//Blink
		mo.flags2 = $^^MF2_DONTDRAW
	end
end

addHook("MobjThinker",function(mo)
	if not(CBW_Battle) return end
	if CBW_Battle.SuddenDeath
		P_RemoveMobj(mo)
		return
	end
	mo.flags2 = $&~MF2_SHADOW
	if mo.target and mo.target.valid 
		mo.destscale = mo.target.destscale
		if mo.target.player == consoleplayer
			mo.flags2 = $|MF2_SHADOW
		end
	end

	if mo.active
		ClaimedThinker(mo)
	else
		IdleThinker(mo)
	end
end,MT_POWERCARD)

