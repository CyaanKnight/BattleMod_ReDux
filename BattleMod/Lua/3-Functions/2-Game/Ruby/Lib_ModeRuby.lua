local B = CBW_Battle
local R = B.Ruby
local CV = B.Console
R.ID = nil
R.CheckPoint = nil
R.RedGoal = nil
R.BlueGoal = nil
R.SpawnGrace = 0
local RUBYRUN_SCORE = 250 -- The score a player gets for capping ruby in ruby run

local rotatespd = ANG20
local rubytext = "\x81".."Phantom Ruby".."\x80"

local idletics = TICRATE*16
local waittics = TICRATE*4
local freetics = TICRATE
local bounceheight = 10

local timeout = function()
	B.Timeout = R.CapAnimTime --Value is inside of Lib_ModeArena.lua
end

R.GameControl = function()
	if not(B.RubyGametype())or B.PreRoundWait() 
	then return end
	if R.ID == nil or not(R.ID.valid) then
		if CV.RubySpawnDelay.value and not(R.SpawnGrace) then
			if (R.CheckPoint and R.CheckPoint.valid) then
				R.SpawnGrace = 1
			else
				R.SpawnGrace = CV.RubySpawnDelay.value
			end
		else
			R.SpawnGrace = max(0,$-1)
			if not(R.SpawnGrace) then
				R.SpawnRuby()
			end
		end
	end
	for player in players.iterate do
		if player and player.mo and player.mo.valid then
			if R.ID and R.ID.valid then
				if not(player.mo.btagpointer) then
					player.mo.btagpointer = P_SpawnMobjFromMobj(player.mo, 0, 0, 0, MT_BTAG_POINTER)
					if player.mo.btagpointer and player.mo.btagpointer.valid then
						player.mo.btagpointer.tracer = player.mo
					end
				end

				if R.ID.target and R.ID.target.valid and R.ID.target.player and R.ID.target.player.gotcrystal then
					if not(player.mo.btagpointer2) then
						player.mo.btagpointer2 = P_SpawnMobjFromMobj(player.mo, 0, 0, 0, MT_BTAG_POINTER)
						if player.mo.btagpointer2 and player.mo.btagpointer2.valid then
							player.mo.btagpointer2.tracer = player.mo
							player.mo.btagpointer2.goalpointer = true
						end
					end
				end
			end
		end
	end
end
R.Reset = function()
	R.ID = nil
	R.CheckPoint = nil
	R.RedGoal = nil
	R.BlueGoal = nil
	B.DebugPrint("Ruby mode reset",DF_GAMETYPE)
end

