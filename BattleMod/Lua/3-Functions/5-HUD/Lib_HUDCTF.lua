local B = CBW_Battle
local F = B.CTF
local CV = CBW_Battle.Console
local BASEVIDWIDTH = 320 --NEVER CHANGE THIS! This is the original
local SEP = 33
local YPOS = 8

local yoff = 0
local yofftime = 0
local function scoreboard_detection_hacks()
	yoff = -10
	yofftime = leveltime
end
hud.add(scoreboard_detection_hacks, "scores")

local mapToEsc = {
	[0] = "\x80",
	[V_MAGENTAMAP] = "\x81",
	[V_YELLOWMAP] = "\x82",
	[V_GREENMAP] = "\x83",
	[V_BLUEMAP] = "\x84",
	[V_REDMAP] = "\x85",
	[V_GRAYMAP] = "\x86",
	[V_ORANGEMAP] = "\x87",
	[V_SKYMAP] = "\x88",
	[V_PURPLEMAP] = "\x89",
	[V_AQUAMAP] = "\x8A",
	[V_PERIDOTMAP] = "\x8B",
	[V_AZUREMAP] = "\x8C",
	[V_BROWNMAP] = "\x8D",
	[V_ROSYMAP] = "\x8E",
	[V_INVERTMAP] ="\x8F"
}


local update_pos = function(player)
	if (not player) or B.Console.FindVarString("battleconfig_hud", {"New", "Minimal"}) then
		SEP = 36
		YPOS = 12
	else
		SEP = 22
		YPOS = 0
	end
	if leveltime == 0 then
		yoff = 0
		yofftime = 0
	elseif leveltime-yofftime > 0 then
		yoff = 0
	end
end

F.CompassHUD = function(v, player, cam)
	if not (B.HUDMain) then return end
	if B.Console.FindVarString("battleconfig_hud", {"New", "Minimal"}) then return end
	if gametype ~= GT_BATTLECTF then return end -- Gametype Gateway
	--if not hud.enabled("teamscores") then return end -- Gateway.
	
	local redflag = F.RedFlag
	local blueflag = F.BlueFlag
	
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
	local xoffsetred = 152 + 20
	local xoffsetblue = 152 - 20
	local yoffset = 25
	local angle
	local cmpangle
	local compass
	local color
	
	local xx = cam.x
	local yy = cam.y
	local zz = cam.z
	local lookang = cam.angle

	--Use the realmo coordinates when not using chasecam
	if (player.spectator or not cam.chase) and (player.realmo and player.realmo.valid) then 
		xx = player.realmo.x
		yy = player.realmo.y
		zz = player.realmo.z
		lookang = player.cmd.angleturn<<16
	end
	
	color = v.getColormap(TC_DEFAULT,skincolor_redteam)
	if redflag and redflag.valid and not (player.mo and player.mo == redflag) then
		if twodlevel then
			angle = R_PointToAngle2(xx, zz, redflag.x, redflag.z) - ANGLE_90 + ANGLE_22h
		else
			angle = R_PointToAngle2(xx, yy, redflag.x, redflag.y) - lookang + ANGLE_22h
		end
		
		local cmpangle = 8
		if (angle >= 0) and (angle < ANGLE_45) then
			cmpangle = 1
		elseif (angle >= ANGLE_45) and (angle < ANGLE_90) then
			cmpangle = 2
		elseif (angle >= ANGLE_90) and (angle < ANGLE_135) then
			cmpangle = 3
		elseif (angle >= ANGLE_135) --[[and (angle < ANGLE_180)]] then
			cmpangle = 4
		elseif (angle >= ANGLE_180) and (angle < ANGLE_225) then
			cmpangle = 5
		elseif (angle >= ANGLE_225) and (angle < ANGLE_270) then
			cmpangle = 6
		elseif (angle >= ANGLE_270) and (angle < ANGLE_315) then
			cmpangle = 7
		end
		
		compass = v.getSpritePatch("CMPS",A,max(min(cmpangle,8),1))

		v.draw(xoffsetred,yoffset,compass,flags,color)
		
	elseif player.mo and player.mo == redflag then
		compass = v.cachePatch("FLAGICO")
		v.draw(xoffsetred,yoffset,compass,flags,color)
	end
	
	color = v.getColormap(TC_DEFAULT,skincolor_blueteam)
	if blueflag and blueflag.valid and not (player.mo and player.mo == blueflag) then
		if twodlevel then
			angle = R_PointToAngle2(xx, zz, blueflag.x, blueflag.z) - ANGLE_90 + ANGLE_22h
		else
			angle = R_PointToAngle2(xx, yy, blueflag.x, blueflag.y) - lookang + ANGLE_22h
		end
		
		local cmpangle = 8
		if (angle >= 0) and (angle < ANGLE_45) then
			cmpangle = 1
		elseif (angle >= ANGLE_45) and (angle < ANGLE_90) then
			cmpangle = 2
		elseif (angle >= ANGLE_90) and (angle < ANGLE_135) then
			cmpangle = 3
		elseif (angle >= ANGLE_135) --[[and (angle < ANGLE_180)]] then
			cmpangle = 4
		elseif (angle >= ANGLE_180) and (angle < ANGLE_225) then
			cmpangle = 5
		elseif (angle >= ANGLE_225) and (angle < ANGLE_270) then
			cmpangle = 6
		elseif (angle >= ANGLE_270) and (angle < ANGLE_315) then
			cmpangle = 7
		end
		
		compass = v.getSpritePatch("CMPS",A,max(min(cmpangle,8),1))

		v.draw(xoffsetblue,yoffset,compass,flags,color)

	elseif player.mo and player.mo == blueflag then
		compass = v.cachePatch("FLAGICO")
		v.draw(xoffsetblue,yoffset,compass,flags,color)
	end
