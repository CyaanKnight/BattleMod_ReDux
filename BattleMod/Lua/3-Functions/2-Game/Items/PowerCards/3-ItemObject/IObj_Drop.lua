local PR = CBW_PowerCards

local toss_thrust = 15
local toss_lift = 7*FRACUNIT

local drop_thrust = 7
local drop_lift = 5*FRACUNIT

local fuse = 10*TICRATE

local toss_sfx = sfx_s3k51

PR.LoseOwner = function(mo,intangible)
	if mo.target and mo.target.valid
		mo.destscale = mo.target.destscale
		local player = mo.target.player
		PR.Item[mo.item].func_drop(mo,player)
		//Disassociate owner
		if player
			player.gotpowercard = nil
			player.tossdelay = max($,27)
		end
		//Disassociate target
		mo.target = nil
	end
	if intangible
		mo.flags = $&~MF_SPECIAL
	end
	mo.active = false
	mo.dropped = true
	mo.flags = ($|MF_BOUNCE)&~(MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)
	mo.fuse = fuse
end

PR.TossItem = function(mo,intangible)
	if mo.target and mo.target.valid
		local t = mo.target
		P_TeleportMove(mo,t.x,t.y,t.z)
		mo.momx = mo.target.momx
		mo.momy = mo.target.momy
		mo.momz = mo.target.momz
		local angle = mo.target.angle
		P_Thrust(mo,angle,toss_thrust*mo.scale)
	end
	CBW_Battle.ZLaunch(mo,toss_lift,true)
	PR.LoseOwner(mo,intangible)
	S_StartSound(mo,sfx_s3k51)
end

PR.DropItem = function(mo,intangible)
	if mo.target and mo.target.valid
		local t = mo.target
-- 		P_TeleportMove(mo,t.x,t.y,t.z)
		local angle = R_PointToAngle2(t.x,t.y,mo.x,mo.y)
		P_InstaThrust(mo,angle,drop_thrust*mo.scale)
	end
	CBW_Battle.ZLaunch(mo,drop_lift)
	PR.LoseOwner(mo,intangible)
end