--Special rings for special things

local cloneinfo = {
    "spawnstate",
    "spawnhealth",
    "seestate",
    "seesound",
    "reactiontime",
    "attacksound",
    "painstate",
    "painchance",
    "painsound",
    "meleestate",
    "missilestate",
    "deathstate",
    "xdeathstate",
    "deathsound",
    "speed",
    "radius",
    "height",
    "dispoffset",
    "mass",
    "damage",
    "activesound",
    "flags",
    "raisestate"
}

freeslot("MT_BFLINGRING")

for i = 1, #cloneinfo do
    local field = cloneinfo[i]
    mobjinfo[MT_BFLINGRING][field] = mobjinfo[MT_FLINGRING][field]
end