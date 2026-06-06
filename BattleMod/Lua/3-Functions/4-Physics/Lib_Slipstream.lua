local B = CBW_Battle
local CV = CBW_Battle

B.GetBackdraftSpeed = function(player, nearest)
	local p_normalspeed = skins[player.mo.skin].normalspeed
	local p_dashmode = player.dashmode
	local p_gradualspeed = player.gradualspeed

	local n_normalspeed = skins[nearest.mo.skin].normalspeed
	local n_dashmode = nearest.dashmode
	local n_gradualspeed = nearest.gradualspeed
	local n_speed = nearest.speed
	local n_speedboost = n_speed > FixedMul(n_normalspeed, nearest.mo.scale)
	and n_dashmode*(FU/5)
	or 0 --nil?

	local p_slipstream = (p_normalspeed + p_dashmode*(FU/5)) + p_gradualspeed 
	local n_slipstream = (n_gradualspeed + n_speedboost)
	local base_speed =  p_slipstream + n_slipstream

	return base_speed
end

B.BackdraftThinker = function(player, nearest)
	player.normalspeed = B.GetBackdraftSpeed(player, nearest)
	if not player.slipping then
		local pmo = player.mo
		if not (S_SoundPlaying(pmo, sfx_cdfm40) or S_SoundPlaying(pmo, sfx_s3ka2)) then
			B.teamSound(pmo, player, sfx_cdfm40, sfx_s3ka2, 255, true)
			P_SpawnParaloop(pmo.x, pmo.y, pmo.z + pmo.height / 2, pmo.height, 16, MT_DUST, pmo.angle * ANGLE_180, nil, false)
		end
		player.slipping = true
	end
end

B.DisableBackdraft = function(player)
	--player.didslipbutton = 0
	player.slipping = false
	player.normalspeed = (player.dashmode and skins[player.mo.skin].normalspeed+(player.dashmode*(FRACUNIT/5))) or skins[player.mo.skin].normalspeed
end

B.DoBackdraft = function(player)
	if B.Console.Slipstream.value == 0 then return false end--Server has disabled the backdraft/slipstream mechanic
	if player.charmed == true then --Charmed players cannot take advantage of the backdraft mechanic
		player.gradualspeed = 0
		player.backdraft = 0
		return false 
	end 

	local pmo = player.mo
	local area = 70
	local angle = R_PointToAngle2(0,0,player.rmomx,player.rmomy)
	local nearest = CBW_Battle.GetNearestPlayer(pmo,area,0,angle)
	local topspeed = skins[pmo.skin].normalspeed
-- 	local threshold = 60
	local threshold = TICRATE*2
	local time = 3*TICRATE
	local time2 = 2*TICRATE
	local extraspeed = 24*FRACUNIT/time
	local extraspeed2 = 30*FRACUNIT/time2

	--Slipstream
	if nearest and nearest.speed > 2*FRACUNIT and R_PointToDist2(pmo.x,pmo.y,nearest.mo.x,nearest.mo.y) < pmo.scale*2200 and FixedHypot(player.rmomx,player.rmomy) >= player.runspeed then
		if abs(pmo.z-nearest.mo.z) < pmo.scale*260 then  --Prevent meter from going down, but don't let it increase if too far away vertically
			if nearest.powers[pw_sneakers] then
				player.backdraft = min(35,$+1)
				area = 100
			else
				player.backdraft = min(35,$+1)
				area = 70
			end
			
			if nearest.powers[pw_sneakers] 
				and player.backdraft > 34
			then
				player.gradualspeed = min(30*FRACUNIT,$+extraspeed2)
				area = 100
			elseif player.backdraft > 34 then
				player.gradualspeed = min(24*FRACUNIT,$+extraspeed)
				area = 70
			end
-- 			local dir = B.GetInputAngle(player)
-- 			if player.charflags&SF_DASHMODE
-- 				if player.dashmode < TICRATE*3-1 then
-- 					player.dashmode = $+1
-- 				end
-- 			end
			if player.gradualspeed then 
				--Add fx
				local f = FRACUNIT
				local r = pmo.radius/f
				local h = pmo.height/f
				local random1 = P_RandomRange(-r,r)*f
				local random2 = P_RandomRange(-r,r)*f
				local random3 = P_RandomRange(0,h)*f
				local m = P_SpawnMobj(random1+pmo.x,random2+pmo.y,random3+pmo.z,MT_SPINDUST)
				if m and m.valid then m.scale = $/2 end
			end
		end
	else
		player.gradualspeed = max(0, $-extraspeed)
		player.backdraft = max(0, $-1)
	end

	--if B.ButtonCheck(player, player.battleconfig_slipstreambutton) == 1 then
		--player.didslipbutton = $+1
	--end

	if player.gradualspeed
	and (nearest and nearest.valid)
	and not B.Timeout
	then
		B.BackdraftThinker(player, nearest)
	elseif player.slipping then
		B.DisableBackdraft(player)
	end
end