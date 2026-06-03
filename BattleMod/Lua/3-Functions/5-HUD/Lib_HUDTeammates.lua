local B = CBW_Battle
local CV = B.Console

B.TeammateHUD = function(v, player)
	if not G_GametypeHasTeams()
	or not CV.FindVarString("battleconfig_hud", {"New", "Minimal"})
	then
		return
	end

	local flags = V_PERPLAYER|V_SNAPTOTOP
	local sep = 9*FRACUNIT
	local basesep = 48*FRACUNIT
	local x = 160*FRACUNIT
	local y = 26*FRACUNIT
	local rednum = 0
	local bluenum = 0
	
	local player_self = nil
	local autobalancing = nil
	for p in players.iterate() do
		if p.autobalancing then 
			if p == player then player_self = true end
			autobalancing = true
		end

		local xmult = 1
		local doflip = 0
		local num
		local teamcol
		if (p.ctfteam ~= 1 and p.ctfteam ~= 2) or not p.mo or p.isjettysyn then
			continue
		end
		if p.ctfteam == 1 then
			rednum = $ + 1
			num = rednum
			teamcol = skincolor_redteam
		else
			xmult = -1
			doflip = V_FLIP
			bluenum = $ + 1
			num = bluenum
			teamcol = skincolor_blueteam
		end
		local offset = (basesep + num * sep) * xmult
		local yoffset = 0
		local scale = FRACUNIT/2
		local hires = skins[p.skin].highresscale
		local black = v.getColormap(TC_BLINK, SKINCOLOR_PITCHBLACK)
		local playercol = v.getColormap(TC_BLINK, teamcol)
		local color = black
		local trans = V_HUDTRANSHALF
		if p.playerstate == PST_LIVE then
			yoffset = -scale*2
			trans = V_HUDTRANS
			v.drawScaled(x + offset, y, FixedMul(scale, hires), v.getSprite2Patch(p.mo.skin, SPR2_LIFE), flags | trans | doflip, color)
			color = playercol
		end
		
		v.drawScaled(x + offset, y + yoffset, FixedMul(scale, hires), v.getSprite2Patch(p.mo.skin, SPR2_LIFE), flags | trans | doflip, color)
		if p.playerstate == PST_DEAD then
			v.drawScaled(x + offset, y, scale, v.cachePatch("HUD_X"), flags | V_HUDTRANS, v.getColormap(TC_RAINBOW, teamcol))
		end
		if G_GametypeUsesLives() and not p.revenge then
			local stock_sep = 2*FRACUNIT
			local stock_yoff = 3*FRACUNIT + FRACUNIT/2
			local maxstocks = max(p.lives, CV.SurvivalStock.value)
			for i = 0, p.lives-1 do
				local offset2 = -((maxstocks - 1) * stock_sep / 2) + (i * stock_sep)
				local scale2 = FRACUNIT/3
				v.drawScaled(x + offset + offset2, y + stock_yoff + scale2*2, scale2, v.cachePatch("HUD_STOK"), flags | trans, black)
				v.drawScaled(x + offset + offset2, y + stock_yoff, scale2, v.cachePatch("HUD_STOK"), flags | trans, playercol)
			end
		end
	end

	--// rev: If autobalance is happening, let's tell everyone about it
	local ax = 120
	local ay = 18
	local aflags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER

	--// You are the player being autobalanced
	if player_self and autobalancing then
		local team = player.ctfteam == 1 and "\x85" or "\x84"
		local time = 3 - (player.autobalancing/TICRATE)
		v.drawString(ax-30, ay - 14, team+"You will be autobalanced in: "+time, aflags, "thin")

	--// Someone else is being autobalanced
	elseif not player_self and autobalancing then
		v.drawString(ax, ay - 14, "Rebalancing teams...", aflags, "thin")
	end
end
