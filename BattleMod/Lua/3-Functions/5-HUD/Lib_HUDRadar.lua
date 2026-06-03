--HUD_ScanRadar.lua originally from CBW_Chaos
local B = CBW_Battle
local D = B.Diamond
local R = B.Ruby
local F = B.CTF
local A = B.Arena
local CP = B.ControlPoint
local CV = CBW_Battle.Console

B.clamp = function(num, minimum, maximum)
	return min(maximum, max(num, minimum))
end

B.screentransform = function(x, y, z, camz, ang, aim, realwidth, realheight)
	z = $ - camz
	aim = B.clamp(aim, -ANGLE_90 + 1, ANGLE_90 - 1)
	
	local width = 160
	local height = 100
	
	--FOV calcs
	local FOV = CV.FindVar("fov").value * FRACUNIT
    local fovang2 = (FOV + (consoleplayer and consoleplayer.fovadd or 90*FRACUNIT))/2
    local fovtan = tan(FixedAngle(fovang2))
    local fg = width*fovtan
	
	--Screen width calculations
	local diffwidth = realwidth-(width*2)
	local clampang = ANGLE_45 + (ANG1*5/64)*diffwidth
	
	--Horizontal
    local h = R_PointToDist(x, y)
	local diffang = ang - R_PointToAngle(x, y)
    local da = B.clamp(diffang, -clampang, clampang)
	local clampedh = 0
	if da > diffang
		clampedh = 1--left side of screen
	elseif da < diffang
		clampedh = 2--right side of screen
	end
	
	--Screen height calculations
	local diffheight = realheight-(height*2)
	local clampvert = FRACUNIT*3/5 + (FRACUNIT*3/50/16)*diffheight
	
	--Vertical
	local diffaim = tan(aim) - FixedDiv(z, 1 + FixedMul(cos(da), h))
	local dv = B.clamp(diffaim, -clampvert, clampvert)
	local clampedv = 0
	if dv > diffaim
		clampedv = 1--top side of screen
	elseif dv < diffaim
		clampedv = 2--bottom side of screen
	end
	
	--Final hud position calcs
    local sx = width<<FRACBITS + FixedMul(tan(da), fg)
    local sy = height<<FRACBITS + FixedMul(dv, fg)
    local scale = FixedDiv(width<<FRACBITS, h+1)
	
    return sx, sy, scale, clampedv, clampedh
end

