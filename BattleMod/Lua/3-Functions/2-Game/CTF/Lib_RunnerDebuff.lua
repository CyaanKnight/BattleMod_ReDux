local B = CBW_Battle

local PR = CBW_PowerCards

B.GotFlagStats = function(player, force)
	local mo = player.mo
	local skin = skins[mo.skin]
	local skinvar = (pcall(do return B.SkinVars[mo.skin].flagstats end) and (type(B.SkinVars[mo.skin].flagstats) == "table") and B.SkinVars[mo.skin].flagstats) or {}


	//Check PowerCard status
	if player.gotpowercard and not(player.gotpowercard.valid and player.gotpowercard.target == player.mo)
		player.gotpowercard = nil
	end

	//Register debuff
	if (B.MidAirAbilityAllowed(player) == false) and (player.gotflagdebuff == false) then
		player.gotflagdebuff = true
		print(false)
		mo.color = player.skincolor
		player.secondjump = 0
		player.powers[pw_tailsfly] = 0
		player.pflags = $&~(PF_BOUNCING|PF_GLIDING|PF_THOKKED)
		player.climbing = 0
		if player.actionstate and not(player.actionsuper) then
			player.actionstate = 0
			player.actiontime = 0
			mo.tics = 0
			mo.spritexscale = FRACUNIT
			mo.spriteyscale = FRACUNIT
			-- Reset state (prevent anything that looks weird)
			if not P_IsObjectOnGround(mo) then
				player.mo.state = S_PLAY_FALL
			else
				player.mo.state = S_PLAY_WALK
			end
			player.pflags = $ &~ (PF_JUMPED|PF_SPINNING) -- Disallow spin attack status while in fall/walk anims
		end
		B.ZLimit(mo, 10*FRACUNIT) -- Worth about 125% of Sonic's jump
		B.XYLimit(mo, player.normalspeed*5/4) -- 125% of Top speed
	end
	//Unregister debuff and apply normal stats
	if B.MidAirAbilityAllowed(player) and player.gotflagdebuff == true then
		player.gotflagdebuff = false
		player.normalspeed = skin.normalspeed
		player.acceleration = skin.acceleration
		player.accelstart = skin.accelstart
		player.runspeed = skin.runspeed
		player.mindash = skin.mindash
		player.maxdash = skin.maxdash
		player.charflags = skins[mo.skin].flags
		player.jumpfactor = skin.jumpfactor
	end
	//Apply debuff
	if player.gotflagdebuff
		player.normalspeed = skinvar.normalspeed or skin.normalspeed
		player.acceleration = skinvar.acceleration or skin.acceleration
		player.runspeed = skinvar.runspeed or skin.runspeed
		if not(B.GetSkinVarsFlags(player) & SKINVARS_ROSY) then
			player.mindash = skinvar.mindash or (15*3/4*FRACUNIT)
			player.maxdash = skinvar.maxdash or (36*4/5*FRACUNIT)
			player.accelstart = skin.accelstart*1/2
		end
		player.dashmode = 0
		player.jumpfactor = skinvar.jumpfactor or FRACUNIT
		player.charflags = skins[mo.skin].flags & ~SF_RUNONWATER
		player.powers[pw_strong] = $&~STR_METAL
	end
end
