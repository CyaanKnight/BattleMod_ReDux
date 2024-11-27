local B = CBW_Battle
local CV = B.Console
local F = B.CTF
local grace1 = CV.CTFdropgrace
local grace2 = CV.CTFrespawngrace
local FLG_SCORE = 250 -- The score a player gets for capping flag
local RET_SCORE = 200 -- The score a player gets for returning flag
F.RedScore = 0
F.BlueScore = 0
F.RedFlag = nil
F.BlueFlag = nil

-- mtopts: MapThing options (e.g. flipped gravity, etc)
-- spawnpoint: used to assign spawnpoint to the object (mapthing_t)
F.RedFlagPos = {x=0,y=0,z=0, mtopts=0, spawnpoint=nil}
F.BlueFlagPos = {x=0,y=0,z=0, mtopts=0, spawnpoint=nil}
F.RedFlagOpts = {flagbase_tag=0}
F.BlueFlagOpts = {flagbase_tag=0}

-- delay cap variables
F.DelayCap = false
F.NOTICE_TIME = TICRATE*3 -- TODO: uhh.. make it a local variable probably lol
F.DC_NoticeTimer = F.NOTICE_TIME+1 --inactive by default; this variable is used both for the HUD and to flash bases!
F.DC_ColorSwitch = true -- When true flips color text to red, when false flips to white. Used to create a flickering effect

F.TrackRed = function(mo)
	F.RedFlag = mo
end
F.TrackBlue = function(mo)
	F.BlueFlag = mo
end
F.TrackPlayers = function()
	for p in players.iterate
		if p.valid and p.mo and p.mo.valid and p.gotflag
			if p.ctfteam == 1
				F.BlueFlag = p.mo
			elseif p.ctfteam == 2
				F.RedFlag = p.mo
			end
		end
	end
end

F.TouchFlag = function(mo, pmo)
	local player = pmo.player
	if not mo.fuse
		return
	end
	if player.guard
	or player.airdodge > 0
	or (player.actionstate and (player.battle_atk or player.battle_satk))
		if P_IsObjectOnGround(mo) and not mo.jostletimer
			mo.jostletimer = 16
			S_StartSound(mo, sfx_s3k6d)
			B.ZLaunch(mo, FRACUNIT*10)
			P_InstaThrust(mo, R_PointToAngle2(pmo.x - pmo.momx, pmo.y - pmo.momy, mo.x, mo.y), mo.scale*4)
		end
		return true -- Disallow grabbing the flag while in one of these states
	end
	
	if player.powers[pw_flashing]
		player.powers[pw_flashing] = max($,2)
	end
end

F.FlagIntangible = function(mo)
	if B.CPGametype() then
		mo.flags2 = $&~MF2_DONTDRAW
		mo.flags = $&~MF_SPECIAL
	return end
	//Get spawntime
	local spawntype = 1 //flag is at base
	if mo.fuse then spawntype = 2 end //flag has been dropped

	//Flag has been dropped manually
	local lasttouched = mo.tracer or mo.target
	if lasttouched
	and lasttouched.player
	and lasttouched.player.gotflagdebuff
	and lasttouched.player.cmd.buttons & BT_TOSSFLAG
		spawntype = 3
		mo.intangibletime = 0
		S_StartSound(mo, sfx_toss)
	end

	//Initiate mo.intangibletime
	if mo.intangibletime == nil then
		if spawntype == 2 then
			mo.intangibletime = TICRATE*grace1.value
		else
			mo.intangibletime = TICRATE*grace2.value
		end
	end
	
	//Countdown
	mo.intangibletime = max(0,$-1)
	
	//Determine blink frame
	local blink = 0
	if spawntype == 2 or (spawntype == 1 and mo.intangibletime > TICRATE*2) then
		blink = mo.intangibletime&1
	else
		blink = mo.intangibletime&4
	end
	
	if blink then
		mo.flags2 = $|MF2_DONTDRAW
	else
		mo.flags2 = $&~MF2_DONTDRAW
	end

	//Determine toss blink
	local tossblink = 0
	if lasttouched and lasttouched.player then
		tossblink = lasttouched.player.tossdelay
	end

	if tossblink then
		local g = P_SpawnGhostMobj(mo)
		g.tics = 4
	end
	if tossblink&4 then
		mo.shadowscale = 1
	else
		mo.shadowscale = mo.scale
	end
	
	//Determine tangibility
	if mo.intangibletime then
		mo.flags = $&~MF_SPECIAL
	else
		mo.flags = $|MF_SPECIAL
	end
end

local function resetFlagvars()
	-- If anyone is holding the flag, get rid of it
	for p in players.iterate do
		if p.gotflag then p.gotflag = 0 end
	end
end

