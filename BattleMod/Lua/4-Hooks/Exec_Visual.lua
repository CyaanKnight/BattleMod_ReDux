local B = CBW_Battle

addHook("MobjThinker", B.BattleShieldThinker, MT_BATTLESHIELD)
addHook("MobjThinker", B.NegaShieldThinker, MT_NEGASHIELD)
addHook("MobjThinker", B.InstaFlip, MT_INSTASHIELD)
addHook("MobjThinker", B.StunBreakVFXThinker, MT_STUNBREAK)

addHook("MobjThinker",function(mo) B.EnergyGather(mo,mo.target,mo.extravalue1,mo.extravalue2) end,MT_ENERGYGATHER)
addHook("MobjThinker", B.TargetDummyThinker, MT_TARGETDUMMY)
addHook("MobjThinker",function(mo) B.MetalAura(mo,mo.target) end, MT_ENERGYAURA)
addHook("MobjThinker", function(mo) 
	if mo and mo.valid and mo.target and mo.target.valid then
		B.SparkAura(mo, mo.target) 
	end
end, MT_RINGSPARKAURA)

//Shields (yeah, this is pretty messy...)
local colorsh = function(mo, redcol, bluecol)
	B.OverlayHide(mo,mo.target)
	
	if mo.colorized return end
	local target = mo.target
	if target and target.valid and not target.player and target.target and target.target.player
		target = target.target
	end
	
	if not (G_GametypeHasTeams() and target and target.valid and target.player and target.player.valid and target.player.ctfteam)
		return
	end
	
	if (target.player.ctfteam == 1) and redcol
		mo.color = redcol
		mo.colorized = true
		return
		
	elseif (target.player.ctfteam == 2) and bluecol
		mo.color = bluecol
		mo.colorized = true
		return
	end
end

local colorsh2 = function(mo)
	if mo.state >= S_ARMA1 and mo.state <= S_ARMB32
		colorsh(mo,nil,SKINCOLOR_PURPLE)
		return
	end
	if mo.state >= S_ZAPS1 and mo.state <= S_ZAPSB11
		colorsh(mo,SKINCOLOR_SUPERRED3,SKINCOLOR_SUPERSKY2)
		return
	end
	if mo.state >= S_FIRS1 and mo.state <= S_FIRSB10
		colorsh(mo,nil,SKINCOLOR_CYAN)
		return
	end
	if mo.state >= S_BUBS1 and mo.state <= S_BUBSB6
		colorsh(mo,SKINCOLOR_SUPERGOLD1,nil)
		return
	end
	B.OverlayHide(mo,mo.target)
end

B.RestoreTailsFollowMobj = function(p, mobj) -- cry
	if not (p and p.mo and p.mo.skin == "tails") then return end
	if (mobj == nil) then mobj = p.followmobj end
	if not (mobj) then return end

	if p.mo.state == S_PLAY_LEDGE_GRAB 
	or p.mo.state == S_PLAY_LEDGE_RELEASE
        mobj.state = S_TAILSOVERLAY_PLUS60DEGREES
		P_SetOrigin(mobj,
		p.mo.x-P_ReturnThrustX(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustX(mobj, mobj.angle, mobj.scale),
		p.mo.y-P_ReturnThrustY(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustY(mobj, mobj.angle, mobj.scale),
		p.mo.z+FixedMul(4*p.mo.scale, mobj.scale)
		)
		mobj.angle = p.drawangle
		return true
    end

	if mobj.state == S_INVISIBLE
		mobj.state = S_TAILSOVERLAY_PLUS30DEGREES
	end

	if (p.skidtime or mobj.restorebuffer)
	and P_IsValidSprite2(mobj, SPR2_WALK)
		mobj.state = S_TAILSOVERLAY_PLUS30DEGREES
		mobj.frame = 512 + min(7,1+p.speed/(p.mo.scale*2))
		P_MoveOrigin(mobj,
		p.mo.x-P_ReturnThrustX(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustX(mobj, mobj.angle, mobj.scale),
		p.mo.y-P_ReturnThrustY(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustY(mobj, mobj.angle, mobj.scale),
		p.mo.z+FixedMul(2*p.mo.scale, mobj.scale)
		)
		mobj.angle = p.drawangle
		mobj.restorebuffer = p.skidtime --+1 frame
		if leveltime%3 == 1
			S_StartSound(mobj,sfx_s3k7e)
		end
		return true
	end
end

addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_CRIMSON,nil) end,MT_ELEMENTAL_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_ORANGE,SKINCOLOR_VAPOR) end,MT_ATTRACT_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_FLAME,SKINCOLOR_SKY) end,MT_WHIRLWIND_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,nil) end,MT_FORCE_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,nil,SKINCOLOR_BLUE) end,MT_ARMAGEDDON_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,nil,SKINCOLOR_DUSK) end,MT_FLAMEAURA_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,nil) end,MT_BUBBLEWRAP_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,SKINCOLOR_SAPPHIRE) end,MT_THUNDERCOIN_ORB)
addHook("MobjThinker", colorsh2,MT_OVERLAY)
addHook("MobjThinker",function(mo) 
	B.OverlayHide(mo,mo.target)
	if gametyperules&GTR_PITYSHIELD or G_GametypeHasTeams()
		local owner = mo.target
		if not(owner and owner.valid and owner.player and owner.player.valid) then return nil end
		mo.color = owner.player.skincolor
		mo.colorized = true
	else
		mo.color = SKINCOLOR_CERULEAN
	end
end,MT_PITY_ORB)
addHook("FollowMobj", B.RestoreTailsFollowMobj, MT_TAILSOVERLAY)