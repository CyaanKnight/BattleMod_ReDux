local B = CBW_Battle
local CV = B.Console
local PR = CBW_PowerCards

B.ActionHUD=function(v, player, cam)
	if not (B.HUDMain) then return end
	if not hud.enabled("rings") then return end
	if player.playerstate ~= PST_LIVE then return end
	if not(CV.Actions.value) then return end
	//if G_TagGametype() and (leveltime < CV_FindVar("hidetime").value*TICRATE) then return end
	local TF_GRAY = 1
	local TF_YELLOW = 2
	local TF_RED = 3
	local blink = false
	local xoffset = hudinfo[HUD_RINGS].x -- 16
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER
	local align = "thin"
	
	if (player.actionallowed ~= true or player.tumble) and not player.gotflagdebuff then
		local yoffset = hudinfo[HUD_RINGS].y+14
		if B.StunBreakAllowed(player) then
			local patch = v.cachePatch("PARRYBT")
			local text = "Stun Break"
			local cost = player.stunbreakcosttext
			local textcolor = "\x86"
			if cost != nil and player.rings >= cost then
				if leveltime % 3 == 0 then
					textcolor = ""
				elseif leveltime % 3 == 1 then
					textcolor = "\x83"
				else
					textcolor = "\x87"
				end
			end
			if not(cost) then
				cost = ""
			end
			text = "\x82" .. cost .. textcolor .. " " .. $
			v.draw(xoffset+1,yoffset-1,patch,flags)
			v.drawString(xoffset+10,yoffset,text,flags,align)
		elseif player.tumble then
			local patch = v.cachePatch("PRAYBT")
			v.draw(xoffset+1,yoffset+10-1,patch,flags)
		end
		return
	end
	
	--Action 1 text
	local yoffset = hudinfo[HUD_RINGS].y+14 -- 42+14 = 56
	local text = player.actiontext
	local textflags = player.actiontextflags
	local gotflag = player.gotflag
	local gotcrystal = player.gotcrystal
	local gotcard = player.gotpowercard and player.gotpowercard.valid
	local gotcard_debuff = gotcard and PR.Item[player.gotpowercard.item].flags&PCF_RUNNERDEBUFF
	--Item text
	if gotflag or gotcrystal or gotcard_debuff then
		local patch = v.cachePatch("TOSSFLAG")
		if gotflag then
			text = "Got flag!"
		elseif gotcrystal then
			if B.RubyGametype() then
				text = "Got Ruby!"
			elseif B.DiamondGametype() then
				text = "Got Topaz!"
			else
				text = "Got Crystal!"
			end
		elseif gotcard_debuff then
			patch = v.cachePatch("CARDBT")
			text = PR.Item[player.gotpowercard.item].name
		end
		if leveltime&4 then
			text = "\x82"+$
		end
		v.draw(xoffset,yoffset-1,patch,flags)
		v.drawString(xoffset+12,yoffset,text,flags,align)
	elseif text and not(player.actioncooldown and leveltime&1) then 
		if player.actioncooldown or player.actionallowed ~= true then
			textflags = TF_GRAY
			text = "Cooldown "..G_TicsToSeconds(player.actioncooldown).."."..G_TicsToCentiseconds(player.actioncooldown)
		elseif textflags == nil then
			textflags = 0
			if (player.actionstate == 0 and player.actionrings > player.rings) then
				textflags = $|TF_GRAY
			end		
			if player.actionstate then
				textflags = $|TF_YELLOW
			end
		end
		if textflags == TF_GRAY then
			text = "\x86"+$
		elseif textflags == TF_YELLOW then
			text = "\x82"+$
		elseif textflags == TF_RED then
			text = "\x85"+$
		else
			text = "\x80"+$
		end
		if player.actionrings and not(player.actioncooldown) then 
			if (CV.RequireRings.value and player.rings < player.actionrings) and not player.actionstate then
				text = "\x85"+player.actionrings+"\x80 "+$
			else
				text = "\x82"+player.actionrings+"\x80 "+$
			end
		end
		--Draw
		local patch = v.cachePatch("THRWRING")
		v.draw(xoffset,yoffset-1,patch,flags)
		v.drawString(xoffset+12,yoffset,text,flags,align)
	end
	--Action 2 text
	text = player.action2text
	textflags = player.action2textflags
	if not(player.gotflag) and text and not(player.actioncooldown) then 
		yoffset = $+10
		if textflags == nil then
			textflags = 0
			if (player.actionstate == 0 and player.action2rings > player.rings) then
				textflags = $|TF_GRAY
			end		
			if player.actionstate then
				textflags = $|TF_YELLOW
			end
		end
		if textflags == TF_GRAY then
			text = "\x86"+$
		elseif textflags == TF_YELLOW then
			text = "\x82"+$
		elseif textflags == TF_RED then
			text = "\x85"+$
		else
			text = "\x80"+$
		end
		if player.action2rings then 
			text = "\x82"+player.action2rings+"\x80 "+$
		end
		--Draw
		local patch = v.cachePatch("TOSSFLAG")
		v.draw(xoffset,yoffset-1,patch,flags, v.getColormap(TC_RAINBOW, SKINCOLOR_WHITE))
		v.drawString(xoffset+12,yoffset,text,flags,align)
	end
	
	local guardoverride = tonumber(player.canguard) and tonumber(player.canguard) > 1
	if not (CV.Guard.value or guardoverride) then return end
	
	if not (player.mo and player.mo.valid) then return end
	
	yoffset = $+10
	local patch = v.cachePatch("PARRYBT")
	local textcolor = 0
	local canguard = (player.canguard
		and CV.parrytoggle.value
		and not player.actionstate)
	local candodge = (player.canguard
		and CV.airtoggle.value
		and player.mo.state ~= S_PLAY_PAIN
		and player.mo.state ~= S_PLAY_STUN
		and player.airdodge == 0
		and player.playerstate == PST_LIVE
		and not player.exiting
		and not player.actionstate
		and not player.climbing
		and not player.armachargeup
		and not player.isjettysyn
		and not player.revenge
		and not player.powers[pw_nocontrol]
		and not player.powers[pw_carry]
		and not P_IsObjectOnGround(player.mo))
	
	textcolor = "\x80"
	if guardoverride then
		text = player.guardtext
	elseif P_IsObjectOnGround(player.mo) and canguard then
		text = "Guard"
	elseif candodge then
		text = "Air Dodge"
		if player.dodgecooldown then
			if player.dodgecooldown > CV.dodgetime.value*TICRATE/2 then
				textcolor = "\x85"
			elseif player.dodgecooldown > CV.dodgetime.value*TICRATE/3 then
				textcolor = "\x87"
			else
				textcolor = "\x82"
			end
		end
	end
	if not(text and (canguard or candodge)) then
		return
	end
	text = textcolor .. " " .. $
	v.draw(xoffset+1,yoffset-1,patch,flags)
	v.drawString(xoffset+10,yoffset,text,flags,align)
end