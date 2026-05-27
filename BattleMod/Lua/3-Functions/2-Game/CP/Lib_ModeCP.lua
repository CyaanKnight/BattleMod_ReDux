local B = CBW_Battle
local CP = B.ControlPoint
local CV = B.Console
CP.Num = 0
CP.Mode = false
CP.ID = {}
CP.TeamCapAmt = {0,0}
CP.LeadCapPlr = nil
CP.LeadCapAmt = 0
CP.Active = false
CP.Capturing = false
CP.Blocked = false
CP.Meter = 1
CP.Timer = 0
CP.HintSFX = sfx_prloop
CP.AppearSFX = sfx_ngdone
CP.StartCaptureSFX = sfx_drill1
CP.CapturingSFX = sfx_drill2
CP.BlockSFX = sfx_ngskid
CP.WinSFX = sfx_hidden
CP.LoseSFX = sfx_nxitem
CP.SFXtic = 1

CP.ThinkFrame = function(mo)
	if not(B.CPGametype() and CP.Mode) then return end
	if B.PreRoundWait() then return end
	if not(G_GametypeHasTeams()) and (CP.LeadCapAmt > 0 and not(CP.LeadCapPlr != nil and CP.LeadCapPlr.valid and CP.LeadCapPlr.playerstate == PST_LIVE and CP.LeadCapPlr.mo and CP.LeadCapPlr.mo.valid)) then
		CP.RefreshLeadCapPlr()
	end
	if ((CP.Timer <= TICRATE*10)) or CP.Active then
		for player in players.iterate do
			if not(player.mo and player.mo.valid) then
				continue
			end
			if not(player.mo.btagpointer) then
				player.mo.btagpointer = P_SpawnMobjFromMobj(player.mo, 0, 0, 0, MT_BTAG_POINTER)
				if player.mo.btagpointer and player.mo.btagpointer.valid then
					player.mo.btagpointer.tracer = player.mo
					player.mo.btagpointer.target = CP.ID[CP.Num]
				end
			end
		end
	end
	if CP.Active == true then return end
	//Countdown to activate capture point
	CP.Timer = $-1
	if CP.Timer == TICRATE*10 then
		S_StartSound(nil,CP.HintSFX)
	end
	if (CP.Timer == TICRATE or CP.Timer == TICRATE*2 or CP.Timer == TICRATE*3) then
		S_StartSound(nil,sfx_s3ka7)
	end
	if CP.Timer <= 0 then
		CP.ActivatePoint()
	end
end

CP.RefreshPoints = function()
	CP.TeamCapAmt[1] = 0
	CP.TeamCapAmt[2] = 0
	CP.LeadCapPlr = nil
	CP.LeadCapAmt = 0
	CP.Blocked = false
	CP.Capturing = false
	for player in players.iterate()
		player.captureamount = 0
		player.capturing = 0
	end
end

CP.Reset = function()
	CP.Mode = false
	CP.Active = false
	CP.ID = {}
	CP.Timer = CV.CPWait.value*TICRATE
	CP.RefreshPoints()
end

local function shuffle(set)
	local sh = {}
	local size = #set
	for n = 1,size
		while sh[n] == nil 
			local r = P_RandomRange(1,size)
			sh[n] = set[r]
			set[r] = nil
		end
	end		
	B.DebugPrint("Shuffled "..size.." indices",DF_GAMETYPE)
	return sh
end

CP.Shuffle = function()
	CP.ID = shuffle($)
end

CP.BackupGenerate = function()
	//Spawning a single backup CP at the player 1 spawn, in case something has gone wrong with the map or mode
	for mapthing in mapthings.iterate
		if mapthing.type != 1 then continue end
		local fu = FRACUNIT
		local x = mapthing.x*fu
		local y = mapthing.y*fu
		local z = mapthing.z*fu
		local subsector = R_PointInSubsector(x,y)
		if subsector.valid and subsector.sector then
			z = $+subsector.sector.floorheight
			local mo = P_SpawnMobj(x,y,z,MT_CONTROLPOINT)			
			print("Backup CP has been spawned at Player 1 start")
			return mo
		end
	end
	//Default behavior, in case somehow there's no player 1 spawns????
	print("\x82 WARNING:\x80 Viable backup CP spawn could not be found.")
	return nil
