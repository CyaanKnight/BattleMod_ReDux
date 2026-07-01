local B = CBW_Battle
local R = B.Ruby
local CV = B.Console
R.FadeColor = 176

local captime = CV.RubyCaptureTime.value * TICRATE

R.FadeFunc = function(v, player)

	player = $ or displayplayer

	--Ruby Run
	if ((B.Timeout > 1) or ((B.Timeout < (TICRATE + (TICRATE/5))) and player.exiting) or R.RubyFade == 10) or 
	((R.FadeColor and R.RubyFade and R.RubyFade >= 1) and player.battlespawning and (player.battlespawning > 25) and (player.battlespawning < 48)) then
		v.fadeScreen(R.FadeColor, R.RubyFade)
	end
	--Fade
end

R.HUD = function(v, player, cam)
	if not (B.HUDMain) then return end
	local newhud = CV.FindVarString("battleconfig_hud", {"New", "Minimal"})

	if B.RubyGametype() and R.SpawnGrace then
		local xoff = 320/2
		local yoff = 24
		if newhud then yoff = $+12 end
		v.drawString(xoff,yoff,R.SpawnGrace/TICRATE,V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER,"center")
	end

	if not (player.realmo and player.realmo.valid) then return end

	local ruby = R.ID
	if not (ruby and ruby.valid) then return end
	
	if newhud then
		local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
		local xoffset = 160
		local yoffset = 38
		local face_yoffset = 3
		local percent_yoffset = 5
		local rotatex = cos(leveltime*ANG20)*15
		local rotatey = sin(leveltime*ANG20)
		local frontrotate = leveltime%18 > 9
		local rubycolor = nil
		
		if ruby.color then
			rubycolor = v.getColormap(TC_RAINBOW,ruby.color)
		end
		
		if ruby.target then
			if not frontrotate then
				v.drawScaled(rotatex + xoffset*FRACUNIT, rotatey + yoffset*FRACUNIT, FRACUNIT*2/3, v.cachePatch("RAD_RUBY1"), flags, rubycolor)
			end
		else
			v.draw(xoffset, yoffset, v.cachePatch("RAD_RUBY1"), flags, rubycolor)
		end
		
		if ruby.target and ruby.target.valid and ruby.target.player then
			local playercolor = v.getColormap(ruby.target.skin, ruby.target.player.skincolor)
			local facepatch = v.getSprite2Patch(ruby.target.skin, SPR2_LIFE)
			v.drawScaled(xoffset*FU, (yoffset + face_yoffset)*FU,
				skins[ruby.target.player.skin].highresscale,
				facepatch, flags|V_FLIP, playercolor
			)
			if frontrotate then
				v.drawScaled(rotatex + xoffset*FRACUNIT, rotatey + yoffset*FRACUNIT, FRACUNIT*2/3, v.cachePatch("RAD_RUBY1"), flags, rubycolor)
			end
			local color = 0
			if R.RedGoal and R.BlueGoal and R.RedGoal.valid and R.BlueGoal.valid then
				local base = R.BlueGoal
				if (ruby.target.player.ctfteam == 2) then
					base = R.RedGoal
				end
				local distance = R_PointToDist2(0, 0, abs(ruby.target.z - base.z), R_PointToDist2(ruby.target.x, ruby.target.y, base.x, base.y))
				distance = ($ / (FRACUNIT*60))
				if (leveltime/2 % 2) and distance <= 50 then
					color = V_MAGENTAMAP
				end
				v.drawString(xoffset, yoffset + percent_yoffset, distance+"m", flags | color, "thin-center")
				
			elseif ruby.target.player.gotcrystal and ruby.target.player.gotcrystal_time then
				local percent_amt = ruby.target.player.gotcrystal_time * 100 / captime
				local percent_text = percent_amt.."%"
				if (leveltime/2 % 2) and percent_amt >= 75 then
					color = V_MAGENTAMAP
				end
				v.drawString(xoffset, yoffset + percent_yoffset, percent_text, flags | color, "thin-center")
			end
		end
		
		if ruby.idle then
			local text = ruby.idle/TICRATE
			local color = 0
			if (leveltime/2 % 2) then
				color = V_MAGENTAMAP
			end
			v.drawString(xoffset, yoffset, text, flags|color, "center") //Draw timer
		end
	else
		local id = ruby
		local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
		local xoffset = 152
		local yoffset = 4
		local angle
		local compass
		local color
		
		local xx = cam.x
		local yy = cam.y
		local zz = cam.z
		local lookang = cam.angle
		if (player.spectator or not cam.chase) and (player.realmo and player.realmo.valid) then //Use the realmo coordinates when not using chasecam
			xx = player.realmo.x
			yy = player.realmo.y
			zz = player.realmo.z
			lookang = player.cmd.angleturn<<16
		end
		
		if id.target == player.mo then
			compass = v.cachePatch("RUBY")
		else
			if twodlevel then
				angle = R_PointToAngle2(xx, zz, id.x, id.z) - ANGLE_90 + ANGLE_22h
			else
				angle = R_PointToAngle2(xx, yy, id.x, id.y) - lookang + ANGLE_22h
			end
			
			local cmpangle = 8
			if (angle >= 0) and (angle < ANGLE_45) then
				cmpangle = 1
			elseif (angle >= ANGLE_45) and (angle < ANGLE_90) then
				cmpangle = 2
			elseif (angle >= ANGLE_90) and (angle < ANGLE_135) then
				cmpangle = 3
			elseif (angle >= ANGLE_135)// and (angle < ANGLE_180) then
				cmpangle = 4
			elseif (angle >= ANGLE_180) and (angle < ANGLE_225) then
				cmpangle = 5
			elseif (angle >= ANGLE_225) and (angle < ANGLE_270) then
				cmpangle = 6
			elseif (angle >= ANGLE_270) and (angle < ANGLE_315) then
				cmpangle = 7
			end
			
			compass = v.getSpritePatch("CMPS",A,max(min(cmpangle,8),1))
		end
		local pcol = id.color
		color = v.getColormap(TC_DEFAULT,pcol)
		local cflags = flags
		if id.target == player.realmo then
			cflags = V_HUDTRANSHALF|V_SNAPTOTOP|V_PERPLAYER
		end
		//Draw
		v.draw(xoffset,yoffset,compass,cflags,color)
		
		local text = ""
		local center = 8
		local left = -2
		local right = 8
		local blue = center-1
		local red = center+1
		local bottom = 20
		local centeralign = "center"
		local leftalign = "thin-right"
		local rightalign = "thin"
		//Get timer
		if id.idle then
			local text = id.idle/TICRATE
			v.drawString(xoffset+center,yoffset+bottom,text,flags,centeralign) //Draw timer
		end
		//Get item holder
		if id.target and id.target.valid and id.target.player then
			if not(G_GametypeHasTeams()) then
				v.drawScaled((xoffset+right+(center*2))*FU, (yoffset+bottom)*FU, 
					skins[id.target.skin].highresscale,
					v.getSprite2Patch(id.target.skin, SPR2_LIFE),
					flags|V_FLIP, v.getColormap(id.target.skin, id.target.player.skincolor)
				)
			else
				v.drawScaled((xoffset+right*4+(center*2))*FU, (yoffset+bottom/2)*FU,
					skins[id.target.skin].highresscale,
					v.getSprite2Patch(id.target.skin, SPR2_LIFE),
					flags|V_FLIP, v.getColormap(id.target.skin, id.target.player.skincolor)
				)
			end
			if id.target.player.gotcrystal and id.target.player.gotcrystal_time then
				local percent_amt = id.target.player.gotcrystal_time * 100 / captime
				local percent_text = percent_amt.."%"
				v.drawString(xoffset+center,yoffset+bottom,percent_text,flags,centeralign)
			end
		end		
	end	

end

local BASEVIDWIDTH = 320
local BASEVIDHEIGHT = 200
-- Draws flag next to players' icons, shows the flag power-up icon, etc.
R.RubyRankHUD = function(v)
	-- Ensure that the gametype is custom ctf!
	if not(B.RubyGametype()) then return end

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

		local cond = (not CV.FindVar("compactscoreboard").value) and (redplayers <= 9 or blueplayers <= 9)
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
		local fx = cond and x-12 or x-5
		local fy = cond and y+10 or y+7

        if R.ID and R.ID.valid and p.gotcrystal then
            local intpatch = {v.getSpritePatch(R.ID.sprite, R.ID.frame)}

            local ring = intpatch[1]
            local flip = (intpatch[2] and V_FLIP) or 0
            v.drawScaled(fx*FRACUNIT, fy*FRACUNIT, iconscale, ring, 0|flip)
        end
	end
end