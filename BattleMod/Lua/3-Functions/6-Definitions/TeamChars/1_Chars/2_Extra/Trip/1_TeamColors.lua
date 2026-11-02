local B = CBW_Battle

-- From Trip the Sungazer (https://mb.srb2.org/addons/trip-the-sungazer.7714/)
-- by lightdasher

B.SafeFreeslot("SKINCOLOR_SUNGAZER", "SKINCOLOR_TERRA_TRIP_1", 
"SKINCOLOR_TERRA_TRIP_2", "SKINCOLOR_TERRA_TRIP_3", "SKINCOLOR_TERRA_TRIP_4",
"SKINCOLOR_TERRA_TRIP_5")

skincolors[SKINCOLOR_SUNGAZER] = {
    name = Sungazer,
    ramp = {51, 52, 53, 54, 55, 56, 58, 38, 39, 40, 41, 42, 43, 44, 45, 46},
    invcolor = SKINCOLOR_CRIMSON,
    invshade = 9,
    chatcolor = V_ORANGEMAP,
    accessible = True
}

-- Terra Trip
skincolors[SKINCOLOR_TERRA_TRIP_1] = {
    name = "Terra TRIP 1",
    ramp = {72,64,65,65,66,66,55,58,58,58,43,45,45,186,187,187
},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_TERRA_TRIP_2] = {
    name = "Terra TRIP 2",
    ramp = {64,65,66,66,55,55,58,40,40,40,45,46,46,187,187,187
},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_TERRA_TRIP_3] = {
    name = "Terra TRIP 3",
    ramp = {65,66,55,55,58,58,40,42,42,42,46,47,47,169,254,254
},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_TERRA_TRIP_4] = {
    name = "Terra TRIP 4",
    ramp = {66,56,58,58,41,41,42,44,44,44,47,47,47,254,31,31
},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
skincolors[SKINCOLOR_TERRA_TRIP_5] = {
    name = "Terra TRIP 5",
    ramp = {56,58,41,41,42,42,44,46,46,46,47,47,47,31,31,31
},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}