#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cs_player_models_api>
#include <cs_maxspeed_api>
#include <cs_ham_bots_api>
#include <cs_weap_restrict_api>
#include <cvar_util>
#include <flags32>

#include <ZP_Core_Const>
#include <ZP_Core_Stocks>
#include <ZP_VarManager>
#include <ZP_Log>

static const Plugin [] = "ZP Base/Engine";
static const Version[] = "0.0.1";
static const Author [] = "ZP Development Team";

/**
 * Defined constants used to get, set, and unset specific player
 * flags. These flags are located in {@link ePlayerFlags}.
 */
#define flag_get_boolean(%1,%2)	(!!flag_get(%1,%2))
#define flag_get(%1,%2)		(g_playerFlags[%1] &   (1 << (%2 & 31)))
#define flag_set(%1,%2)		(g_playerFlags[%1] |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)	(g_playerFlags[%1] &= ~(1 << (%2 & 31)))

/**
 * Defined constants used to ease the process of checking bits.  These
 * are more specifically used when checking {@link g_pCvars[Value][CVAR_AllowedWeapons]}
 * and making sure that the knife is always included in this bitsum.
 */
#define SetBit(%1,%2)		(%1 |=  (1<<%2))
#define UnsetBit(%1,%2)		(%1 &= ~(1<<%2))
#define GetBit(%1,%2)		(%1 &   (1<<%2))

/**
 * Defined constant determining the default weapons allowed to a
 * zombie.
 */
#define DEFAULT_WEAPONS_BITSUM (1<<CSW_KNIFE)

/**
 * This field represents the maximum amount of playersr that
 * a server running this modification is allowed.  This field
 * is then used to cache this value in order to improve
 * processing time where such a constant is needed.
 */
static g_iMaxPlayers;

/**
 * Enumerated constants representing the various forwards this
 * plugin executes.
 */
enum eForwardedEvents {
	fwDummy = 0,
	fwUserInfectPre,
	fwUserInfect,
	fwUserInfectPost,
	fwUserCurePre,
	fwUserCure,
	fwUserCurePost,
	fwPlayerSpawn,
	fwPlayerDeath,
	fwTeamChangeBlock,
	fwRegisterModel
};

/**
 * An array of fields containing values for all enumerated constants
 * located in {@link eForwardedEvents}.  These values are assigned
 * forward pointers and executed addordingly.
 */
static g_Forwards[eForwardedEvents];

/**
 * Enumerated constants representing the various flags needed in
 * order to properly track a player with this modification.
 */
enum _:ePlayerFlags {
	g_bIsConnected,
	g_bIsAlive,
	g_bIsZombie
};

/**
 * An array of fields containing values for all enumerated constants
 * located in {@link ePlayerFlags}. These values are used to replace
 * MAXPLAYER-sized arrays for each individual flag, with a single
 * cell of bits.  These values should only be changed using the defined
 * preprocessor commands {@link flag_get(%1,%2)}, {@link flag_set(%1,%2)},
 * and {@link flag_unset(%1,%2)}
 */
static g_playerFlags[ePlayerFlags];

/**
 * Enumerated constants representing the two team types in this
 * modification. These constants are also used when accessing
 * array indeces in which their corresponding data is located.
 */
enum _:ZP_TEAMS {
	ZP_HUMAN = 0,
	ZP_ZOMBIE
};

/**
 * Constant fields representing the default values of which to
 * assign a member of a team who has no class set.
 */
static const g_baseAttributes[ZP_TEAMS][eZP_FL_BaseInfo] = {
	//Health	Speed		Gravity		//ModelID
	{ 100.0,	1.0,		1.0,		-1 },	// Human
	{ 1800.0,	0.9,		1.0,		-1 }	// Zombie
};

/**
 * An array of fields containing immediate information on the
 * details of a players class. In the event when no classes
 * loaded, default values will be assigned to the corresponding
 * indeces located at {@link g_baseAttributes} and
 * {@link g_baseModel}. This information is loaded when the player
 * is targetted through {@link _refreshPlayer(id)}.
 */
static g_playerInfo[MAXPLAYERS+1][eZP_FL_BaseInfo];

/**
 * Constant fields representing the default models of which to
 * assign a member of a team who has no class set. Since logically
 * a human may not have a standard set model, setting this field
 * to {@code ""} will enable all random standard CS player models
 * to survivors.
 */