-- fteam: Team for which to respawn flag
-- TODO: sanity check (don't create more than 1 of one flag)
-- 1: Red team
-- 2: Blue team
local function spawnFlag(fteam, mt)
	local flagtype = fteam == 1 and MT_CREDFLAG or MT_CBLUEFLAG
	local flagpos = (fteam == 1) and F.RedFlagPos or F.BlueFlagPos
	local spawnpoint = flagpos.spawnpoint

	local x = flagpos.x
	local y = flagpos.y
	local z = flagpos.z
	local mtopts = flagpos.mtopts
	
	local obj_flip = mtopts and ((mtopts&MTF_OBJECTFLIP) == 2) or nil
	
	-- rev: thanks ... @ source code (see `P_FlagFuseThink` function)
	local ss = R_PointInSubsector(x, y)
	if obj_flip then 
		z = ss.sector.ceilingheight - mobjinfo[flagtype].height-z 
	else
		z = $+ss.sector.floorheight
	end

	local flagmo = P_SpawnMobj(x,y,z,flagtype)
	if obj_flip then
		flagmo.eflags = $|MFE_VERTICALFLIP
		flagmo.flags2 = $|MF2_OBJECTFLIP
	end

	-- rev: cept these, not source code (:
	flagmo.mtopts = mtopts
	flagmo.atbase = true
	flagmo.spawnpoint = spawnpoint
	if fteam == 1 then
		F.RedFlagOpts.flagbase_tag = flagmo.subsector.sector.tag
	elseif fteam == 2 then
		F.BlueFlagOpts.flagbase_tag = flagmo.subsector.sector.tag
	end
end

local function getFlagPosAsTables()
	local arrays = {
		r = {},
		b = {}
	}
	for mt in mapthings.iterate do
		if mt.type == 310 then -- RED FLAG
			arrays.r.x = mt.x<<FRACBITS
			arrays.r.y = mt.y<<FRACBITS
			arrays.r.z = mt.z<<FRACBITS
		elseif mt.type == 311 then  -- BLUE FLAG
			arrays.b.x = mt.x<<FRACBITS
			arrays.b.y = mt.y<<FRACBITS
			arrays.b.z = mt.z<<FRACBITS
		end
	end
	return arrays
end

local function getFlagpos()
	for mt in mapthings.iterate do
		if mt.type == 310 then -- MT_REDFLAG
			F.RedFlagPos.x = mt.x<<FRACBITS
			F.RedFlagPos.y = mt.y<<FRACBITS
			F.RedFlagPos.z = mt.z<<FRACBITS
			F.RedFlagPos.mtopts = mt.options
			F.RedFlagPos.spawnpoint = mt -- NOTE: this doesn't sync across games..?
			F.RedFlagPos.mtnum = #mt
			F.RedFlag = {}
			spawnFlag(1)
		elseif mt.type == 311 then  -- MT_BLUEFLAG
			F.BlueFlagPos.x = mt.x<<FRACBITS
			F.BlueFlagPos.y = mt.y<<FRACBITS
			F.BlueFlagPos.z = mt.z<<FRACBITS
			F.BlueFlagPos.mtopts = mt.options
			F.BlueFlagPos.spawnpoint = mt  -- NOTE: this doesn't sync across games..?
			F.BlueFlagPos.mtnum = #mt
			F.BlueFlag = {}
			spawnFlag(2)
		end
	end
end

F.ResetPlayerFlags = function()
	resetFlagvars()
end

F.LoadVars = function()
	-- Reset all flag variables
	--resetFlagvars()
	if gametype ~= GT_BATTLECTF then return end

	-- Find flag coordinates in the map, and save them; They will be used to spawn the flag
	getFlagpos()
end

-- Makes an injured or dead player lose possession of the flag.
-- if `toss` is nonzero, it indicates tossing the flag.
F.PlayerFlagBurst = function(p, toss, suicideflagdrop)
		if gametype ~= GT_BATTLECTF then return end
		if not p.gotflag and not suicideflagdrop then 
		return end -- player MUST have a flag for this to occur!
		// make sure we drop flag if played died by suicide
		if not p.gotflagdebuff and suicideflagdrop then
			return
		end
		
		if p.mo.flag_indicator then
			P_RemoveMobj(p.mo.flag_indicator)
			p.mo.flag_indicator = nil
		end
		p.gotflag = 0
		local type = p.ctfteam == 1 and MT_CBLUEFLAG or MT_CREDFLAG
		local spawnpoint = p.ctfteam == 1 and F.RedFlagPos.spawnpoint or F.BlueFlagPos.spawnpoint
		local mo = p.mo
		local flag = P_SpawnMobj(mo.x, mo.y, mo.z, type)
		flag.spawnpoint = spawnpoint
		flag.jostletimer = 8
		if (mo.eflags & MFE_VERTICALFLIP) then
			flag.flags2 = $|MF2_OBJECTFLIP
		end

		if toss then
			P_SetObjectMomZ(flag, P_MobjFlip(mo)*6*FRACUNIT, mo.scale)
			P_InstaThrust(flag, mo.angle, FixedMul(15*FRACUNIT, mo.scale))
		else
			P_SetObjectMomZ(flag, P_MobjFlip(mo)*8*FRACUNIT, mo.scale)
			-- Random range
			local fa = FixedAngle(P_RandomRange(1, 360)*FRACUNIT)
			flag.momx = FixedMul(cos(fa), FixedMul(6*FRACUNIT, mo.scale))
			if (not(twodlevel or (mo.flags2 & MF2_TWOD))) then
				flag.momy = FixedMul(sin(fa), FixedMul(6*FRACUNIT, mo.scale))
			end
		end

		local ftime = CV_FindVar("flagtime").value * TICRATE
		flag.fuse = ftime
		flag.target = mo

		-- Flag text
		local plname = p.name
		local pcolor = p.ctfteam == 1 and '\x85' or '\x84'
		local flagtext = 0
		local flagcolor = 0

		if (type == MT_CREDFLAG) then
			flagtext = "Red flag"
			flagcolor = '\x85'
		else
			flagtext = "Blue flag"
			flagcolor = '\x84'
		end
		if (toss) then
			print(pcolor..plname.."\128 tossed the "..flagcolor..flagtext..".")
		else
			print(pcolor..plname.."\128 dropped the "..flagcolor..flagtext..".")
		end

		p.gotflag = 0 -- no flag

		if (toss) then
			p.tossdelay = 2*TICRATE
		end
end

B.DoFirework = function(mo)
	local spark = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SUPERSPARK)
	if spark and spark.valid then
		spark.momz = mo.scale*4
	end
	local fw = P_SpawnMobj(mo.x,mo.y,mo.z+(mo.scale*96),MT_EFIREWORK)
	if fw and fw.valid then
		fw.speed = mo.scale
		fw.state = S_EFIREWORK0
		fw.skin = mo.skin
		fw.color = mo.color
		fw.scale = mo.scale
		fw.destscale = mo.scale*2
	end
end


-- Immediately captures the flag, increments team's score and ticks some variables on for visuals (fireworks, HUD, etc)
-- This function is meant to be used only once, so make sure you have a set condition before you use this function!!!
-- @p 	: the player who committed this action
-- @flag: 1 = red, 2 = blue
local function capFlag(p, flag)
	p.gotflag = 0
	
	if flag == 1 then F.RedScore = $+1 elseif flag == 2 then F.BlueScore = $+1 end
	spawnFlag(flag == 1 and 2 or 1) --respawn opposite team flag
	P_AddPlayerScore(p, FLG_SCORE)
	
	--sounds
	local friendly = (splitscreen or (consoleplayer and consoleplayer.ctfteam == p.ctfteam))
	if friendly then S_StartSoundAtVolume(nil, B.LongSound(p, sfx_flgcap, false), (B.LongSound(p, nil, nil, nil, true)).volume or 255) else S_StartSoundAtVolume(nil, B.LongSound(p, sfx_lose, true, true), (B.LongSound(p, nil, nil, nil, true)).volume or 255) end
	--hud
	F.GameState.CaptureHUDTimer = 5*TICRATE
	F.GameState.CaptureHUDName = p.name
	F.GameState.CaptureHUDTeam = p.ctfteam
	--vfx
	local mo = flag==1 and F.BlueFlag or F.RedFlag
	if mo and mo.valid then
		local vfx = P_SpawnMobj(mo.x,mo.y,mo.z,MT_THOK)
		if vfx and vfx.valid then
			vfx.sprite = flag==1 and SPR_BFLG or SPR_RFLG
			vfx.destscale = vfx.scale*4
			vfx.fuse = $*2
		end
		B.DoFirework(mo)
	end
	
end

local SLOWCAPPINGALLY_SFX  = sfx_s3kc3s
local SLOWCAPPINGENEMY_SFX = sfx_s3k72
-- If the delay cap consvar is ticked on, then start slowly capturing a point.
--@p 	: player committing the action
--@team : 1 = red, 2 = blue
local function delayCap(p, team)

	local dcap_timer = 0
	for player in players.iterate() do
		if player.spectator and not player.spectator_abuse then continue end
		dcap_timer = $ + 1
	end
	dcap_timer = max(5, min(16, 20 - $)) * TICRATE

	if p.spectator or not (p.mo and p.mo.valid and p.gotflag and p.ctfteam) then
		p.ctf_slowcap = nil
		return
	end

	local effect 		= 3
	local mo 			= p.mo
	local otherteam 	= team == 1 and 2 or 1
	local homeflag 		= team == 1 and MT_CREDFLAG or MT_BLUEFLAG
	local capturedflag 	= team == 1 and MT_CBLUEFLAG or MT_CREDFLAG
	local cap 			= false
	local friendly 		= (splitscreen or (consoleplayer and consoleplayer.ctfteam == team))
	local sfx			= friendly and SLOWCAPPINGALLY_SFX or SLOWCAPPINGENEMY_SFX
	
	p.ctf_slowcap = ($ == nil) and dcap_timer or $-1
	cap = (p.ctf_slowcap <= 0) and true or $
	if cap then
		capFlag(p, team)
		p.ctf_slowcap = nil
		for player in players.iterate() do
			if player.spectator and not player.spectator_abuse then continue end
			player.gotflag = 0 // its the winning score removing this from everyone should be fine
		end

	elseif p.ctf_slowcap % 35 == 11 then
		S_StartSoundAtVolume(nil, sfx, 160)
	elseif p.ctf_slowcap % 35 == 22 then
		S_StartSoundAtVolume(nil, sfx, 90)
	elseif p.ctf_slowcap % 35 == 33 then
		S_StartSoundAtVolume(nil, sfx, 20)
	end
	
	-- Small visual particles while we're slow capping
	if p.ctf_slowcap and p.ctf_slowcap % 4 == 0 then
		for i = 0, 5 do
			local dust = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SPINDUST)
			if dust.valid then
				dust.scale = $ / 3
				dust.destscale = mo.scale
				dust.state = S_SPINDUST3
				P_Thrust(dust, mo.angle + (ANG1 * 72 * i) + p.ctf_slowcap * ANG20, mo.scale * 12)
				if (mo.eflags & MFE_VERTICALFLIP) then -- readjust z position if needed
					dust.z = mo.z + mo.height - dust.height
				end
				for j = 0, 3 do
					if dust.valid then P_XYMovement(dust) end
				end
				if dust.valid then
					P_SetObjectMomZ(dust, 3*FRACUNIT, false)
				end
			end
		end
	end