end

CP.Generate = function()
	if not(B.CPGametype()) then return end
	if #CP.ID != 0 then
		CP.ID = shuffle(CP.ID)
		CP.Mode = true
		CP.Num = 1
		return //Already have IDs? Don't need to generate more.
	end
	local id = {}
	local sp_bounce = CV.CPSpawnBounce.value
	local sp_auto = CV.CPSpawnAuto.value
	local sp_scatter = CV.CPSpawnScatter.value
	local sp_bomb = CV.CPSpawnBomb.value
	local sp_grenade = CV.CPSpawnGrenade.value
	local sp_rail = CV.CPSpawnRail.value
	local sp_inf = CV.CPSpawnInfinity.value
	local n = 1
	B.DebugPrint("Checking map things for Control Point spawn placement",DF_GAMETYPE)
	for mapthing in mapthings.iterate
		local t = mapthing.type
		//Range of types
		if not(t >= 330 and t <= 335) and not(t == 303) then continue end
		//CVar checks
		if t==303 and not(sp_inf) then continue end
		if t==330 and not(sp_bounce) then continue end
		if t==331 and not(sp_rail) then continue end
		if t==332 and not(sp_auto) then continue end
		if t==333 and not(sp_bomb) then continue end
		if t==334 and not(sp_scatter) then continue end
		if t==335 and not(sp_grenade) then continue end
		B.DebugPrint("Spawning for thing type "..t,DF_GAMETYPE)
		local fu = FRACUNIT
		local x = mapthing.x*fu
		local y = mapthing.y*fu
		local z = mapthing.z*fu
		local subsector = R_PointInSubsector(x,y)
		if subsector.valid and subsector.sector then
			z = $+subsector.sector.floorheight
			local mo = P_SpawnMobj(x,y,z,MT_CONTROLPOINT)			
			id[n] = mo
			n = $+1
		end
	end
	local size = #id
	if size then
		CP.ID = shuffle(id)
		B.DebugPrint("Shuffled "..#CP.ID.." ids",DF_GAMETYPE)
		CP.Mode = true
		CP.Num = 1
	else
		print("\x82 WARNING:\x80 No valid CP spawn positions found for current map. Attempting to spawn backup CP...")
		local mo = CP.BackupGenerate()
		if mo != nil then
			CP.Mode = true
			CP.ID = {}
			CP.Num = 1
			CP.ID[1] = mo
		else
			CP.Mode = false
		end
	end
end

CP.CalcMeter = function(value)
	local minmeter = 400
	local maxmeter = 2400
	local defaultmeter = 1200
	if value != nil and value > 0 then
		local frac = FRACUNIT*value/15
		return B.FixedLerp(minmeter*FRACUNIT,maxmeter*FRACUNIT,frac)/FRACUNIT	
	else
		return defaultmeter
	end
end

CP.CalcRadius = function(value)
	local minradius = 94*FRACUNIT
	local maxradius = 720*FRACUNIT
	local defaultradius = 384*FRACUNIT
	if value != nil and value > 0 then
		local frac = FRACUNIT*value/359
		return B.FixedLerp(minradius,maxradius,frac)
	else
		return defaultradius
	end
end

CP.CalcHeight = function(value)
	local flagheight = 96
	if value == nil or value == 0 then
		value = 2
	elseif value < 0 then
		return 0
	end
	return flagheight*value*FRACUNIT
end

CP.RandomColor = function(mo) 
	return (G_GametypeHasTeams() and mo) and mo.color
		or (SKINCOLOR_SUPERSILVER5 + P_RandomRange(0,8)*5)
end

local randomcolor = CP.RandomColor

local function createSet(mo, flip, floor, radius, quadrants, teamcolor, makeghosts)
	for n = 1, quadrants and 4 or 8 do
		local angle = n*FRACUNIT*90
		if n > 4
			angle = $-FRACUNIT*45
		end
		angle = FixedAngle($)
		local fx = P_SpawnMobj(mo.x + P_ReturnThrustX(mo, angle, radius), mo.y + P_ReturnThrustY(mo, angle, radius), floor, MT_CPBONUS)
		table.insert(mo.fx, fx)
		fx.tracer = mo
		fx.teamcolor = teamcolor or false
		fx.angle = angle
		fx.distance = radius
		fx.ghosts = makeghosts
		fx.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
		if flip == -1 
			fx.flags2 = $|MF2_OBJECTFLIP 
			fx.eflags = $|MFE_VERTICALFLIP
		end
		if quadrants and n >= 4 then break end
	end
end

local function createSplat(mo, flip, floor, radius, quadrants, teamcolor, makeghosts)
	for n = 1, quadrants and 4 or 8 do
		local angle = n*FRACUNIT*90
		if n > 4
			angle = $-FRACUNIT*45
		end
		angle = FixedAngle($)
		local fx = P_SpawnMobj(mo.x + P_ReturnThrustX(mo, angle, radius), mo.y + P_ReturnThrustY(mo, angle, radius), floor, MT_CPBONUS)
		table.insert(mo.fx, fx)
		fx.sprite = SPR_THOK
		fx.tracer = mo
		fx.teamcolor = teamcolor or false
		fx.angle = angle
		fx.distance = radius
		fx.ghosts = makeghosts
		fx.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_FLOORSPRITE
		if flip == -1 
			fx.flags2 = $|MF2_OBJECTFLIP 
			fx.eflags = $|MFE_VERTICALFLIP
		end
		if quadrants and n >= 4 then break end
	end
	
	
-- 	local fx = P_SpawnMobj(mo.x, mo.y, floor, MT_CPBONUS)
-- 	table.insert(mo.fx, fx)
-- 	fx.sprite = SPR_CPSP
-- 	fx.frame = FF_TRANS70
-- 	fx.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_FLOORSPRITE
-- 	fx.spritexscale = radius/128
-- 	fx.spriteyscale = radius/128
-- 	fx.distance = 0
-- 	fx.teamcolor = true
-- 	fx.target = mo
end


local createFull = function(mo)
	--Get CP attributes
	local radius
	local height
	if CV.CPRadius.value > 0 then --Calculate radius
		radius = CP.CalcRadius(CV.CPRadius.value)
	else
		radius = mo.cp_radius
	end
	if CV.CPHeight.value > 0 then --Calculate height
		height = CP.CalcHeight(CV.CPHeight.value)
	elseif CV.CPHeight.value == -1 then
		height = mo.ceilingz - mo.floorz
	elseif mo.cp_height > 0 then
		height = mo.cp_height
	else
		height = mo.ceilingz - mo.floorz
	end

	--Get Orientation and surfaces
	local flip = P_MobjFlip(mo)
	local floor
	local ceil
	if flip == 1 then
		floor = mo.floorz
		ceil = mo.ceilingz
	else
		floor = mo.ceilingz
		ceil = mo.floorz
	end

	-- Create object sets
	createSet(mo,	flip,	floor,					radius,		false,	false,	true)
	createSet(mo,	flip,	floor+flip*height/4,	radius/8,	true,	true,	false)
	createSet(mo,	flip,	floor+flip*height/8,	radius/16,	true,	true,	false)
	createSet(mo,	flip,	flip*height+floor,		radius,		false,	false,	true)
	createSet(mo,	flip,	flip*height*3/4+floor,	radius/8,	true,	true,	false)
	createSet(mo,	flip,	flip*height*7/8+floor,	radius/16,	true,	true,	false)
	-- Create splats
	createSplat(mo,	flip,	flip*height+floor,				radius,		false,	false,	true)
	createSplat(mo,	flip,	flip*height+floor+mo.scale*4,	radius,		false,	false,	true)
	createSplat(mo,	flip,	floor,							radius,		false,	false,	true)
	createSplat(mo,	flip,	floor+mo.scale*4,				radius,		false,	false,	true)
-- 	createSplat(mo,	floor+mo.scale*flip, radius)
-- 	createSplat(mo, flip*height+floor-mo.scale*flip, radius)
end

local createShockWaves = function(mo)
	mo.shockwaves = {}
	local amount = 24
	local angleIncrement = FixedAngle(360 * FRACUNIT / amount)

	for i = 0, amount - 1 do
		local angle = angleIncrement * i
		local x = mo.x
		local y = mo.y
		local z = mo.z + (mo.cp_height/2)
		local shockwave = P_SpawnMobj(x, y, z, MT_CPBONUS)
		if shockwave and shockwave.valid then
			shockwave.state = S_SHOCKWAVE1
			shockwave.angle = angle + ANGLE_90
			shockwave.target = mo
			table.insert(mo.shockwaves, shockwave)
		end
	end
end

CP.ActivateFX = function(mo)
	mo.flags2 = $&~MF2_SHADOW
	if #mo.fx
		return
	end
	
	-- Construct visual objects table
	createFull(mo)

	if mo.isdeathzone then
		createShockWaves(mo)
	end
end

CP.ResetFX = function(mo)
	mo.flags2 = $|MF2_SHADOW
	mo.color = SKINCOLOR_CARBON
	-- Clean up the visual objects table
	while #mo.fx do
		local fx = mo.fx[1]
		if fx and fx.valid
			P_RemoveMobj(fx)
		end
		table.remove(mo.fx, 1)
	end
	if mo.isdeathzone then
		while #mo.shockwaves do
			local shockwave = mo.shockwaves[1]
			if shockwave and shockwave.valid
				P_RemoveMobj(shockwave)
			end
			table.remove(mo.shockwaves, 1)
		end
	end
end

CP.Spawn = function(mo)
	mo.cp_radius = CP.CalcRadius()
	mo.cp_height = CP.CalcHeight()
	mo.cp_meter = CP.CalcMeter()
	mo.renderflags = $|RF_PAPERSPRITE|RF_FULLBRIGHT
	mo.fx = {} -- Objects table for visual parts
	CP.ResetFX(mo)
end

CP.MapThingSpawn = function(mo,thing)
	if not(B.CPGametype()) then
		P_RemoveMobj(mo)
	return end
	CP.ID[#CP.ID+1] = mo
	local settings = thing.options&15
	local parameters = thing.extrainfo
	local args = thing.args
	local angle = thing.angle
	local flip = 0
	
	//Meter
	--[1-15]Set amount of time to capture point
	
	if args[0] > 0 or parameters > 0 then
		mo.cp_meter = CP.CalcMeter(args[0])
	end
	
	//Radius
	--[0-384]Set the size of the CP Radius
	if args[1] > 0 or angle > 0 then
		mo.cp_radius = CP.CalcRadius(args[1])
	end
	
	//Height
	local n = 2
	--[1]Height is decreased by 50%.
	if args[2] or settings&8 then n = $-1 end //Ambush flag
	--[1]Height is increased by 100% 
	if args[3] or settings&1 then n = $+2 end //Extra flag
	--[1]Base and height are equal to the floor and ceiling height of the sector.
	if args[4] or settings&4 then n = -1 end //Special flag
	mo.cp_height = CP.CalcHeight(n)
	local fu = FRACUNIT
	B.DebugPrint("Control Point ID #"..#CP.ID..": radius "..mo.cp_radius/fu..", height "..mo.cp_height/fu..", flip "..flip..", meter "..mo.cp_meter,DF_GAMETYPE)
end

local function Wrap(num,size)
	if num > size then
		num = $-size
	end
	return num
end

CP.ActivatePoint = function()
	if not(CP.Num) then CP.Num = 1 end 
	if not(CP.ID[CP.Num] and CP.ID[CP.Num].valid) then
		print("\x82 WARNING:\x80 Next control point is invalid! Attempting to spawn backup CP...")
		local mo = CP.BackupGenerate()
		if mo != nil then
			CP.ID[CP.Num] = mo
		end
	end
	if CP.ID[CP.Num] and CP.ID[CP.Num].valid then
		CP.Mode = true
		CP.Active = true
		CP.Timer = 0
		CP.RefreshPoints()
		S_StartSound(nil,CP.AppearSFX)
		print("A\x82 Control Point\x80 has been unlocked!")
	else
		CP.Mode = false
	end
end

CP.SeizePoint = function()
	if G_GametypeHasTeams() then	//Teams
		local victor = 0
		if CP.TeamCapAmt[1] > CP.TeamCapAmt[2] then
			victor = 1
			print("\x85 Red Team captured the Control Point!")
			redscore = $+1
		end
		if CP.TeamCapAmt[2] > CP.TeamCapAmt[1] then
			victor = 2			
			print("\x84 Blue Team captured the Control Point!")
			bluescore = $+1
		end
		if not victor then
			return
		end
		if consoleplayer and consoleplayer.ctfteam == victor then
			S_StartSoundAtVolume(nil,B.ShortSound(consoleplayer, CP.WinSFX, false), (B.ShortSound(consoleplayer, nil, nil, nil, true)).volume or 255, consoleplayer)
		else
			S_StartSoundAtVolume(nil,B.ShortSound(consoleplayer, CP.LoseSFX, true, true), (B.ShortSound(consoleplayer, nil, nil, nil, true)).volume or 255, consoleplayer)
		end
	elseif CP.LeadCapPlr then //Free for all
		print(CP.LeadCapPlr.name.." captured the Control Point!")
		P_AddPlayerScore(CP.LeadCapPlr,CV.CPBonus.value)
		
		local sfx = CP.LoseSFX
		local lose = true

		for p in players.iterate()
			if splitscreen and p == players[1] then 
				return
			end
			S_StartSound(nil, sfx_s243, p)
			local sfx
			local lose
			if (p == CP.LeadCapPlr) then
				sfx = sfx_s3k68
			else
				sfx = sfx_lose
				lose = true
			end
			S_StartSoundAtVolume(nil, B.ShortSound(CP.LeadCapPlr, sfx, lose), (B.ShortSound(CP.LeadCapPlr, nil, nil, nil, true)).volume or 255, p)
		end
	end
	if CP.ID[CP.Num] and CP.ID[CP.Num].valid then
		S_StartSound(CP.ID[CP.Num], sfx_s243)
	end
	CP.RefreshPoints()
	CP.Active = false
	CP.Num = Wrap($+1,#CP.ID)
	if CP.Num == 1 then CP.Shuffle() end
	CP.Timer = CV.CPWait.value*TICRATE
	for player in players.iterate do
		if not(player.mo and player.mo.valid) then continue end
		if player.mo.btagpointer then
			if player.mo.btagpointer.valid then
				P_RemoveMobj(player.mo.btagpointer)
				player.mo.btagpointer = nil
			end
		end
	end
end

CP.PointHover = function(mo, floor, flip, height, active)
	local hover_amount = flip*height/2-mo.height/2
	local hover_speed = mo.scale*4
	local hover_accel = hover_speed/12
	if mo.z > hover_amount+floor then
		mo.momz = max(-hover_speed,$-hover_accel)
	end
	if mo.z < hover_amount+floor then	
		mo.momz = min(hover_speed,$+hover_accel)
	end
	
	--Twirl the object
	local spd = active and ANG20 or ANG1
	mo.angle = $ + spd
	
	-- Glitter
	if active and CP.Capturing and not(leveltime % 12)
		local r = mo.radius/FRACUNIT
		local h = mo.height/FRACUNIT
		local fx = P_SpawnMobjFromMobj(mo,
			P_RandomRange(-r, r)*FRACUNIT,
			P_RandomRange(-r, r)*FRACUNIT,
			P_RandomRange(0, h)*FRACUNIT,
			MT_BOXSPARKLE)
		P_SetObjectMomZ(fx, FRACUNIT)
	end
end

CP.UpdateFX = function(mo, newradius)
	for n, fx in ipairs(mo.fx) do
		if not(fx.valid)
			table.remove(mo.fx, n)
			return
		end
		if fx.extravalue1 and fx.fuse
			if not(fx.target and fx.target.valid and fx.tracer and fx.tracer.valid)
				P_RemoveMobj(fx)
				return
			end
			local frac = FRACUNIT*fx.fuse/fx.extravalue1
			local x = B.FixedLerp(fx.target.x, fx.tracer.x, frac)
			local y = B.FixedLerp(fx.target.y, fx.tracer.y, frac)
			local z = B.FixedLerp(fx.target.z + fx.target.height/2, fx.tracer.z + fx.tracer.height/2, frac)
			P_MoveOrigin(fx, x, y, z)
			return
		end
		
		-- Update color
		fx.color = fx.teamcolor and mo.color or randomcolor(mo)
		-- Update position
		if fx.sprite == SPR_CPBS
			fx.angle = $ + FixedAngle(FRACUNIT*2)
		else
			fx.angle = $ - FixedAngle(FRACUNIT*2)
		end
		P_MoveOrigin(fx,
			mo.x + P_ReturnThrustX(nil, fx.angle, fx.distance),
			mo.y + P_ReturnThrustY(nil, fx.angle, fx.distance),
			fx.z)
		-- Make ghost mobj
		if fx.ghosts
			local ghost = P_SpawnGhostMobj(fx)
			ghost.color = fx.color
			ghost.renderflags = fx.renderflags
			ghost.frame = fx.frame
		end
		if newradius then
			fx.distance = newradius
		end
	end
	-- Shockwaves (for survival)
	if mo.isdeathzone then
		local source = (displayplayer and displayplayer.mo) and displayplayer or B.GetNearestPlayer(mo)
		if source then source = source.mo end
		
		local amount = 24
		local angleIncrement = FixedAngle(360 * FRACUNIT / amount)
		local baseRadius = 300 * FRACUNIT	-- Base radius for scaling reference
		local baseScale = FRACUNIT			-- Base scale at baseRadius

		for i, shockwave in ipairs(mo.shockwaves) do
			if shockwave and shockwave.valid then
				if displayplayer and displayplayer.BT_antiAFK < 200 then
					shockwave.trans = TR_TRANS90
				elseif source and source.valid then
					local xydist = R_PointToDist2(shockwave.x, shockwave.y, source.x, source.y)
					P_MoveOrigin(shockwave, shockwave.x, shockwave.y, source.z + (source.height/2))
					shockwave.trans = B.TIMETRANS(100-(xydist/(FU*16)), 1, "TR_TRANS", "", 10, 90, false)
				end
				local angle = angleIncrement * (i - 1)
				P_MoveOrigin(shockwave,
					mo.x + FixedMul(newradius, cos(angle)),
					mo.y + FixedMul(newradius, sin(angle)),
					shockwave.z)

				-- Dynamic scaling based on radius
				local scale = FixedMul(baseScale, FixedDiv(newradius, baseRadius))
				shockwave.scale = scale
			else
				-- Remove invalid shockwaves from the table
				mo.shockwaves[i] = nil
			end
		end
	end
end

CP.ActiveThinker = function(mo,floor,flip,ceil,radius,height,meter)
	mo.flags2 = $&~MF2_SHADOW

	mo.color = SKINCOLOR_JET

	if mo.isdeathzone then return end

	//Get capturers
	local team = {0,0}
	local activeplayers = 0
	local captureplayers = 0
	for player in players.iterate()
		player.capturing = 0
		if player.spectator then continue end
		activeplayers = $+1
		if not(player.playerstate == PST_LIVE and not(player.powers[pw_flashing]) and player.mo and player.mo.valid) then continue end
		if player.mo.flags&MF_NOCLIPTHING then continue end
		if not(P_CheckSight(mo,player.mo)) then continue end 
		if not(R_PointToDist2(player.mo.x,player.mo.y,mo.x,mo.y) < radius) then continue end
-- 		if not(abs(player.mo.z-floor) < height) then continue end
		local zpos1 = player.mo.z-floor
		local zpos2 = player.mo.z+player.mo.height-floor
		if flip == 1 and (zpos1 > height or zpos2 < 0) then continue end
		if flip == -1 and (zpos2 < -height or zpos1 > 0)  then continue end
		player.capturing = 1
		local t = player.ctfteam
		captureplayers = $+1
		if t then
			team[t] = $+1
		end
	end
	--[[if G_GametypeHasTeams() and team[1] > 0 and team[2] > 0 then	//Contested point
		if team[1] != team[2] then //Uneven player amounts
			CP.Blocked = false
			//Color flash
			if leveltime&4 then
				mo.color = SKINCOLOR_GREY
			elseif team[1] > team[2] then
				mo.color = SKINCOLOR_RED
			else
				mo.color = SKINCOLOR_BLUE
			end
			//Points calculation
			if team[1] > team[2] then
				CP.TeamCapAmt[1] = $+team[1]-team[2]
			else
				CP.TeamCapAmt[2] = $+team[2]-team[1]
			end
			for player in players.iterate
				if player.capturing and not(leveltime&7) then
					P_AddPlayerScore(player,1)
				end
			end
		else //Blocked point
			mo.color = SKINCOLOR_YELLOW
			if CP.Blocked != true then
				print("\x82 Capture blocked!")
				S_StartSound(mo,CP.BlockSFX)
				CP.Blocked = true
			end
		end
		CP.LeadCapAmt = max(CP.TeamCapAmt[1],CP.TeamCapAmt[2])

	else]]if G_GametypeHasTeams() then	// Team capturing
		CP.Blocked = false
		for t = 1,2
			local amt = team[t]
			CP.TeamCapAmt[t] = $+amt
			if team[1] > team[2] then
				mo.color = SKINCOLOR_RED
			end
			if team[2] > team[1] then
				mo.color = SKINCOLOR_BLUE
			end
			for player in players.iterate
				if player.capturing and not(leveltime&3) then
					player.captureamount = $+amt --for silver crown
					P_AddPlayerScore(player,1)
				end
			end
		end
		CP.LeadCapAmt = max(CP.TeamCapAmt[1],CP.TeamCapAmt[2])

	else //Free for all capture
		CP.Blocked = false
		for player in players.iterate()
			if player.capturing then
				local amt = 2
-- 				local amt = max(1,4/captureplayers)
				player.captureamount = $+amt
				CP.LeadCapAmt = max($,player.captureamount)
				if player.captureamount == CP.LeadCapAmt and CP.LeadCapPlr != player then
					CP.LeadCapPlr = player
					print(player.name.." has taken the capture lead!")
				end
				if player == CP.LeadCapPlr then
					mo.color = player.skincolor
				end
				if not(leveltime&3)
					P_AddPlayerScore(player,amt)
				end
			end
		end
	end
	
	//Update capturing state
	if captureplayers == 0 or CP.Blocked or B.Exiting or B.Timeout then
		CP.Capturing = false
		CP.SFXtic = 1
	elseif CP.Capturing == false then
		CP.Capturing = true
		S_StartSound(mo,CP.StartCaptureSFX)
	elseif not(S_SoundPlaying(mo,CP.StartCaptureSFX)) then
		if CP.SFXtic == 1 then
			S_StartSound(mo,CP.CapturingSFX)
		end
		CP.SFXtic = Wrap($+1,8)
	end
	
	//Get CP meter
	CP.Meter = meter
	
	//Seize Point
	if CP.LeadCapAmt >= CP.Meter then
		CP.SeizePoint()
	end

	if captureplayers and not(CP.Blocked or B.Exiting or B.Timeout) then
		local interval = 3
-- 		if G_GametypeHasTeams() then
-- 			interval = 3
-- 		else
-- 			interval = min(4,captureplayers+1)
-- 		end
		if not(leveltime&(1<<interval - 1)) then
			for player in players.iterate
				if not(player.capturing) then continue end
				local b = P_SpawnMobj(mo.x,mo.y,mo.z,MT_CPBONUS)
				if b and b.valid then
					b.target = player.mo
					b.tracer = mo
					b.fuse = 10
					b.extravalue1 = b.fuse
					b.color = randomcolor()
					b.scale = $*2
				end
			end
		end
	end
end

CP.InertThinker = function(mo)
	mo.color = SKINCOLOR_CARBON
	mo.flags2 = $|MF2_SHADOW
end

CP.PointThinker = function(mo)
	//Get CP attributes
	local radius
	local height
	local meter
	if CV.CPRadius.value > 0 then //Calculate radius
		radius = CP.CalcRadius(CV.CPRadius.value)
	else
		radius = mo.cp_radius
	end
	if CV.CPHeight.value > 0 then //Calculate height
		height = CP.CalcHeight(CV.CPHeight.value)
	elseif CV.CPHeight.value == -1 then
		height = mo.ceilingz - mo.floorz
	elseif mo.cp_height > 0 then
		height = mo.cp_height
	else
		height = mo.ceilingz - mo.floorz
	end
	if CV.CPMeter.value > 0 then //Calculate meter
		meter = CP.CalcMeter(CV.CPMeter.value)
	else
		meter = mo.cp_meter
	end	

	//Get Orientation and surfaces
	local flip = P_MobjFlip(mo)
	local floor
	local ceil
	if flip == 1 then
		floor = mo.floorz
		ceil = mo.ceilingz
	else
		floor = mo.ceilingz
		ceil = mo.floorz
	end

	local active = CP.Active and mo == CP.ID[CP.Num]
	CP.PointHover(mo,floor,flip,height,active)
	
	//Do Active/Inactive Thinker instructions
	if active then
		CP.ActiveThinker(mo,floor,flip,ceil,radius,height,meter)
		if not #mo.fx then
			CP.ActivateFX(mo)
		end
		CP.UpdateFX(mo)
	elseif not mo.isdeathzone then
		--CP.InertThinker(mo)
		CP.ResetFX(mo)
	end
end

CP.RefreshLeadCapPlr = function(mo)
	CP.LeadCapPlr = nil
	CP.LeadCapAmt = 0
	for player in players.iterate()
		if player.playerstate == PST_LIVE and player.captureamount > CP.LeadCapAmt then
			CP.LeadCapPlr = player
			CP.LeadCapAmt = player.captureamount
		end
	end
end

CP.SphereThinker = function(mo)
	local tc = mo.tracer
	local tg = mo.target
	local ev = mo.extravalue1
	local fs = mo.fuse
	if not(tc and tc.valid and tg and tg.valid and ev and fs) then
		if fs < ev and fs&1 then 
			mo.flags2 = $|MF2_SHADOW 
			mo.scale = FRACUNIT*fs/ev
		else
			mo.flags2 = $&~MF2_SHADOW
		end
	return end
	local frac = FRACUNIT*fs/ev
	local x = B.FixedLerp(tg.x,tc.x,frac)
	local y = B.FixedLerp(tg.y,tc.y,frac)
	local z = B.FixedLerp(tg.z+tg.height/2,tc.z+tc.height/2,frac)
	P_MoveOrigin(mo,x,y,z)
end