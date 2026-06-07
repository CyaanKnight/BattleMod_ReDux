local B = CBW_Battle
local G = B.Gametypes
local CV = B.Console

B.ResetSparring = function()
	B.TrainingDummy = nil
	B.HitCounter = 0
	B.TrainingDummyName = nil
end

B.SparringPartnerControl = function()
	if not(B.BattleGametype()) then return end
	//Get player counts
	local playercount = 0
	local redcount = 0
	local bluecount = 0
	for player in players.iterate
		if not(player.spectator) then
			playercount = $+1
		end
		if player.ctfteam == 1 then
			redcount = $+1
		end
		if player.ctfteam == 2 then
			bluecount = $+1
		end
	end
	local training = false
	local exists = (B.TrainingDummy and B.TrainingDummy.valid)
	//Get training value
	if G_TagGametype() or not G.TailsDoll[gametype] then training = false
	elseif CBW_Chaos_Library and CBW_Chaos_Library.Gametypes[gametype] then training = false
	elseif not(G_GametypeHasTeams()) and playercount == 1 and CV.TailsDoll.value >= 1 then training = true
	elseif G_GametypeHasTeams() and (redcount == 0 or bluecount == 0) and CV.TailsDoll.value >= 1 then training = true
	end
	//Supercede training value
	if CV.TailsDoll.value == 2 then training = true end
	//Training activate
	if training == true and not(exists) then
		for mapthing in mapthings.iterate
			if mapthing.type != 1 then continue end
			local fu = FRACUNIT
			local x = mapthing.x*fu
			local y = mapthing.y*fu
			local z = mapthing.z*fu
			local subsector = R_PointInSubsector(x,y)
			if subsector.valid and subsector.sector then
				z = $+subsector.sector.floorheight
				B.TrainingDummy = P_SpawnMobj(x,y,z,MT_SPARRINGDUMMY)
				if not (B.TrainingDummy and B.TrainingDummy.valid) then continue end //Invalid spawn gate
				B.TrainingDummyName = B.TrainingDummy.name
				if B.HitCounter then
					B.TrainingDummy.hitcounter = B.HitCounter
					print(tostring(B.TrainingDummy.name).."\x80 respawned.")
				else
					print(tostring(B.TrainingDummy.name).."\x80 was added to the game for target practice.")
				end
				break
			end
		end
	end
	//Training deactivate
	if training == false and exists == true then
		B.TrainingDummy.exiting = true
		B.TrainingDummy.fuse = 0
		local name = "The sparring partner "
		if B.TrainingDummyName then
			name = tostring(B.TrainingDummyName)
		end
		print(name.."\x80 was removed from the game.")
		B.TrainingResults()
		B.TrainingDummyName = nil
	end
end

B.TrainingResults = function()
	if B.TrainingDummy and B.HitCounter then
		local name = "Your sparring partner"
		if B.TrainingDummyName then
			name = tostring(B.TrainingDummyName)+"\x80"
		end
		local s = ""
		if B.HitCounter > 1 then s = "s" end
		print("Nice workout! "..name.." was hit \x83"..B.HitCounter.."\x80 time"..s.." in this match.")
	end
	B.HitCounter = 0
	B.TrainingDummy = nil
end

