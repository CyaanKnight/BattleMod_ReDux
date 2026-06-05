/*
	Ring-Up powerup.
	Grants rings to the holder over an extended period of time.
*/
local PR = CBW_PowerCards
local ring_rate = 12
local ring_amt = 32*ring_rate
local ring_fuse = TICRATE*5

local function HoldFunc(mo,player)
	if mo.health > 1
		mo.health = $-1
		if mo.health%ring_rate == 0
			P_SpawnMobjFromMobj(player.mo,0,0,0,MT_FLINGRING)
		end
	else
		PR.DiscardDeath(mo,player)
		return true
	end
end

local function IdleFunc(mo,player)
	if not(mo.dropped) return end
	if mo.health > 1
		mo.health = $-1
		mo.fuse = mo.health
		if mo.health%ring_rate == 0
			local ring = P_SpawnMobjFromMobj(mo,0,0,0,MT_FLINGRING)
			if ring and ring.valid
				ring.scale = mo.destscale
				ring.flags = $&~MF_NOGRAVITY
				ring.fuse = ring_fuse
				P_InstaThrust(ring,FixedAngle(P_RandomRange(0,359)<<FRACBITS),P_RandomRange(1,10)*ring.scale)
				CBW_Battle.ZLaunch(ring,P_RandomRange(5,10)*FRACUNIT,false)
			end
		end	
	else
		PR.DiscardDeath(mo,player)
		return true
	end
end

table.insert(CBW_PowerCardQueue, {
	name 		= "Ring-Up",
	chance		= 7,
	health		= ring_amt,
	flags		= 0,
	state		= S_POWERCARD_RINGS,
	mapthing	= MT_POWERCARDSPAWN_RINGS,
	func_spawn	= nil,
	func_idle 	= IdleFunc,
	func_hold	= HoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil, 
})