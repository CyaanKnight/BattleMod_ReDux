freeslot("MT_BATTLEHITBOX",
		 "S_BATTLEHITBOX"
)

mobjinfo[MT_BATTLEHITBOX] = {
	doomednum = -1,
	spawnhealth = 1,
	spawnstate = S_BATTLEHITBOX,
	radius = 15*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 1,
	flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_BATTLEHITBOX] = {SPR_NULL, 0|FF_FULLBRIGHT, 4, none, 5*FRACUNIT, 60*FRACUNIT, S_NULL}
