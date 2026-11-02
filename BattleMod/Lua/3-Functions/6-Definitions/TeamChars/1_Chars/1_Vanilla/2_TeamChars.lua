
local B = CBW_Battle

freeslot(
"SPR_SONICFLAG",
"SPR_TAILSFLAG",
"SPR_KNUCKLESFLAG",
"SPR_AMYFLAG",
"SPR_FANGFLAG",
"SPR_METALSONFLAG",
"SPR_EGGFLAG"
)

B.AddTeamChar("sonic", {
    flagsprite = SPR_SONICFLAG,
    skincolor = SKINCOLOR_BLUE,
    supercolor = SKINCOLOR_SUPERSAPPHIRE1
})

B.AddTeamChar("tails", {
    flagsprite = SPR_TAILSFLAG,
    skincolor = SKINCOLOR_ORANGE,
    supercolor = SKINCOLOR_SUPERORANGE1
})

B.AddTeamChar("knuckles", {
    flagsprite = SPR_KNUCKLESFLAG,
    skincolor = SKINCOLOR_PEPPER,
    flagcolor = SKINCOLOR_RED,
    supercolor = SKINCOLOR_SUPERRED1
})

B.AddTeamChar("amy", {
    flagsprite = SPR_AMYFLAG,
    skincolor = SKINCOLOR_TAFFY,
    flagcolor = SKINCOLOR_ROSY,
    supercolor = SKINCOLOR_SUPERROSY1,
    flagname = "PINK"
})

B.AddTeamChar("fang", {
    flagsprite = SPR_FANGFLAG,
    skincolor = SKINCOLOR_MAUVE,
    supercolor = SKINCOLOR_SUPERLAVENDER1
})

B.AddTeamChar("metalsonic", {
    flagsprite = SPR_METALSONFLAG,
    skincolor = SKINCOLOR_COBALT,
    supercolor = SKINCOLOR_SUPERCOBALT1
})

B.AddTeamChar("eggman", {
    flagsprite = SPR_EGGFLAG,
    skincolor = SKINCOLOR_JET,
    supercolor = SKINCOLOR_SUPERJET1
})