local B = CBW_Battle
local CV = B.Console
local TF_GRAY = 1
local TF_YELLOW = 2
local TF_RED = 3

B.TIMETRANS = function(time, speed, minimum, cap, debug)
    speed = speed or 1
    local level = (time / speed / 10) * 10
    level = max(10, min(100, level))
    
	if minimum then level = max($, minimum / 10 * 10) end
	if cap then level = min($, cap / 10 * 10) end

    if level == 100 then
		if debug then print(level) end
    else
		if debug then print(level) end
        return _G["V_" .. (100 - level) .. "TRANS"]
    end
end

B.RingsHUD = function(v, player, cam)
	if not (B.HUDMain)
	or not (player.battleconfig_newhud)
	or not hud.enabled("rings")
	or player.spectator
	then
		return
	end
	
	local V_HUDTRANSQUARTER = B.GetHudQuarterTrans(v)
	local flags = V_PERPLAYER|V_SNAPTOBOTTOM|V_SNAPTOLEFT
	local flags_hudtrans = V_PERPLAYER|V_HUDTRANS|V_SNAPTOBOTTOM|V_SNAPTOLEFT
	local x = 40
	local y = 180
	local num_offsetx = 4
	local num_offsety = -5
	local action_offsetx = 15
	local action_offsety = 2
	local action_offsety_line = -8
	local cooldownbar_offsetx = -6
	local cooldownnum_offsetx = 5
	if player.rings >= 1000 then
		num_offsetx = $ + 12
	elseif player.rings >= 100 then
		num_offsetx = $ + 8
	elseif player.rings >= 10 then
		num_offsetx = $ + 4
	else
		num_offsetx = $ + 1
	end
	
	--Face
	local facepatch = v.getSprite2Patch(player.skin, SPR2_SIGN)
	local facepos = 0
	if B.SkinVars[skins[player.skin].name] then
		facepos = B.SkinVars[skins[player.skin].name].hud_facepos or 0
	end
	local col = player.skincolor
	if player.rings == 0 then
		col = SKINCOLOR_PITCHBLACK
	end
	v.draw(x + 3 + facepos, 200, facepatch, flags | V_HUDTRANSHALF, v.getColormap(TC_BLINK, SKINCOLOR_PITCHBLACK))
	v.draw(x + 2 + facepos, 201, facepatch, flags | V_HUDTRANSQUARTER, v.getColormap(TC_BLINK, col))
	
	--Rings
	local scale = FRACUNIT + (player.ringhudflash * FRACUNIT/50)
	local ringpatchname = "HUD_RING"
	if (player.rings == 0 and (leveltime/5 & 1)) then
		ringpatchname = "HUD_RINGR"
	elseif player.rings < player.actionrings then
		ringpatchname = "HUD_RINGG"
	end
	local ringpatch = v.cachePatch(ringpatchname)
	v.drawScaled(x*FRACUNIT + FRACUNIT/2, y*FRACUNIT, scale, ringpatch, flags_hudtrans)

	--Actions
	if B.StunBreakAllowed(player) then
		local text = "Stun Break"
		local cost = player.stunbreakcosttext
		if cost != nil and player.rings >= cost then
			if leveltime % 3 == 0 then
				text = "\x82" + $
			elseif leveltime % 3 == 1 then
				text = "\x83" + $
			else
				text = "\x87" + $
			end
			if cost == 0 then
				cost = ""
			end
			text = $ + " \x82 "..cost
		else
			cost = ""
			text = "\x86" + $ + " \x85 "..cost
		end
		v.drawString(x + action_offsetx, y + action_offsety, text, flags_hudtrans, "thin")
	else
		if (player.actioncooldown) then
			local lastcooldown = player.lastcooldown or 1
			local scale_factor = 1000
			local scaled_ratio = (player.actioncooldown * scale_factor) / lastcooldown
			local spacing = 4 --maybe this makes it more performant?
			local angles = scaled_ratio * (360/spacing) / scale_factor
			for n=1, angles do
				local p = v.getSpritePatch("CDBR", leveltime/4 % 4, 0, n*ANG1*spacing)
				v.draw(x, y-9, p, flags_hudtrans)
			end
			--[[
			local barpatch = v.cachePatch("HUD_CDBAR"+(leveltime/2 % 4))
			local barlength = 80 * player.actioncooldown / prev
			local prev = player.lastcooldown or player.actioncooldown
			if barlength then
				for i = 0, barlength do
					v.draw(x + action_offsetx + cooldownbar_offsetx + i, y + action_offsety, barpatch, flags_hudtrans)
				end
			end
			]]
			local function roundToMultipleOf5(num)
				local remainder = num % 5
				if remainder >= 3 then
					return num + (5 - remainder)
				else
					return num - remainder
				end
			end
			local text = "\x86" + G_TicsToSeconds(player.actioncooldown) + "." + roundToMultipleOf5(G_TicsToCentiseconds(player.actioncooldown))
			--v.drawString(x + action_offsetx + cooldownbar_offsetx + cooldownnum_offsetx + barlength, y + action_offsety, text, flags_hudtrans, "thin")
			v.drawString(x, y + 14, text, flags_hudtrans, "thin-center")
		else
			if (player.actiontext) then
				local text = player.actiontext
				if player.actionstate then
					text = "\x82" + $
				else
					if not B.CanDoAction(player) then
						text = "\x86" + $
					end
					if player.actionrings and not(player.actioncooldown) then
						if not B.CanDoAction(player) then
							if (CV.RequireRings.value and player.rings < player.actionrings) then
								text = $ + "  \x85" + player.actionrings
							else
								text = $ + "  " + player.actionrings
							end
						else
							text = $ + "  \x82" + player.actionrings
						end
					end
				end
				v.drawString(x + action_offsetx, y + action_offsety, text, flags_hudtrans, "thin")
				action_offsety = $ + action_offsety_line
			end
			if (player.action2text) then
				local text = player.action2text
				local textflags = player.action2textflags
				if textflags == TF_GRAY then
					text = "\x86"+$
				elseif textflags == TF_YELLOW then
					text = "\x82"+$
				elseif textflags == TF_RED then
					text = "\x85"+$
				else
					text = "\x80"+$
				end
				v.drawString(x + action_offsetx, y + action_offsety, text, flags_hudtrans, "thin")
				action_offsety = $ + action_offsety_line
			end
		end
	end
	
	--Number
	if player.ringhudflash ~= 0 then
		local flashpatch
		if player.ringhudflash > 0 then
			flashpatch = v.cachePatch("HUD_RINGW")
		else
			flashpatch = v.cachePatch("HUD_RINGB")
		end
		local flash_trans = TR_TRANS70
		if abs(player.ringhudflash) == 1 then
			flash_trans = TR_TRANS90
		elseif abs(player.ringhudflash) == 2 then
			flash_trans = TR_TRANS80
		end
		v.drawScaled(x*FRACUNIT + FRACUNIT/2, y*FRACUNIT, scale, flashpatch, flags | flash_trans)
	end
	
	v.drawNum(x + num_offsetx, y + num_offsety, player.rings, flags_hudtrans)

	--Sweat
	local warningtic = FRACUNIT/3
	if player.exhaustmeter < warningtic then
		local frame = 0
		if player.exhaustmeter == 0 then
			frame = 1
		elseif not(leveltime % 7) then
			return
		end
		x = $+12
		y = $-12
		v.drawScaled(x*FRACUNIT + FRACUNIT/2, y*FRACUNIT, scale, v.getSpritePatch("SWET", frame), flags_hudtrans)
	end

	--Ring spent effect
	if player.spentrings then
		local scale2 = FRACUNIT*5 - (player.spentrings * (FRACUNIT*4)/(TICRATE/2))
		local transrights = B.TIMETRANS(player.spentrings * 6) or 0
		v.drawScaled(x*FRACUNIT + FRACUNIT/2, y*FRACUNIT, scale2, ringpatch, flags|transrights)
	end
end
