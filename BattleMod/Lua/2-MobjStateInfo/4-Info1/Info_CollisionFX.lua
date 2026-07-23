freeslot("S_BCEBOOM",
"sfx_hit00",
"sfx_hit01",
"sfx_hit02",
"sfx_hit03",
"sfx_hit04",
"sfx_bshove"
)

sfxinfo[sfx_hit00].caption = "Strong hit"
sfxinfo[sfx_hit01].caption = "Electric shock"
sfxinfo[sfx_hit02].caption = "Slash"
sfxinfo[sfx_hit03].caption = "Magical hit"
sfxinfo[sfx_hit04].caption = "Hit"

rawset(_G, "DMG_SHOVE", 127)
sfxinfo[sfx_bshove].caption = "Weak Hit"

states[S_BCEBOOM] = {SPR_BARX, FF_ANIMATE|FF_TRANS50|A, 8, nil, 4, 2, S_NULL}