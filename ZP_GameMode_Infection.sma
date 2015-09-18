/*
* This is an Example mode to test the new game mode
* selection system implemented in the main game mode module.
*/

#include <amxmodx>
#include <fakemeta>
#include <cvar_util>
#include <ZP_GameModeModule>

new const Plugin [] = "ZP Infection Mode";
new const Version[] = "0.0.1";
new const Author [] = "WiLs & Tirant & @bdul!";

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

// CS Teams
enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}
new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

new Float:g_teamMsgTargetTime
new g_hudSync
new g_msgTeamInfo
new g_pCvar

public plugin_init()
{
	register_plugin(Plugin, Version, Author)
	
	// Create the HUD Sync Objects
	g_hudSync = CreateHudSyncObj()
	
	// Messages
	g_msgTeamInfo = get_user_msgid("TeamInfo")
	
	g_pCvar = CvarRegister("zp_gamemode_delay", "2", "The minimum players required to start Example Mode", FCVAR_SERVER, .hasMin = true, .minValue = 0.0);
	
	// register game mode
	zp_register_game_mode("Example Mode")
}

public zp_game_mode_starting()
{
	// Get alive players count
	static players[32], playerCount;
	get_players(players, playerCount, "a");
	
	// Not enough players to start the game mode 
	if (playerCount < get_pcvar_num(g_pCvar))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_game_mode_started(target_player)
{
	// Infect him!
	zp_infect_user(target_player)
	
	// This is just to make our example mode different from infection mode (I couldnt think of a better way :D)
	set_pev(target_player, pev_effects, pev(target_player, pev_effects) | EF_BRIGHTLIGHT)
	
	// Remaining players should be humans (CTs)
	new id, maxplayers = get_maxplayers()
	for (id = 1; id <= maxplayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our first zombie
		if (is_user_zombie(id))
			continue;
		
		// Switch to CT
		fm_cs_set_user_team(id, FM_CS_TEAM_CT, 1)
	}
	
	// Show First Zombie HUD notice
	new zombie_name[32]
	get_user_name(target_player, zombie_name, charsmax(zombie_name))
	set_hudmessage(255, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_hudSync, "Example Mode, Player ^"%s^" Is Infected!", zombie_name)
}

public zp_infect_post(id)
{
	// zombies are switched to Terrorist team
	fm_cs_set_user_team(id, FM_CS_TEAM_T, 1)
}

// Set a Player's Team
stock fm_cs_set_user_team(id, team, send_message)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG)
	
	// Already belongs to the team
	if (fm_cs_get_user_team(id) == team)
		return;
	
	set_pdata_int(id, OFFSET_CSTEAMS, team)
	
	// Send message to update team?
	if (send_message) fm_user_team_update(id)
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_msgTeamInfo)
	ewrite_byte(ID_TEAMMSG) // player
	ewrite_string(CS_TEAM_NAMES[fm_cs_get_user_team(ID_TEAMMSG)]) // team
	emessage_end()
}

// Update Player's Team on all clients (adding needed delays)
stock fm_user_team_update(id)
{	
	new Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_teamMsgTargetTime >= 0.1)
	{
		set_task(0.1, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_teamMsgTargetTime = current_time + 0.1
	}
	else
	{
		set_task((g_teamMsgTargetTime + 0.1) - current_time, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_teamMsgTargetTime = g_teamMsgTargetTime + 0.1
	}
}

// Get User Team
stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return FM_CS_TEAM_UNASSIGNED;
	
	return get_pdata_int(id, OFFSET_CSTEAMS);
}