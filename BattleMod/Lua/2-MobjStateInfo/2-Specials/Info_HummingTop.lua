local B = CBW_Battle

states[freeslot("S_HUMMINGTOP")] = {
	sprite = freeslot("SPR_HUMMINGTOP"),
	frame = FF_FULLBRIGHT|FF_ANIMATE|_G["A"],
	var1 = 7,
	var2 = 1,
	tics = -1,
	nextstate = S_NULL
}

sfxinfo[freeslot("sfx_htop")].caption = "Humming Top"
sfxinfo[freeslot("sfx_htok")].caption = "Humming Top Clash"

spr2defaults[freeslot("SPR2_TRIK")] = SPR2_SKID

states[freeslot("S_SONIC_HUMMINGTOP")] = {
	sprite = SPR_PLAY,
	frame = SPR2_TRIK|A,
	tics = -1
}

B.Sonic_RECURLCOOLDOWN = 10

spr2defaults[freeslot("SPR2_DRPD")] = SPR2_DASH
states[freeslot("S_PLAY_DROPDASH")] = {
	sprite = SPR_PLAY,
	frame = SPR2_DRPD|FF_SPR2ENDSTATE,
	var1 = S_PLAY_DROPDASH
}

--Assign sprites, objects, and sfx
freeslot(
	"SPR_REBO",
	"MT_REBOUND",
	"S_REBOUND",
	"sfx_bounc1",
	"sfx_bounc2"
)


sfxinfo[sfx_bounc1] = {
	singular = false,
	caption = "Rebound"
}
sfxinfo[sfx_bounc2] = {
	singular = false,
	caption = "Heavy Rebound"
}

--Wallbounce ring effect object
mobjinfo[MT_REBOUND] = {
	doomednum = -1,
	spawnstate = S_REBOUND,
	flags = MF_NOCLIP|MF_SCENERY|MF_NOGRAVITY
}
states[S_REBOUND] = {
	sprite = SPR_REBO,
	frame = TR_TRANS50|FF_PAPERSPRITE|A
}

--Instashield
freeslot(
	"MT_SONIC_INSTASHIELD",
	"S_SONIC_INSTASHIELD",
	"S_SONIC_INSTASHIELD1A",
	"S_SONIC_INSTASHIELD1B",
	"S_SONIC_INSTASHIELD2A",
	"S_SONIC_INSTASHIELD2B",
	"S_SONIC_INSTASHIELD3A",
	"S_SONIC_INSTASHIELD3B",
	"S_SONIC_INSTASHIELD4A",
	"S_SONIC_INSTASHIELD4B",
	"S_SONIC_INSTASHIELD5A",
	"S_SONIC_INSTASHIELD5B",
	"S_SONIC_INSTASHIELD6A",
	"S_SONIC_INSTASHIELD6B",
	"SPR_SONIC_INSTASHIELD"
)

mobjinfo[MT_SONIC_INSTASHIELD] = {
	doomednum = -1,
	spawnhealth = 1,
	spawnstate = S_SONIC_INSTASHIELD,
	radius = 48*FRACUNIT,
	height = 48*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT
}

states[S_SONIC_INSTASHIELD] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD1A}
states[S_SONIC_INSTASHIELD1A] = {SPR_SONIC_INSTASHIELD, 0|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD1B}
states[S_SONIC_INSTASHIELD1B] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD2A}
states[S_SONIC_INSTASHIELD2A] = {SPR_SONIC_INSTASHIELD, 1|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD2B}
states[S_SONIC_INSTASHIELD2B] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD3A}
states[S_SONIC_INSTASHIELD3A] = {SPR_SONIC_INSTASHIELD, 2|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD3B}
states[S_SONIC_INSTASHIELD3B] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD4A}
states[S_SONIC_INSTASHIELD4A] = {SPR_SONIC_INSTASHIELD, 3|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD4B}
states[S_SONIC_INSTASHIELD4B] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD5A}
states[S_SONIC_INSTASHIELD5A] = {SPR_SONIC_INSTASHIELD, 4|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD5B}
states[S_SONIC_INSTASHIELD5B] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD6A}
states[S_SONIC_INSTASHIELD6A] = {SPR_SONIC_INSTASHIELD, 5|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_SONIC_INSTASHIELD6B}
states[S_SONIC_INSTASHIELD6B] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_NULL}