B.HitCounterHUD = function(v,player,cam)
	if B.HitCounter == 0
	or B.TrainingDummy == nil
	return end
	local xo = 160
	local yo = 160
	if (B.ArenaGametype() and #B.Arena.Survivors > 3) then
		yo = 20
	end
	v.drawString(xo,yo,"Hits",V_HUDTRANS|V_SNAPTOBOTTOM|V_PERPLAYER,"center")
	v.drawString(xo,yo+8,tostring(B.HitCounter),V_HUDTRANS|V_SNAPTOBOTTOM|V_PERPLAYER,"center")
end

//Tails Doll Spawn script
B.TailsDollCreate = function(mo)
	B.CreateBashable(mo,nil,nil,false,true)
	mo.color = SKINCOLOR_ORANGE
	mo.exiting = false
	mo.pain = false
	mo.ai = 0
-- 	mo.z = mo.ceilingz-mo.height
	mo.attacking = 0
	mo.attacktype = 0
	mo.ammo = 0
	mo.interval = 5
	mo.naturalcolor = mo.color
	mo.name = "\x87".."Tails Doll"
	mo.telegraph = TICRATE
	mo.invisible = 0
	mo.cooldown = TICRATE*2
	mo.phase = 0
	mo.joining = TICRATE
-- 	mo.flags2 = $|MF2_INVERTAIMABLE
end

//****
//Fuse and Thinker stuff

local joining = function(mo)
	//Gate
	if not(mo.joining>0) then return false end
	mo.joining = $-1
	if not(leveltime&3) then 
		P_SpawnMobj(mo.x,mo.y,mo.z,MT_IVSP)
	end
	if mo.joining>0 then
		mo.flags = $|MF_NOCLIPTHING
		mo.flags2 = $^^MF2_DONTDRAW
		mo.angle = $-ANG30
		mo.momz = mo.scale*2
		return true
	else
		mo.flags = $&~MF_NOCLIPTHING
		mo.flags2 = $&~MF2_DONTDRAW
		return false
	end
end

//General air control
local hover = function(mo,t)
	//Exiting gate
	if exiting then return end
	//Z coordinate to hover to
	local destz = mo.floorz
	if mo.ai and t then destz = max(mo.floorz,t.z) end //Get target z, but only if it exceeds floorz
	//Horizontal movement
	local spd = FixedHypot(mo.momx,mo.momy)
	local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
	P_Thrust(mo,dir,-spd/10) //Employ air friction
	//Vertical movement
	local water = B.WaterFactor(mo)
	local hoverthreshold = mo.scale*24
	local groundstop = mo.scale*10
	local thrustaccel = (mo.scale+1)/water
	local thrustmax = min(mo.scale*4,max(mo.scale*3,mo.scale*mo.hitcounter/4))
	local didthrust = false
	//Apply the "brakes" if we're about to hit the ground (prevents object from hitting a deathpit)
	if mo.z < destz +groundstop then
		mo.momz = max($,0)
		didthrust = true
	end
	//Rise if below hover threshold
	if mo.z < destz +hoverthreshold then
		mo.momz = min($+thrustaccel,thrustmax)
		didthrust = true
	end
	//Do aesthetic
	if didthrust and not(leveltime&3) and not(mo.invisible) then
		local dist = 8*mo.scale
		local x = mo.x+P_ReturnThrustX(mo,mo.angle+ANGLE_180,dist)
		local y = mo.y+P_ReturnThrustY(mo,mo.angle+ANGLE_180,dist)
		local z = mo.z+mo.height/2
		local spd = mo.scale*4
		local zspd = -mo.scale*6
		local d = P_SpawnMobj(x,y,z,MT_DUST)
		P_InstaThrust(d,mo.angle+ANGLE_180,mo.scale*4)
		P_SetObjectMomZ(d,zspd)
	end
end

//XY control
local zoning = function(mo,t)
	//Exiting gate
	if mo.exiting then return end
	//AI gate
	if not(mo.ai) then return end
	//Do "strafing"; every 128 tics the object will change direction
	local drift = 1
	if leveltime&128 then drift = -$ end
	//No target gate
	if not(t) then 
		if leveltime&64 then mo.angle = $+ANG10*drift end //Look around!
	return end
	//Acceleration increases as the Tails Doll takes more hits
	local water = B.WaterFactor(mo)
	local accel = mo.scale/30*mo.hitcounter/water
	local optimaldistmin = 256*mo.scale
	local optimaldistmax = 192*mo.scale
	local dist = R_PointToDist2(mo.x,mo.y,t.x,t.y)
	local angle = R_PointToAngle2(mo.x,mo.y,t.x,t.y)	
	//Turning
	local turn = ANG10
	local diff = angle-mo.angle
	if abs(diff) < turn then
		mo.angle = angle
	else
		mo.angle = $+max(-turn,min(turn,diff))
		angle = mo.angle
	end
	//Apply acceleration
	if dist > optimaldistmin then //Get closer
		P_Thrust(mo,angle+ANGLE_45*drift,accel)
	elseif dist < optimaldistmax then //Move farther away
		P_Thrust(mo,angle+ANGLE_135*drift,accel)
	else //Full strafing
		P_Thrust(mo,angle+ANGLE_90*drift,accel)
	end
end

//Exit animation script
local exiting = function(mo)
	if not(mo.exiting) then return false end
	//Do sparkle
	if not(leveltime&3) then P_SpawnMobj(mo.x,mo.y,mo.z,MT_IVSP) end
	mo.state = S_TAILSDOLL1
	mo.colorized = false
	mo.color = mo.naturalcolor
	//Flag object for stage exit
	mo.flags = $|MF_NOGRAVITY|MF_NOCLIPHEIGHT
	//Do blink
	mo.flags2 = $^^(MF2_DONTDRAW)
	//Spin
	mo.angle = $+ANG10
	//Halt xy momentum
	P_InstaThrust(mo,mo.angle,0)
	//Rise
	mo.momz = $+mo.scale/4
	//Once we've reached past the ceiling, the exit phase is complete and the object can be destroyed
	if mo.z > mo.ceilingz then
		P_RemoveMobj(mo)
	end
	return true
end

//Attack stuff
local headbullet = function(mo,t)
	local dist = mo.scale*4
	local height = mo.height
	local x = mo.x+P_ReturnThrustX(mo,mo.angle,dist)
	local y = mo.y+P_ReturnThrustY(mo,mo.angle,dist)
	local z = mo.z+height/2
	P_SpawnXYZMissile(mo,t,MT_JETTBULLET,x,y,z)
	S_StartSound(mo,sfx_s3k4d)
end

local bombheight = FRACUNIT*256
local bombcompensate = FRACUNIT*64
local dangersparkle = function(mo,lerp)
	local h = FixedMul(bombheight,mo.scale)
	local c = FixedMul(bombcompensate,mo.scale)
	local height = min(mo.z+h,mo.ceilingz-c)
	height = B.FixedLerp(mo.z,$,lerp)
	local i = P_SpawnMobj(mo.x,mo.y,height,MT_IVSP)
	i.colorized = true
	i.color = mo.naturalcolor
end

local telebomb = function(mo,t)
	local h = FixedMul(bombheight,mo.scale)
	local c = FixedMul(bombcompensate,mo.scale)
	local height = min(mo.z+h,mo.ceilingz-c)
	local x = mo.x
	local y = mo.y
	local z = height
	P_SpawnXYZMissile(mo,t,MT_FBOMB,x,y,z)
	S_StartSound(mo,sfx_s3k51)
	dangersparkle(mo,FRACUNIT)
end

local attacktype = function(mo,nosound)
	if mo.ai < 2 then
		mo.ammo = 1
	end
	//Bullets
	if mo.ai == 2 then 
		mo.attacktype = 0
		mo.ammo = 3
		mo.interval = TICRATE/3
	end 
	//Bombs
	if mo.ai == 3 then 
		mo.attacktype = 1
		mo.ammo = 1
		mo.interval = TICRATE/2
	end
	//Mixups
	if mo.ai == 4
		then 
		if P_RandomChance(FRACUNIT*3/5) then
			mo.attacktype = 0
			mo.ammo = 5
			mo.interval = TICRATE/4
		else 
			mo.attacktype = 1
			mo.ammo = 2
			mo.interval = TICRATE/2
		end
	end
	if mo.ai == 5 //Ambush stage
		then 
		if P_RandomChance(FRACUNIT*3/5) then
			mo.attacktype = 0
			mo.ammo = 7
			mo.interval = TICRATE/4
		else 
			mo.attacktype = 1
			mo.ammo = 4
			mo.interval = TICRATE/3
		end
	end
	//Master!
	if mo.ai == 6 then
		if P_RandomChance(FRACUNIT*3/5)
			mo.attacktype = 0
			mo.ammo = 12
			mo.interval = TICRATE/7
		else 
			mo.attacktype = 1
			mo.ammo = 6
			mo.interval = TICRATE/4
		end
	end
	//Get Sound
	if(nosound) then return end
	if mo.attacktype == 0 then S_StartSound(mo,sfx_cdfm60) end
	if mo.attacktype == 1 then S_StartSound(mo,sfx_s3k73) end
end

local attack = function(mo,t)
	//pain gate
	if mo.pain then
		mo.attacking = 0 //Reset attack state
		mo.fuse = 0
	return end
	//ai gate
	if mo.ai < 2 then return end
	//Fuse not set?
	if mo.attacking == 0 and mo.fuse <= 0 then
		mo.fuse = TICRATE
	end
	//Tele-Bomb telegraph
	if mo.attacking == 1 and mo.attacktype == 1 and not(leveltime&3) then
		dangersparkle(mo,-FRACUNIT*(mo.fuse-mo.telegraph)/mo.telegraph)
	end
end

//Invisibility
local ghost = function(mo)
	mo.phase = $^^1 //Toggle phasing animation
	if not(mo.phase) then
		mo.invisible = $^^1 //Toggle invisiblity
	else //Start disappear
		mo.flags = $|MF_NOCLIPTHING
		if not(mo.invisible)
			S_StartSound(mo,sfx_s3k92)
		else //Reappear
			S_StartSound(mo,sfx_s3k8a)
			mo.attacking = 1
			attacktype(mo,true) //Prep attack type
		end
	end
	
	//Ambush attack
	if not(mo.invisible or mo.phase) then
		mo.flags = $&~MF_NOCLIPTHING
		return false //Continue fuse instructions
	else //Set next action time
		if mo.phase then
			mo.fuse = mo.telegraph
		else
			mo.fuse = mo.cooldown
		end
		return true //Gate off the fuse instructions
	end
end

//Draw control
local tdsprites = function(mo)
	if mo.pain_tics&1 then return end //pain flashing takes precedent
	if (mo.phase and leveltime&1) then
		mo.flags2 = $|MF2_DONTDRAW
	elseif not(mo.phase) and mo.invisible then
		mo.flags2 = $|MF2_DONTDRAW
	else
		mo.flags2 = $&~MF2_DONTDRAW
	end
	//Color
	mo.colorized = (mo.attacking == 1)
	if mo.colorized then
		mo.color = B.Choose(SKINCOLOR_WHITE,SKINCOLOR_RED,SKINCOLOR_YELLOW,SKINCOLOR_ORANGE)
	else
		mo.color = mo.naturalcolor
	end

	if mo.pain then
		mo.state = S_TAILSDOLL2
	elseif mo.state == S_TAILSDOLL2 then
		mo.state = S_TAILSDOLL1
	end
	
	return mo.state
end

//State/vars control
local tdstate = function(mo)
	//Regulate attack vars
	if mo.pain then
		mo.fuse = 0
	end
	//AI difficulty
	if mo.fuse == 0 then
		mo.attacking = 0 //Stationary
	end
	if mo.pain then return end
	mo.ai = 0
	if mo.hitcounter>=1 then mo.ai = 1 end //Moving
	if mo.hitcounter>=3 then mo.ai = 2 end //Attacking (Beginner; shoots bullets)
	if mo.hitcounter>=8 then mo.ai = 3 end //Attacking (Intermediate; throws bombs)
	if mo.hitcounter>=16 then mo.ai = 4 end //Attacking (Advanced; uses mix-ups) 
	if mo.hitcounter>=24 then mo.ai = 5 end //Attacking (Expert; sometimes turns invisible)
	if mo.hitcounter>=32 then mo.ai = 6 end //Attacking (Master; uses all moves at max intensity)
	//Invisibility start (Expert difficulty)
	if mo.fuse == 0 and mo.ai >= 5 and P_RandomChance(FRACUNIT*2/5) and mo.target then
		ghost(mo)
	end
end

//Skin color
local color = function(mo,n)
	if not(n) then return end
	local list = {
		SKINCOLOR_ORANGE, //1 
		SKINCOLOR_SUNSET, //2 
		SKINCOLOR_RUST, //3
		SKINCOLOR_RED, //4 
		SKINCOLOR_PURPLE, //5 
		B.FlashColor(SKINCOLOR_SUPERORANGE1,SKINCOLOR_SUPERORANGE5), //6 
	}
	mo.naturalcolor = list[n]
end

//Target finding

local gettarget = function(mo)
	if not(mo.target and mo.target.player) then
		P_LookForPlayers(mo)
	end
end

//Thinker body
B.TailsDollThinker = function(mo)
	mo.battle_atk = 0
	mo.battle_def = 0
	color(mo,mo.ai)
	if joining(mo) then return end
	if exiting(mo) then return end
	tdstate(mo)
	tdsprites(mo)
-- 	if mo.pain_tics then return end
	if mo.pain then return end
	gettarget(mo)
	hover(mo,mo.target)
	zoning(mo,mo.target)
	attack(mo,mo.target)
end

//Fuse body
B.TailsDollFuse = function(mo,t)
	//bashed gate
	if mo.pain then return end
	//ghost
	if mo.invisible or mo.phase then
		if ghost(mo) then 
			return //Fuse instructions regulated by phase/invisibility
		else
			mo.attacking = 2
		end
	end
	//Choose ghost (master difficulty)
	if mo.ai == 6 and mo.attacking == 0 and P_RandomChance(FRACUNIT/5) and t then
		ghost(mo)
	return end
	
	//target gate
	if not(t and t.valid) then return end
	//Start attack telegraph
	if mo.attacking == 0 then
		mo.fuse = mo.telegraph
		mo.attacking = 1
		attacktype(mo)
	return end
	//Launch attack
	if mo.attacking == 1 then
		mo.attacking = 2
	end
	if mo.attacktype == 0 then headbullet(mo,t) end
	if mo.attacktype == 1 then telebomb(mo,t) end
	mo.ammo = $-1
	//Multishot
	if mo.ammo then
		mo.fuse = mo.interval
	else //Restart the cycle
		mo.attacking = 0
		mo.fuse = TICRATE*2
	end
end