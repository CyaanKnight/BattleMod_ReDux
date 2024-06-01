-- the lua directory
local directories = {

    {
        folder = "1-Init",
        files = { 
            "Init",
            "Init_Gametype",
            "Init_GametypeExtra",
            "Init_VersionInfo"
        },
    },
    
    
    {
        folder = "2-MobjStateInfo/1-Gamemodes",
        files = { 
            "Info_2DCam",
            "Info_Arena",
            "Info_CP",
            "Info_CTF",
            "Info_Diamond",
            "Info_RevengeGunner",
            "Info_Ruby",
            "Info_Tag"
        },
    },
    
    {
        folder = "2-MobjStateInfo/2-Specials",
        files = { 
            "Info_ActBomb",
            "Info_ActDashSlicer",
            "Info_ActDustDevil",
            "Info_ActEnergyBlast",
            "Info_ActGroundPound",
            "Info_Actions",
            "Info_ActRoboMissile",
            "Info_ActRockBlast",
            "Info_ActTailSweep",
            "Info_RingSpark"
        },
    },
    
    {
        folder = "2-MobjStateInfo/3-Items",
        files = { 
            "Info_GoldenMonitors",
            "Info_ItemBubble1",
            "Info_ItemBubble2"
        },
    },
        
    {
        folder = "2-MobjStateInfo/4-Info1",
        files = { 
            "Info_Bashables",
            "Info_CollisionFX",
            "Info_CollisionVFX",
            "Info_CommonVFX",
            "Info_Dashmode",
            "Info_EmeraldProps",
            "Info_FireTrail",
            "Info_Fireworks",
            "Info_Guard",
            "Info_Hammer",
            "Info_Invulnerability",
            "Info_PlayerOverlay",
            "Info_Popgun",
            "Info_RadarPoints",
            "Info_ShieldBubbles",
            "Info_StunBreak"
        },
    },
        
    {
        folder = "2-MobjStateInfo/5-Names",
        files = { 
            "Info_ObjectNames",
            "Info_Sound"
        },
    },
        
    {
        folder = "2-MobjStateInfo/6-Colors",
        files = { 
            "Info_PitchBlack"
        },
    },
        
    {
        folder = "3-Console",
        files = { 
            "Cons_Arena",
            "Cons_Battle",
            "Cons_CP",
            "Cons_CTF",
            "Cons_Debug",
            "Cons_Diamond",
            "Cons_Item",
            "Cons_Misc",
            "Cons_PlayerConfig",
            "Cons_Ruby"
        },
    },
        
        
    {
        folder = "3-Functions/1-General",
        files = { 
            "Lib_Color",
            "Lib_Debug",
            "Lib_Math",
            "Lib_Random"
        },
    },
        
    {
        folder = "3-Functions/2-Game",
        files = { 
            "Lib_2DControl",
            "Lib_BattleFeed",
            "Lib_ChangeTeam",
            "Lib_CharacterSwitch",
            "Lib_Flicky",
            "Lib_GametypeControl",
            "Lib_Intermission",
            "Lib_NetVars",
            "Lib_RoundControl",
            "Lib_ScoreControl",
            "Lib_TailsDoll"
        },
    },
        
    {
        folder = "3-Functions/2-Game/Arena",
        files = { 
            "Lib_Crown",
            "Lib_ModeArena",
            "Lib_Revenge"
        },
    },
        
    {
        folder = "3-Functions/2-Game/Bank",
        files = { 
            "HUDObj",
            "RingBank"
        },
    },
        
    {
        folder = "3-Functions/2-Game/CP",
        files = { 
            "Lib_ModeCP"
        },
    },
        
    {
        folder = "3-Functions/2-Game/CTF",
        files = { 
            "Lib_ModeCTF",
            "Lib_ReturnNerf",
            "Lib_RunnerDebuff"
        },
    },
        
    {
        folder = "3-Functions/2-Game/Diamond",
        files = { 
            "Lib_ModeDiamond"
        },
    },
        
    {
        folder = "3-Functions/2-Game/Items",
        files = { 
            "Lib_ItemBubble",
            "Lib_ItemSpawn"
        },
    },
        
    {
        folder = "3-Functions/2-Game/Ruby",
        files = { 
            "Lib_ModeRuby"
        },
    },
        
    {
        folder = "3-Functions/2-Game/Tag",
        files = { 
            "Lib_ModeTag"
        },
    },
        
    {
        folder = "3-Functions/3-Player",
        files = { 
            "Lib_AbilityControl",
            "Lib_ActionControl",
            "Lib_AirDodge",
            "Lib_BattleProjectiles",
            "Lib_DamageControl",
            "Lib_Dashmode",
            "Lib_Guard",
            "Lib_Hammer",
            "Lib_Input",
            "Lib_PlayerControl",
            "Lib_PlayerFrame",
            "Lib_PlayerOverlay",
            "Lib_PlayerSpawn",
            "Lib_Popgun",
            "Lib_ShieldActives",
            "Lib_ShieldControl",
            "Lib_Spectator",
            "Lib_StunBreak",
            "Lib_UserConfig"
        },
    },
        
    {
        folder = "3-Functions/3-Player/Special Moves",
        files = { 
            "Lib_ActBombThrow",
            "Lib_ActCombatRoll",
            "Lib_ActDig",
            "Lib_ActDodgeRoll",
            "Lib_ActEnergyAttack",
            "Lib_ActPikoSpin",
            "Lib_ActPikoTornado",
            "Lib_ActRoboMissile",
            "Lib_ActSuperSpinJump",
            "Lib_ActTailSweep"
        },
    },
        
    {
        folder = "3-Functions/4-Physics",
        files = { 
            "Lib_Movement",
            "Lib_Seek",
            "Lib_Slipstream",
            "Lib_WaterControl"
        },
    },
        
    {
        folder = "3-Functions/4-Physics/Collision",
        files = { 
            "Lib_Bashables",
            "Lib_Collide2",
            "Lib_Collide",
            "Lib_PriorityCommon",
            "Lib_Priority_Index",
            "Lib_Priority"
        },
    },
    
    {
        folder = "3-Functions/5-HUD",
        files = { 
            "Lib_HUDArena",
            "Lib_HUDArenaWait",
            "Lib_HUDCP",
            "Lib_HUDCTF",
            "Lib_HUDDebug",
            "Lib_HUDDiamond",
            "Lib_HUDMinimap",
            "Lib_HUDPinch",
            "Lib_HUDPreRound",
            "Lib_HUDRadar",
            "Lib_HUDRings",
            "Lib_HUDRuby",
            "Lib_HUDShield",
            "Lib_HUDSpecials",
            "Lib_HUDTeammates",
            "Lib_HUDTimer",
            "Lib_HUDTitle",
            "Lib_SwitchHud",
            "Lib_ToggleVanillaHUD"
        }
    },
    
    {
        folder = "3-Functions/6-Definitions",
        files = { 
            "Def_SkinVars"
        }
    },
    
    {
        folder = "4-Hooks",
        files = { 
            "Exec_Bashable",
            "Exec_Chat",
            "Exec_Collectibles",
            "Exec_ControlPoint",
            "Exec_Dashmode",
            "Exec_Diamond",
            "Exec_EnergyAttack",
            "Exec_HUD",
            "Exec_HurtMsg",
            "Exec_ItemSpawn",
            "Exec_Player",
            "Exec_Projectiles",
            "Exec_Ruby",
            "Exec_SpinWave",
            "Exec_Springs",
            "Exec_System",
            "Exec_Visual"
        }
    },
    
    {
        folder = "5-Resources",
        files = { 
            "2DCamera",
            "L_JumpLeniency",
            "L_LedgeGrab",
            "MetalBugFix",
            "ObjRespawn_Core",
            "ObjRespawn_Types"
        }
    },
    
    {
        folder = "6-End",
        files = { 
            "PrintVersion" 
        }
    }
}

-- load the files
for _, directory in ipairs(directories)
    for _, file in ipairs(directory.files)
        dofile(directory.folder.."/"..file..".lua")
    end
end