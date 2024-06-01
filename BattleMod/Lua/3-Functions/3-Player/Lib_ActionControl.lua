local B = CBW_Battle
local CV = B.Console
local S = B.SkinVars

local spendringwarning = false

B.MasterActionScript = function(player,doaction)
	--Set action state
	player.actionallowed = B.CanDoAction(player)
	player.actioncooldown = max($,player.tossdelay-TICRATE)

	local mo = player.mo
	--Player is not on the field
	if not(mo and mo.valid) then return end
	--Tag egg robos and revenge jettysyns cannot use actions
	if player.iseggrobo or player.isjettysyn then return end
	--Actions are disallowed in ringslinger
	if G_RingSlingerGametype() then return false end
	--Actions have been disallowed by servber
	if not(CV.Actions.value) then return false end
	--Other checks -- set doaction value
	if doaction and (
		player.actioncooldown
		or player.exiting
		or player.pflags&PF_STASIS
		or not(player.actionallowed)
		) then
		if doaction == 1 then
			doaction = -1
		else
			doaction = 0
		end
	end

	local t = player.skinvars
	--Reset action values for this frame
	player.actiontext = nil
	player.action2text = nil
	player.actionrings = 0
	player.action2rings = 0
	player.actiontextflags = nil
	player.action2textflags = nil
	player.actionsuper = false
	--Set exhaustmeter hud (if enabled)
	if player.exhaustmeter ~= FRACUNIT then
-- 		player.action2text = player.exhaustmeter*100/FRACUNIT.."%"
		if player.exhaustmeter > FRACUNIT/3 or (player.exhaustmeter > 0 and leveltime&4) then
			player.action2textflags = 0
		elseif player.exhaustmeter > 0 then
			player.action2textflags = 2
		else
			player.action2textflags = 3
		end
	end
	--Perform action script
	if S[t].special ~= nil then
		S[t].special(mo,doaction)
		--For custom characters
		if player.spendrings == 1 then
			if not(spendringwarning) then
				spendringwarning = true
				B.Warning("player.spendrings is deprecated! Use CBW_Battle.PayRings(player)")
			end
			B.PayRings(player)
		elseif (doaction == -1) then
			S_StartSound(mo,sfx_s3k8c,player)
		end
	end
	--Apply debt cooldowns
	if player.rings < 0 then
		player.actiondebt = $+abs(player.rings)
		player.rings = 0
	end
	if player.actiondebt > 0 and player.actionstate == 0 then
		B.ApplyCooldown(player,player.cooldown,true)
	end
	
	--Action successful
	return true
end

B.CanDoAction=function(player)
	if CV.RequireRings.value and player.rings < player.actionrings then return false end
	if G_RingSlingerGametype() then return false end
	if P_PlayerInPain(player) or player.playerstate ~= PST_LIVE then return false end
	if B.TagGametype() and not(player.pflags&PF_TAGIT) then return false end
	if player.gotflag then return false end
	if player.gotcrystal then return false end
	if player.isjettysyn then return false end
	if player.powers[pw_nocontrol] then return false end
	if player.powers[pw_carry] then return false end
	if (player.airdodge > 0) then return false end
	return true
end

local checkringwarning = false
B.CheckRings=function(player,doaction,rings)
	if not(checkringwarning) then
		checkringwarning = true
		B.Warning("CBW_Battle.CheckRings is deprecated!")
	end
	return doaction
end

B.PayRings=function(player,spendrings,sound)
	player.spentrings = TICRATE/2
	if spendrings == nil then spendrings = player.actionrings end
	if spendrings == 0 then return end
	player.rings = $-spendrings
	if sound ~= false then
		if player.rings >= 0 then
			S_StartSound(mo,sfx_cdfm66,player)
		else
			S_StartSound(mo,sfx_noring,player)
		end
	end
end

B.ApplyCooldown=function(player,cooldown,applydebt)
	if cooldown == nil then cooldown = 0 end
	if applydebt == nil then applydebt = true end
	
	if applydebt and player.rings < 0 or player.actiondebt > 0 then
		local debt = player.actiondebt-player.rings
		cooldown = max(TICRATE*2,$+$*debt/10)
		--player.rings = 0
		player.actiondebt = 0
	end
	player.actioncooldown = cooldown
end
