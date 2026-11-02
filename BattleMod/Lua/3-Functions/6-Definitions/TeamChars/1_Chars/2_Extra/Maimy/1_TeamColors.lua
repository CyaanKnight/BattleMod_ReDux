local B = CBW_Battle

-- From Maimy (https://mb.srb2.org/addons/maimy-the-rosy-robot.2514/)
-- by DrStephen

B.SafeFreeslot(
"SKINCOLOR_MIAMI"
)
skincolors[SKINCOLOR_MIAMI] = {
    name = "Miami",
    ramp = {0,128,120,121,121,122,122,122,123,124,142,142,137,138,138,159
},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = true
}

B.SafeFreeslot(
"SKINCOLOR_SUPER_PRISMARINE1",
"SKINCOLOR_SUPER_PRISMARINE2",
"SKINCOLOR_SUPER_PRISMARINE3",
"SKINCOLOR_SUPER_PRISMARINE4",
"SKINCOLOR_SUPER_PRISMARINE5"
)

skincolors[SKINCOLOR_SUPER_PRISMARINE1] = {
    name = "Super Prismarine 1",
    ramp = {0, 128, 120, 120, 121, 121, 122, 122, 123, 123, 124, 125, 125, 143, 143, 138},
    invcolor = SKINCOLOR_ROSY,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_PRISMARINE2] = {
    name = "Super Prismarine 2",
    ramp = {0, 120, 120, 121, 122, 122, 123, 123, 124, 124, 125, 125, 126, 143, 138, 138},
    invcolor = SKINCOLOR_ROSY,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_PRISMARINE3] = {
    name = "Super Prismarine 3",
    ramp = {0, 120, 120, 121, 140, 141, 123, 124, 142, 125, 126, 143, 143, 138, 138, 139},
    invcolor = SKINCOLOR_ROSY,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_PRISMARINE4] = {
    name = "Super Prismarine 4",
    ramp = {0, 128, 120, 120, 140, 140, 141, 141, 142, 142, 143, 143, 143, 138, 138, 139},
    invcolor = SKINCOLOR_ROSY,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_PRISMARINE5] = {
    name = "Super Prismarine 5",
    ramp = {0, 128, 120, 120, 140, 141, 141, 142, 142, 137, 137, 138, 138, 138, 139, 139},
    invcolor = SKINCOLOR_ROSY,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}