end


F.FlagPreThinker = function()
	if gametype ~= GT_BATTLECTF then return end
	for p in players.iterate do
		if p and p.mo then

			local pctf_flag = ({F.RedFlag, F.BlueFlag})[p.ctfteam]
			if (type(pctf_flag) == "mobj_t") and not(p.mo.btagpointer) then
				p.mo.btagpointer = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_BTAG_POINTER)
				if p.mo.btagpointer and p.mo.btagpointer.valid then
					p.mo.btagpointer.tracer = p.mo
					p.mo.btagpointer.target = pctf_flag
				end
			end
			-- Press tossflag to tossflag
			local btns = p.cmd.buttons
			if (btns&BT_TOSSFLAG and not(p.powers[pw_carry] & CR_PLAYER) and not(p.powers[pw_super]) and not(p.tossdelay) and G_GametypeHasTeams() and p.gotflag)
			then
				F.PlayerFlagBurst(p, 1)
			end
			-- If we're not on the ground then we can't cap flag
			if not (P_IsObjectOnGround(p.mo) or (p.mo.eflags&MFE_JUSTHITFLOOR)) then 
				p.ctf_slowcap = nil -- Let's reset this even if delaycap is off
				continue
			end

			local team = p.ctfteam == 1 and SSF_REDTEAMBASE or SSF_BLUETEAMBASE
			local s = P_PlayerTouchingSectorSpecialFlag(p, team)
			if not s then continue end --then return end
			
			local obj_flip = (p.mo.flags2&MF2_OBJECTFLIP) == MF2_OBJECTFLIP
			local on_base = false
			if (s.specialflags&team) then on_base = true end

			local player_rover = p.mo.floorrover
			if player_rover then

				-- TODO: break this down into functions (see function doFlagBaseRover)
				-- look for next rover
				local next_rover = player_rover
				while next_rover ~= nil do
					local cs = next_rover.sector

					if (cs.specialflags&team) then 
						on_base = true 
						break
					else
						on_base = false
					end
					next_rover = $.next
				end

				-- look for prev rover.. if `on_base` is still false
				if not on_base then
					local prev_rover = player_rover
					while prev_rover ~= nil do
						local cs = prev_rover.sector

						if (cs.specialflags&team) then 
							on_base = true 
							break
						else
							on_base = false
						end
						prev_rover = $.prev
					end
				end
			end

			-- UDMF(?) : if this is a gravity flipped sector and we're also gravity flipped, then capture the flag
			if 		(not obj_flip and (s.flags&MSF_FLIPSPECIAL_CEILING)) then 
				on_base = false
			elseif (obj_flip and (s.flags&MSF_FLIPSPECIAL_CEILING)) then
				on_base = true
			end

			if p.gotflag and on_base then
				-- If the flag is home and we're home, cap
				if F.IsFlagAtBase(p.ctfteam) and not p.exiting then 
					capFlag(p, p.ctfteam)
					return
				end

				-- If delay cap is on, let's slowly start capturing..
				if F.DelayCap then delayCap(p, p.ctfteam) end
			end
		end
	end
