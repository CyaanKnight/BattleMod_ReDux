freeslot(
	'mt_energyblast',
	'mt_energyaura',
	'mt_energygather',
	'SPR2_MSC2'
)

//Metal Sonic's Energy Blast

mobjinfo[MT_ENERGYBLAST] = {
	spawnstate = S_ENERGYBALL1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = 15*FRACUNIT,
	radius = 8*FRACUNIT,
	height = 48*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_NOBLOCKMAP
}

mobjinfo[MT_ENERGYAURA] = {
	spawnstate = S_MSSHIELD_F1,
	dispoffset = 2,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}

mobjinfo[MT_ENERGYGATHER] = {
	spawnstate = S_JETFUME1,
	dispoffset = -1,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}

freeslot("sfx_nblst")

sfxinfo[sfx_nblst].caption = "\x82".."ENERGY BLAST".."\x80"