end

local function getdigits(num)
	if num then
		local digits = 0
		while(num >= 10) do
			digits = $ + 1
			num = $ / 10
		end
		return digits
	end
	return 0
end

local matchpoint_flash = TICRATE/2
local matchpoint_shake = 1

local ranking = false
local function shouldDisplay(flag)
	local despawning = flag.fuse < TICRATE and not(flag.floorvfx and #flag.floorvfx)
	return flag.fuse > 1 and not despawning
end

--Bruh
local flashes = {
	[V_MAGENTAMAP] = V_ROSYMAP,
	[V_YELLOWMAP] = V_ORANGEMAP,
	[V_GREENMAP] = V_PERIDOTMAP,
	[V_BLUEMAP] = V_AZUREMAP,
	[V_REDMAP] = V_ORANGEMAP,
	[V_GRAYMAP] = nil,
	[V_ORANGEMAP] = V_REDMAP,
	[V_SKYMAP] = V_AQUAMAP,
	[V_PURPLEMAP] = V_MAGENTAMAP,
	[V_AQUAMAP] = V_SKYMAP,
	[V_PERIDOTMAP] = V_GREEMAP,
	[V_AZUREMAP] = V_BLUEMAP,
	[V_BROWNMAP] = nil,
	[V_ROSYMAP] = V_MAGENTAMAP,
	[V_INVERTMAP] = V_GRAYMAP
} 

local function drawFlagfromP(v)
	local patch_flags = V_HUDTRANS|V_PERPLAYER|V_SNAPTOTOP

	local bcol = v.getColormap(TC_DEFAULT, B.BlueTeam_Info.flagcolor or B.BlueTeam_Info.skincolor)
	local rcol = v.getColormap(TC_DEFAULT, B.RedTeam_Info.flagcolor or B.RedTeam_Info.skincolor)

	local bflagico = v.getSpritePatch(B.BlueTeam_Info.flagsprite, 2)
	local rflagico = v.getSpritePatch(B.RedTeam_Info.flagsprite, 3)

	local held = v.cachePatch("NONICON3")
	-- Thanks, "scores" -- I can't fucking use the player from the parameters
	for player in players.iterate do

		

		-- If blue flag isn't at base
		if (player.gotflag & GF_BLUEFLAG) then
			local BNON_X = BASEVIDWIDTH/2 - SEP - (held.width / 2)
			local BNON_Y = YPOS
			v.drawScaled(BNON_X*FRACUNIT, (BNON_Y+yoff)*FRACUNIT, FRACUNIT, held, patch_flags, rcol)
		end
		-- If red flag isn't at base
		if (player.gotflag & GF_REDFLAG) then 
			local RNON_X = BASEVIDWIDTH/2 + SEP - (held.width / 2)
			local RNON_Y = YPOS
			v.drawScaled(RNON_X*FRACUNIT, (RNON_Y+yoff)*FRACUNIT, FRACUNIT, held, patch_flags, bcol)
		end


		local redflag = F.RedFlag
		local blueflag = F.BlueFlag
		-- Display a countdown timer showing how much time left until the flag returns to base.
		local scr_flags = V_YELLOWMAP|V_HUDTRANS|V_PERPLAYER|V_SNAPTOTOP
		if blueflag and blueflag.valid and shouldDisplay(blueflag) then
			local BFS_X = BASEVIDWIDTH/2 - SEP
			local BFS_Y = YPOS + 8
			local bfuse = blueflag.fuse/TICRATE
			v.drawString(BFS_X, BFS_Y, bfuse, scr_flags, "center")
		end
		if redflag and redflag.valid and shouldDisplay(redflag) then
			local RFS_X = BASEVIDWIDTH/2 + SEP
			local RFS_Y = YPOS + 8
			local rfuse = redflag.fuse/TICRATE
			v.drawString(RFS_X, RFS_Y, rfuse, scr_flags, "center")
		end
	end

	-- (Will be used later for custom CTF + disable vanilla HUD indicators in first person view)
	-- Draw the flag icon in a fucking unorthodox way
	-- Also don't show this if rankings are currently being shown.
	--[[
	/*
	local player = consoleplayer
	if player.gotflag and not camera.chase and not ranking then
		-- Display flag powerup icon
		local offs_x = 288 --hudinfo[HUD_POWERUPS].x -- matches weapon rings HUD
		if player.powers[pw_shield] ~= SH_NONE then offs_x = $-20 end
		if player.powers[pw_flashing] or player.powers[pw_invulnerability] then offs_x = $-20 end
		if player.powers[pw_sneakers] then offs_x = $-20 end
		local offs_y = hudinfo[HUD_POWERUPS].y
		local flg_str = (player.gotflag == GF_REDFLAG) and "GOTRFLAG" or "GOTBFLAG"
		local flag = v.cachePatch(flg_str)
		local V_HUDFLAG = hudinfo[HUD_POWERUPS].f
		v.drawScaled(offs_x*FRACUNIT, offs_y*FRACUNIT, FRACUNIT/2, flag, V_PERPLAYER|V_HUDFLAG|V_HUDTRANS)
	end
	*/
	--]]

	local bpatch_flags, rpatch_flags = patch_flags, patch_flags
	local bscore = bluescore
	local rscore = redscore

	local red_textmap = (pcall(do return skincolors[B.RedTeam_Info.skincolor].chatcolor end) and skincolors[B.RedTeam_Info.skincolor].chatcolor) or nil
	local blue_textmap = (pcall(do return skincolors[B.BlueTeam_Info.skincolor].chatcolor end) and skincolors[B.BlueTeam_Info.skincolor].chatcolor) or nil

	-- Blue flag score (drawn here so it's always shown on top of the flag icons)
	local BFLG_SCR_X = BASEVIDWIDTH/2 - SEP - getdigits(bscore)*2
	local BFLG_SCR_Y = YPOS + 15
	if (B.MatchPoint and B.IsTeamNearLimit(bscore)) or (B.Pinch and bscore > rscore) then
		bpatch_flags = $ | ((leveltime/matchpoint_flash & 1) and blue_textmap or (flashes[blue_textmap] or 0))
		BFLG_SCR_X = $ + v.RandomRange(-matchpoint_shake,matchpoint_shake)
		BFLG_SCR_Y = $ + v.RandomRange(-matchpoint_shake,matchpoint_shake)
	end

	-- Red flag score
	local RFLG_SCR_X = BASEVIDWIDTH/2 + SEP + getdigits(rscore)*2
	local RFLG_SCR_Y = YPOS + 15
	if (B.MatchPoint and B.IsTeamNearLimit(rscore)) or (B.Pinch and rscore > bscore) then
		rpatch_flags = $ | ((leveltime/matchpoint_flash & 1) and red_textmap or (flashes[red_textmap] or 0))
		RFLG_SCR_X = $ + v.RandomRange(-matchpoint_shake,matchpoint_shake)
		RFLG_SCR_Y = $ + v.RandomRange(-matchpoint_shake,matchpoint_shake)
	end

	v.drawString(BFLG_SCR_X, BFLG_SCR_Y+yoff, bscore, bpatch_flags, "center")
	v.drawString(RFLG_SCR_X, RFLG_SCR_Y+yoff, rscore, rpatch_flags, "center")
end

local function cctf_hud(v, p, cam)
	update_pos(p)

	local patch_flags = V_HUDTRANS|V_PERPLAYER|V_SNAPTOTOP

	-- Blue flag
	local bflag = v.getSpritePatch(B.BlueTeam_Info.flagsprite or SPR_SONICFLAG, 2)
	local BFLG_POS_X = (BASEVIDWIDTH/2) - SEP - (bflag.width/4)
	local BFLG_POS_Y = YPOS + 4

	-- Red flag
	local rflag = v.getSpritePatch(B.RedTeam_Info.flagsprite or SPR_KNUCKLESFLAG, 3)
	local RFLG_POS_X = (BASEVIDWIDTH/2) + SEP - (bflag.width/4)
	local RFLG_POS_Y = YPOS + 4

	-- Unique icons (TODO: Possibly add an icon parameter to the gamemodes themselves?)
	local bcol, rcol
	local bpatch_flags, rpatch_flags = patch_flags, patch_flags
	if gametype == GT_BATTLECTF then
		bcol = v.getColormap(TC_DEFAULT, B.BlueTeam_Info.flagcolor or B.BlueTeam_Info.skincolor)
		rcol = v.getColormap(TC_DEFAULT, B.RedTeam_Info.flagcolor or B.RedTeam_Info.skincolor)
	else
		bcol = v.getColormap(TC_RAINBOW, SKINCOLOR_BLUE)
		rcol = v.getColormap(TC_RAINBOW, SKINCOLOR_RED)
	end
	if B.RubyGametype() then
		bcol = v.getColormap(TC_RAINBOW, SKINCOLOR_COBALT)
		bflag, rflag = v.cachePatch("RAD_RUBY2"), v.cachePatch("RAD_RUBY2")
	elseif B.DiamondGametype() then
		bflag, rflag = v.cachePatch("RAD_TOPAZ2"), v.cachePatch("RAD_TOPAZ2")
	elseif B.CPGametype() then
		bflag, rflag = v.cachePatch("RAD_CP2"), v.cachePatch("RAD_CP2")
		BFLG_POS_X = $ + (bflag.width/5)
		RFLG_POS_X = $ + (rflag.width/5)
		BFLG_POS_Y = $ + (bflag.height/4)
		RFLG_POS_Y = $ + (rflag.height/4)
	elseif G_GametypeUsesLives() then
		bflag = v.cachePatch("BMATCICO")
		rflag = v.cachePatch("RMATCICO")
	elseif B.ArenaGametype() then
		local frames = 24
		local spr = SPR_NCHP
		local freeze = 2
		local bframe = B.Wrap(leveltime/freeze, 1, frames)
		local rframe = B.Wrap((leveltime+12)/freeze, 1, frames)
		if spr == SPR_TRNG then
			if bframe > frames/2 then bpatch_flags = $ | V_FLIP end
			if rframe > frames/2 then rpatch_flags = $ | V_FLIP end
		end
		bflag, rflag = v.getSpritePatch(spr, bframe-1), v.getSpritePatch(spr, rframe-1)
		BFLG_POS_X = $ + (bflag.width/4)
		RFLG_POS_X = $ + (rflag.width/4)
		BFLG_POS_Y = $ + (bflag.height*2/5)
		RFLG_POS_Y = $ + (rflag.height*2/5)
	end

	-- Drawing the flags at the top of screen
	v.drawScaled(BFLG_POS_X*FRACUNIT, (BFLG_POS_Y+yoff)*FRACUNIT, FRACUNIT/2, bflag, bpatch_flags, bcol)
	v.drawScaled(RFLG_POS_X*FRACUNIT, (RFLG_POS_Y+yoff)*FRACUNIT, FRACUNIT/2, rflag, rpatch_flags, rcol)

	-- Draw player depended flag icons. etc (TODO: Move functions from ruby, tag and stuff into this)
	drawFlagfromP(v)
end

-- This will see use another time..
-- Draws flag icons on top of screen, scores, etc.
F.TeamScoreHUD = function(v, p, cam)
	if hud.enabled("teamscores") then
		hud.disable("teamscores")
	end

	if not G_GametypeHasTeams() then return end
	ranking = false
	cctf_hud(v, p, cam)
end

-- Draws flag next to players' icons, shows the flag power-up icon, etc.
F.RankingHUD = function(v)
	-- Ensure that the gametype is custom ctf!
	--if gametype ~= GT_BATTLECTF then return end
	if not (B.BattleGametype() and G_GametypeHasTeams()) then return end

	ranking = true
	cctf_hud(v)

-- TODO: RE-code all of the ranking that shows up when you press tab

	-- Draws flag icon next to flag holder when showing rankings
	local bflagico = v.getSpritePatch(B.BlueTeam_Info.flagsprite, 2)
	local rflagico = v.getSpritePatch(B.RedTeam_Info.flagsprite, 3)

	local bcol = v.getColormap(TC_DEFAULT, B.BlueTeam_Info.flagcolor or B.BlueTeam_Info.skincolor)
	local rcol = v.getColormap(TC_DEFAULT, B.RedTeam_Info.flagcolor or B.RedTeam_Info.skincolor)

	local redplayers = 0
	local blueplayers = 0
	local x, y = 0--40, 32
	

	local players_sorted = {}
	for p in players.iterate do
		table.insert(players_sorted, p)
	end

	-- Properly sort players
	-- TODO: This probably still won't work.. what to do?
	-- Maybe recode the entirety of rankings i guess? :shrug:
	table.sort(players_sorted, function(a, b)
		if a.score == b.score then
		return #a > #b
		else
		return (a.score > b.score)
		end
	end)

	for i=1, #players_sorted do
		local p = players_sorted[i]
		if p.spectator then continue end
		--if p.ctfteam == 0 then continue end

		local compact = (not CV.FindVar("compactscoreboard").value) and (redplayers <= 9 or blueplayers <= 9)
		local cond = compact
		if p.ctfteam == 1 then
			redplayers = $+1
			--if (redplayers > 8) then continue end
			if cond then 
				x = 32 + (BASEVIDWIDTH/2)
				y = (redplayers * 16) + 16
			else
				x = 14 + (BASEVIDWIDTH/2)
				y = (redplayers * 9) + 20
			end
		elseif p.ctfteam == 2 then
			blueplayers = $+1
			--if (blueplayers > 8) then continue end
			if cond then
				x = 32
				y = (blueplayers * 16) + 16
			else
				x = 14
				y = (blueplayers * 9) + 20
			end
		else 
			continue
		end

		local iconscale = cond and FRACUNIT/2 or FRACUNIT/4
		local fx = cond and x-28 or x-10
		local fy = cond and y-4 or y

		if p.gotflag & GF_REDFLAG then -- holds red flag
			v.drawScaled(fx*FRACUNIT, fy*FRACUNIT, iconscale, rflagico, 0, rcol)
		elseif p.gotflag & GF_BLUEFLAG then --holds blue flag
			v.drawScaled(fx*FRACUNIT, fy*FRACUNIT, iconscale, bflagico, 0, bcol)
		end
	end

	--[[ TODO: 32 players tab ranking draw, when the players too much ( use condition)
	for p in players.iterate do
		if (p.spectator) then continue end
		if p.ctfteam == 1 then	  -- red
			redplayers=$+1
			x = 14 + (BASEVIDWIDTH/2)
			y = (redplayers * 9) + 20
		elseif p.ctfteam == 2 then      -- blue
			blueplayers=$+1
			x = 14
			y = (blueplayers * 9) + 20
		else			    -- black
			continue
		end

		if p.gotflag & GF_REDFLAG then -- holds red flag
			v.drawScaled((x-10)*FRACUNIT, (y)*FRACUNIT, FRACUNIT/2, rflag)
		elseif p.gotflag & GF_BLUEFLAG then --holds blue flag
			v.drawScaled((x-10)*FRACUNIT, (y)*FRACUNIT, FRACUNIT/2, bflag)
		end
	end
	--]]
end

local lerpamt = FRACUNIT
F.CapHUD = function(v)
	if (gametype ~= GT_BATTLECTF) and not(B.DiamondGametype() or B.RubyGametype()) then
		return
	end

	local rcol = B.RedTeam_Info.skincolor
	local bcol = B.BlueTeam_Info.skincolor
	
	--An attempt to look exactly like the hardcode cecho
	if not(F.GameState.CaptureHUDTimer) then --... Except for the text easing in.
		lerpamt = FRACUNIT
	elseif F.GameState.CaptureHUDName and F.GameState.CaptureHUDName != "" then
		local trans = 0
		if (F.GameState.CaptureHUDTimer <= 20) then
			trans = V_10TRANS * ((20 - F.GameState.CaptureHUDTimer) / 2)
		end
		local name = F.GameState.CaptureHUDName
		local team = F.GameState.CaptureHUDTeam
		local red = (pcall(do return skincolors[rcol].chatcolor end) and mapToEsc[skincolors[rcol].chatcolor]) or mapToEsc[V_REDMAP]
		local blue = (pcall(do return skincolors[bcol].chatcolor end) and mapToEsc[skincolors[bcol].chatcolor]) or mapToEsc[V_BLUEMAP]

		local redname = B.RedTeam_Info.flagname or (pcall(do return R_GetNameByColor(rcol) end) and R_GetNameByColor(rcol):upper().." FLAG")
		local bluename = B.BlueTeam_Info.flagname or (pcall(do return R_GetNameByColor(bcol) end) and R_GetNameByColor(bcol):upper().." FLAG")

		local magenta = "\x81"
		local orange = "\x87"
		local flagtext
		local chatcolor = 0
		if G_GametypeHasTeams() then
			if (team == 1) then
				name = red + $
				flagtext = blue+bluename
			else
				name = blue + $
				flagtext = red+redname
			end
		else
			chatcolor = team --for diamond
		end
		if B.DiamondGametype() then
			flagtext = orange+"WARP TOPAZ"
		elseif B.RubyGametype() then
			flagtext = magenta+"PHANTOM RUBY"
		end
		local x = 160
		local y = B.Exiting and 160 or 66
		lerpamt = B.FixedLerp(0,FRACUNIT,$*90/100)
		local subtract = B.FixedLerp(0,180,lerpamt)
		v.drawString(x-subtract, y, name, trans|V_ALLOWLOWERCASE|chatcolor, "center")
		v.drawString(x+subtract, y + 12, "CAPTURED THE "+flagtext+"\x80.", trans, "center")
		F.GameState.CaptureHUDTimer = $ - 1
	end
end

F.DelayCapNotice = function(v, p, cam)
	if 	(F.DC_NoticeTimer >= F.NOTICE_TIME) or (F.DC_NoticeTimer < 0) or
		((gametype ~= GT_BATTLECTF) and not(B.DiamondGametype() or B.RubyGametype()))
	then
		return
	end

	local x = 160
	local y = 66


	local rcol = B.RedTeam_Info.flagcolor or B.RedTeam_Info.skincolor
	local bcol = B.BlueTeam_Info.flagcolor or B.BlueTeam_Info.skincolor

	local color = F.DC_ColorSwitch and "\x85" or "\x80"
	local flagIcon = v.cachePatch("FLAGBT")
	local bluFlag = v.getColormap(0, bcol)
	local redFlag = v.getColormap(0, rcol)

	local text1 = color+"Overtime!"
	local text2 = color+"Delay Capture Enabled!"
	local text2Width = v.stringWidth(text2)
	v.drawString(x, y, text1, V_ALLOWLOWERCASE, "center")
	v.drawString(x, y + 12, text2, V_ALLOWLOWERCASE, "center")

	local bluFlagX = (x/2)-(flagIcon.width-2)
	local redFlagX = (x/2)+(text2Width)+flagIcon.width
	v.draw(bluFlagX, y+12, flagIcon, V_FLIP,bluFlag)
	v.draw(redFlagX, y+12, flagIcon, V_FLIP,redFlag)
end

F.DelayCapBar = function(v) --, p, cam)
	if (gametype ~= GT_BATTLECTF) and not F.DelayCap and not(B.DiamondGametype() or B.RubyGametype()) then return end
	
	if consoleplayer then
		local slowcaps = {nil, nil}
		for p in players.iterate do
			if p.mo and p.mo.valid then
				slowcaps[p.ctfteam] = p.ctf_slowcap or $
			end
		end

		local x = 160
		local y = 176
		local dist = 25
		local flags = V_HUDTRANS|V_SNAPTOBOTTOM|V_PERPLAYER

		local rcol = B.RedTeam_Info.flagcolor or B.RedTeam_Info.skincolor
		local bcol = B.BlueTeam_Info.flagcolor or B.BlueTeam_Info.skincolor
		local red = (pcall(do return skincolors[rcol].chatcolor end) and skincolors[rcol].chatcolor) or V_REDMAP
		local blue = (pcall(do return skincolors[bcol].chatcolor end) and skincolors[bcol].chatcolor) or V_BLUEMAP


		if slowcaps[1] then -- Red team is capturing
			if slowcaps[2] then y = $-dist/2 end

			local width = 1+((slowcaps[1])/10)
			v.drawFill(x - width, y, width * 2, 4, flags | (72+slowcaps[1] % 8))
			v.drawString(x,y - 8, "DELAYED CAPTURE", flags|red, "thin-center")
		end

		if slowcaps[2] then -- Blue team is capturing
			if slowcaps[1] then y = $+dist end
			local width = 1+ ((slowcaps[2])/10)
			v.drawFill(x-width, y, width * 2, 4, flags | (72 + slowcaps[2] % 8))
			v.drawString(x, y - 8, "DELAYED CAPTURE", flags|blue, "thin-center")
		end
	end
end