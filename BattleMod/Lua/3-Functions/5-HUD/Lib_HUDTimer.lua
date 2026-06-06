local B = CBW_Battle
local CV = B.Console

--Repurposed and edited this function from Lianvee's MinHUD
local cv_timelimit = CV.FindVar("timelimit")
local cv_hidetime = CV.FindVar("hidetime")

local function GetTimer(player)
	local tics
	local timelimit = cv_timelimit.value
	local hidetime = cv_hidetime.value
	if timelimit then
		timelimit = $ * 60 * TICRATE
		if gametyperules&GTR_FIXGAMESET then
			timelimit = $-(60*TICRATE)
		end
	end
	if hidetime then
		hidetime = $ * TICRATE
	end
	
	if (gametyperules & GTR_STARTCOUNTDOWN) 
		and (player.realtime <= hidetime)
	then
		tics = hidetime - player.realtime + TICRATE
		
	else
		if (gametyperules & GTR_TIMELIMIT) and timelimit then
			if timelimit > player.realtime then
				tics = timelimit - player.realtime
			else
				tics = 0	
			end
		elseif (gametyperules & GTR_STARTCOUNTDOWN) and (gametyperules & GTR_TIMELIMIT) then
			tics = timelimit - player.realtime
		elseif (gametyperules & GTR_STARTCOUNTDOWN) then
			tics = player.realtime - hidetime
		else
			tics = player.realtime
		end
	end
	
	return tics
end

B.DrawTimer = function(v, player, cam, x, y, flags)
	if not CV.FindVarString("battleconfig_hud", {"New", "Minimal"})
		or not hud.enabled("time")
	then
		return
	end

	v.draw(x+12,y+5,v.cachePatch("HUD_FADBAR"),(flags or 0)|V_REVERSESUBTRACT)

	if B.MatchPoint == 2 then
		local flash = TICRATE/2
		if (leveltime/flash & 1) then
			v.drawString(x+12, y, "FINAL", flags, "thin-center")
			v.drawString(x+12, y+8, "SHOWDOWN!!", flags, "thin-center")
		end
		return
	end

	local hud = B.GametypeHUD[gametype] or {}
	local timeproperties = hud.Timer or {}

	local p = player or displayplayer
	local tics

	if timeproperties.gettimefunc then
		tics = timeproperties.gettimefunc(p)
	end
	if tics == nil then
		tics = GetTimer(p)
	end

	local mins = G_TicsToMinutes(tics)
	local secs = G_TicsToSeconds(tics)
	local cs = G_TicsToCentiseconds(tics)
	if (mins >= 10) then
		x = $ + 4
	end
	if (cs < 10) then
		cs = "0"..$
	end
	if (mins > 99) then
		mins = 99
		secs = 59
		cs = 99
	end
	v.drawNum(x, y, mins, flags)
	v.draw(x - 2, y, v.cachePatch("STTCOLON"), flags)
	x = $ + 20
	if (secs < 10) then
		v.drawNum(x - 8, y, 0, flags)
	end
	v.drawNum(x, y, secs, flags)
	v.drawString(x, y + 4, "."..cs, flags, "thin")
end

B.TimerHUD = function(v, player, cam)
	local hud = B.GametypeHUD[gametype] or {}
	local timeproperties = hud.Timer or {}

	if hud.enabled == false then return end -- code runs if its either nil or true

	local timex = timeproperties.gamex
	local timey = timeproperties.gamey
	local timeflags = timeproperties.gameflags
	local timefunc = timeproperties.gamefunc

	if timex == nil then timex = 148 end
	if timey == nil then timey = 18 end
	if timeflags == nil then timeflags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER end
	if timefunc == nil then timefunc = B.DrawTimer end

	timefunc(v, player, cam, timex, timey, timeflags)
end
B.ScoresTimerHUD = function(v, cam)
	if not multiplayer then return end

	local hud = B.GametypeHUD[gametype] or {}
	local timeproperties = hud.Timer or {}

	if hud.enabled == false then return end -- code runs if its either nil or true

	local timex = timeproperties.scoresx
	local timey = timeproperties.scoresy
	local timeflags = timeproperties.scoresflags
	local timefunc = timeproperties.scoresfunc

	if timex == nil then timex = timeproperties.gamex end
	if timey == nil then timey = timeproperties.gamey end
	if timeflags == nil then timeflags = timeproperties.gameflags end
	if timefunc == nil then timefunc = timeproperties.gamefunc end

	if timex == nil then timex = 148 end
	if timey == nil then timey = 8 end
	if timeflags == nil then timeflags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER end
	if timefunc == nil then timefunc = B.DrawTimer end

	timefunc(v, player, cam, timex, timey, timeflags)
end