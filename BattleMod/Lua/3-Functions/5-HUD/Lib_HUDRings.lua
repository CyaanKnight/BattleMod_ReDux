local B = CBW_Battle
local CV = B.Console
local PR = CBW_PowerCards
local TF_WHITE = 1
local TF_YELLOW = 2
local TF_RED = 3

local function spawnSparkle(v, f, x, y, m1, m2, s)
	table.insert(hudobjs, {
		drawtype = "sprite",
		string = "SPRK",
		frame = 1,
		animlength = 8,
		animspeed = 4,
		animloop = false,
		flags = f,
		x = x,
		y = y,
		momy = m1 or 0,
		momx = m2 or 0,
		friction = FRACUNIT * 7 / 8,
		scale = s or FRACUNIT/2
	})
end

local function roundToMultipleOf5(num)
	local remainder = num % 5
	if remainder >= 3 then
		return num + (5 - remainder)
	else
		return num - remainder
	end
	return num
end

local radarColor = {SKINCOLOR_GREY, SKINCOLOR_BLUE, SKINCOLOR_SHAMROCK, SKINCOLOR_YELLOW, SKINCOLOR_ORANGE, SKINCOLOR_RED}

B.RingsHUD = function(v, player, cam)
	if not (B.HUDMain)
	or not CV.FindVarString("battleconfig_hud", {"New", "Minimal"})
	or not hud.enabled("rings")
	or player.spectator
	then
		return
	end
	
	local minimal_hud = CV.FindVarString("battleconfig_hud", "Minimal")
	local V_HUDTRANSQUARTER = B.GetHudQuarterTrans(v)
	local flags = V_PERPLAYER|V_SNAPTOBOTTOM|V_SNAPTOLEFT
	local flags_hudtrans = V_PERPLAYER|V_HUDTRANS|V_SNAPTOBOTTOM|V_SNAPTOLEFT
	local x = 39
	local y = 180
	local shake = 0
	local patch
	if (not player.playerstate) and P_PlayerInPain(player) then --p_playerinpain crashes w/ playerstate :v
		shake = 5
	elseif player.tumble then
		shake = 2
	end
	local xshake = 0
	local yshake = 0
	if shake and not (paused or player.playerstate) then
		xshake = v.RandomRange(-shake,shake)
		yshake = v.RandomRange(-shake,shake)
		x = $ + xshake
		y = $ + yshake
	end
	local num_offsetx = 4
	local num_offsety = -5
	local action_offsetx = 15
	local action_offsety = 2
	local action_offsety_line = -8
	local cooldownbar_offsetx = -6
	local cooldownnum_offsetx = 5
	local shaking = player.shakemobj and player.shakemobj.valid
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
	local col = G_GametypeHasTeams() and player.skincolor or SKINCOLOR_PITCHBLACK
	if player.rings == 0 and (leveltime/5 & 1) and not player.isjettysyn then
		col = SKINCOLOR_PITCHBLACK
	end
	v.drawScaled(
		(x + 3 + facepos)*FU, 200*FU,
		skins[player.skin].highresscale,
		facepatch, flags | V_HUDTRANSQUARTER, v.getColormap(TC_BLINK, col)
	)
	--v.draw(x + 2 + facepos, 201, facepatch, flags | V_HUDTRANSQUARTER, v.getColormap(TC_BLINK, col))

	if B.PreRoundWait() then
		v.drawString(x + action_offsetx, y + action_offsety, "GET READY...", flags_hudtrans, "thin")
		return
	end
	
	--Rings
	local scale = FRACUNIT + (player.ringhudflash * FRACUNIT/50)
	local ringpatchname = "HUD_RING"
	local actionrings = player.actionrings or player.lastactionrings or 0
	local patch2
	local patch2percent 
	if player.rings == 0 and (leveltime/5 & 1) and not (player.isjettysyn) then
		ringpatchname = "HUD_RINGR"
	elseif player.rings < actionrings then
		ringpatchname = "HUD_RINGG"
	elseif CV.RingLimit and B.BattleGametype() then
		patch2 = v.cachePatch("HUD_RINGG")
		patch2percent = FU - FixedDiv(player.rings, CV.RingLimit.value)
		patch2percent = max(0, $)
	end
	local ringpatch = v.cachePatch(ringpatchname)
	v.drawScaled(x*FRACUNIT, y*FRACUNIT, scale, ringpatch, flags_hudtrans)
	if patch2 and patch2percent then
		v.drawCropped(x*FU, y*FU, scale, scale, patch2, flags_hudtrans, nil, 0, 0, patch2.width*FU, patch2.height*patch2percent)
	elseif CV.RingLimit and B.BattleGametype() and player.rings >= CV.RingLimit.value and leveltime > TICRATE and (leveltime % 5 == 0) then
		local r = function() return v.RandomFixed() - v.RandomFixed() end
		local r1 = function() return (ringpatch.width/4)*r() end
		local r2 = function() return (ringpatch.height/4)*r() end
		local s = function() return (scale/3)+(FixedMul(scale/2, v.RandomFixed())) end
		spawnSparkle(v, flags_hudtrans, x*FU, y*FU, r1(), r2(), s())
	end

	--Chaos Ring Radar
	/*if B.BankGametype() and not(player.gotcrystal) then
		local outline = v.cachePatch("HUD_RINGC")
		if player.chaosring_radarbeeps and #player.chaosring_radarbeeps then
			v.drawScaled(x*FRACUNIT, y*FRACUNIT, scale, outline, flags_hudtrans, v.getColormap(TC_BLINK, radarColor[player.chaosring_radarbeeps[1].proximity]))
		end
	end*/

	--Actions
	local stunbreakallowed = B.StunBreakAllowed(player)
	local gotcard = player.gotpowercard and player.gotpowercard.valid
	local gotcard_debuff = gotcard and PR.Item[player.gotpowercard.item].flags&PCF_RUNNERDEBUFF
	local extra_icon = false
	if stunbreakallowed then
		local text = minimal_hud and "" or "Stun Break"
		local cost = player.stunbreakcosttext
		local noshake = false
		local colormap = nil
		if cost != nil and player.rings >= cost then
			noshake = true
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
			if not(cost) then
				cost = ""
			end
			text = "\x86" + $ + " \x85 "..cost
			colormap = v.getColormap(TC_RAINBOW, SKINCOLOR_CARBON)
		end
		patch = v.cachePatch("PARRYBT")
		local x_for_readability = x + 9 + action_offsetx - (noshake and xshake or xshake/2)
		local y_for_readability = y - 8 + action_offsety - (noshake and yshake or yshake/2)
		v.draw(x_for_readability-9, y_for_readability, patch, flags, colormap)
		v.drawString(x_for_readability+3, y_for_readability, text, flags_hudtrans, "thin")
	elseif player.tumble then
		local x_for_readability = x + 9 + action_offsetx
		local y_for_readability = y - 8 + action_offsety
		patch = v.cachePatch("PRAYBT")
		v.draw(x_for_readability-9, y_for_readability, patch, flags, colormap)
	else
		if (player.actioncooldown) then
			local lastcooldown = player.lastcooldown or 1
			local scale_factor = 1000
			local scaled_ratio = (player.actioncooldown * scale_factor) / lastcooldown
			local spacing = 4 --maybe this makes it more performant?
			local angles = scaled_ratio * (360/spacing) / scale_factor
			for n=1, angles do
				local p = v.getSpritePatch("CDBR", leveltime/4 % 4, 0, n*ANG1*spacing)
				v.draw(x-1, y-12, p, flags_hudtrans)
			end
			local text = "\x86" + G_TicsToSeconds(player.actioncooldown) + "." + roundToMultipleOf5(G_TicsToCentiseconds(player.actioncooldown))
			v.drawString(x, y + 14, text, flags_hudtrans, "thin-center")
		else
			local text = player.actiontext or player.lastactiontext or 0
			if minimal_hud then
				text = player.actionstate and "--" or ""
			end
			if shaking and player.jumpstasistimer and player.strugglerings then
				text = "          "..player.strugglerings.." COST"
				text = (leveltime%2==0) and "\131"+text or "\139"+text
			end
			local tagguardcost = B.TagGametype() and not (player.pflags & PF_TAGIT or player.battletagIT)
			if ((text or tagguardcost) and not(player.gotflagdebuff)) or gotcard_debuff then
				if player.actionstate then
					text = "\x82" + text
				else
					if gotcard_debuff then
						text = PR.Item[player.gotpowercard.item].name
						if leveltime&4 then
							text = "\x82"+$
						end
						action_offsetx = $+8
						action_offsety = $+1
						extra_icon = v.cachePatch("CARDBT")
					else
						if tagguardcost then
							text = "\x82"..(player.actionrings or "10")
							v.draw(x-14,y + 14,v.cachePatch("PARRYBT"),flags)
						else
							text = "\x86" + text
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
				end
				if extra_icon then
					v.draw(x+15,y+2,extra_icon,flags)
				end
				if minimal_hud or tagguardcost then
					v.drawString(x, y + 14, text, flags_hudtrans, "thin-center")
				else
					v.drawString(x + action_offsetx, y + action_offsety, text, flags_hudtrans, "thin")
				end
				action_offsety = $ + action_offsety_line
			end
		end
		if (player.action2text and not (minimal_hud or player.gotflagdebuff)) then
			local text = player.action2text
			local textflags = player.action2textflags
			local icon_offset = 0
			local colormap
			if textflags == TF_WHITE then
				text = "\x80"+$
			elseif textflags == TF_YELLOW then
				colormap = v.getColormap(TC_DEFAULT, SKINCOLOR_YELLOW)
				text = "\x82"+$
			elseif textflags == TF_RED then
				text = "\x85"+$
				colormap = v.getColormap(TC_DEFAULT, SKINCOLOR_RED)
			else
				text = "\x86"+$
				colormap = v.getColormap(TC_DEFAULT, SKINCOLOR_SILVER)
			end
			local yoff = 0
			if player.actioncooldown then
				yoff = -action_offsety_line*2
			end
			if colormap and not (player.gotflagdebuff) then
				v.draw(x + action_offsetx, y-2 - (action_offsety*2)+yoff, v.cachePatch("FLAGBT"), flags, colormap)
				icon_offset = 10
			end
			v.drawString(x + icon_offset + action_offsetx, y-2 - (action_offsety*2)+yoff, text, flags_hudtrans, "thin")
			--action_offsety = $ + action_offsety_line
		end
		if (player.gotflagdebuff) and not(gotcard_debuff) then
			local color = SKINCOLOR_WHITE
			local iconflags = (flags or 0)
			local icon_offsetx = 0
			local icon_offsety = 0
			patch = v.cachePatch("FLAGBT")

			if B.RubyGametype() then
				patch = v.cachePatch("RUBYBT")
				color = nil
			elseif B.DiamondGametype() then
				patch = v.cachePatch("TOPZBT")
				color = nil
			/*elseif B.BankGametype() and (player.mo and player.mo.valid and player.mo.chaosring and player.mo.chaosring.valid) then
				local ring, flip = v.getSpritePatch(SPR_TRNG, player.mo.chaosring.frame)
				scale = FRACUNIT/3
				if flip then
					iconflags = $^^V_FLIP
				end
				patch = ring
				color = ((player.mo and player.mo.valid) and 
						(player.mo.chaosring and player.mo.chaosring.valid) and 
						(player.mo.chaosring.chaosring_num and CR.Data[player.mo.chaosring.chaosring_num]) and
						CR.Data[player.mo.chaosring.chaosring_num].color) or SKINCOLOR_GOLDENROD
				icon_offsetx = 4
				icon_offsety = 11*/
			elseif G_GametypeHasTeams() then
				local flagcolors = {SKINCOLOR_BLUE, SKINCOLOR_RED}
				color = flagcolors[player.ctfteam]
			end
			local final_x = (x + action_offsetx + icon_offsetx) * FRACUNIT
			local final_y = (y - 1 + action_offsety + icon_offsety) * FRACUNIT
			local final_color = color and v.getColormap(TC_DEFAULT, color) or nil
			v.drawScaled(final_x, final_y, scale, patch, iconflags, final_color)
		end
	end
	
	--Number
	if player.ringhudflash ~= 0 then
		local flashpatch = (player.ringhudflash > 0) and v.cachePatch("HUD_RINGW") or v.cachePatch("HUD_RINGB")
		local flash_trans = TR_TRANS70
		if abs(player.ringhudflash) == 1 then
			flash_trans = TR_TRANS90
		elseif abs(player.ringhudflash) == 2 then
			flash_trans = TR_TRANS80
		end
		v.drawScaled(x*FRACUNIT, y*FRACUNIT, scale, flashpatch, flags | flash_trans)
	end

	if not (player.isjettysyn and player.rings == 0) then
		v.drawNum(x + num_offsetx, y + num_offsety, player.rings, flags_hudtrans)
	end

	--Sweat
	local warningtic = FRACUNIT/3
	if player.exhaustmeter < warningtic then
		local frame = 0
		local sprite = (player.charflags & SF_MACHINE) and "SPAK" or "SWET"
		local nodraw = false
		if player.exhaustmeter == 0 then
			frame = 1
		elseif not(leveltime % 7) then
			nodraw = true
		end
		if not nodraw then
			v.drawScaled((x+12)*FRACUNIT, (y-14)*FRACUNIT, scale, v.getSpritePatch(sprite, frame), flags_hudtrans)
		end
	end

	--Shake
	if shaking then
		local frame = B.Wrap(leveltime/2, 0, states[S_SHAKE].var1-1)
		v.drawScaled(x*FRACUNIT, y*FRACUNIT, scale, v.getSpritePatch("SHAK", frame), flags_hudtrans)
	end

	--Mash!! (so many checks :sob:)
	if player.powers[pw_carry] and player.mo and player.mo.valid
	and player.mo.tracer and player.mo.tracer.valid and player.mo.tracer.player
	and not B.MyTeam(player, player.mo.tracer.player) then
		local color = v.getColormap(nil, player.mo.tracer.color)
		local frame = (player.realbuttons & BT_JUMP) and "A" or "B"
		v.drawScaled(172*FRACUNIT, 140*FRACUNIT, scale, v.cachePatch("MASH"..frame), flags_hudtrans, color)
		if (not shaking) and leveltime % 4 >= 2 then
			v.drawScaled(172*FRACUNIT, 140*FRACUNIT, scale, v.cachePatch("MASHC"), flags_hudtrans, color)
		end
		--Opponent cooldown
		local opponent = player.mo.tracer.player
		if opponent and opponent.actioncooldown then
			local barpatch = v.cachePatch("HUD_CDBAR"+(leveltime/2 % 4))
			local prev = opponent.lastcooldown or opponent.actioncooldown
			local barlength = 80 * opponent.actioncooldown / prev
			if barlength then
				for i = 0, barlength do
					v.draw(172 + i, 170, barpatch, flags_hudtrans)
				end
			end
			local text = "\x86" + G_TicsToSeconds(opponent.actioncooldown) + "." + roundToMultipleOf5(G_TicsToCentiseconds(opponent.actioncooldown))
			v.drawString(172 + cooldownnum_offsetx + barlength, 170, text, flags_hudtrans, "thin")
		end
	end

	--Ring spent effect
	if player.spentrings then
		local scale2 = FRACUNIT*5 - (player.spentrings * (FRACUNIT*4)/(TICRATE/2))
		local transrights = B.TIMETRANS(player.spentrings * 6) or 0
		v.drawScaled(x*FRACUNIT, y*FRACUNIT, scale2, ringpatch, flags|transrights)
	end

	if B.TagGametype() and player.actioncooldown and not (player.battletagIT or player.pflags & PF_TAGIT) then
		return
	end

	--GUARD
	local mo = player.mo
	if not(mo and mo.valid) then return end
	if player.tumble or stunbreakallowed then return end
	local guardoverride = tonumber(player.canguard) and tonumber(player.canguard) > 1 and not player.deadtimer

	x = $+20
	y = $-6
	
	local canguard = (player.canguard
		and CV.Guard.value
		and CV.parrytoggle.value
		and P_IsObjectOnGround(mo)
		and not player.actionstate
		and not P_PlayerInPain(player)
		and not player.guard
		and not player.actionstate
		and not (player.skidtime and player.powers[pw_nocontrol])
		--and not (mo.eflags & MFE_JUSTHITFLOOR)
		and not (player.weapondelay and mo.state == S_PLAY_FIRE)
		and leveltime > TICRATE*5/4
	)
	local candodge = (player.canguard
		and CV.airtoggle.value
		and mo.state ~= S_PLAY_PAIN
		and mo.state ~= S_PLAY_STUN
		--and player.airdodge == 0
		and player.playerstate == PST_LIVE
		and not player.exiting
		and not player.actionstate
		and not player.climbing
		and not player.armachargeup
		and not player.isjettysyn
		and not player.revenge
		--and not player.powers[pw_nocontrol]
		--and not player.powers[pw_carry]
		--and not P_IsObjectOnGround(mo)
		and leveltime>TICRATE*5/4
	)
	
	local defaultguardtext = (B.Exiting or B.Timeout) and "Salute" or "Guard"
	local guardtext = "\x82"..(guardoverride and player.guardtext or defaultguardtext)
	/*if B.TagGametype() and not (player.pflags & PF_TAGIT)
		guardtext = $ + "\x85" + " 10"
	end*/
	patch = v.cachePatch("PARRYBT")
	flags = $ | V_HUDTRANS
	if (canguard or guardoverride) and not (minimal_hud) then
		v.draw(x-5,y-1,patch,flags)
		v.drawString(x+7,y,guardtext,flags,"thin")
	end

	--AIR DODGE
	if candodge then
		if P_IsObjectOnGround(mo) and not (minimal_hud) then
			y = $-9
		end
		if player.dodgecooldown then
			local maxcooldown = CV.dodgetime.value*TICRATE or 1
			local scale_factor = 1000
			local scaled_ratio = (player.dodgecooldown * scale_factor) / maxcooldown
			local spacing = 4 --maybe this makes it more performant?
			local angles = scaled_ratio * (360/spacing) / scale_factor
			local tiny = 4 -- 0 for not tiny
			for n=1, angles do
				local p = v.getSpritePatch("CDBR", tiny+(leveltime/4 % 4), 0, n*ANG1*spacing)
				v.draw(x, y-5, p, flags_hudtrans)
			end
			local unsafe_dodge = (player.safedodge and player.safedodge < 0)
			if player.dodgecooldown > maxcooldown and (unsafe_dodge or (leveltime/5 & 1)) then
				local color = "\x85"
				if unsafe_dodge then
					color = (leveltime/5 & 1) and $ or "\x8F"
					x = $ + v.RandomRange(-1,1)
					y = $ + v.RandomRange(-1,1)
				end
				v.drawString(x-1,y-2,color+"!",flags,"thin")
				flags = ($ & ~V_HUDTRANS) | V_HUDTRANSQUARTER
				y = $-2
			else
				y = $-2
				patch = v.cachePatch("DODGEBT")
				flags = ($ & ~V_HUDTRANS) | V_HUDTRANSHALF
				v.draw(x-4,y,patch,flags)
			end
			if player.airdodge == 0 and not (minimal_hud or P_IsObjectOnGround(mo)) then
				v.drawString(x+7,y,"AIR DODGE",flags|V_YELLOWMAP,"thin")
			end
		elseif not (minimal_hud or P_IsObjectOnGround(mo)) then
			patch = v.cachePatch("DODGEBT")
			v.draw(x-5,y,patch,flags)
			v.drawString(x+7,y,"AIR DODGE",flags|V_YELLOWMAP,"thin")
		end
	end

	--hi
end