R.GetSpawns = function()
	local list = {}
	for thing in mapthings.iterate do
		local t = thing.type
		if t == 3630 -- Ruby Spawn object
			list[#list+1] = thing
			B.DebugPrint("Added Ruby spawn #"..#list.. " from mapthing type "..t,DF_GAMETYPE)
		end
	end
	if not(#list)
		B.DebugPrint("No ruby spawn points found on map. Checking for backup spawn positions...",DF_GAMETYPE)
		for thing in mapthings.iterate do
			local t = thing.type
			if t == 1 -- Player 1 Spawn
			or (t >= 330 and t <= 335) -- Weapon Ring Panels
			or (t == 303) -- Infinity Ring
			or (t == 3640) -- Control Point
				list[#list+1] = thing
				B.DebugPrint("Added Ruby spawn #"..#list.. " from mapthing type "..t,DF_GAMETYPE)
			end
		end
	end
	return list
end

local function free(mo)
	if not (mo and mo.valid) then return end
	--print(true)
	mo.fuse = freetics
	mo.flags = $&~MF_SPECIAL
	mo.flags = $|MF_GRENADEBOUNCE
	mo.idle = idletics
end

R.SpawnRuby = function()
	B.DebugPrint("Attempting to spawn ruby",DF_GAMETYPE)
	local s, x, y, z
	local fu = FRACUNIT
	local usedcheckpoint
	if R.CheckPoint and R.CheckPoint.valid
		s = R.CheckPoint
		x = s.x
		y = s.y
		z = s.z
		P_RemoveMobj(R.CheckPoint)
		R.CheckPoint = nil
		usedcheckpoint = true
	else
		local list = R.GetSpawns()
		s = list[P_RandomRange(1,#list)]
		x = s.x*fu
		y = s.y*fu
		z = s.z*fu
		local subsector = R_PointInSubsector(x,y)
-- 		z = $+subsector.sector.ceilingheight
		z = $+subsector.sector.floorheight
	end
	R.ID = P_SpawnMobj(x,y,z,MT_RUBY)
	local mo = R.ID
	if mo and mo.valid
		if leveltime > 5
			S_StartSound(nil, sfx_ruby2)
			if not usedcheckpoint then
				if gametype == GT_RUBYRUN
					print("The "..rubytext.." has respawned!")
				else
					print("The "..rubytext.." has spawned!")
				end
			end
		end
		B.DebugPrint("Ruby coordinates: "..mo.x/fu..","..mo.y/fu..","..mo.z/fu,DF_GAMETYPE)
		mo.ctfteam = 0
		mo.idealz = mo.z
		if gametyperules & GTR_TEAMFLAGS
			mo.fuse = waittics
			mo.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
		end
		if usedcheckpoint then
			mo.idle = TICRATE*16
		end
	end
end

R.Collect = function(mo,toucher,playercansteal)

	local rubyIsValid 			= (mo and mo.valid)
	local targetIsValid			= rubyIsValid and (mo.target and mo.target.valid)
	local toucherIsValid 		= (toucher and toucher.valid)
	local targetIsToucher 		= targetIsValid and toucherIsValid and (mo.target == toucher)
	local toucherIsPlayer 		= toucherIsValid and toucher.player
	local targetIsPlayer 		= targetIsValid and mo.target.player
	local toucherIsPlayerInPain = toucherIsValid and toucherIsPlayer and P_PlayerInPain(toucher.player)
	local toucherIsFlashing 	= toucherIsValid and toucherIsPlayer and toucher.player.powers[pw_flashing]
	local toucherIsDead 		= toucherIsValid and toucherIsPlayer and (toucher.player.playerstate ~= PST_LIVE)
	local toucherIsParrying     = toucherIsValid and (toucherIsPlayer and toucher.player.guard)
	local toucherIsAirDodging   = toucherIsValid and (toucherIsPlayer and toucher.player.airdodge > 0)

	local teammatepass = (G_GametypeHasTeams() and (targetIsValid and toucherIsValid) and not(targetIsToucher) and (toucherIsPlayer and targetIsPlayer) and (toucher.player.ctfteam == mo.target.player.ctfteam) and (mo.target.player.cmd.buttons & BT_TOSSFLAG))

	
	if targetIsValid and toucherIsValid then
		if toucherIsPlayer and targetIsPlayer then
			if (toucherIsPlayerInPain) or (toucherIsDead) then return true end
			if not(playercansteal or teammatepass) then return true end
		end
	end


	if not(rubyIsValid) then return true end
	if not(toucherIsValid) then return true end

	if toucherIsFlashing or B.HomingDeflect(toucher.player, mo.target) then
		toucher.player.powers[pw_flashing] = max($,2)
		return true
	end

	mo.lasttouched = (targetIsValid and mo.target)
	local previoustarget = mo.target
	mo.target = toucher
	free(mo)
	mo.idle = nil
	mo.ctfteam = 0
	P_SetObjectMomZ(toucher, toucher.momz/2)
	S_StartSound(mo,sfx_lvpass)
	if (splitscreen or (displayplayer and toucher.player == displayplayer)) or (displayplayer and previoustarget and previoustarget.player and previoustarget.player == displayplayer)
		S_StartSound(nil, sfx_ruby1)
	end
	toucher.spritexscale = toucher.scale
	toucher.spriteyscale = toucher.scale

	if not(previoustarget) then
		B.PrintGameFeed(toucher.player," picked up the "..rubytext.."!")
	elseif toucher.player and previoustarget.player then
		if B.MyTeam(toucher.player, previoustarget.player) then
			B.PrintGameFeed(previoustarget.player," passed the "..rubytext.." to ",toucher.player,"!")
		else
			B.PrintGameFeed(toucher.player," stole the "..rubytext.." from ",previoustarget.player,"!")
		end	
	end
end

local points = function(player)
	if (B.Exiting) return end
	local p = 1
	P_AddPlayerScore(player,p)
	if not (gametyperules & GTR_TEAMS)
		player.gotcrystal_time = $ + 1
	end
	if gametyperules & (GTR_TEAMS|GTR_TEAMFLAGS) == GTR_TEAMS
		if player.ctfteam == 1 then
			redscore = $+p
		else
			bluescore = $+p
		end
	end
end

local capture = function(mo, player)
	if (gametype == GT_RUBYCONTROL or gametype == GT_TEAMRUBYCONTROL)
		P_AddPlayerScore(player,CV.RubyCaptureBonus.value)
	else
		P_AddPlayerScore(player,RUBYRUN_SCORE)
	end
	S_StartSound(nil, sfx_prloop)
	for p in players.iterate()
		if splitscreen and p == players[1] then 
			return
		end
 		local sfx
		local loss
		if G_GametypeHasTeams() then
			if (p.ctfteam == player.ctfteam) or p.spectator or splitscreen then
				sfx = sfx_s3k68
			else
				sfx = sfx_lose
				loss = true
			end
		else
			if (p == player) then
				sfx = sfx_s3k68
			else
				sfx = sfx_lose
				loss = true
			end
		end
		S_StartSoundAtVolume(nil, B.LongSound(player, sfx, loss), (B.LongSound(p, nil, nil, nil, true)).volume or 255, p)
	end
	P_RemoveMobj(mo)
	if R.CheckPoint and R.CheckPoint.valid
		P_RemoveMobj(R.CheckPoint)
		R.CheckPoint = nil
	end
	--Reuse CTF's capture HUD
	B.CTF.GameState.CaptureHUDTimer = 5*TICRATE
	B.CTF.GameState.CaptureHUDName = player.name
	B.CTF.GameState.CaptureHUDTeam = player.ctfteam

	player.ruby_capped = true --Know if they should do the floaty spin thing

	--vfx
	if player.mo and player.mo.valid then
		--player.mo.momz = FRACUNIT
		B.DoFirework(player.mo)
		local cooleffect = P_SpawnMobjFromMobj(player.mo,0,0,0,MT_THOK)
		cooleffect.color = SKINCOLOR_PITCHMAGENTA
		cooleffect.frame = $|FF_FULLBRIGHT
		cooleffect.blendmode = AST_ADD
		cooleffect.fuse = TICRATE*2
		cooleffect.tics = cooleffect.fuse
		cooleffect.destscale = FRACUNIT*20
		cooleffect.scalespeed = cooleffect.destscale/cooleffect.fuse
	end
end

local blink = B.Blink
local claimedscale = B.ClaimedScale
local macguffinclaimed = B.MacGuffinClaimed
local updatecheckpoint = B.UpdateCheckpoint
local handleremovalsectors = B.HandleRemovalSectors
R.Thinker = function(mo)
	mo.shadowscale = FRACUNIT>>1

	-- Idle timer
	if mo.idle != nil then 
		mo.idle = $-1
		if mo.idle == 0
			if mo.ctfteam
				-- Remove team protection
				mo.idle = nil
				mo.ctfteam = 0
			else
				-- Remove object
				if R.CheckPoint and R.CheckPoint.valid then
					P_RemoveMobj(R.CheckPoint)
					R.CheckPoint = nil
				end
				P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
				P_RemoveMobj(mo)
				return
			end
		end
	end
	
	blink(mo)
	claimedscale(mo, FRACUNIT, FRACUNIT*7/3)
	
	mo.angle = $+rotatespd
	
	--Glow
	if not (mo.light and mo.light.valid) then
		mo.light = P_SpawnMobjFromMobj(mo, 0,0,20*mo.scale, MT_INVINCIBLE_LIGHT)
	else
		local zmo = (mo.flags2&MF2_OBJECTFLIP) and (mo.z) or (mo.z+mo.height-(20*mo.scale))
		P_MoveOrigin(mo.light, mo.x, mo.y, zmo)
		--mo.tics = TICRATE
		--mo.fuse = mo.tics
	end
	local light = mo.light
	if mo.target
		light.flags2 = $|MF2_DONTDRAW
	else
		light.flags2 = $&~MF2_DONTDRAW
	end
	light.frame = ($ & ~FF_TRANSMASK) | FF_TRANS90
	light.blendmode = AST_ADD
	light.target = mo
	light.scale = mo.scale / 2
	light.colorized = true
	light.color = mo.color

	if handleremovalsectors(mo, rubytext) then
		return
	end

	for player in players.iterate do
		-- !!! I'm not sure why I resorted to an iterate function. I guess it's one way to ensure no other player thinks they have a crystal, but it's not cheap. Should be optimized later.
		if not player.mo 
			continue
		end
		if player.mo == mo.target
			if (gametype == GT_RUBYCONTROL or gametype == GT_TEAMRUBYCONTROL)
				points(player)
			end
			player.gotcrystal = true
		else
			player.gotcrystal = false
			player.gotcrystal_time = 0
		end
	end
	
	-- Owner has been pushed by another player
	if mo.flags&MF_SPECIAL and mo.target and mo.target.valid 
	and mo.target.pushed_last and mo.target.pushed_last.valid
	and mo.target.pushed_last.player
		R.Collect(mo,mo.target.pushed_last, B.MyTeam(mo.target, mo.target.pushed_last) == false)
	end
	
	-- Owner has taken damage or has gone missing
	if mo.target and mo.target.player
		if not(mo.target.valid)
		or P_PlayerInPain(mo.target.player)
		or mo.target.player.playerstate != PST_LIVE
			if mo.target and mo.target.valid and mo.target.player then
				B.PrintGameFeed(mo.target.player," dropped the "..rubytext..".")
			end
			mo.target = nil
			B.ZLaunch(mo,FRACUNIT*bounceheight/2,true)
			--B.XYLaunch(mo,mo.angle,FRACUNIT*5)	
			P_InstaThrust(mo,mo.angle,FRACUNIT*5)
			free(mo)
		end
	end
	
	-- Unclaimed behavior
	if not(mo.target and mo.target.player) then
		if mo.ctfteam == 1
			mo.color = B.FlashColor(SKINCOLOR_SUPERRED1,SKINCOLOR_SUPERRED5)
			local g = B.SpawnGhostForMobj(mo)
			g.color = mo.color
			g.colorized = true
			g.destscale = g.scale * 2
			g.blendmode = AST_ADD
		elseif mo.ctfteam == 2
			mo.color = B.FlashColor(SKINCOLOR_SUPERSKY1,SKINCOLOR_SUPERSKY5)
			local g = B.SpawnGhostForMobj(mo)
			g.color = mo.color
			g.colorized = true
			g.destscale = g.scale * 2
			g.blendmode = AST_ADD
		else
			--mo.color = B.FlashColor(SKINCOLOR_SUPERSILVER1,SKINCOLOR_SUPERSILVER5)
			if not(leveltime&3)
				local g = B.SpawnGhostForMobj(mo)
				--g.color = B.FlashRainbow()
				g.colorized = true
			end
		end
		mo.colorized = true
		
		mo.flags = ($|MF_BOUNCE)&~MF_SLIDEME
		if mo.flags & MF_GRENADEBOUNCE == 0
			mo.flags = $|MF_NOGRAVITY
			local zz = mo.idealz + (sin(leveltime * ANG10) * 128)
			B.ZLaunch(mo, (zz - mo.z) / 120, false)
			
		else
			mo.flags = $&~MF_NOGRAVITY
			if P_IsObjectOnGround(mo)
				-- Bounce behavior
				B.ZLaunch(mo, FRACUNIT*bounceheight/2, true)
				S_StartSoundAtVolume(mo, sfx_tink, 100)
				S_StartSoundAtVolume(mo, sfx_ruby3, 180)
			end
		end
		-- Presence ambience
		if not S_SoundPlaying(mo, sfx_ruby5)
			S_StartSound(mo, sfx_ruby5)
		end
		return
	end
	if S_SoundPlaying(mo, sfx_ruby5)
		S_StopSoundByID(mo, sfx_ruby5)
	end
	
	-- Claimed behavior
	mo.color = 0
	mo.colorized = false
	local g = B.SpawnGhostForMobj(mo)
	g.scale = $ * 2/3
	g.destscale = 1
	g.fuse = $ * 3
	g.scalespeed = g.scale / g.fuse
	g.blendmode = AST_ADD
	
	macguffinclaimed(mo)
	R.CheckPoint = updatecheckpoint(mo, $)
	
	local cvar_pointlimit = CV.FindVar("pointlimit").value
	local cvar_overtime = CV.FindVar("overtime").value
	local cvar_timelimit = CV.FindVar("timelimit").value
	local overtime = ((cvar_overtime) and cvar_timelimit*60-leveltime/TICRATE <= 0)

	if not(B.Exiting) then
		local t = mo.target
	
		-- Ruby Run capture mechanics
		if gametyperules & GTR_TEAMFLAGS
			if not P_IsObjectOnGround(t)
				return
			end
			local player = t.player
			if (player.ctfteam == 1) and (B.MobjTouchingFlagBase(player.mo) == 2)
				if ((redscore+1 < cvar_pointlimit) or not(cvar_pointlimit)) and not(overtime) then
					timeout()
				end
				redscore = $+1
				capture(mo, player)
				S_StartSound(nil, sfx_ruby0)
			elseif (player.ctfteam == 2) and (B.MobjTouchingFlagBase(player.mo) == 1)
				if ((bluescore+1 < cvar_pointlimit) or not(cvar_pointlimit)) and not(overtime) then
					timeout()
				end
				bluescore = $+1
				capture(mo, player)
				S_StartSound(nil, sfx_ruby0)
			end
			return
		end
	end
	
	-- Ruby Control capture mechanics
	--[[
	local captime = CV.RubyCaptureTime.value * TICRATE
	if (player.gotcrystal_time == captime - 1 * TICRATE)
	or (player.gotcrystal_time == captime - 2 * TICRATE)
	or (player.gotcrystal_time == captime - 3 * TICRATE)
		S_StartSound(nil, sfx_s227) -- Countdown sound effect
	end
	if player.gotcrystal_time >= captime
		player.gotcrystal_time = 0
		capture(mo, player)
	end
	--]]
end

/*
COM_AddCommand("ruby_capture", function(player)

	local ruby

	for mo in mobjs.iterate() do
		if mo.type == MT_RUBY then
			mo.target = player.mo
			ruby = mo
		end
	end

	--capture(ruby, player)
	--S_StartSound(nil, sfx_ruby0)
	--player.ruby_capped = true
	timeout()
end, COM_ADMIN)*/

