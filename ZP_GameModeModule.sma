#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cvar_util>
#include <cs_ham_bots_api>
#include <ZP_Core>

new const Plugin [] = "ZP Game Mode Manager";
new const Version[] = "0.0.1";
new const Author [] = "WiLs";

enum (+= 1000) {
	TASK_GAMEMODE = 966243, //Zombie on a keypad ;)
	TASK_TEAMMSG
};

#define INVALID_GAME_MODE -1
#define PLAYER_RANDOM 0

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

// CS Teams
enum {
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
};

new const CS_TEAM_NAMES[][] = {
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

enum _:eCvars {
	CVAR_GameModeDelay
};

enum _:CvarModes {
	Pointer,
	Value
};

new g_pCvars[CvarModes][eCvars];

new g_iMaxPlayers;
new Float:g_teamMsgTargetTime;
new g_hudSync;
new g_msgTeamInfo;

enum _:eForwards {
	fwDummy = 0,
	fwGameModeStarting,
	fwGameModeStarted,
	fwGameModeEnded
};
new g_Forwards[eForwards];

enum _:eModeInfo {
	PluginID,
	Name[32],
	File[32]
};

enum _:eDefaultModes {
	MODE_INFECTION = 0
};

new Array:g_aGameModes;
new Trie:g_tModeNames;
new g_gameModeCount

public g_currentGameMode = INVALID_GAME_MODE;

public plugin_precache() {
	g_aGameModes = ArrayCreate(eModeInfo);
	g_tModeNames = TrieCreate();
  
	// Register Infection Mode as default mode
	static newGameMode[eModeInfo];
	copy(newGameMode[Name], 31, "Infection Mode")
	
	// Set these to invalid parameters, since we dont want to pause our own plugin
	newGameMode[PluginID] = -1
	newGameMode[File] = 0
	
	ArrayPushArray(g_aGameModes, newGameMode);
	TrieSetCell(g_tModeNames, newGameMode[Name], g_gameModeCount);
	
	g_gameModeCount++;
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0");
	//register_event("TextMsg", 	"logevent_round_end", "a", "2=#Game_will_restart_in");
	
	register_logevent("logevent_round_end", 2, "1=Round_End");
	
	// ham take damage forward
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage");
	
	g_iMaxPlayers = get_maxplayers();
	g_hudSync = CreateHudSyncObj();
	
	g_msgTeamInfo = get_user_msgid("TeamInfo");
	
	g_pCvars[Pointer][CVAR_GameModeDelay] = CvarRegister("zp_gamemode_delay", "10", "The delay before choosing a game mode", FCVAR_SERVER, .hasMin = true, .minValue = 0.0);
	CvarHookChangeCache(g_pCvars[Pointer][CVAR_GameModeDelay], CvarType_Int, g_pCvars[Value][CVAR_GameModeDelay]);
	
	g_Forwards[fwGameModeStarting	] = CreateMultiForward("zp_game_mode_starting", ET_CONTINUE);
	g_Forwards[fwGameModeStarted	] = CreateMultiForward("zp_game_mode_started", ET_IGNORE, FP_CELL);
	g_Forwards[fwGameModeEnded	] = CreateMultiForward("zp_game_mode_ended", ET_IGNORE);
}

public plugin_cfg()
{
	// Call first round start event manually
	set_task(0.5, "ev_RoundStart")
}

public plugin_natives() {
	register_native("zp_register_game_mode", "_register_gamemode", 0)
}

public _register_gamemode(iPlugin, iParams) {
	if (iParams != 1) {
		return -1;
	}
	
	static newGameMode[eModeInfo], i;
	get_string(1, newGameMode[Name], 31);
	if (TrieGetCell(g_tModeNames, newGameMode[Name], i)) {
		zp_core_log_error("Game mode already registered (%s)", newGameMode[Name]);
		return i;
	}

	newGameMode[PluginID] = iPlugin;
	get_plugin(iPlugin, newGameMode[File], 31);
	
	ArrayPushArray(g_aGameModes, newGameMode);
	TrieSetCell(g_tModeNames, newGameMode[Name], g_gameModeCount);

	pause("ac", newGameMode[File]);
	
	g_gameModeCount++;
	return g_gameModeCount-1;
}

public logevent_round_end() {
	ExecuteForward(g_Forwards[fwGameModeEnded], g_Forwards[fwDummy])
  
	if (g_currentGameMode > MODE_INFECTION) {
		static gameMode[eModeInfo];
		ArrayGetArray(g_aGameModes, g_currentGameMode, gameMode);
		pause("ac", gameMode[File]);
	}
	
	g_currentGameMode = INVALID_GAME_MODE;
  
	// Stop old tasks
	remove_task(TASK_GAMEMODE);
	
	// Determine round winner, show HUD notice
	set_hudmessage(0, 0, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1);
	if (!fnGetZombies()) {
		ShowSyncHudMsg(0, g_hudSync, "Humans win!");
	} else if (!fnGetHumans()) {
		ShowSyncHudMsg(0, g_hudSync, "Zombies win!");
	} else {
		ShowSyncHudMsg(0, g_hudSync, "No one wins...");
	}
	
	// Balance the teams
	balance_teams();
}

public ev_RoundStart() {
	remove_task(TASK_GAMEMODE);
	set_task(float(g_pCvars[Value][CVAR_GameModeDelay]), "start_game_mode_task", TASK_GAMEMODE);
}

public start_game_mode_task()
{
	// Get alive players count
	static players[32], playerCount;
	get_players(players, playerCount, "a");
	
	// Not enough players, come back later!
	if (playerCount < 1) {
		set_task(2.0, "start_game_mode_task", TASK_GAMEMODE);
		return;
	}
	
	// No custom game modes registered, start infection mode instead
	if (g_gameModeCount == 1) {
		start_game_mode(MODE_INFECTION, players[random(playerCount)])
		return;
	}
	
	// Loop through every custom game mode present
	// This is to ensure that every game mode is given a chance
	static gameMode, gameModeData[eModeInfo]
	for (gameMode = 1; gameMode < g_gameModeCount; gameMode++)
	{
		// Retrieve the game mode's data
		ArrayGetArray(g_aGameModes, gameMode, gameModeData)
		
		// Unpause it
		unpause("ac", gameModeData[File]);
		
		// Inform the game mode about its turn, this is where it will decide to run itself or block itself
		ExecuteForward(g_Forwards[fwGameModeStarting], g_Forwards[fwDummy])
		
		// Useful Debug!
		client_print(0, print_chat, "[ZP debug info] Return Value: %d", g_Forwards[fwDummy])
		
		// The game mode doesnt want to run itself
		if (g_Forwards[fwDummy] >= PLUGIN_HANDLED)
		{
			// Pause this one and give other game modes a chance
			pause("ac", gameModeData[File])
			
			// Debug!
			client_print(0, print_chat, "[ZP debug info] Game Mode %d refused to start!", gameMode)
			continue;
		}
		else
		{
			// Otherwise start the game mode
			start_game_mode(gameMode, players[random(playerCount)])
			return;
		}
	}
	
	// No game mode started ? Start the default infection mode
	start_game_mode(MODE_INFECTION, players[random(playerCount)])
}

public start_game_mode(game_mode, target_player) {
	// Choose player randomly?
	if (target_player == PLAYER_RANDOM) {
		// Get alive players count
		static players[32], playerCount;
		get_players(players, playerCount, "a");
		
		target_player = players[random(playerCount)];
	}
	
	// testing only...
	client_print(0, print_chat, "[ZP debug info] game mode %d started", game_mode);
	
	// set current game mode
	g_currentGameMode = game_mode;
	
	// Check if its the default infection mode
	if (game_mode == MODE_INFECTION) {
		// Turn player into the first zombie
		zp_core_infect_user(target_player)
		
		// Remaining players should be humans (CTs)
		static id;
		
		for (id = 1; id <= g_iMaxPlayers; id++) {
			// Not alive
			if (!is_user_alive(id))
				continue;
			
			// This is our first zombie
			if (target_player == id)
				continue;
			
			// Switch to CT
			fm_cs_set_user_team(id, FM_CS_TEAM_CT, 1)
		}
		
		// Show First Zombie HUD notice
		new zombie_name[32]
		get_user_name(target_player, zombie_name, charsmax(zombie_name))
		
		set_hudmessage(255, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_hudSync, "%s is the first zombie!", zombie_name)
	} else {
		// Execute game mode started forward
		ExecuteForward(g_Forwards[fwGameModeStarted], g_Forwards[fwDummy], target_player);
	}
}

// Zombies are switched to Terrorist team
public zp_infect_post(id) {
	if (g_currentGameMode == MODE_INFECTION)
		fm_cs_set_user_team(id, FM_CS_TEAM_T, 1)
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	// Non-player damage or self damage
	if (!is_user_connected(attacker) || victim == attacker) {
		return HAM_IGNORED;
	}
	
	// Retrieve victim and attacker's zombie status
	static isZombieAttacker, isZombieVictim
	isZombieAttacker = is_user_zombie(attacker)
	isZombieVictim = is_user_zombie(victim)
	
	// Prevent friendly fire
	if (isZombieAttacker == isZombieVictim) {
		return HAM_SUPERCEDE;
	}
	
	// Not infection mode ? Nothing to do here
	if (g_currentGameMode != MODE_INFECTION) {
		return HAM_IGNORED;
	}
	
	// Zombie attacking human...
	if (isZombieAttacker && !isZombieVictim)
	{
		// Last human is killed
		if (fnGetHumans() == 1)
			return HAM_IGNORED;
		
		// Infect victim!
		zp_core_infect_user(victim)
		// testing only...
		client_print(0, print_chat, "[ZP debug info] player %d infected %d", attacker, victim)
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

// Balance Teams
balance_teams() {
	// Get amount of users playing
	new players_count = fnGetPlaying();
	
	// No players, don't bother
	if (players_count < 1) {
		return;
	}
	
	// Split players evenly
	static players[32], playerCount, player, iTerrors, i, team;
	static iMaxTerrors; iMaxTerrors = players_count / 2;
	get_players(players, playerCount);
	
	// First, set everyone to CT
	for (i = 0; i < playerCount; i++) {
		player = players[i];
		team = fm_cs_get_user_team(player);
		
		// Skip if not playing
		if (team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED) {
			continue;
		}
		
		// Set team
		fm_cs_set_user_team(player, FM_CS_TEAM_CT, 0);
	}
	
	// Then randomly move half of the players to Terrorists
	i = 0;
	do {
		player = players[i];
		team = fm_cs_get_user_team(player);
		
		// Skip if not playing or already a Terrorist
		if (team != FM_CS_TEAM_CT) {
			continue;
		}
		
		// Player id is odd
		if (i % 2) {
			fm_cs_set_user_team(player, FM_CS_TEAM_T, 0);
			iTerrors++;
		}
	} while (iTerrors < iMaxTerrors && i < playerCount);
}

// Get Alive -returns alive players number-
/*fnGetAlive()
{
	static players[32], num
	get_players(players, num, "a");
	return num;
}*/

// Get Random Alive -returns index of alive player number target_index -
/*fnGetRandomAlive(target_index)
{
	new iAlive, id
	new maxplayers = get_maxplayers()
	
	for (id = 1; id <= maxplayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}*/

// Get Playing -returns number of users playing-
fnGetPlaying() {
	static players[32], playerCount, iPlaying, team;
	get_players(players, playerCount);
	for (new i; i < playerCount; i++) {
		team = fm_cs_get_user_team(players[i]);
		
		switch (team) {
			case FM_CS_TEAM_UNASSIGNED:	iPlaying++;
			case FM_CS_TEAM_SPECTATOR:	iPlaying++;
		}
	}
	
	return iPlaying;
}

// Get Zombies -returns alive zombies number-
fnGetZombies() {
	static players[32], playerCount, zombieCount;
	get_players(players, playerCount, "a");
	
	for (new i; i < playerCount; i++) {
		if (is_user_zombie(players[i])) {
			zombieCount++;
		}
	}
	
	return zombieCount;
}

// Get Humans -returns alive humans number-
fnGetHumans() {
	static players[32], playerCount, humanCount;
	get_players(players, playerCount, "a");
	
	for (new i; i < playerCount; i++) {
		if (!is_user_zombie(players[i])) {
			humanCount++;
		}
	}
	
	return humanCount;
}

// Set a Player's Team
stock fm_cs_set_user_team(id, team, send_message) {
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE) {
		return;
	}
	
	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG);
	
	// Already belongs to the team
	if (fm_cs_get_user_team(id) == team) {
		return;
	}
	
	set_pdata_int(id, OFFSET_CSTEAMS, team);
	
	// Send message to update team?
	if (send_message) {
		fm_user_team_update(id)
	}
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid) {
	taskid -= TASK_TEAMMSG;
	
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_msgTeamInfo);
	ewrite_byte(taskid); // player
	ewrite_string(CS_TEAM_NAMES[fm_cs_get_user_team(taskid)]); // team
	emessage_end();
}

// Update Player's Team on all clients (adding needed delays)
stock fm_user_team_update(id) {	
	new Float:current_time;
	current_time = get_gametime();
	
	if (current_time - g_teamMsgTargetTime >= 0.1) {
		set_task(0.1, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG);
		g_teamMsgTargetTime = current_time + 0.1;
	} else {
		set_task((g_teamMsgTargetTime + 0.1) - current_time, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG);
		g_teamMsgTargetTime = g_teamMsgTargetTime + 0.1;
	}
}

// Get User Team
stock fm_cs_get_user_team(id) {
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE) {
		return FM_CS_TEAM_UNASSIGNED;
	}
	
	return get_pdata_int(id, OFFSET_CSTEAMS);
}