end

-- Dictates what happens when you touch the flag
F.FlagTouchSpecial = function(special, toucher)
	-- Ensure that the gametype is custom ctf first!
	if gametype ~= GT_BATTLECTF then return end
	if F.TouchFlag(special, toucher) then return true end --don't interact with flag if true!

	if special and toucher and toucher.player then
		local p = toucher.player
		local pteam = p.ctfteam

		if special.type == MT_CREDFLAG or special.type == MT_CBLUEFLAG then
			-- Under these conditions, do NOT interact with the flag.
			if      p.powers[pw_flashing] or
				P_PlayerInPain(p) or
				p.playerstate ~= PST_LIVE or
				p.tossdelay
			then return true end
		end

		local fcolor_r = "\x85"
		local fcolor_b = "\x84"
		local pcolor = p.ctfteam == 1 and fcolor_r or fcolor_b

		-- If object is valid and player doesn't have tossdelay
		if special.valid and not p.tossdelay then
			-- Only interact with if you're on blu
			if special.type == MT_CREDFLAG then 
				if pteam == 2 then -- Opposite team of flag, so grab it
					p.gotflag = GF_REDFLAG
					if splitscreen or (displayplayer and p == displayplayer)
						S_StartSound(nil, sfx_lvpass)
					end
					print(pcolor+p.name+"\128 picked up the "+fcolor_r+"Red flag!")
					special.wasgrabbed = true
				elseif pteam == 1 and special.fuse then -- Same team as flag, so return it (remove the special.fuse part for sfx spam)
					special.wasreturned = true
					P_RemoveMobj(special)
					local sfx_fr = p.ctfteam == 1 and sfx_hoop1 or sfx_hoop3
					S_StartSound(nil, sfx_fr)
					print(pcolor+p.name+"\128 returned the "+fcolor_r+"Red flag\128 to base.")
					P_AddPlayerScore(p, RET_SCORE)
					return
				end
			-- Only interact with if you're on red
			elseif special.type == MT_CBLUEFLAG then
				if pteam == 1 then -- Opposite team of flag, so grab it
					p.gotflag = GF_BLUEFLAG
					if splitscreen or (displayplayer and p == displayplayer)
						S_StartSound(nil, sfx_lvpass)
					end
					print(pcolor+p.name+"\128 picked up the "+fcolor_b+"Blue flag!")
					special.wasgrabbed = true
				elseif pteam == 2 and special.fuse then -- Same team as flag, so return it (remove the special.fuse part for sfx spam)
					special.wasreturned = true
					P_RemoveMobj(special)
					local sfx_fr = p.ctfteam == 2 and sfx_hoop1 or sfx_hoop3
					S_StartSound(nil, sfx_fr)
					print(pcolor+p.name+"\128 returned the "+fcolor_b+"Blue flag\128 to base.")
					P_AddPlayerScore(p, RET_SCORE)
					return
				end
			end
		end

		-- Dumb condition: prevent same team players from grabbing their own flag
		-- TODO: maybe there's a better way, idk..
		if      special.valid and ((special.type == MT_CREDFLAG and pteam == 1) or
			(special.type == MT_CBLUEFLAG and pteam == 2))
		then
			return true 
		end
	end