B.RadarHUD = function(v, player, cam)
	local pmo = player.realmo
	
	if not (pmo)
	or not (pmo.valid)
	or not B.Console.FindVarString("battleconfig_hud", {"New", "Minimal"})
	or splitscreen
		return
	end
	
	for r = 1, 8 do
		local t = {}
		local scale = FRACUNIT/2
		local trans = V_10TRANS
		local fade = 0
		local fade2 = 0
		local patch
		local patch_clamped
		local patch_arrow
		local allow_clamp = true
		local center = false
		local yoff = false
		local float = false
		local color = nil
		local flags = V_PERPLAYER
		local colormap = TC_RAINBOW
		
		--Goal
		if r == 1 or r == 2
			if r == 1 and R.RedGoal
				table.insert(t, R.RedGoal)
			end
			if r == 2 and R.BlueGoal
				table.insert(t, R.BlueGoal)
			end
			scale = FRACUNIT/6
			
			if (R.ID and R.ID.valid and R.ID.target and R.ID.target.valid and R.ID.target.player)
				local runner_team = R.ID.target.player.ctfteam
				
				if (r != runner_team)
					if (consoleplayer and consoleplayer.spectator) or (runner_team == displayplayer.ctfteam)
						patch = v.cachePatch("RAD_GOAL2")
					else
						patch = v.cachePatch("RAD_DEFEN")
					end
				else
					patch = v.cachePatch("RAD_NO")
					trans = V_70TRANS
					scale = FRACUNIT/7
				end
			else
				continue
				--patch = v.cachePatch("RAD_GOAL1")
				--trans = V_40TRANS
			end
			center = true
			float = true
			allow_clamp = false
		end
		--Red Flag
		if r == 3
			if not (
				(F.RedFlag and F.RedFlag.valid and not(F.RedFlag.flags2 & MF2_DONTDRAW) and (F.RedFlag.state ~= S_RUBYPORTAL))
			) then
				continue
			end
			table.insert(t,F.RedFlag)
			fade = V_40TRANS
			fade2 = V_60TRANS
			local ringin = player.ctfteam == 1 and (player.gotmaxrings or player.gotcrystal)
			/*if B.BankGametype() then
				patch_clamped = v.cachePatch("RAD_RING1")
				patch = v.cachePatch("RAD_RING2")
				if ringin then
					patch = v.cachePatch("RAD_RINGIN1")
				end
			else*/
				patch = v.cachePatch("RAD_FLAG")
			--end
			color = (ringin and leveltime%11<5) and SKINCOLOR_GOLDENROD or (B.RedTeam_Info.flagcolor or B.RedTeam_Info.skincolor)
			center = true
		end
		--Blue Flag / Bank
		if r == 4
			if not (
				(F.BlueFlag and F.BlueFlag.valid and not(F.BlueFlag.flags2 & MF2_DONTDRAW) and (F.BlueFlag.state ~= S_RUBYPORTAL))
			) then
				continue
			end
			table.insert(t,F.BlueFlag)
			fade = V_40TRANS
			fade2 = V_60TRANS
			local ringin = player.ctfteam == 2 and (player.gotmaxrings or player.gotcrystal)
			flags = $|V_FLIP
			/*if B.BankGametype() then
				patch_clamped = v.cachePatch("RAD_RING1")
				patch = v.cachePatch("RAD_RING2")
				if ringin then
					patch = v.cachePatch("RAD_RINGIN1")
					flags = $ & ~V_FLIP
				end
			else*/
				patch = v.cachePatch("RAD_FLAG")
			--end
			color = (ringin and leveltime%11<5) and SKINCOLOR_SUPERGOLD2 or (B.BlueTeam_Info.flagcolor or B.BlueTeam_Info.skincolor)
			center = true
		end
		--Ruby
		if r == 5
			if B.Timeout or not (R.ID and R.ID.valid) then continue end
			table.insert(t,R.ID)
			fade = V_40TRANS
			fade2 = V_60TRANS
			patch_clamped = v.cachePatch("RAD_RUBY1")
			patch = v.cachePatch("RAD_RUBY2")
			color = R.ID.color
			scale = FRACUNIT / 2
			center = true
		end
		--Bounty
		if r == 6
			if not (A.Bounty and A.Bounty.mo and A.Bounty.mo.valid) then continue end
			table.insert(t,A.Bounty.mo)
			fade = V_40TRANS
			fade2 = V_60TRANS
			patch = v.cachePatch("RAD_CROWN")
			if B.CPGametype() then color = SKINCOLOR_SILVER end
			scale = FRACUNIT / 6
			center = true
		end
		--Topaz
		if r == 7
			if not (D.Diamond and D.Diamond.valid) then continue end
			table.insert(t,(D.Diamond.target and D.Diamond.target.valid) and D.Diamond.target or D.Diamond)
			fade = V_40TRANS
			fade2 = V_60TRANS
			patch_clamped = v.cachePatch("RAD_TOPAZ1")
			patch = v.cachePatch("RAD_TOPAZ2")
			scale = FRACUNIT / 2
			center = true
		end
		--Capture Point
		if r == 8 then
			if not (
				(CP.Mode and CP.ID and CP.ID[CP.Num] and CP.ID[CP.Num].valid and (CP.Active or CP.Timer and CP.Timer <= 10*TICRATE))
				or D.ActivePoint
			) then
				continue
			end
			local mobj = D.ActivePoint or CP.ID[CP.Num]
			table.insert(t,mobj)
			fade = V_40TRANS
			fade2 = V_60TRANS
			if CP.Timer and not (D.Diamond and D.Diamond.valid and D.Diamond.target) then
				patch_clamped = v.cachePatch("RAD_LOCK1")
				patch = v.cachePatch("RAD_LOCK2")
			else
				if mobj and mobj.valid then
					patch_clamped = v.cachePatch("RAD_CP1")
					patch = v.cachePatch("RAD_CP2")
					color = mobj.color
					colormap = TC_DEFAULT
				end
			end
			scale = FRACUNIT / 2
			center = true
		end
		
		--Get camera info
		local xx = cam.x
		local yy = cam.y
		local zz = cam.z
		local angle = 0
		local aiming = cam.aiming
		if player.playerstate == PST_LIVE
			angle = cam.angle
			if (player.spectator or not cam.chase)--Use the realmo coordinates when not using chasecam
				xx = pmo.x
				yy = pmo.y
				zz = pmo.z
				angle = player.cmd.angleturn<<FRACBITS
				aiming = player.cmd.aiming<<FRACBITS
			end
		end
		
		for n = 1, #t do
			local mo = t[n]
			if not(mo.valid and mo.health) continue end
			local yoffset = 0
			if center
				yoffset = mo.height / 2
			elseif yoff
				yoffset = yoff
			end
			if float
				yoffset = $ + (64 * FRACUNIT)
			end
			
			--Calculate
			local dx, dy, ds, clampedv, clampedh = B.screentransform(mo.x, mo.y, mo.z + yoffset, zz, angle, aiming, v.width()/v.dupx(), v.height()/v.dupy())
			
			--Check distance
			local final_trans = trans
			local final_patch = patch
			local dist = R_PointToDist(mo.x,mo.y)
			local clampscale = true
			local did_clamp = false
			
			if (clampedv or clampedh)
				if not allow_clamp
					continue
				end
				if (patch_clamped)
					final_patch = patch_clamped
					did_clamp = true
				end
			else
				if dist < pmo.scale * 2040
					if fade and not patch_arrow
						continue
					end
					--Don't draw arrows for items that aren't in our view
					if patch_arrow and P_CheckSight(pmo, mo)
						final_trans = 0
						final_patch = patch_arrow
						color = nil
						clampscale = false
					end
				elseif dist < pmo.scale * 2544
					if fade2
						final_trans = fade2
					end
				elseif dist < pmo.scale * 3048
					if fade
						final_trans = fade
					end
				end
			end
			
			--Clamped objects lose scale
			if clampscale
				ds = min(FRACUNIT*2/3, ds)
			end

			local final_scale = max(1, scale + ds)
			
            --Finally draw the damn thing
			if color == 0
				color = nil
			end
			--[[
			if clampedh == 2 then
				dx = $-(final_scale*12) --ugh
			end
			]]
			-- Bias big clamped patches to the left based on how large they are
			if not did_clamp then
				-- Define the range for interpolation
				local height_min = 30
				local height_max = 90

				-- Calculate the weight factor (t) for interpolation
				local t = 0
				if final_patch.height > height_min and final_patch.height < height_max then
					t = FixedDiv(final_patch.height - height_min, height_max - height_min)
				elseif final_patch.height >= height_max then
					t = FRACUNIT
				end

				-- Calculate the interpolated offsets
				local dx1 = (final_patch.width * 2 / 7) * FRACUNIT
				local dy1 = (final_patch.height * 2 / 3) * FRACUNIT
				local dx2 = (final_patch.width / 8) * FRACUNIT
				local dy2 = (final_patch.height / 2) * FRACUNIT
			
				dx = $ - FixedMul(dx1, t) - FixedMul(dx2, FRACUNIT - t)
				dy = $ - FixedMul(dy1, t) - FixedMul(dy2, FRACUNIT - t)
			end
			v.drawScaled(dx, dy, final_scale, final_patch, final_trans|flags, color and v.getColormap(colormap, color))
		end
	end
end