static const g_baseModel[ZP_TEAMS][] = {
	"",
	"classic"
};

/**
 * Array: field storing all model names for both teams.  Each model
 * is registered by separate plugins. If no models are registered,
 * then the corresponding model located at {@link g_baseModel} is
 * applied.  In the event where a model has no name, then the model
 * is reset to a default CS1.6 player model.
 */
static Array:g_aModels[ZP_TEAMS];

/**
 * Trie: field containing a list of all models registered.  This is
 * used because tries can query and return a result much faster than
 * looping through an entire array.  The purpose of this trie is to
 * check if a model has already been registered, and if it has, then
 * to return the index of that model, because there is no point in
 * registering the same model twice.
 */
static Trie:g_tModels[ZP_TEAMS];

/**
 * This field contains an array of integers containing the number of
 * models on each team.  This is used to help track the total number
 * of models registered.
 */
static g_modelCount[ZP_TEAMS];

/**
 * Enumerated constants copied from the cstrike module representing
 * all teams a player can be on.
 */
enum CsTeams {
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
};

/**
 * Constant strings storing the names of all teams a player can be
 * on in cstrike.
 */
static const szTeamNames[CsTeams][] = {
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

/**
 * Enumerated constants representing all the cvars to be used by
 * this mod.
 */
enum eCvars {
	CVAR_AllowedWeapons = 0,
	CVAR_ModelMode
};

/**
 * Enumerated constants representing the two types of data we want
 * to store in a cvar.  The pointer for the cvar, and the actual
 * value.
 */
enum _:CvarModes {
	Pointer,
	Value
};

/**
 * An array of cvars used to help simplify finding and naming them.
 */
static g_pCvars[CvarModes][eCvars];

/**
 * Constant array containing a list of all CSW_* constants represented
 * by their weapon entity names.  The purpose of this is to speed up
 * and weapon entity processing that needs to be done.
 */
static const g_szWpnEntNames[][] = {
	"", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90"
};

public plugin_precache() {
	for (new i; i < ZP_TEAMS; i++) {
		if (g_baseModel[i][0] != '^0') {
			if (!zp_core_precache_player_model(g_baseModel[i])) {
				new szTemp[64];
				formatex(szTemp, 63, "Error locating essential file to run engine (^"%s^")", g_baseModel[i]);
				set_fail_state(szTemp);
			}
		}
		
		g_aModels[i] = ArrayCreate(32);
		g_tModels[i] = TrieCreate();
	}
	
	g_Forwards[fwRegisterModel] = CreateMultiForward("zp_fw_core_register_model", ET_IGNORE);
	ExecuteForward(g_Forwards[fwRegisterModel], g_Forwards[fwDummy]);
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	CvarRegister("zp_version", Version, "The current version of Zombie Plague being used", FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("zp_version", Version);
	
	register_clcmd("chooseteam", "blockTeamChange");
	register_clcmd("jointeam", "blockTeamChange");
	
	RegisterHam(Ham_Spawn, 		"player", "ham_PlayerSpawn_Post", 	1);
	RegisterHamBots(Ham_Spawn,	"ham_PlayerSpawn_Post", 		1);
	RegisterHam(Ham_Killed, 	"player", "ham_PlayerKilled", 		0);
	RegisterHamBots(Ham_Killed, 	"ham_PlayerKilled", 			0);

	new szTemp[33];
	get_flags32(DEFAULT_WEAPONS_BITSUM, szTemp, 32);
	g_pCvars[Pointer][CVAR_AllowedWeapons] = CvarRegister("zp_core_allowedzombieweapons", szTemp, "Controls the weapons zombies are allowed to use", FCVAR_SERVER);
	CvarHookChange(g_pCvars[Pointer][CVAR_AllowedWeapons], "hookBitsumChange");
	
	g_pCvars[Pointer][CVAR_ModelMode     ] = CvarRegister("zp_core_obeyassignedmodels", "1", "Controls how models are set using this plugin", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0);
	CvarCache(g_pCvars[Pointer][CVAR_ModelMode], CvarType_Int, g_pCvars[Value][CVAR_ModelMode]);
	
	
	g_iMaxPlayers = get_maxplayers();
	
	/* Infection Forwards	*/
	/// Executed before a player is infected. Can be stopped.
	g_Forwards[fwUserInfectPre	] = CreateMultiForward("zp_fw_core_infect_pre", ET_STOP, FP_CELL);
	/// Executed before a player is infected. Can't be stopped.
	g_Forwards[fwUserInfect		] = CreateMultiForward("zp_fw_core_infect", ET_IGNORE, FP_CELL);
	/// Executed after a player is infected. Can't be stopped.
	g_Forwards[fwUserInfectPost	] = CreateMultiForward("zp_fw_core_infect_post", ET_IGNORE, FP_CELL);
	
	/* Cure Forwards	*/
	/// Executed before a player is cured. Can be stopped.
	g_Forwards[fwUserCurePre	] = CreateMultiForward("zp_fw_core_cure_pre", ET_STOP, FP_CELL);
	/// Executed before a player is cured. Can't be stopped.
	g_Forwards[fwUserCure		] = CreateMultiForward("zp_fw_core_cure", ET_IGNORE, FP_CELL);
	/// Executed after a player is cured. Can't be stopped.
	g_Forwards[fwUserCurePost	] = CreateMultiForward("zp_fw_core_cure_post", ET_IGNORE, FP_CELL);
	
	/* Player Forwards	*/
	/// Executed after a player is spawned. Forwards whether or not they are a zombie. Can't be stopped.
	g_Forwards[fwPlayerSpawn	] = CreateMultiForward("zp_fw_core_player_spawn_post", ET_IGNORE, FP_CELL, FP_CELL);
	/// Executed after a player dies. Can't be stopped.
	g_Forwards[fwPlayerDeath	] = CreateMultiForward("zp_fw_core_player_death", ET_IGNORE, FP_CELL, FP_CELL);
	/// Executed when a player tries to change teams and is blocked. Can't be stopped.
	g_Forwards[fwTeamChangeBlock	] = CreateMultiForward("zp_fw_core_changeteam_blocked", ET_IGNORE, FP_CELL);
	/// Executed once all data structures for registering models are set and models can be registered. Can't be stopped.
	g_Forwards[fwRegisterModel	] = CreateMultiForward("zp_fw_core_register_model", ET_IGNORE);
}

public plugin_natives() {
	register_library("ZombiePlagueCore");
	
	register_native("is_user_zombie",		"_isUserZombie",		 1);
	register_native("zp_core_is_user_zombie",	"_isUserZombie",		 1);
	register_native("zp_core_infect_user",		"_infectUser",			 1);
	register_native("zp_core_cure_user",		"_cureUser",			 1);
	register_native("zp_core_refresh",		"_refreshPlayer",		 1);
	register_native("zp_core_get_players",		"_getPlayers",			 0);
	register_native("zp_core_register_model",	"_registerModel",		 0);
	register_native("zp_core_get_model_from_id",	"_ModelIDToName",		 0);
	register_native("zp_core_respawn_user",		"_respawnUser",			 1);
	
	register_native("zp_core_get_zombie_bits",	"_getZombieWeaponBitsum",	 1);
	register_native("zp_core_set_zombie_bits",	"_setZombieWeaponBitsum",	 1);
	register_native("zp_core_check_zombie_bits",	"_checkZombieWeapons",		 1);
}

public client_putinserver(id) {
	resetPlayerInfo(id);
	flag_set(g_bIsConnected,id);
}

public client_disconnect(id) {
	resetPlayerInfo(id);
}

/**
 * Private method used to reset the player flags for a given player.  This
 * method is called only when a player joins or leaves the server.
 */
resetPlayerInfo(id) {
	for (new i; i < ePlayerFlags; i++) {
		flag_unset(i,id);
	}
	
	resetClassInfo(id);
}

/**
 * Private method used to reset the class information of a player. This is
 * executed whenever a player joins or leaves the server, as well as when
 * a player dies. This method is used to help flag the player as having no
 * class set, and also to know when to set the default values to that player.
 */
resetClassInfo(id) {
	if (0 < id <= g_iMaxPlayers) {
		for (new i; i < eZP_FL_BaseInfo; i++) {
			g_playerInfo[id][i] = _:-1;
		}
	}
}

/**
 * This forward is used to track the spawning event for a player. This forwards
 * main purpose is also to refresh and assign the class attributes to this player.
 * The reason that the information is refreshed here is because this is where class
 * information should be reloaded into a player whether they are a human or a 
 * zombie.
 */
public ham_PlayerSpawn_Post(id) {
	if (!is_user_alive(id)) {
		return HAM_IGNORED;
	}
		
	flag_set(g_bIsAlive,id);
	ExecuteForward(g_Forwards[fwPlayerSpawn], g_Forwards[fwDummy], id, flag_get_boolean(g_bIsZombie,id));
	_refreshPlayer(id)
	
	return HAM_IGNORED;
}

/**
 * This forward is used to track the death event for a player.  This forwards main
 * purpose is also to reset the class information of a player using the
 * {@link resetClassInfo(id)} method.
 */
public ham_PlayerKilled(killer, victim, shouldgib) {
	if (is_user_alive(victim)) {
		return HAM_IGNORED;
	}
	
	flag_unset(g_bIsAlive,victim);
	resetClassInfo(victim);
	
	ExecuteForward(g_Forwards[fwPlayerDeath], g_Forwards[fwDummy], killer, victim);
	
	return HAM_IGNORED;
}

/**
 * Private method used to infect a player and make them a zombie. This
 * method does not do any checks whether a person is a zombie or not,
 * it will only set a player as a zombie.
 */
infectPlayer(id) {
	ExecuteForward(g_Forwards[fwUserInfectPre	], g_Forwards[fwDummy], id);
	ExecuteForward(g_Forwards[fwUserInfect		], g_Forwards[fwDummy], id);
	flag_set(g_bIsZombie,id);
	fm_cs_set_user_team(id, CS_TEAM_T);
	_refreshPlayer(id);
	ExecuteForward(g_Forwards[fwUserInfectPost	], g_Forwards[fwDummy], id);
}

/**
 * Private method used to cure a player and make them a human. This
 * method does not do any checks whether a person is a human or not,
 * it will only set a player as a human.
 */
curePlayer(id) {
	ExecuteForward(g_Forwards[fwUserCurePre		], g_Forwards[fwDummy], id);
	ExecuteForward(g_Forwards[fwUserCure		], g_Forwards[fwDummy], id);
	flag_unset(g_bIsZombie,id);
	fm_cs_set_user_team(id, CS_TEAM_CT);
	_refreshPlayer(id);
	ExecuteForward(g_Forwards[fwUserCurePost	], g_Forwards[fwDummy], id);
}

/**
 * Public method used to track and block client team changes. This
 * method also executes a forward so that an scripters may access this
 * event.
 */
public blockTeamChange(id) {
	static CsTeams:curTeam;
	curTeam = fm_cs_get_user_team(id);
	
	if (curTeam == CS_TEAM_SPECTATOR || curTeam == CS_TEAM_UNASSIGNED) {
		return PLUGIN_CONTINUE;
	}
	
	ExecuteForward(g_Forwards[fwTeamChangeBlock	], g_Forwards[fwDummy], id);
	return PLUGIN_HANDLED;
}

/**
 * @see ZP_VarManager.inc
 */
public zp_fw_varmanager_get(id, field) {
	switch (field) {
		case ZP_INT_modelid: 	return g_playerInfo[id][zpbase_modelid];
		case ZP_FL_health:	return _:g_playerInfo[id][zpbase_health];
		case ZP_FL_speed:	return _:g_playerInfo[id][zpbase_speed];
		case ZP_FL_gravity:	return _:g_playerInfo[id][zpbase_gravity];
	}
	
	return -1;
}

/**
 * @see ZP_VarManager.inc
 */
public zp_fw_varmanager_set(id, field, any:value, const string[]) {
	switch (field) {
		case ZP_INT_modelid: {
			if (value < 0 || value >= g_modelCount[flag_get_boolean(g_bIsZombie,id)]) {
				return -1;
			}
			g_playerInfo[id][zpbase_modelid	] = value;
			return value;
		}
		case ZP_FL_health: {
			if (value < 1.0) {
				return _:-1.0;
			}
			g_playerInfo[id][zpbase_health	] = _:value;
			return value;
		}
		case ZP_FL_speed: {
			if (value <= 0.0) {
				return _:-1.0;
			}
			g_playerInfo[id][zpbase_speed	] = _:value;
			return value;
		}
		case ZP_FL_gravity: {
			if (value <= 0.0) {
				return _:-1.0;
			}
			g_playerInfo[id][zpbase_gravity	] = _:value;
			return value;
		}
	}
	
	return -1;
}

/**
 * @see ZP_Core.inc
 */
public bool:_isUserZombie(id)  {
	if (!flag_get(g_bIsConnected,id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return false;
	}
	
	return flag_get_boolean(g_bIsZombie,id);
}

/**
 * @see ZP_Core.inc
 */
public PlayerState:_infectUser(id)  {
	if (!flag_get(g_bIsConnected,id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return ps_Invalid;
	}
	
	if (flag_get(g_bIsZombie,id)) {
		//zp_core_log_error("Player already infected (%d)", id);
		_refreshPlayer(id);
		return ps_NoChange;
	}
	
	infectPlayer(id);
	client_print(id, print_chat, "You're infected!");
	return ps_Change;
}

/**
 * @see ZP_Core.inc
 */
public PlayerState:_cureUser(id) {
	if (!flag_get(g_bIsConnected,id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return ps_Invalid;
	}
	
	if (!flag_get(g_bIsZombie,id)) {
		//zp_core_log_error("Player not infected (%d)", id);
		_refreshPlayer(id);
		return ps_NoChange;
	}
	
	curePlayer(id);
	return ps_Change;
}

/**
 * @see ZP_Core.inc
 */
public _getPlayers(iPlugin, iParams) {
	if (iParams != 3) {
		return PLUGIN_CONTINUE;
	}
	
	static iPlayers[32], iCounter, getZombies;
	getZombies = get_param(3);

	if (getZombies) {
		for (new i = 1; i <= g_iMaxPlayers; i++) {
			if (flag_get(g_bIsZombie,i)) {
				iPlayers[iCounter] = i;
				iCounter++;
			}
		}
	} else {
		for (new i = 1; i <= g_iMaxPlayers; i++) {
			if (!flag_get(g_bIsZombie,i)) {
				iPlayers[iCounter] = i;
				iCounter++;
			}
		}
	}
	
	set_array(1, iPlayers, iCounter);
	set_param_byref(2, iCounter);
	
	return PLUGIN_CONTINUE;
}

/**
 * @see ZP_Core.inc
 */
public bool:_refreshPlayer(id) {
	if (!flag_get(g_bIsConnected,id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return false;
	}
	
	if (!flag_get(g_bIsAlive,id)) {
		return false;
	}
	
	static bool:isZombie;
	isZombie = flag_get_boolean(g_bIsZombie,id);
	
	if (isZombie) {
		fm_strip_user_weapons(id);
		fm_give_item(id, g_szWpnEntNames[CSW_KNIFE]);
		cs_set_player_weap_restrict(id, true, g_pCvars[Value][CVAR_AllowedWeapons], CSW_KNIFE);
	} else {
		cs_set_player_weap_restrict(id, false);
	}
	
	if (fm_cs_get_user_team(id) != isZombie) {
		fm_cs_set_user_team(id, isZombie);
	}
	
	for (new i; i < eZP_FL_BaseInfo; i++) {
		if (g_playerInfo[id][i] == _:-1) {
			g_playerInfo[id][i] = _:g_baseAttributes[isZombie][i];
		}
	}
	
	// If there is no model set yet, then set default
	if (g_playerInfo[id][zpbase_modelid] == -1 || !g_modelCount[isZombie]) {
		cs_set_player_model(id, g_baseModel[isZombie]);
	} else if (!g_pCvars[Value][CVAR_ModelMode]) {
		static model[32];
		ArrayGetString(g_aModels[isZombie], random(g_modelCount[isZombie]), model, 31);
		cs_set_player_model(id, model);
	} else {
		static model[32];
		ArrayGetString(g_aModels[isZombie], g_playerInfo[id][zpbase_modelid], model, 31);
		cs_set_player_model(id, model);
	}
	
	set_pev(id, pev_health, g_playerInfo[id][zpbase_health]);
	set_pev(id, pev_gravity, g_playerInfo[id][zpbase_gravity]);
	cs_set_player_maxspeed_auto(id, g_playerInfo[id][zpbase_speed]);
	
	return true;
}

/**
 * @see ZP_Core.inc
 */
public _registerModel(iPlugin, iParams) {
	if (iParams != 2) {
		return -1;
	}
	
	static bool:isZombie, model[64], i;
	isZombie = bool:get_param(1);
	get_string(2, model, 63);
	
	if (g_aModels[isZombie] == Invalid_Array || g_tModels[isZombie] == Invalid_Trie) {
		zp_core_log_error("Player model ^"%s^" could not be registered, using standard model instead", model);
		return -1;
	}
	
	// Check if the model has been registered before, return old register id
	if (TrieGetCell(g_tModels[isZombie], model, i)) {
		return i;
	}

	if (!zp_core_precache_player_model(model)) {
		zp_core_log_error("Player model ^"%s^" could not be found, using standard model instead", model);
		return -1;
	}
	
	// Push the new model into the array and trie
	ArrayPushString(g_aModels[isZombie], model);
	TrieSetCell(g_tModels[isZombie], model, g_modelCount[isZombie]);
	
	g_modelCount[isZombie]++;
	return g_modelCount[isZombie]-1;
}

/**
 * @see ZP_Core.inc
 */
public _ModelIDToName(iPlugin, iParams) {
	if (iParams != 4) {
		return;
	}
		
	static bool:isZombie;
	isZombie = !!get_param(1);
	
	static modelid;
	modelid = get_param(2);
	
	if (modelid == -1) {
		set_string(3, g_baseModel[isZombie], get_param(4));
	} else {
		static model[32];
		ArrayGetString(g_aModels[isZombie], modelid, model, 31);
		set_string(3, model, get_param(4));
	}
}

public hookBitsumChange(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
	g_pCvars[Value][CVAR_AllowedWeapons] = read_flags32(newValue);
}

/**
 * @see ZP_Core.inc
 */
public _getZombieWeaponBitsum() {
	return g_pCvars[Value][CVAR_AllowedWeapons];
}

/**
 * @see ZP_Core.inc
 */
public _setZombieWeaponBitsum(bits){
	SetBit(bits,CSW_KNIFE);
	g_pCvars[Value][CVAR_AllowedWeapons] = bits;
	return g_pCvars[Value][CVAR_AllowedWeapons];
}

/**
 * @see ZP_Core.inc
 */
public bool:_checkZombieWeapons(csw) {
	if (csw < CSW_P228 || csw > CSW_P90) {
		return false;
	}
	
	return !!GetBit(g_pCvars[Value][CVAR_AllowedWeapons],csw);
}

/**
 * @see ZP_Core.inc
 */
public bool:_respawnUser(id) {
	if (!flag_get(g_bIsConnected,id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return false;
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	return true;
}

/**
 * Taken from Fakemeta Utilities by VEN
 * https://forums.alliedmods.net/showthread.php?t=28284
 */
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent)) {
		return 0;
	}

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10)) {
		return 0;
	}

	new ent = fm_create_entity(item);
	if (!pev_valid(ent)) {
		return 0;
	}

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save) {
		return ent;
	}

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock fm_get_weaponbox_type(entity) {
	static max_clients, max_entities;
	if (!max_clients) {
		max_clients = global_get(glb_maxClients);
	}
	if (!max_entities) {
		max_entities = global_get(glb_maxEntities);
	}

	for (new i = max_clients + 1; i < max_entities; ++i) {
		if (pev_valid(i) && entity == pev(i, pev_owner)) {
			new wname[32];
			pev(i, pev_classname, wname, sizeof wname - 1);
			return get_weaponid(wname);
		}
	}

	return 0;
}

/**
 * Taken from Cstrike Module to Fakemeta by Exolent[jNr]
 * https://forums.alliedmods.net/showthread.php?t=87574
 */
#define EXTRAOFFSET	5
#define OFFSET_TEAM	114
 
/*
***Copied up top***
enum CsTeams {
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
};

new const team_names[CsTeams][] = {
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};*/
 
stock fm_cs_set_user_team(client, {CsTeams,_}:team) {
	set_pdata_int(client, OFFSET_TEAM, _:team, EXTRAOFFSET);
	
	dllfunc(DLLFunc_ClientUserInfoChanged, client, engfunc(EngFunc_GetInfoKeyBuffer, client));
	
	static TeamInfo;
	if(TeamInfo || (TeamInfo = get_user_msgid("TeamInfo"))) {
		emessage_begin(MSG_BROADCAST, TeamInfo); {
		ewrite_byte(client);
		ewrite_string(szTeamNames[team]);
		} emessage_end();
	}
}

stock CsTeams:fm_cs_get_user_team(client) {
	return CsTeams:get_pdata_int(client, OFFSET_TEAM, EXTRAOFFSET);
}
