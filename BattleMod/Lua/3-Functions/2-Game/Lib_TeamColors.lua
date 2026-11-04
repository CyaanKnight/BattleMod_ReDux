-- Team Colors
/* 
    B.RightTeam_Info and B.LeftTeam_Info contain the following

	flagsprite - Sprite to use for the flag.
    Frame 0/A - Sprite for in-game flag, left side
    Frame 1/B - Sprite for in-game flag, Right side
    Frame 2/C - Sprite for flag on HUD and gotflag indicator, left side
    Frame 3/D - Sprite for flag on HUD and gotflag indicator, right side


    The following can all use SKINCOLOR_* constants, or tables with the contents of a skincolor_t*
	skincolor
	flagcolor (skincolor by default)
	ringcolor (skincolor by default)
	monitorcolor (skincolor by default)

    supercolor - Can either be set as...
                 a single SKINCOLOR_* constant, and will cycle the 4 colors after it like a vanilla supercolor
                 or...
                 a table containing five tables, each with the contents of a skincolor_t*
    
    static_supercolor - Boolean, if set, supercolor will act like a normal skincolor field like the other color fields.


	flagname - Custom name for flag, will automatically have the word "Flag", after it in dialogs
               Automatically set to the name of the flagcolor

    fullname - Boolean, if set, the word "Flag" will not automatically display after the flagname

*/

/*
    Team Characters
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Using B.AddTeamChar, you can add a pre-configured team that contains all of the information
    B.RightTeam_Info/B.LeftTeam_Info needs.

    B.AddTeamChar(name, table)

    name - name of the team
    table - table containing the fields in the documentation above this
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Using B.AddTeamMatchup, you can add a pre-configured matchup of two characters, and optionally provide overrides for either of them.

    B.AddTeamMatchup(name1, name2, overrides, hidden, noflip)

    name1 - Name of first character
    name2 - Name of second character

    overrides - table that can contains overrides for either character's team info, like so

    -- Example
    B.AddTeamMatchup("sonic", "metalsonic", {
        ["metalsonic"] = {
            skincolor = SKINCOLOR_YELLOW
        }
    }

    noflip - If set, the team will not randomly switch left and right on load
    
    This code creates a matchup between Sonic and Metal Sonic. When this specific matchup is active, Metal Sonic's team will always be yellow.
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    hidden - Boolean, if set, this matchup will never be picked randomly, and can only be accessed via the level header

*/

/*
    Level Header usage (CASE INSENSITIVE)

    If a given map does NOT use TOL_CTF, by default, a team gametype will have teams randomly picked by picking a random matchup.
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    If you want to configure your map to use a specific matchup, or pick randomly from a specific pool of matchups...

    # Example
    Lua.TeamColors_Matchups = sonic|knuckles,amy|metalsonic

    This will have your map randomly pick either Sonic & Knuckles, or Amy & Metal Sonic, as the teams.

    Note that the matchups do not actually have to exist in Lua to be used here. If no overrides are set, the defaults for each character are used.
    
    You cannot set character matchup overrides in the level header, but you can manually override team aspects statically.
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    By default, there is a random chance to flip the teams. If you don't want this then use

    # Example
    Lua.TeamColors_TeamFlip = false
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    If you want your map to always use a specific team configuration, you can set Lua.TeamColors_Matchups to only one matchup.

    Alternatively, you can manually override each of the character fields as follows.

    ---> Let *** be either Left or Right <---



    Lua.***Team_flagsprite - Set to full SPR_* constant, no quotation marks
    
    The following can only be set as SKINCOLOR_* constants 
    Lua.***Team_skincolor
    Lua.***Team_flagcolor
    Lua.***Team_ringcolor
    Lua.***Team_monitorcolor

    Lua.***Team_supercolor - Set to the first supercolor in a set of 5, as a SKINCOLOR_* constant.
    Lua.***Team_static_supercolor - Boolean, if set to true, Lua.***Team_supercolor can be set to a single SKINCOLOR_* constant

    Lua.***Team_flagname - Custom name for flag, will automatically have the word "Flag", after it in dialogs
    Lua.***Team_fullname - Boolean, if set, the word "Flag" will not automatically display after the flagname
-------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
    
local B = CBW_Battle

-- The order of things
local enum_table = {
    "flagsprite",
    "skincolor",
    "flagcolor",
    "ringcolor",
    "monitorcolor",
    "supercolor",
    "static_supercolor",
    "flagname",
    "fullname"
}

local debug = true

local function dprint(...)
    if debug then
        print(...)
    end
end

B.TeamChars = {}

-- Random Picks
B.Matchups = {}

B.Matchup_Lookup = {}

/* Matchup Table
   
        {char1, char2, overrides}

*/