end

F.FlagSpawn = function(mo)
	if gametype ~= GT_BATTLECTF then return end

	if mo and mo.type == MT_CREDFLAG or mo.type == MT_CBLUEFLAG then
		mo.shadowscale = mo.scale --set flag shadow

		-- The flag was tossed by someone, so give it fuse time
		if mo.target then mo.fuse = CV_FindVar("cv_flagtime") end
	end
end

-- Respawns the flag if it was tossed in a deathpit
F.RespawnFlag = function(mo)
	-- Ensure that the gametype is custom ctf first!
	if gametype ~= GT_BATTLECTF then return end

	-- re-spawn the flags
	if mo.type == MT_CREDFLAG then spawnFlag(1)
	elseif mo.type == MT_CBLUEFLAG then spawnFlag(2)
	end
end
F.FlagRemoved = function(mo)
	if gamestate ~= GS_LEVEL then return end
	if gametype ~= GT_BATTLECTF then return end

	-- If the flag was removed because it wasn't grabbed, then respawn it (it presumably fell in a pit or was returned by a player)
	if mo and (mo.type == MT_CREDFLAG or mo.type == MT_CBLUEFLAG) then
		if not mo.wasgrabbed then

			-- TODO: this is a duplicate, probably bad idea 
			-- Play sound and show messages, assuming the flag somehow got removed (most likely by a pit)
			if not mo.wasreturned and not mo.touched_sector then
				-- Play corresponding sounds
				local p = consoleplayer --idk, this may be bad? :shrug
				local sfx_fr = sfx_hoop3
				if p
					if mo.type == MT_CREDFLAG and not p.spectator then -- red
							sfx_fr = p.ctfteam == 2 and sfx_hoop3 or sfx_hoop1
							CONS_Printf(p, "The \133Red flag\128 has returned to base.")
					elseif mo.type == MT_CBLUEFLAG and not p.spectator then -- blu
							sfx_fr = p.ctfteam == 1 and sfx_hoop3 or sfx_hoop1
							CONS_Printf(p, "The \132Blue flag\128 has returned to base.")
					end
				end
				S_StartSound(nil, sfx_fr)
			end
			F.RespawnFlag(mo) 
		end
	end
end

F.GotFlagCheck = function(p)
	if p.mo and p.gotflag then return true end
end

