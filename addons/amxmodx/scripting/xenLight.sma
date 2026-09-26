/*
*
*	Xen Light by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /xl                             "Opens the Xen Light menu."
*       say_team /xl                        "Opens the Xen Light menu."
*       say /xenlight                       "Opens the Xen Light menu."
*       say_team /xenlight                  "Opens the Xen Light menu."
*       xl_reload                           "Reloads the configuration file."
*       xenlight_reload                     "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define LIGHT_KEY                   821090
#define LIGHT_ARRAY_ITEM            pev_iuser1
#define LIGHT_SEQ_IDLE              0
#define LIGHT_SEQ_RETRACT           1
#define LIGHT_SEQ_DEPLOY            2
#define LIGHT_DLIGHT_SCALE_MAX      100
#define LIGHT_DLIGHT_SCALE_MIN      1
#define LIGHT_DEPLOY_DURATION       1.88
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "XenLight_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_LIGHT
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_SOLID              = (1 << 0),
    FLAG_REVERSE            = (1 << 1),
    FLAG_COLOR_RANDOM       = (1 << 2),

    FLAG_SHOW               = (1 << 3),
    FLAG_GHOST              = (1 << 4),
    FLAG_GROUND             = (1 << 5),
    FLAG_ACTIVE             = (1 << 6),
    FLAG_LOCK               = (1 << 7),
    FLAG_PENDING            = (1 << 8)
}

enum
{
    ROTATE_MODE_PITCH,
    ROTATE_MODE_YAW,
    ROTATE_MODE_ROLL
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SIZE_SMALL,
    SIZE_MEDIUM,
    SIZE_LARGE
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,

    SETTING_DEFAULT_GLOW_SPRITE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_DEFAULT_GLOW_FRAMERATE,
    Float:SETTING_DEFAULT_GLOW_SCALE[3],
    SETTING_DEFAULT_GLOW_ALPHA,
    Float:SETTING_DEFAULT_TRIGGER_DISTANCE,
    Float:SETTING_DEFAULT_TRIGGER_DURATION[2],
    Float:SETTING_DEFAULT_COLOR_FREQUENCY[2],

    SETTING_MODEL_SMALL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_MEDIUM[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_LARGE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_SMALL[3],
    Float:SETTING_MAXS_SMALL[3],
    Float:SETTING_MINS_MEDIUM[3],
    Float:SETTING_MAXS_MEDIUM[3],
    Float:SETTING_MINS_LARGE[3],
    Float:SETTING_MAXS_LARGE[3],

    bool:SETTING_LIGHT_LOAD,
    Float:SETTING_LIGHT_CHECK,
    Float:SETTING_LIGHT_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP,
    SETTING_LIGHT_LIFE,
}

enum _:LIGHT
{
    LIGHT_ID,
    LIGHT_ITEM,
    LIGHT_FLAGS,
    LIGHT_TEAM,
    LIGHT_SIZE,
    LIGHT_GLOW,
    LIGHT_NAME[MAX_VALUE_LENGTH],

    Float:LIGHT_ORIGIN[3],
    Float:LIGHT_ORIGIN_GLOW[3],
    Float:LIGHT_ANGLES[3],
    Float:LIGHT_MINS[3],
    Float:LIGHT_MAXS[3],

    Float:LIGHT_FRAMERATE,
    LIGHT_GLOW_SPRITE[MAX_RESOURCE_PATH_LENGTH],
    Float:LIGHT_GLOW_FRAMERATE,
    Float:LIGHT_GLOW_SCALE,
    LIGHT_GLOW_ALPHA,
    Float:LIGHT_TRIGGER_DISTANCE,
    Float:LIGHT_TRIGGER_DURATION[2],
    Float:LIGHT_COLOR_FREQUENCY[2],
    LIGHT_DLIGHT_COLOR[3],
    LIGHT_DLIGHT_SCALE,

    Float:LIGHT_NEXT_SHOW,
    Float:LIGHT_NEXT_HIDE,
    Float:LIGHT_NEXT_IDLE,
    Float:LIGHT_NEXT_RANDOM
}

enum _:PLAYER_DATA
{
    PDATA_LIGHT_GHOST,
    PDATA_LIGHT_MENU,
    bool:PDATA_LIGHT_ACTION,
    PDATA_ROTATE_MODE,
    PDATA_ROTATE_SIZE,
    PDATA_LIGHT_FACTOR,
    PDATA_LIGHT_COLOR,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE,
    MENU_LIGHT
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_MODE,
    ROTATE_SIZE,
    ROTATE_PLACE
}

enum
{
    LIGHT_SCALE_UP,
    LIGHT_SCALE_DOWN,

    LIGHT_FACTOR = 3,
    LIGHT_COLOR,
    LIGHT_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate",
    "menuHandlerLight"
}

new g_szCN[] = "xenlight"

new Array:g_aLight,
    Array:g_aLightConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iLight, g_iLightConfig,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateMode[][] = {"LIGHT_ROTATE_PITCH", "LIGHT_ROTATE_YAW", "LIGHT_ROTATE_ROLL"}
new g_szRotateSize[][] = {"LIGHT_ROTATE_SMALL", "LIGHT_ROTATE_MEDIUM", "LIGHT_ROTATE_LARGE"}
new g_szLightColor[][] = {"LIGHT_COLOR_WHITE", "LIGHT_COLOR_RED", "LIGHT_COLOR_GREEN", "LIGHT_COLOR_BLUE", "LIGHT_COLOR_CYAN", "LIGHT_COLOR_YELLOW", "LIGHT_COLOR_MAGENTA", "LIGHT_COLOR_ORANGE", "LIGHT_COLOR_PURPLE", "LIGHT_COLOR_PINK", "LIGHT_COLOR_AQUA", "LIGHT_COLOR_WARM"}
new const g_iLightFactor[] = {1, 2, 3, 5, 10}
new const g_iLightColors[][3] =
{
    { 255, 255, 255 }, // White
    { 255,   0,   0 }, // Red
    {   0, 255,   0 }, // Green
    {   0,   0, 255 }, // Blue
    {   0, 255, 255 }, // Cyan
    { 255, 255,   0 }, // Yellow
    { 255,   0, 255 }, // Magenta
    { 255, 128,   0 }, // Orange
    { 128,   0, 255 }, // Purple
    { 255, 128, 192 }, // Pink
    { 128, 255, 255 }, // Aqua
    { 255, 192, 128 }  // Warm
}

public plugin_init()
{
    register_plugin("Xen Light", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_XenLight", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /xl",               "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Light menu.")
    register_clcmd("say_team /xl",          "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Light menu.")
    register_clcmd("say /xenlight",         "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Light menu.")
    register_clcmd("say_team /xenlight",    "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Light menu.")
    register_concmd("xl_reload",          "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_concmd("xenlight_reload",    "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("XenLight.txt")

    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()

    lightInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aLight = ArrayCreate(LIGHT)
    g_aLightConfig = ArrayCreate(LIGHT)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aLight)
    ArrayDestroy(g_aLightConfig)
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    lightSound(id, SOUND_MENU_NAV)
    lightMenu(id, MENU_ROOT)

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    lightReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id))
                UpdateData(id)

        ArrayClear(g_aLightConfig)
        g_iLightConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/XenLight.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eLight[LIGHT], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iLightConfig )
                            ArrayPushArray(g_aLightConfig, eLight)

                        copy(eLight[LIGHT_NAME], charsmax(eLight[LIGHT_NAME]), szData)
                        copy(eLight[LIGHT_GLOW_SPRITE], charsmax(eLight[LIGHT_GLOW_SPRITE]), g_eSettings[SETTING_DEFAULT_GLOW_SPRITE])
                        eLight[LIGHT_FLAGS]                 = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eLight[LIGHT_TEAM]                  = g_eSettings[SETTING_DEFAULT_TEAM]
                        eLight[LIGHT_FRAMERATE]             = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eLight[LIGHT_GLOW_FRAMERATE]        = g_eSettings[SETTING_DEFAULT_GLOW_FRAMERATE]
                        eLight[LIGHT_GLOW_ALPHA]            = g_eSettings[SETTING_DEFAULT_GLOW_ALPHA]
                        eLight[LIGHT_TRIGGER_DISTANCE]      = g_eSettings[SETTING_DEFAULT_TRIGGER_DISTANCE]
                        eLight[LIGHT_TRIGGER_DURATION][0]   = g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION][0]
                        eLight[LIGHT_TRIGGER_DURATION][1]   = g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION][1]
                        eLight[LIGHT_COLOR_FREQUENCY][0]    = g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY][0]
                        eLight[LIGHT_COLOR_FREQUENCY][1]    = g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY][1]

                        iSection = SECTION_LIGHT
                        g_iLightConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_SPRITE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_SPRITE], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_SPRITE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_SCALE], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_SCALE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_ALPHA], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_ALPHA]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TRIGGER_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TRIGGER_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_TRIGGER_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TRIGGER_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COLOR_FREQUENCY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_MODEL_SMALL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_SMALL], charsmax(g_eSettings[SETTING_MODEL_SMALL]))
                        else if ( equali(szKey, "SETTING_MODEL_MEDIUM") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_MEDIUM], charsmax(g_eSettings[SETTING_MODEL_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MODEL_LARGE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_LARGE], charsmax(g_eSettings[SETTING_MODEL_LARGE]))
                        else if ( equali(szKey, "SETTING_MINS_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_SMALL], charsmax(g_eSettings[SETTING_MINS_SMALL]))
                        else if ( equali(szKey, "SETTING_MAXS_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_SMALL], charsmax(g_eSettings[SETTING_MAXS_SMALL]))
                        else if ( equali(szKey, "SETTING_MINS_MEDIUM") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_MEDIUM], charsmax(g_eSettings[SETTING_MINS_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MAXS_MEDIUM") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_MEDIUM], charsmax(g_eSettings[SETTING_MAXS_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MINS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_LARGE], charsmax(g_eSettings[SETTING_MINS_LARGE]))
                        else if ( equali(szKey, "SETTING_MAXS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_LARGE], charsmax(g_eSettings[SETTING_MAXS_LARGE]))
                        else if ( equali(szKey, "SETTING_LIGHT_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_LIGHT_LOAD], charsmax(g_eSettings[SETTING_LIGHT_LOAD]))
                        else if ( equali(szKey, "SETTING_LIGHT_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_LIGHT_CHECK], charsmax(g_eSettings[SETTING_LIGHT_CHECK]))
                        else if ( equali(szKey, "SETTING_LIGHT_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_LIGHT_TASK], charsmax(g_eSettings[SETTING_LIGHT_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                        else if ( equali(szKey, "SETTING_LIGHT_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_LIGHT_LIFE], charsmax(g_eSettings[SETTING_LIGHT_LIFE]))
                    }
                    case SECTION_LIGHT:
                    {
                        if ( equali(szKey, "LIGHT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eLight[LIGHT_FLAGS], charsmax(eLight[LIGHT_FLAGS]))
                        else if ( equali(szKey, "LIGHT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eLight[LIGHT_TEAM], charsmax(eLight[LIGHT_TEAM]))
                        else if ( equali(szKey, "LIGHT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eLight[LIGHT_FRAMERATE], charsmax(eLight[LIGHT_FRAMERATE]))
                        else if ( equali(szKey, "LIGHT_GLOW_SPRITE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), eLight[LIGHT_GLOW_SPRITE], charsmax(eLight[LIGHT_GLOW_SPRITE]))
                        else if ( equali(szKey, "LIGHT_GLOW_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eLight[LIGHT_GLOW_FRAMERATE], charsmax(eLight[LIGHT_GLOW_FRAMERATE]))
                        else if ( equali(szKey, "LIGHT_GLOW_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eLight[LIGHT_GLOW_ALPHA], charsmax(eLight[LIGHT_GLOW_ALPHA]))
                        else if ( equali(szKey, "LIGHT_TRIGGER_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eLight[LIGHT_TRIGGER_DISTANCE], charsmax(eLight[LIGHT_TRIGGER_DISTANCE]))
                        else if ( equali(szKey, "LIGHT_TRIGGER_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eLight[LIGHT_TRIGGER_DURATION], charsmax(eLight[LIGHT_TRIGGER_DURATION]))
                        else if ( equali(szKey, "LIGHT_COLOR_FREQUENCY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eLight[LIGHT_COLOR_FREQUENCY], charsmax(eLight[LIGHT_COLOR_FREQUENCY]))
                    }
                }
            }
        }
    }

    if ( g_iLightConfig )
        ArrayPushArray(g_aLightConfig, eLight)
    else
        set_fail_state("No Lights were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eLight[LIGHT], iItem
    if ( (iItem = lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST])) != -1 )
    {
        lightKill(eLight)
        lightRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_LIGHT_GHOST]  = 0
    g_ePlayerData[id][PDATA_LIGHT_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock lightInit()
{
    if ( g_eSettings[SETTING_LIGHT_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock lightTerminate()
{
    new eLight[LIGHT]
    for ( new i = 0; i < g_iLight; i ++ )
    {
        ArrayGetArray(g_aLight, i, eLight)
        if ( !(eLight[LIGHT_FLAGS] & FLAG_PENDING)
        || eLight[LIGHT_FLAGS] & FLAG_REVERSE )
            continue

        eLight[LIGHT_FLAGS] |= FLAG_ACTIVE
        eLight[LIGHT_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aLight, i, eLight)
    }
}

stock lightMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[64], iMenu
    formatex(szData, charsmax(szData), "%L", id, "LIGHT_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:   { menuRoot(id, iMenu); }
        case MENU_CREATE: { menuCreate(iMenu);      format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_CREATE"); }
        case MENU_EDIT:   { menuEdit(id, iMenu);    format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_EDIT"); }
        case MENU_REMOVE: { menuRemove(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_REMOVE"); }
        case MENU_SHOW:   { menuShow(id, iMenu);    format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_SHOW"); }
        case MENU_STATUS: { menuStatus(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_STATUS"); }
        case MENU_ROTATE: { menuRotate(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_ROTATE"); }
        case MENU_LIGHT:  { menuLight(id, iMenu);   format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_ROOT_LIGHT"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "LIGHT_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROOT_NOCLIP", id, get_user_noclip(id) ? "LIGHT_ON" : "LIGHT_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROOT_GODMODE", id, get_user_godmode(id) ? "LIGHT_ON" : "LIGHT_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iLight >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_LIMIT", MAX_ENT)

                lightSound(id, SOUND_MENU_REMOVE)
                lightMenu(id, MENU_ROOT)
            }
            else
            {
                lightSound(id, SOUND_MENU_NAV)
                lightMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iLight )
            {
                client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_NO_LIGHT")

                lightSound(id, SOUND_MENU_REMOVE)
                lightMenu(id, MENU_ROOT)
            }
            else
            {
                lightSound(id, SOUND_MENU_NAV)
                lightMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iLight )
            {
                client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_NO_LIGHT")

                lightSound(id, SOUND_MENU_REMOVE)
                lightMenu(id, MENU_ROOT)
            }
            else
            {
                lightSound(id, SOUND_MENU_REMOVE)
                lightMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            lightNoClip(id)
        }
        case ROOT_GODMODE:
        {
            lightGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eLight[LIGHT], szItem[64]
    for ( new i = 0; i < g_iLightConfig; i ++ )
    {
        ArrayGetArray(g_aLightConfig, i, eLight)

        copy(szItem, charsmax(szItem), eLight[LIGHT_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        lightSound(id, SOUND_MENU_NAV)
        lightMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    lightCreate(id, item)
    lightSound(id, SOUND_MENU_NAV)
    lightMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eLight[LIGHT]
    menuNav(id, iMenu)
    ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_REMOVE_CURRENT", eLight[LIGHT_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    lightSelect(eLight, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
}

public menuHandlerRemove(id, menu, item)
{
    new eLight[LIGHT]
    ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        lightSelect(eLight, eLight[LIGHT_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_LIGHT_MENU] >= g_iLight - 1 )
                g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
            else
                g_ePlayerData[id][PDATA_LIGHT_MENU] ++

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_LIGHT_MENU] <= 0 )
                g_ePlayerData[id][PDATA_LIGHT_MENU] = g_iLight - 1
            else
                g_ePlayerData[id][PDATA_LIGHT_MENU] --

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            lightSetState(eLight)
            lightKill(eLight)
            lightRemove(g_ePlayerData[id][PDATA_LIGHT_MENU])

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_REMOVE_CURRENT", eLight[LIGHT_NAME])
            g_ePlayerData[id][PDATA_LIGHT_MENU] = 0

            lightSound(id, g_iLight > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            lightMenu(id, g_iLight > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iLight )
            {
                ArrayGetArray(g_aLight, 0, eLight)
                lightSetState(eLight)
                lightKill(eLight)
                lightRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_LIGHT_MENU] = 0

            lightSound(id, SOUND_MENU_ALERT)
            lightMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                lightSound(id, SOUND_MENU_NAV)
                lightMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eLight[LIGHT]
    menuNav(id, iMenu)
    ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_SHOW_CURRENT",
    eLight[LIGHT_FLAGS] & FLAG_SHOW ? "\y" : "\r", eLight[LIGHT_NAME], id, eLight[LIGHT_FLAGS] & FLAG_SHOW ? "LIGHT_SHOWN" : "LIGHT_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    lightSelect(eLight, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
}

public menuHandlerShow(id, menu, item)
{
    new eLight[LIGHT]
    ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        lightSelect(eLight, eLight[LIGHT_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_LIGHT_MENU] >= g_iLight - 1 )
                g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
            else
                g_ePlayerData[id][PDATA_LIGHT_MENU] ++

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_LIGHT_MENU] <= 0 )
                g_ePlayerData[id][PDATA_LIGHT_MENU] = g_iLight - 1
            else
                g_ePlayerData[id][PDATA_LIGHT_MENU] --

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eLight[LIGHT_FLAGS] ^= FLAG_SHOW
            lightSetState(eLight)

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_SHOW_CURRENT",
            eLight[LIGHT_NAME], id, eLight[LIGHT_FLAGS] & FLAG_SHOW ? "LIGHT_CHAT_SHOWN" : "LIGHT_CHAT_HIDDEN")
            ArraySetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iLight; i ++ )
            {
                ArrayGetArray(g_aLight, i, eLight)
                eLight[LIGHT_FLAGS] |= FLAG_SHOW
                lightSetState(eLight)

                ArraySetArray(g_aLight, i, eLight)
            }

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_SHOW_ALL_SHOWN")
            lightSound(id, SOUND_MENU_ALERT)
            lightMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iLight; i ++ )
            {
                ArrayGetArray(g_aLight, i, eLight)
                eLight[LIGHT_FLAGS] &= ~FLAG_SHOW
                lightSetState(eLight)

                ArraySetArray(g_aLight, i, eLight)
            }

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_SHOW_ALL_HIDDEN")
            lightSound(id, SOUND_MENU_ALERT)
            lightMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                lightSound(id, SOUND_MENU_NAV)
                lightMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eLight[LIGHT]
    menuNav(id, iMenu)
    ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_STATUS_CURRENT",
    eLight[LIGHT_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eLight[LIGHT_NAME], id, eLight[LIGHT_FLAGS] & FLAG_ACTIVE ? "LIGHT_ENABLED" : "LIGHT_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    lightSelect(eLight, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
}

public menuHandlerStatus(id, menu, item)
{
    new eLight[LIGHT]
    ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        lightSelect(eLight, eLight[LIGHT_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_LIGHT_MENU] >= g_iLight - 1 )
                g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
            else
                g_ePlayerData[id][PDATA_LIGHT_MENU] ++

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_LIGHT_MENU] <= 0 )
                g_ePlayerData[id][PDATA_LIGHT_MENU] = g_iLight - 1
            else
                g_ePlayerData[id][PDATA_LIGHT_MENU] --

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eLight[LIGHT_FLAGS] ^= FLAG_ACTIVE
            lightSetState(eLight)

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_STATUS_CURRENT",
            eLight[LIGHT_NAME], id, eLight[LIGHT_FLAGS] & FLAG_ACTIVE ? "LIGHT_CHAT_ENABLED" : "LIGHT_CHAT_DISABLED")
            ArraySetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iLight; i ++ )
            {
                ArrayGetArray(g_aLight, i, eLight)
                eLight[LIGHT_FLAGS] |= FLAG_ACTIVE
                lightSetState(eLight)

                ArraySetArray(g_aLight, i, eLight)
            }

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_STATUS_ALL_ENABLED")
            lightSound(id, SOUND_MENU_ALERT)
            lightMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iLight; i ++ )
            {
                ArrayGetArray(g_aLight, i, eLight)
                eLight[LIGHT_FLAGS] &= ~FLAG_ACTIVE
                lightSetState(eLight)

                ArraySetArray(g_aLight, i, eLight)
            }

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_STATUS_ALL_DISABLED")
            lightSound(id, SOUND_MENU_ALERT)
            lightMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                lightSound(id, SOUND_MENU_NAV)
                lightMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_LIGHT_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eLight[LIGHT]
    if ( lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROTATE_GROUND",
    id, eLight[LIGHT_FLAGS] & FLAG_GROUND ? "LIGHT_ON" : "LIGHT_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROTATE_MODE", id, g_szRotateMode[g_ePlayerData[id][PDATA_ROTATE_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eLight[LIGHT], iItem
    if ( (iItem = lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eLight[LIGHT_ID], pev_angles, eLight[LIGHT_ANGLES])
            eLight[LIGHT_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eLight[LIGHT_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] < -180.0 ) eLight[LIGHT_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += 360.0

            set_pev(eLight[LIGHT_ID], pev_angles, eLight[LIGHT_ANGLES])
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eLight[LIGHT_ID], pev_angles, eLight[LIGHT_ANGLES])
            eLight[LIGHT_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eLight[LIGHT_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] > 180.0 ) eLight[LIGHT_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= 360.0

            set_pev(eLight[LIGHT_ID], pev_angles, eLight[LIGHT_ANGLES])
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eLight[LIGHT_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROTATE)
        }
        case ROTATE_MODE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_MODE] > ROTATE_MODE_ROLL )
                g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_PITCH

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROTATE)
        }
        case ROTATE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_LARGE )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_SMALL

            eLight[LIGHT_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eLight[LIGHT_SIZE] )
            {
                case SIZE_SMALL:  { engfunc(EngFunc_SetModel, eLight[LIGHT_ID], g_eSettings[SETTING_MODEL_SMALL]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][0]; }
                case SIZE_MEDIUM: { engfunc(EngFunc_SetModel, eLight[LIGHT_ID], g_eSettings[SETTING_MODEL_MEDIUM]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][1]; }
                case SIZE_LARGE:  { engfunc(EngFunc_SetModel, eLight[LIGHT_ID], g_eSettings[SETTING_MODEL_LARGE]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][2]; }
            }
            set_pev(eLight[LIGHT_GLOW], pev_scale, eLight[LIGHT_GLOW_SCALE])
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            lightTrace(eLight, id)

            eLight[LIGHT_FLAGS] |= (FLAG_SHOW | FLAG_LOCK)
            eLight[LIGHT_FLAGS] &= ~FLAG_GHOST
            eLight[LIGHT_ANGLES][0] = -eLight[LIGHT_ANGLES][0]
            if ( !(eLight[LIGHT_FLAGS] & FLAG_REVERSE) )
                eLight[LIGHT_FLAGS] |= FLAG_ACTIVE
            else
                eLight[LIGHT_FLAGS] |= FLAG_PENDING
            lightSetSize(eLight)
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_LIGHT)
        }
        case MENU_EXIT:
        {
            lightKill(eLight)
            lightRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_LIGHT_GHOST] = 0

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_CREATE)
        }
        default:
        {
            lightKill(eLight)
            lightRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_LIGHT_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuLight(id, iMenu)
{
    new szItem[64], eLight[LIGHT]

    if ( lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_SCALE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_SCALE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_FACTOR", g_iLightFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_COLOR", id, g_szLightColor[g_ePlayerData[id][PDATA_LIGHT_COLOR]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "LIGHT_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerLight(id, menu, item)
{
    new eLight[LIGHT], iItem

    if ( (iItem = lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch ( item )
    {
        case LIGHT_SCALE_UP:
        {
            eLight[LIGHT_DLIGHT_SCALE] = clamp(eLight[LIGHT_DLIGHT_SCALE] + g_iLightFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]], LIGHT_DLIGHT_SCALE_MIN, LIGHT_DLIGHT_SCALE_MAX)
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_LIGHT)
        }
        case LIGHT_SCALE_DOWN:
        {
            eLight[LIGHT_DLIGHT_SCALE] = clamp(eLight[LIGHT_DLIGHT_SCALE] - g_iLightFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]], LIGHT_DLIGHT_SCALE_MIN, LIGHT_DLIGHT_SCALE_MAX)
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_LIGHT)
        }
        case LIGHT_FACTOR:
        {
            if ( ++ g_ePlayerData[id][PDATA_LIGHT_FACTOR] >= sizeof(g_iLightFactor) )
                g_ePlayerData[id][PDATA_LIGHT_FACTOR] = 0

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_LIGHT)
        }
        case LIGHT_COLOR:
        {
            if ( ++ g_ePlayerData[id][PDATA_LIGHT_COLOR] >= sizeof(g_iLightColors) )
                g_ePlayerData[id][PDATA_LIGHT_COLOR] = 0

            eLight[LIGHT_DLIGHT_COLOR][0] = g_iLightColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][0]
            eLight[LIGHT_DLIGHT_COLOR][1] = g_iLightColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][1]
            eLight[LIGHT_DLIGHT_COLOR][2] = g_iLightColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][2]
            set_ent_rendering(eLight[LIGHT_GLOW], kRenderFxNone, eLight[LIGHT_DLIGHT_COLOR][0], eLight[LIGHT_DLIGHT_COLOR][1], eLight[LIGHT_DLIGHT_COLOR][2], kRenderTransAdd, eLight[LIGHT_GLOW_ALPHA])
            ArraySetArray(g_aLight, iItem, eLight)

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_LIGHT)
        }
        case LIGHT_PLACE:
        {
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_LIGHT_GHOST] = 0
            eLight[LIGHT_FLAGS] &= ~FLAG_LOCK
            lightSetState(eLight)
            ArraySetArray(g_aLight, iItem, eLight)

            client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_CREATE_NEW", eLight[LIGHT_NAME])
            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            lightKill(eLight)
            lightRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_LIGHT_GHOST] = 0

            lightSound(id, SOUND_MENU_NAV)
            lightMenu(id, MENU_CREATE)
        }
        default:
        {
            lightKill(eLight)
            lightRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_LIGHT_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public lightTask()
{
    new eLight[LIGHT], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iLight; i ++ )
    {
        ArrayGetArray(g_aLight, i, eLight)
        bModified = false

        if ( eLight[LIGHT_FLAGS] & FLAG_SHOW )
        {
            if ( eLight[LIGHT_FLAGS] & FLAG_ACTIVE )
            {
                lightDraw(eLight)
                if ( !(eLight[LIGHT_FLAGS] & FLAG_LOCK) )
                {
                    lightDistance(eLight, fCurrentTime, eLight[LIGHT_FLAGS] & FLAG_REVERSE ? false : true)
                    bModified = true
                }

                if ( eLight[LIGHT_NEXT_IDLE] > 0.0
                && fCurrentTime >= eLight[LIGHT_NEXT_IDLE] )
                {
                    eLight[LIGHT_NEXT_IDLE] = 0.0
                    lightSetSeq(eLight[LIGHT_ID], eLight[LIGHT_FRAMERATE], LIGHT_SEQ_IDLE)

                    bModified = true
                }

                if ( eLight[LIGHT_NEXT_RANDOM] > 0.0
                && fCurrentTime >= eLight[LIGHT_NEXT_RANDOM] )
                {
                    new iColor = random(sizeof(g_iLightColors))
                    eLight[LIGHT_DLIGHT_COLOR][0] = g_iLightColors[iColor][0]
                    eLight[LIGHT_DLIGHT_COLOR][1] = g_iLightColors[iColor][1]
                    eLight[LIGHT_DLIGHT_COLOR][2] = g_iLightColors[iColor][2]
                    eLight[LIGHT_NEXT_RANDOM] = fCurrentTime + random_float(eLight[LIGHT_COLOR_FREQUENCY][0], eLight[LIGHT_COLOR_FREQUENCY][1])

                    bModified = true
                }

                if ( eLight[LIGHT_NEXT_HIDE] > 0.0
                && fCurrentTime >= eLight[LIGHT_NEXT_HIDE] )
                {
                    eLight[LIGHT_FLAGS] &= ~FLAG_ACTIVE
                    eLight[LIGHT_FLAGS] |= FLAG_PENDING
                    eLight[LIGHT_NEXT_HIDE] = 0.0

                    lightSetState(eLight)
                    bModified = true
                }
            }
            else
            {
                if ( eLight[LIGHT_FLAGS] & FLAG_REVERSE
                && eLight[LIGHT_FLAGS] & FLAG_LOCK )
                    lightDraw(eLight)

                if ( eLight[LIGHT_FLAGS] & FLAG_PENDING
                && !(eLight[LIGHT_FLAGS] & FLAG_LOCK) )
                {
                    lightDistance(eLight, fCurrentTime, eLight[LIGHT_FLAGS] & FLAG_REVERSE ? true : false)
                    bModified = true
                }

                if ( eLight[LIGHT_NEXT_SHOW] > 0.0
                && fCurrentTime >= eLight[LIGHT_NEXT_SHOW] )
                {
                    eLight[LIGHT_FLAGS] |= FLAG_ACTIVE
                    eLight[LIGHT_NEXT_SHOW] = 0.0

                    lightSetState(eLight)
                    eLight[LIGHT_FLAGS] &= ~FLAG_PENDING
                    eLight[LIGHT_NEXT_IDLE] = fCurrentTime + (LIGHT_DEPLOY_DURATION / eLight[LIGHT_FRAMERATE])

                    bModified = true
                }
            }
        }

        if ( bModified )
            ArraySetArray(g_aLight, i, eLight)
    }
}

stock lightCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eLight[LIGHT]
    ArrayGetArray(g_aLightConfig, iItem, eLight)
    eLight[LIGHT_ID] = iEnt
    eLight[LIGHT_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_LIGHT_GHOST] = eLight[LIGHT_ID]
        g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_YAW
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eLight[LIGHT_FLAGS] |= FLAG_GHOST
    }

    lightSelect(eLight, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, LIGHT_KEY)
    set_pev(iEnt, LIGHT_ARRAY_ITEM, g_iLight)

    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    set_pev(iEnt, pev_framerate, eLight[LIGHT_FRAMERATE])

    if ( id )
    {
        eLight[LIGHT_DLIGHT_SCALE] = g_iLightFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]]
        eLight[LIGHT_DLIGHT_COLOR][0] = g_iLightColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][0]
        eLight[LIGHT_DLIGHT_COLOR][1] = g_iLightColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][1]
        eLight[LIGHT_DLIGHT_COLOR][2] = g_iLightColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][2]
        switch ( eLight[LIGHT_SIZE] )
        {
            case SIZE_SMALL:  { engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SMALL]);  eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][0]; }
            case SIZE_MEDIUM: { engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_MEDIUM]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][1]; }
            case SIZE_LARGE:  { engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_LARGE]);  eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][2]; }
        }

        lightCreateGlow(eLight)
    }

    ArrayPushArray(g_aLight, eLight)
    if ( ++ g_iLight == 1 )
        set_task(g_eSettings[SETTING_LIGHT_TASK], "lightTask", LIGHT_KEY, .flags = "b")
}

stock lightCreateGlow(eLight[LIGHT])
{
    new iEnt = cs_create_entity("env_sprite")
    if ( !pev_valid(iEnt) )
        return

    new szCN[32]
    eLight[LIGHT_GLOW] = iEnt
    formatex(szCN, charsmax(szCN), "%s_glow", g_szCN)
    set_pev(iEnt, pev_classname, szCN)
    set_pev(iEnt, pev_framerate, eLight[LIGHT_GLOW_FRAMERATE])
    set_pev(iEnt, pev_spawnflags, SF_SPRITE_STARTON)
    engfunc(EngFunc_SetModel, iEnt, eLight[LIGHT_GLOW_SPRITE])
    dllfunc(DLLFunc_Spawn, iEnt)

    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
    set_pev(iEnt, pev_skin, eLight[LIGHT_ID])
    set_pev(iEnt, pev_body, 1)
    set_pev(iEnt, pev_aiment, eLight[LIGHT_ID])

    set_pev(iEnt, pev_scale, eLight[LIGHT_GLOW_SCALE])
    set_ent_rendering(iEnt, kRenderFxNone, eLight[LIGHT_DLIGHT_COLOR][0], eLight[LIGHT_DLIGHT_COLOR][1], eLight[LIGHT_DLIGHT_COLOR][2], kRenderTransAdd, eLight[LIGHT_GLOW_ALPHA])
}

public lightRemove(iItem)
{
    new eLight[LIGHT]
    ArrayDeleteItem(g_aLight, iItem)

    if ( -- g_iLight == 0 )
        remove_task(LIGHT_KEY)

    for ( new i = iItem; i < g_iLight; i ++ )
    {
        ArrayGetArray(g_aLight, i, eLight)
        set_pev(eLight[LIGHT_ID], LIGHT_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eLight[LIGHT],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_XenLight.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    lightTerminate()
    for ( new i = 0; i < g_iLight; i ++ )
    {
        ArrayGetArray(g_aLight, i, eLight)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eLight[LIGHT_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eLight[LIGHT_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "size = %d^n", eLight[LIGHT_SIZE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "scale = %d^n", eLight[LIGHT_DLIGHT_SCALE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "color = %d %d %d^n",
        eLight[LIGHT_DLIGHT_COLOR][0], eLight[LIGHT_DLIGHT_COLOR][1], eLight[LIGHT_DLIGHT_COLOR][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eLight[LIGHT_ORIGIN][0], eLight[LIGHT_ORIGIN][1], eLight[LIGHT_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eLight[LIGHT_ANGLES][0], eLight[LIGHT_ANGLES][1], eLight[LIGHT_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "LIGHT_CHAT_TAG", id, "LIGHT_CHAT_SAVE", szFile)
    fclose(iFile)

    lightSound(id, SOUND_MENU_NAV)
    lightMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSize, iScale, iColor[3], iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_XenLight.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                loadDataLight(iItem, iFlags, iSize, iScale, iColor, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "size") )
            {
                iSize = str_to_num(szValue)
            }
            else if ( equal(szKey, "scale") )
            {
                iScale = str_to_num(szValue)
            }
            else if ( equal(szKey, "color") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                iColor[0] = str_to_num(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                iColor[1] = str_to_num(szKey)
                iColor[2] = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        loadDataLight(iItem, iFlags, iSize, iScale, iColor, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock loadDataLight(iItem, iFlags, iSize, iScale, iColor[3], Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eLight[LIGHT]
    lightCreate(0, iItem)
    ArrayGetArray(g_aLight, iCount, eLight)

    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eLight[LIGHT_ORIGIN])
    xs_vec_copy(fAngles, eLight[LIGHT_ANGLES])

    eLight[LIGHT_FLAGS] = iFlags
    eLight[LIGHT_SIZE] = iSize
    eLight[LIGHT_DLIGHT_SCALE] = iScale
    eLight[LIGHT_DLIGHT_COLOR][0] = iColor[0]
    eLight[LIGHT_DLIGHT_COLOR][1] = iColor[1]
    eLight[LIGHT_DLIGHT_COLOR][2] = iColor[2]
    switch( eLight[LIGHT_SIZE] )
    {
        case SIZE_SMALL:  { engfunc(EngFunc_SetModel, eLight[LIGHT_ID], g_eSettings[SETTING_MODEL_SMALL]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][0]; }
        case SIZE_MEDIUM: { engfunc(EngFunc_SetModel, eLight[LIGHT_ID], g_eSettings[SETTING_MODEL_MEDIUM]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][1]; }
        case SIZE_LARGE:  { engfunc(EngFunc_SetModel, eLight[LIGHT_ID], g_eSettings[SETTING_MODEL_LARGE]); eLight[LIGHT_GLOW_SCALE] = g_eSettings[SETTING_DEFAULT_GLOW_SCALE][2]; }
    }

    lightCreateGlow(eLight)
    lightSetBox(eLight)
    lightSetSize(eLight)
    lightSetState(eLight)
    ArraySetArray(g_aLight, iCount, eLight)
}

public lightNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    lightSound(id, SOUND_MENU_NAV)
    lightMenu(id, MENU_ROOT)
}

public lightGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    lightSound(id, SOUND_MENU_NAV)
    lightMenu(id, MENU_ROOT)
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eLight[LIGHT], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST]) != -1
    && !(eLight[LIGHT_FLAGS] & FLAG_LOCK) )
    {
        if ( g_ePlayerData[id][PDATA_LIGHT_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            lightTrace(eLight, id)
        }
        else if ( g_ePlayerData[id][PDATA_LIGHT_ACTION] )
        {
            lightCheck(id)
        }
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_LIGHT_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_LIGHT_GHOST] )
    {
        new eLight[LIGHT], iItem
        if ( (iItem = lightGet(eLight, g_ePlayerData[id][PDATA_LIGHT_GHOST])) != -1 )
        {
            lightKill(eLight)
            lightRemove(iItem)
        }

        g_ePlayerData[id][PDATA_LIGHT_GHOST] = 0
    }
}

stock lightTrace(eLight[LIGHT], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eLight[LIGHT_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eLight[LIGHT_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eLight[LIGHT_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eLight[LIGHT_ORIGIN])

    lightSetBox(eLight)
    lightSetOffset(eLight)
    set_pev(eLight[LIGHT_ID], pev_origin, eLight[LIGHT_ORIGIN])
}

stock lightCheck(id)
{
    new eLight[LIGHT], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_LIGHT_CHECK]
    for ( new i = 0; i < g_iLight; i ++ )
    {
        ArrayGetArray(g_aLight, i, eLight)
        xs_vec_sub(eLight[LIGHT_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eLight[LIGHT_ID], pev_absmin, fMins)
        pev(eLight[LIGHT_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_LIGHT_MENU] != iBest )
    {
        ArrayGetArray(g_aLight, g_ePlayerData[id][PDATA_LIGHT_MENU], eLight)
        lightSelect(eLight, eLight[LIGHT_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_LIGHT_MENU] = iBest
        lightMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock lightDraw(eLight[LIGHT])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, eLight[LIGHT_ORIGIN_GLOW])
    write_byte(TE_DLIGHT)
    write_coord_f(eLight[LIGHT_ORIGIN_GLOW][0])
    write_coord_f(eLight[LIGHT_ORIGIN_GLOW][1])
    write_coord_f(eLight[LIGHT_ORIGIN_GLOW][2])
    write_byte(eLight[LIGHT_DLIGHT_SCALE])
    write_byte(eLight[LIGHT_DLIGHT_COLOR][0])
    write_byte(eLight[LIGHT_DLIGHT_COLOR][1])
    write_byte(eLight[LIGHT_DLIGHT_COLOR][2])
    write_byte(g_eSettings[SETTING_LIGHT_LIFE])
    write_byte(0)
    message_end()
}

stock lightDistance(eLight[LIGHT], Float:fCurrentTime, bool:bSetState)
{
    new Float:fOrigin[3], id
    for ( id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id)
        || ( !(eLight[LIGHT_FLAGS] & FLAG_REVERSE) && CsTeams:eLight[LIGHT_TEAM] & cs_get_user_team(id))
        || ( eLight[LIGHT_FLAGS] & FLAG_REVERSE && !(CsTeams:eLight[LIGHT_TEAM] & cs_get_user_team(id))) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eLight[LIGHT_ORIGIN]) > eLight[LIGHT_TRIGGER_DISTANCE] )
            continue

        if ( eLight[LIGHT_FLAGS] & FLAG_REVERSE )
        {
            eLight[LIGHT_FLAGS] |= FLAG_ACTIVE
            eLight[LIGHT_NEXT_HIDE] = fCurrentTime + random_float(eLight[LIGHT_TRIGGER_DURATION][0], eLight[LIGHT_TRIGGER_DURATION][1])
        }
        else
        {
            eLight[LIGHT_FLAGS] &= ~FLAG_ACTIVE
            eLight[LIGHT_NEXT_SHOW] = fCurrentTime + random_float(eLight[LIGHT_TRIGGER_DURATION][0], eLight[LIGHT_TRIGGER_DURATION][1])
        }

        if ( bSetState )
        {
            lightSetState(eLight)

            if ( eLight[LIGHT_FLAGS] & FLAG_REVERSE )
                eLight[LIGHT_NEXT_IDLE] = fCurrentTime + (LIGHT_DEPLOY_DURATION / eLight[LIGHT_FRAMERATE])
        }

        if ( eLight[LIGHT_FLAGS] & FLAG_REVERSE ) eLight[LIGHT_FLAGS] &= ~FLAG_PENDING
        else                                      eLight[LIGHT_FLAGS] |= FLAG_PENDING
        break
    }
}

stock lightSetBox(eLight[LIGHT])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eLight[LIGHT_ANGLES][0] = -eLight[LIGHT_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eLight[LIGHT_ANGLES], fForward, fRight, fUp)
    switch( eLight[LIGHT_SIZE] )
    {
        case SIZE_SMALL:    { xs_vec_copy(g_eSettings[SETTING_MINS_SMALL], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_SMALL], fMaxs); }
        case SIZE_MEDIUM:   { xs_vec_copy(g_eSettings[SETTING_MINS_MEDIUM], fMins); xs_vec_copy(g_eSettings[SETTING_MAXS_MEDIUM], fMaxs); }
        case SIZE_LARGE:    { xs_vec_copy(g_eSettings[SETTING_MINS_LARGE], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_LARGE], fMaxs); }
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eLight[LIGHT_MINS])
    xs_vec_copy(fMaxs, eLight[LIGHT_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] + fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] + fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] + fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock lightSetOffset(eLight[LIGHT])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eLight[LIGHT_MINS][0]
    fGaps[1] = eLight[LIGHT_MAXS][0]
    fGaps[2] = -eLight[LIGHT_MINS][1]
    fGaps[3] = eLight[LIGHT_MAXS][1]
    fGaps[4] = -eLight[LIGHT_MINS][2]
    fGaps[5] = eLight[LIGHT_MAXS][2]

    if ( eLight[LIGHT_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eLight[LIGHT_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eLight[LIGHT_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eLight[LIGHT_ID], 0)
        get_tr2(0, TR_vecEndPos, eLight[LIGHT_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eLight[LIGHT_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eLight[LIGHT_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eLight[LIGHT_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eLight[LIGHT_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eLight[LIGHT_ORIGIN], fVec1, eLight[LIGHT_ORIGIN])
        }
    }
}

stock lightSetSeq(iEnt, Float:fFrameRate, iSequence)
{
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFrameRate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock lightSetSize(eLight[LIGHT])
{
    lightSelect(eLight, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eLight[LIGHT_ID], eLight[LIGHT_ORIGIN])
    set_pev(eLight[LIGHT_ID], pev_angles, eLight[LIGHT_ANGLES])
    set_pev(eLight[LIGHT_ID], pev_solid, eLight[LIGHT_FLAGS] & (FLAG_SOLID | FLAG_SHOW) == (FLAG_SOLID | FLAG_SHOW) ? SOLID_BBOX : SOLID_NOT)
    set_pev(eLight[LIGHT_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eLight[LIGHT_ID], eLight[LIGHT_MINS], eLight[LIGHT_MAXS])
    engfunc(EngFunc_GetAttachment, eLight[LIGHT_ID], 0, eLight[LIGHT_ORIGIN_GLOW], NULL_VECTOR)
    engfunc(EngFunc_SetOrigin, eLight[LIGHT_GLOW], eLight[LIGHT_ORIGIN_GLOW])
}

stock lightSetState(eLight[LIGHT])
{
    if ( eLight[LIGHT_FLAGS] & FLAG_COLOR_RANDOM )
        eLight[LIGHT_NEXT_RANDOM] = get_gametime() + random_float(eLight[LIGHT_COLOR_FREQUENCY][0], eLight[LIGHT_COLOR_FREQUENCY][1])

    if ( eLight[LIGHT_FLAGS] & FLAG_SHOW )
    {
        set_pev(eLight[LIGHT_ID], pev_solid, eLight[LIGHT_FLAGS] & FLAG_SOLID ? SOLID_BBOX : SOLID_NOT)

        lightSelect(eLight, TARGET_CLEAR)
        if ( eLight[LIGHT_FLAGS] & FLAG_ACTIVE )
        {
            lightSetSeq(eLight[LIGHT_ID], eLight[LIGHT_FRAMERATE], eLight[LIGHT_FLAGS] & FLAG_PENDING ? LIGHT_SEQ_DEPLOY : LIGHT_SEQ_IDLE)
            set_ent_rendering(eLight[LIGHT_GLOW], kRenderFxNone, eLight[LIGHT_DLIGHT_COLOR][0], eLight[LIGHT_DLIGHT_COLOR][1], eLight[LIGHT_DLIGHT_COLOR][2], kRenderTransAdd, eLight[LIGHT_GLOW_ALPHA])
        }
        else
        {
            lightSetSeq(eLight[LIGHT_ID], eLight[LIGHT_FRAMERATE], LIGHT_SEQ_RETRACT)
            set_ent_rendering(eLight[LIGHT_GLOW], kRenderFxNone, eLight[LIGHT_DLIGHT_COLOR][0], eLight[LIGHT_DLIGHT_COLOR][1], eLight[LIGHT_DLIGHT_COLOR][2], kRenderTransAdd, 0)
        }
    }
    else
    {
        set_pev(eLight[LIGHT_ID], pev_solid, SOLID_NOT)
        set_ent_rendering(eLight[LIGHT_GLOW], kRenderFxNone, eLight[LIGHT_DLIGHT_COLOR][0], eLight[LIGHT_DLIGHT_COLOR][1], eLight[LIGHT_DLIGHT_COLOR][2], kRenderTransAdd, 0)

        lightSelect(eLight, TARGET_HIDE)
        lightSetSeq(eLight[LIGHT_ID], eLight[LIGHT_FRAMERATE], LIGHT_SEQ_RETRACT)
    }
}

stock lightSelect(eLight[LIGHT], iAction)
{
    new iRender, iRenderFx, iRenderColor[3], iRenderAmt

    iRenderFx = kRenderFxNone
    if ( iAction == TARGET_SELECT )
    {
        if ( eLight[LIGHT_FLAGS] & FLAG_ACTIVE )    { iRenderColor[0] = g_iColorActive[0];      iRenderColor[1] = g_iColorActive[1];     iRenderColor[2] = g_iColorActive[2]; }
        else                                        { iRenderColor[0] = g_iColorInactive[0];    iRenderColor[1] = g_iColorInactive[1];   iRenderColor[2] = g_iColorInactive[2]; }

        iRender = kRenderTransColor
        iRenderFx = kRenderFxGlowShell
        iRenderAmt = 16
    }
    else if ( iAction == TARGET_GHOST )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = g_eSettings[SETTING_GHOST_ALPHA]
    }
    else if ( iAction == TARGET_HIDE )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = 0
    }
    else if ( iAction == TARGET_CLEAR )
    {
        iRender = kRenderNormal
        iRenderAmt = 255
    }

    set_ent_rendering(eLight[LIGHT_ID], iRenderFx, iRenderColor[0], iRenderColor[1], iRenderColor[2], iRender, iRenderAmt)
}

stock lightReset()
{
    new eLight[LIGHT]
    for ( new i = 0; i < g_iLight; i ++ )
    {
        ArrayGetArray(g_aLight, i, eLight)
        eLight[LIGHT_NEXT_HIDE] = 0.0
        eLight[LIGHT_NEXT_SHOW] = 0.0
        eLight[LIGHT_NEXT_IDLE] = 0.0
        eLight[LIGHT_NEXT_RANDOM] = 0.0
        ArraySetArray(g_aLight, i, eLight)
    }
}

stock lightSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock lightGet(eLight[LIGHT], iEnt)
{
    new iItem
    iItem = pev(iEnt, LIGHT_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iLight )
        return -1

    ArrayGetArray(g_aLight, iItem, eLight)
    return iItem
}

stock bool:isLight(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == LIGHT_KEY
}

stock lightKill(eLight[LIGHT])
{
    if ( pev_valid(eLight[LIGHT_ID]) )
        set_pev(eLight[LIGHT_ID], pev_flags, pev(eLight[LIGHT_ID], pev_flags) | FL_KILLME)

    if ( pev_valid(eLight[LIGHT_GLOW]) )
        set_pev(eLight[LIGHT_GLOW], pev_flags, pev(eLight[LIGHT_GLOW], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_LIGHT_ACTION] )
    {
        new eLight[LIGHT]
        for ( new i = 0; i < g_iLight; i ++ )
        {
            ArrayGetArray(g_aLight, i, eLight)
            if ( eLight[LIGHT_FLAGS] & FLAG_SHOW )
                continue

            lightSelect(eLight, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_LIGHT_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_LIGHT_ACTION] )
    {
        new eLight[LIGHT]
        for ( new i = 0; i < g_iLight; i ++ )
        {
            ArrayGetArray(g_aLight, i, eLight)
            if ( eLight[LIGHT_FLAGS] & FLAG_SHOW )
                continue

            lightSelect(eLight, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_LIGHT_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}


