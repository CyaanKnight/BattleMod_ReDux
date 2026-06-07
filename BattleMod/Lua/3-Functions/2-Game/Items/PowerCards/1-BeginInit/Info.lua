/*
	Power Cards, page 1
	Handles SOC definitions and global namespace info
*/

--*** Global namespace
rawset(_G,"CBW_PowerCards", {})
local PR = CBW_PowerCards
PR.Item = {}
if not(CBW_PowerCardQueue)
	rawset(_G,'CBW_PowerCardQueue', {})
end

--*** Power Card Flag constants
local c = 0
local function pcf(str)
	str = "PCF_"..string.upper($)
	local val = 1<<c
	rawset(_G,str,val)
	c = $+1
-- 	print("Created constant "..str.." ("..val..")")
end

pcf('nospin')
pcf('runnerdebuff')
pcf('notoss')
pcf('mystery')
pcf('hudwarning')
pcf('custom')
pcf('container')
pcf('event')
pcf('fixedspawn')

--*** SOC info
//Sprites
freeslot('spr_card')
//States
freeslot('S_POWERCARD_BLANK',
	'S_POWERCARD_MYSTERY',
	'S_POWERCARD_RINGS',
	'S_POWERCARD_BLESSING',
	'S_POWERCARD_RINGSLINGER',
	'S_POWERCARD_HYPER',
	'S_POWERCARD_DISABLE',
	'S_POWERCARD_PARTICLES',
	'S_POWERCARD_MELTDOWN',
	'S_POWERCARD_SPITE')

//State info
states[S_POWERCARD_BLANK] 		= {sprite = SPR_CARD, frame = A|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_MYSTERY] 	= {sprite = SPR_CARD, frame = B|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_RINGS] 		= {sprite = SPR_CARD, frame = C|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_BLESSING] 	= {sprite = SPR_CARD, frame = D|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_RINGSLINGER]	= {sprite = SPR_CARD, frame = E|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_HYPER] 		= {sprite = SPR_CARD, frame = F|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_DISABLE] 	= {sprite = SPR_CARD, frame = G|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_PARTICLES] 	= {sprite = SPR_CARD, frame = H|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_MELTDOWN] 	= {sprite = SPR_CARD, frame = I|FF_PAPERSPRITE|FF_FULLBRIGHT}
states[S_POWERCARD_SPITE] 		= {sprite = SPR_CARD, frame = J|FF_PAPERSPRITE|FF_FULLBRIGHT}

--*** Power Card object
freeslot("MT_POWERCARD")
mobjinfo[MT_POWERCARD] = {
        doomednum = -1,
        spawnstate = S_POWERCARD_BLANK,
        spawnhealth = 1,
        reactiontime = 40,
        painchance = 0,
        speed = 1,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        dispoffset = 0,
        mass = 100,
        activesound = sfx_None,
        flags = MF_SCENERY,
        raisestate = S_NULL
}

freeslot('mt_powercarddeathprop')
mobjinfo[MT_POWERCARDDEATHPROP] = {
        doomednum = -1,
        spawnstate = S_POWERCARD_BLANK,
        spawnhealth = 1,
        reactiontime = 40,
        painchance = 0,
        speed = 1,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        dispoffset = 0,
        mass = 100,
        activesound = sfx_None,
        flags = MF_SCENERY,
        raisestate = S_NULL
}

--*** Dedicated Map Spawns
freeslot("MT_POWERCARDSPAWN_RANDOM")
mobjinfo[MT_POWERCARDSPAWN_RANDOM] = {
		//$Name "Power Card (Random)"
		//$Sprite CARDA0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3590,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_RINGS")
mobjinfo[MT_POWERCARDSPAWN_RINGS] = {
		//$Name "Power Card (Ring-Up)"
		//$Sprite CARDC0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3591,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_HYPER")
mobjinfo[MT_POWERCARDSPAWN_HYPER] = {
		//$Name "Power Card (Hyper)"
		//$Sprite CARDF0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3592,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_PARTICLES")
mobjinfo[MT_POWERCARDSPAWN_PARTICLES] = {
		//$Name "Power Card (Particles)"
		//$Sprite CARDH0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3593,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_DISABLE")
mobjinfo[MT_POWERCARDSPAWN_DISABLE] = {
		//$Name "Power Card (Disable)"
		//$Sprite CARDG0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3594,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_MELTDOWN")
mobjinfo[MT_POWERCARDSPAWN_MELTDOWN] = {
		//$Name "Power Card (Meltdown)"
		//$Sprite CARDI0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3595,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_RINGSLINGER")
mobjinfo[MT_POWERCARDSPAWN_RINGSLINGER] = {
		//$Name "Power Card (Ringslinger)"
		//$Sprite CARDE0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3596,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_SPITE")
mobjinfo[MT_POWERCARDSPAWN_SPITE] = {
		//$Name "Power Card (Spite)"
		//$Sprite CARDJ0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3597,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

freeslot("MT_POWERCARDSPAWN_BLESSING")
mobjinfo[MT_POWERCARDSPAWN_BLESSING] = {
		//$Name "Power Card (Blessing)"
		//$Sprite CARDD0
		//$Category "BattleMod Power Card Spawns"
        doomednum = 3598,
        spawnstate = S_NULL,
        radius = 36*FRACUNIT,
        height = 80*FRACUNIT,
        flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP,
}

--*** Sound effects
freeslot("sfx_itmspn", "sfx_ssbbmp", "sfx_ssbshk", "sfx_elctrc", "sfx_ebufo", "sfx_pixied")
//To-do: SFX info

sfxinfo[sfx_itmspn].flags = SF_X4AWAYSOUND

sfxinfo[sfx_ebufo].flags = SF_X4AWAYSOUND