local function returnFlagcheck(mo)
	if mo.type == MT_CREDFLAG or mo.type == MT_CBLUEFLAG then
		-- Check sector
		local ss = R_PointInSubsector(mo.x, mo.y)
		local special = ss.sector.special
		if (    (GetSecSpecial(special, 1) == 4) or
			(GetSecSpecial(special, 1) == 3) or
			(GetSecSpecial(special, 1) == 2) or
			(GetSecSpecial(special, 1) == 1) or
			(GetSecSpecial(special, 1) == 5) or
			(GetSecSpecial(special, 1) == 8)
			)
		then
			-- TODO: this is also a duplicate..
			if P_IsObjectOnGround(mo) then					
				-- Play corresponding sounds
				local p = consoleplayer --idk, this may be bad? :shrug
				local sfx_fr = sfx_hoop3
				if p
					if mo.type == MT_CREDFLAG and not p.spectator then -- red
							sfx_fr = p.ctfteam == 2 and sfx_hoop3 or sfx_hoop1
							CONS_Printf(p, "The \133Red flag\128 has returned to base.")
					elseif mo.type == MT_CBLUEFLAG and not p.spectator then -- blu
							sfx_fr = p.ctfteam == 1 and sfx_hoop3 or sfx_hoop1
							CONS_Printf(p, "The \132Blue flag\128 has returned to base.")
					end
				end
				S_StartSound(nil, sfx_fr)
				return true
			end
		end

		-- Check FOFs
		for fof in mo.subsector.sector.ffloors() do
			if      ((GetSecSpecial(fof.sector.special, 1) == 4 ) or -- Electric sector
				 (GetSecSpecial(fof.sector.special, 1) == 3 ) or -- Fire sector
				 (GetSecSpecial(fof.sector.special, 1) == 2 ) or -- Water damage sector
				 (GetSecSpecial(fof.sector.special, 1) == 1 ) or -- Damage sector
				 (GetSecSpecial(fof.sector.special, 1) == 5 ) or -- Spikes sector
				 (GetSecSpecial(fof.sector.special, 1) == 8 )  -- Instant kill sector
				 --or (GetSecSpecial(fof.sector.special, 1) == 6 ) or -- Death pit
				 --(GetSecSpecial(fof.sector.special, 1) == 7 )    -- Death pit
				)
				and
				((P_MobjFlip(mo) == 1 and mo.z <= fof.sector.floorheight) -- Must be above FOF if normal gravity
				or
				(P_MobjFlip(mo) == -1 and mo.z >= fof.sector.ceilingheight))
			then
				if P_IsObjectOnGround(mo) then					
					-- Play corresponding sounds
					local p = consoleplayer --idk, this may be bad? :shrug
					if mo.type == MT_CREDFLAG and not p.spectator then -- red
						local sfx_fr = p.ctfteam == 2 and sfx_hoop3 or sfx_hoop1
						S_StartSound(nil, sfx_fr)
						print("The \133Red flag\128 has returned to base.")
					elseif mo.type == MT_CBLUEFLAG and not p.spectator then -- blu
						local sfx_fr = p.ctfteam == 1 and sfx_hoop3 or sfx_hoop1
						S_StartSound(nil, sfx_fr)
						print("The \132Blue flag\128 has returned to base.")
					end
					mo.touched_sector = true
					P_RemoveMobj(mo) 
					return true
				end
			end
		end
	end
	return
end

F.FlagMobjThinker = function(mo)
	if gametype ~= GT_BATTLECTF then return end

	if mo then
		if mo.jostletimer then
			mo.jostletimer = $ - 1
		end
		local ret_check = returnFlagcheck(mo)
		if ret_check then return end
	end
end