function B.AddTeamChar(name, info)
    assert(name, "You must provide a character name!")
    assert(info, "You must provide character info!")

    assert(type(info)=="table", "character info must be a table!")

    assert(info.flagsprite, "flagsprite must be set!")
    assert(info.skincolor, "skincolor must be set!")

	info.name = name

    B.TeamChars[name] = info

    dprint("Added TeamChar '"..name.."'")
end

function B.AddTeamMatchup(char1, char2, overrides, hidden, noflip)
    assert(char1 and B.TeamChars[char1], "char1 must already be added!")
    assert(char2 and B.TeamChars[char2], "char2 must already be added!")

    table.insert(B.Matchups, {left=char1, right=char2, overrides=overrides, hidden=hidden, noflip=noflip})
    B.Matchup_Lookup[char1.."|"..char2] = #B.Matchups

    dprint("Added matchup '"..char1.."|"..char2.."'")
end

function B.GetMatchup(left, right)

    assert(B.TeamChars[left] and B.TeamChars[right], "Both characters must already be added!")

    local overrides = nil
    local hidden = false
    local noflip = false

    local pair = left.."|"..right

    if B.Matchup_Lookup[pair] then
        dprint("matchup '"+pair+"' found, using special data")

        local matchup = B.Matchups[B.Matchup_Lookup[pair]]

        overrides = matchup.overrides
        hidden = matchup.hidden
        noflip = matchup.noflip
    end

    return {left=left, right=right, overrides=overrides, hidden=hidden, noflip=noflip}
end

function B.SetMatchup(matchup, noflip)

    local left = matchup.left
    local right = matchup.right

    if not(matchup.noflip or noflip) then
        if (P_RandomRange(0,1) == 1) then
            left = matchup.right
            right = matchup.left
        end
    end

	B.LeftTeam_Info = {}
    B.RightTeam_Info = {}

	local characters = {B.TeamChars[left], B.TeamChars[right]}

	for i = 1, #characters do
		local teamChar = characters[i]

		for k, v in pairs(teamChar) do
			if i == 1 then
				B.LeftTeam_Info[k] = v
			elseif i == 2 then
				B.RightTeam_Info[k] = v
			end
		end
	end

    if matchup.overrides then

        for i = 1, #enum_table do
            local var = enum_table[i]


           B.LeftTeam_Info[var] = overrides[left][var]
           B.RightTeam_Info[var] = overrides[right][var]
        end
    end
end

