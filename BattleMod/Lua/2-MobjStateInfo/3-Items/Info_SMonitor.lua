-- ### S Monitor

local B = CBW_Battle

freeslot(

    "SPR_TVSU",
    "MT_SUPER_BOX",
    "MT_SUPER_GOLDBOX",
    "MT_SUPER_ICON",

    "S_SUPER_BOX",
    "S_SUPER_GOLDBOX",
    "S_SUPER_ICON1",
    "S_SUPER_ICON2"
)

function A_DoSuperOn(actor)
    local mo = actor.target
    local player = actor.target.player

    if not(player and (player.playerstate == PST_LIVE) and mo and mo.valid) then
        return
    end

    B.DoSuperOn(player)
end

states[S_SUPER_BOX] = {SPR_TVSU, 0, 2, NULL, 0, 0, S_BOX_FLICKER, 0}
states[S_SUPER_GOLDBOX] = {SPR_TVSU, 1, 2, A_GoldMonitorSparkle, 0, 0, S_GOLDBOX_FLICKER, 0}

states[S_SUPER_ICON1] = {SPR_TVSU, FF_ANIMATE|2, 18, NULL, 3, 4, S_SUPER_ICON2, 0}
states[S_SUPER_ICON2] = {SPR_TVSU, 2, 18, A_DoSuperOn, 0, 0, S_NULL, 0}


mobjinfo[MT_SUPER_BOX] = {
    spawnstate = S_SUPER_BOX,
    spawnhealth = 1,
    seestate = S_NULL,
    seesound = sfx_None,
    reactiontime = 8,
    attacksound = sfx_None,
    painstate = S_SUPER_BOX,
    painchance = 0,
    painsound = sfx_None,
    meleestate = S_NULL,
    missilestate = S_NULL,
    deathstate = S_BOX_POP1,
    xdeathstate = S_NULL,
    deathsound = sfx_pop,
    speed = 1,
    radius = 18*FU,
    height = 40*FU,
    dispoffset = 0,
    mass = 100,
    damage = MT_SUPER_ICON,
    activesound = sfx_none,
    flags = MF_SOLID|MF_SHOOTABLE|MF_MONITOR,
    raisestate = S_NULL
}

mobjinfo[MT_SUPER_GOLDBOX] = {
    spawnstate = S_SUPER_GOLDBOX,
    spawnhealth = 1,
    seestate = S_NULL,
    seesound = sfx_None,
    reactiontime = 8,
    attacksound = sfx_None,
    painstate = S_SUPER_GOLDBOX,
    painchance = 0,
    painsound = sfx_None,
    meleestate = S_NULL,
    missilestate = S_NULL,
    deathstate = S_GOLDBOX_OFF1,
    xdeathstate = S_NULL,
    deathsound = sfx_pop,
    speed = 0,
    radius = 20*FU,
    height = 40*FU,
    dispoffset = 0,
    mass = 100,
    damage = MT_SUPER_ICON,
    activesound = sfx_none,
    flags = MF_SOLID|MF_SHOOTABLE|MF_MONITOR|MF_GRENADEBOUNCE,
    raisestate = S_NULL
}

mobjinfo[MT_SUPER_ICON] = {
    spawnstate = S_SUPER_ICON1,
    spawnhealth = 1,
    seestate = S_NULL,
    seesound = sfx_s3k3e,
    reactiontime = 8,
    attacksound = sfx_None,
    painstate = S_NULL,
    painchance = 0,
    painsound = sfx_None,
    meleestate = S_NULL,
    missilestate = S_NULL,
    deathstate = S_NULL,
    xdeathstate = S_NULL,
    deathsound = sfx_pop,
    speed = 2*FU,
    radius = 2*FU,
    height = 8*FU,
    dispoffset = 0,
    mass = 100,
    damage = 62*FU,
    activesound = sfx_none,
    flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_SCENERY|MF_NOGRAVITY|MF_BOXICON,
	raisestate = S_NULL
}

local replace_box = {
    MT_SNEAKERS_BOX,
    MT_INVULN_BOX
}

local replace_goldbox = {
    MT_SNEAKERS_GOLDBOX,
    MT_INVULN_GOLDBOX
}

for k, v in ipairs(replace_box) do
    addHook("MobjSpawn", function(mo)
        mo.type = MT_SUPER_BOX
    end, v)
end

for k, v in ipairs(replace_goldbox) do
    addHook("MobjSpawn", function(mo)
        mo.type = MT_SUPER_GOLDBOX
    end, v)
end