F.DrawIndicator = function() --TODO: move this out of Lib_ModeCTF, probably
	for p in players.iterate do
		if not(p.mo and p.mo.valid) then continue end
		local pmo = p.mo
		local conditions = {(p.gotflag), (p.wanted)}
		local canhaveicon = false
		for n=1, #conditions do
			if conditions[n] then
				canhaveicon = true
				break
			end
		end
		if not(canhaveicon) then -- no conditions were met! so simply delete indicator
			if pmo and pmo.valid and pmo.flag_indicator and pmo.flag_indicator.valid then
				P_RemoveMobj(pmo.flag_indicator)
				pmo.flag_indicator = nil
			end
			continue
		end

		-- if we're here, at least one of the conditions met, so let's create a generic indicator! (if there isn't any)
		if not(pmo.flag_indicator and pmo.flag_indicator.valid) then
			pmo.flag_indicator = {}
			local icon = P_SpawnMobjFromMobj(pmo,0,0,0,MT_GOTFLAG)
			icon.frame = FF_FULLBRIGHT
			icon.fuse = 0
			icon.tics = 2
			icon.colorized = false
			
			-- then, update it based on which condition was met
			if conditions[1] then -- flag
				icon.frame = $|(p.ctfteam == 1 and 2 or 1) 
				-- TODO: mobjinfo stuff for flags so we don't have to keep comparing ctfteam to fixed numbers
			elseif conditions[2] then -- crown
				icon.sprite = SPR_CRWN
				if B.CPGametype() then
					icon.colorized = true
					icon.color = SKINCOLOR_SILVER
				end
			else -- what
				icon.sprite = SPR_UNKN
			end
			
			pmo.flag_indicator = icon -- assign the icon to be the player's indicator
		else
			pmo.flag_indicator.tics = max($,2)
		end

		-- finally, update the indicator's position
		local zfloatintensity = pmo.scale*6 --lets make things nore lively, why not?
		local zfloat = FixedMul(zfloatintensity, sin(leveltime*(ANG1*2)))
		local zoffset = (pmo.height * P_MobjFlip(pmo)) + zfloatintensity + zfloat
		if (pmo.eflags&MFE_VERTICALFLIP) then -- not sure why this is necessary, but if it works it works
			zoffset = $+(pmo.height/3)
		end
		pmo.flag_indicator.eflags = (pmo.eflags&MFE_VERTICALFLIP) and $|MFE_VERTICALFLIP or $&~MFE_VERTICALFLIP
		P_MoveOrigin(pmo.flag_indicator, pmo.x,pmo.y,pmo.z+zoffset)

		-- players can see their own indicators, so let's make it less visually obstructing for them
		if (displayplayer and p == displayplayer and not splitscreen)
			pmo.flag_indicator.scale = pmo.scale * 2/3
			pmo.flag_indicator.frame = $ | FF_TRANS30
		end
	end
end

-- 1: Red
-- 2: Blue
F.IsFlagAtBase = function(fteam)
	if fteam == 1 then -- red
		if F.RedFlag and F.RedFlag.valid and F.RedFlag.atbase then
			return true
		end
		return false
	else -- blu
		if F.BlueFlag and F.BlueFlag.valid and F.BlueFlag.atbase then
			return true
		end
		return false
	end
end

-- Remove stuff from player if they quit
F.RemoveOnQuit = function(p, reason)
	if p and p.mo and p.mo.flag_indicator then
		P_RemoveMobj(p.mo.flag_indicator)
		p.mo.flag_indicator = nil
	end
end

--example
--[[
addHook("PostThinkFrame", function()
  if not G_GametypeHasTeams() then return end
  for p in players.iterate do


  end
end)
--]]

--// rev: Updates player flag captures. e.g. If a player captures a flag, their flag cap goes up by 1.
--// NOTE: Caps reset when the map changes, in-game time resets when map changes/player spectates (see MapChange, Exec_system)
F.UpdateCaps = function(p)
	if gametype ~= GT_BATTLECTF then return end
    if not (p and p.mo) then return end

    --// Keep track of whether player doesn't have flag anymore and if their team's score just went up.
    local new_score = p.ctfteam == 1 and redscore or bluescore
    local old_score = p.oldscore
    local new_flag 	= p.gotflag
    local old_flag  = p.oldflag

    --// If for this singular frame, the new score is larger than before,
    --// and the player doesn't have the flag anymore, add 1 to the player's caps.
    if new_score > old_score and new_flag ~= old_flag then
    	p.caps = $+1
    end

    --// Refresh old team score
    p.oldscore = new_score
    p.oldflag  = new_flag

end

--F.UpdateScore = function(mo)
--	if gametype ~= GT_BATTLECTF then return end
--	redscore = F.RedScore
--	bluescore = F.BlueScore
--end


-- F.FOFOldPics = {} -- TODO -- will use later...
F.SectorOldPics = {} -- Used to keep track of sector floorpics/ceilingpics
local function isFlagBase(sect, fteam)
	local secSpecial = fteam == 1 and 3 or 4
	local ssf = fteam == 1 and SSF_REDTEAMBASE or SSF_BLUETEAMBASE
	return (GetSecSpecial(sect.special, 4) == secSpecial) or (sect.specialflags&ssf)
end

local redGrad = {
"~038", "~039", "~040",
"~041", "~042", "~043",
"~044", "~045", "~046", "~046"
}
local blueGrad = {
"~151", "~152", "~153",
"~154", "~155", "~156",
"~157", "~158", "~159", "~159"
}
local minVal = 1 -- grad tables start from index 1
local maxVal = 9 -- grad tables end at index 9 (+ index 10 is a copy because the sine wave momentarily hits 1+the max val)
local flickerFreq = 15 -- frequency at which to flicker the texture gradients.

-- Looks to see if this sector is a FOF, and if so, flashes the sector's ceiling, or resets it.
--[[/*
To determine if we're dealing with a FOF, I (reverbal) have assumed certain (weak) conditions:
	1. a FOF may not have backsectors on all its sides. This is a weak assumption because it's definitely possible for it to have sectors on all OR some of its sides.
	2. a FOF may not have tagged linedefs. 				Same argument, but with tags.
		In essence, we take a sector in this function and check for these conditions.

Based on the previous assumptions, if a sector has some empty backsectors or has at least one linedef with a tag, then we're dealing with a FOF.

@sect: 		The sector to perform the checks upon
@fteam: 	Red team or blue team? 1 for red, 2 for blue
@teamTag: 	(not used anymore, remove it?)
@reset: 	if it's set to anything that evaluates to truthy, resets this sector's ceiling textures back to normal (by looking at F.SectorOldPics).
			Otherwise, performs texture flickering.
*/--]]
local function flashTaggedFOFSector(sect, fteam, teamTag, reset)
	local texture = fteam == 1 and redGrad[1] or blueGrad[1]
	local gradientIdx = minVal+FixedMul(maxVal, (sin(FixedAngle(F.DC_NoticeTimer*FU*flickerFreq)) + FU)/2) 

	if isFlagBase(sect, fteam) then

		-- if there's a backsector on all linedefs, it means we're in an in-game sector :skull:
		-- if there's a linedef with a tag, it means we're on a sector outside the in-game sector.
		-- NOTE: Probably only battle specific, but please keep flagbase control sectors in little triangles outside the map :holding_back_tears:
		local backsecs = 0
		local unTagged = 0
		--print("=== Sector no. "+#sect)
		for i=0,#sect.lines do
			if not sect.lines[i] then continue end
			local line = sect.lines[i]
			local tag = line.tag

			backsecs = line.backsector and $+1 or $
			unTagged = tag == 0 and $+1 or $
			--print("Line backsector #"+(i+1)+": ")
			--print("  Backsector? : "+line.backsector)
			--print("  Tag number  : "+tag)
			if (backsecs >= (#sect.lines)) then return end
			
		end
		-- If the sector has untagged linedefs equal to the amount of linedefs, we'll assume it's an in-game sector and so don't do anything with it.
		if unTagged >= #sect.lines then return end
		--print("Backsectors: "+backsecs+" out of "+(#sect.lines)+" backsectors")

		-- If not resetting, just flash sectors
		if not reset then

			if sect.ceilingpic ~= "F_SKY1" then -- don't touch skies :q
				if not F.SectorOldPics[sect] then F.SectorOldPics[sect] = sect.ceilingpic end

					-- Gradient flash
					sect.ceilingpic = fteam == 1 and redGrad[gradientIdx] or blueGrad[gradientIdx]

					-- Normal flashing
					--sect.ceilingpic = F.DC_ColorSwitch and texture or F.SectorOldPics[sect]

			end

		-- Otherwise, put everything back to normal.
		else
			sect.ceilingpic = F.SectorOldPics[sect] ~= nil and F.SectorOldPics[sect] or $
		end
	end
end

-- We are checking the sector's lines to see if it's a FOF.
-- This is kind of bad, but in essence -- 
-- 		if the sector has any tagged linedefs, it's a FOF
-- 		if the sector doesn't have any tagged linedefs, it's an in-map sector.
local function flashTaggedSector(sect, fteam, teamTag, reset)
	local texture = fteam == 1 and "REDFLR" or "BLUEFLR"
	local gradientIdx = 1+FixedMul(9, (sin(FixedAngle(F.DC_NoticeTimer*FU*15)) + FU)/2) 

	if isFlagBase(sect, fteam) then
		for i=0,#sect.lines-1 do
			local tag = sect.lines[i].tag
			if tag ~= 0 then return end
		end

		-- Not resetting, so flash sector normally
		if not reset then
			if not F.SectorOldPics[sect] then F.SectorOldPics[sect] = sect.floorpic end

			-- Gradient flash
			sect.floorpic = fteam == 1 and redGrad[gradientIdx] or blueGrad[gradientIdx]

			-- Normal flashing
			--sect.floorpic = F.DC_ColorSwitch and texture or F.SectorOldPics[sect]

		-- Resetting, put everything back to normal.
		else
			sect.floorpic = F.SectorOldPics[sect] ~= nil and F.SectorOldPics[sect] or $
		end
	end
end

-- TODO: Currently doesn't work on:
-- Warped moonlight
-- Deadline
F.FlashBaseColors = function()
	local redTag = F.RedFlagOpts.flagbase_tag
	local bluTag = F.BlueFlagOpts.flagbase_tag

	-- Reset sector/FOF textures if delaycap timer is at its limit
	if F.DC_NoticeTimer >= (F.NOTICE_TIME-1) then 

		for sect in sectors.iterate do
			-- Reset flashed sectors
			flashTaggedSector(sect, 1, redTag, true)
			flashTaggedSector(sect, 2, bluTag, true)

			-- Reset flashed FOF sectors
			flashTaggedFOFSector(sect, 1, redTag, true)
			flashTaggedFOFSector(sect, 2, bluTag, true)
		end
		return
	end
	
	-- Iterate over sectors and FOFs to flash their textures
	for sect in sectors.iterate do

		flashTaggedSector(sect, 1, redTag)
		flashTaggedSector(sect, 2, bluTag)

		-- Check for FOFs associated with the flagbase and flash their ceilingpic if they exist
		flashTaggedFOFSector(sect, 1, redTag)
		flashTaggedFOFSector(sect, 2, bluTag)
	end
end

--// Enables delay cap and subsequently enables all related variables to delay cap (delay cap notice, delay cap flag base flashing, etc)
F.DelayCapActivateIndicator = function()
	if (B.DiamondGametype() or B.RubyGametype() or (gametype == GT_BANK)) then
		return
	end
	if (B.Overtime and F.DC_NoticeTimer < 0) then 
		F.DC_NoticeTimer = 0 
		F.DelayCap = true
	end
	if (F.DC_NoticeTimer >= F.NOTICE_TIME) or (F.DC_NoticeTimer < 0) or
		((gametype ~= GT_BATTLECTF) and not(B.DiamondGametype() or B.RubyGametype()))
	then 
		return 
	end

	F.FlashBaseColors()

	if (not(leveltime%3)) then F.DC_ColorSwitch = not $ end
	F.DC_NoticeTimer = $+1
end