function B.GetRandomMatchup()
    local list = B.Matchups
    local num = P_RandomRange(1, #list)
    local matchup = list[num]

    dprint("Got matchup '"+matchup.left+"|"+matchup.right+"'")

    return matchup
end

function B.SetRandomTeams()
	if not(B.RandomTeamBlacklist[gametype]) then
		dprint("Setting teams to random matchup")
		B.LeftTeam_Info = {}
		B.RightTeam_Info = {}
		B.SetMatchup(B.GetRandomMatchup())
	end
end

COM_AddCommand("bro", do
	print(B.LeftTeam_Info.name+"|"+B.RightTeam_Info.name)
end)


function B.VerifyColor(color)
	if pcall(do return skincolors[color] end) then
		return true
	else
		return false
	end
end

function B.GetChatMap(color)
	if pcall(do return skincolors[color].chatcolor end) then
		return skincolors[color].chatcolor
	else
		return 0
	end
end

local textmapToEsc = {
	[0] = "\x80",
	[V_MAGENTAMAP] = "\x81",
	[V_YELLOWMAP] = "\x82",
	[V_GREENMAP] = "\x83",
	[V_BLUEMAP] = "\x84",
	[V_REDMAP] = "\x85",
	[V_GRAYMAP] = "\x86",
	[V_ORANGEMAP] = "\x87",
	[V_SKYMAP] = "\x88",
	[V_PURPLEMAP] = "\x89",
	[V_AQUAMAP] = "\x8A",
	[V_PERIDOTMAP] = "\x8B",
	[V_AZUREMAP] = "\x8C",
	[V_BROWNMAP] = "\x8D",
	[V_ROSYMAP] = "\x8E",
	[V_INVERTMAP] ="\x8F"
}

function B.GetChatEsc(chatmap)
	if textmapToEsc[chatmap] then
		return textmapToEsc[chatmap]
	else
		return "\x80"
	end
end

function B.GetTeamColor(ctfteam)
	local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

	if info.skincolor and B.VerifyColor(info.skincolor) then
		return info.skincolor
	else
		error(string.." team skincolor is not valid!")
	end
end

function B.GetFlagColor(ctfteam)

	local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

	if info.flagcolor and B.VerifyColor(info.flagcolor) then
		return info.flagcolor
	else
		return B.GetTeamColor(ctfteam)
	end
end

function B.GetRingColor(ctfteam)

	local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

	if info.ringcolor and B.VerifyColor(info.ringcolor) then
		return info.ringcolor
	else
		return B.GetTeamColor(ctfteam)
	end
end

function B.GetMonitorColor(ctfteam)

	local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

	if info.monitorcolor and B.VerifyColor(info.monitorcolor) then
		return info.monitorcolor
	else
		return B.GetTeamColor(ctfteam)
	end
end

function B.GetTeamSuperColor(ctfteam)

	local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

	if info.supercolor and B.VerifyColor(info.supercolor) then
		return info.supercolor
	else
		return false
	end
end

function B.GetFlagName(ctfteam)

	local info
	local name

	if ctfteam == 1 then
		info = B.LeftTeam_Info
		name = "BLUE"
	elseif ctfteam == 1 then
		info = B.RightTeam_Info
		name = "RED"
	else
		error("string must be either 'left' or 'right'")
		return nil
	end

	-- Left Flag Name
	if info.flagname then
		name = info.flagname:upper()
	else
		name = R_GetNameByColor(B.GetFlagColor(ctfteam)):upper()
	end

	if info.fullname then
		-- Use the name as-is
	else
		name = $+" FLAG"
	end

	return name
end

function B.GetFlagSprite(ctfteam)
	local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

	return info.flagsprite
end

function B.GetTeamInfo(ctfteam)
    local info
	local string

	if ctfteam == 1 then
		info = B.RightTeam_Info
		string = "right"
	elseif ctfteam == 2 then
		info = B.LeftTeam_Info
		string = "left"
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end

    return info
end

local teams = {
	{"right", "red"},
	{"left", "blue"}
}

local search_table = enum_table

table.insert(search_table, 1, "character")

function B.SetTeamInfoVar(ctfteam, field, value)
	if ctfteam == 1 then
		B.RightTeam_Info[field] = value
	elseif ctfteam == 2 then
		B.LeftTeam_Info[field] = value
	else
		error("ctfteam must be either 1 or 2!")
		return nil
	end
end


function B.MapHasTeamInfo(mapnum)
	local header = (pcall(do return mapheaderinfo[mapnum] end) and mapheaderinfo[mapnum]) or nil

	if not(header) then
		return false
	end

	for ctfteam = 1, 2 do
		for name = 1, 2 do
			local prefix = teams[ctfteam][name]

			for i = 1, #search_table do
				local field = search_table[i]:lower()
				local headerval = header[prefix+"team_"+field]

				if headerval then
					dprint("Level Header info found.")
					return true
				end
			end
		end
	end

	return false
end

function B.SetMapTeams(mapnum)
	
	local header = (pcall(do return mapheaderinfo[mapnum] end) and mapheaderinfo[mapnum]) or nil

	if not(header) then
		return false
	end

	local char1 = nil
	local char2 = nil

	for ctfteam = 1, 2 do
		for name = 1, 2 do
			local prefix = teams[ctfteam][name]

			for i = 1, #search_table do
				local field = search_table[i]:lower()
				local headerval = header[prefix+"team_"+field]

				if not(headerval) then
					continue
				end

				local value = nil
				if field == "character" then
					if B.TeamChars[field:lower()] then
						for char_index = 1, #enum_table do
							local char_field = enum_table[char_index]
							B.SetTeamInfoVar(ctfteam, char_field, B.TeamChars[field:lower()][headerval:lower()])
						end
					end
				elseif field == "flagsprite" then
					value = _G[headerval:upper()]
				elseif field == "skincolor" or
				field == "flagcolor" or
				field == "ringcolor" or
				field == "monitorcolor" then
					local NameToColor = R_GetColorByName(headerval:lower())
					
					if NameToColor then
						value = NameToColor
					elseif _G[headerval:upper()] then
						value = _G[headerval:upper()]
					end
				elseif field == "supercolor" then
					local NameToColor = R_GetSuperColorByName(headerval:lower())
					
					if NameToColor then
						value = NameToColor
					elseif _G[headerval:upper()] then
						value = _G[headerval:upper()]
					end
				elseif (field == "static_supercolor") or (field == "fullname") then
					if headerval == "true" then
						value = true
					else
						value = false
					end
				elseif field == "flagname" then
					value = headerval:upper()
				end

				B.SetTeamInfoVar(ctfteam, field, value)
			end
		end
	end
end

function B.TeamColors(map)
	B.SetMatchup(B.GetMatchup("sonic", "knuckles"), true)
	if B.MapHasTeamInfo(map) then
		B.RightTeam_Info = {}
		B.LeftTeam_Info = {}
		B.SetMatchup(B.GetMatchup("sonic", "knuckles"), true)
		B.SetMapTeams(map)
	else
		B.SetRandomTeams()
	end
	skincolor_redteam = B.GetTeamColor(1)
	skincolor_blueteam = B.GetTeamColor(2)
	skincolor_redring = B.GetRingColor(1)
	skincolor_bluering = B.GetRingColor(2)
end

				



