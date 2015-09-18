/*================================================================================
	
	----------------------------------
	-*- [CS] Player Models API 1.1 -*-
	----------------------------------
	
	- Allows easily setting and restoring custom player models in CS and CZ
	   (models last until player disconnects or are manually reset)
	- Built-in SVC_BAD prevention
	- Support for custom hitboxes (model index offset setting)
	- You still need to precache player models in your plugin!
	
	Original thread:
	http://forums.alliedmods.net/showthread.php?t=161255
	
================================================================================*/

// Delay between model changes (increase if getting SVC_BAD kicks)
#define MODELCHANGE_DELAY 0.2

// Delay after roundstart (increase if getting kicks at round start)
#define ROUNDSTART_DELAY 2.0

// Enable custom hitboxes (experimental, might lag your server badly with some models)
//#define SET_MODELINDEX_OFFSET

/*=============================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <ZP_Core>

#define MAXPLAYERS 32

#define TASK_MODELCHANGE 100

new const DEFAULT_MODELINDEX_T[][] = {
	"models/player/terror/terror.mdl",
	"models/player/leet/leet.mdl",
	"models/player/arctic/arctic.mdl",
	"models/player/guerilla/guerilla.mdl"
}
new const DEFAULT_MODELINDEX_CT[][] = {
	"models/player/urban/urban.mdl",
	"models/player/gign/gign.mdl",
	"models/player/gsg9/gsg9.mdl",
	"models/player/sas/sas.mdl"
}

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114
#define OFFSET_MODELINDEX 491 // Orangutanz

// CS Teams
enum CsTeams {
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
}

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2)		(%1 |= (1 << (%2 & 31)))
#define flag_unset(%1,%2)	(%1 &= ~(1 << (%2 & 31)))

new g_hasCustomModel
new Float:g_modelChangeTargetTime
new g_customPlayerModel[MAXPLAYERS+1][32]
#if defined SET_MODELINDEX_OFFSET
new g_customModelIndex[MAXPLAYERS+1]
#endif

public plugin_init()
{
	register_plugin("[CS] Player Models API", "1.1", "WiLS")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
}

public plugin_natives()
{
	register_library("cs_player_models_api")
	register_native("cs_set_player_model", "native_set_player_model", 1)
	register_native("cs_reset_player_model", "native_reset_player_model", 1)
}

public native_set_player_model(id, const newmodel[])
{
	if (!is_user_connected(id))
	{
		zp_core_log_error("Player is not in game (%d)", id)
		return false;
	}
	
	// Strings passed byref
	param_convert(2)
	
	remove_task(id+TASK_MODELCHANGE)
	flag_set(g_hasCustomModel, id)
	
	copy(g_customPlayerModel[id], charsmax(g_customPlayerModel[]), newmodel)
	
#if defined SET_MODELINDEX_OFFSET	
	static modelPath[32+(2*32)]
	formatex(modelPath, charsmax(modelPath), "models/player/%s/%s.mdl", newmodel, newmodel)
	g_customModelIndex[id] = engfunc(EngFunc_ModelIndex, modelPath)
#endif
	
	static currentModel[32]
	fm_cs_get_user_model(id, currentModel, charsmax(currentModel))
	
	if (!equal(currentModel, newmodel))
		fm_cs_user_model_update(id+TASK_MODELCHANGE)
	
	return true;
}

public native_reset_player_model(id)
{
	if (!is_user_connected(id))
	{
		zp_core_log_error("Player is not in game (%d)", id)
		return false;
	}
	
	remove_task(id+TASK_MODELCHANGE)
	flag_unset(g_hasCustomModel, id)
	fm_cs_reset_user_model(id)
	
	return true;
}

public client_disconnect(id)
{
	remove_task(id+TASK_MODELCHANGE)
	flag_unset(g_hasCustomModel, id)
}

public event_round_start()
{
	// An additional delay is offset at round start
	// since SVC_BAD is more likely to be triggered there
	g_modelChangeTargetTime = get_gametime() + ROUNDSTART_DELAY
	
	// If a player has a model change task in progress,
	// reschedule the task, since it could potentially
	// be executed during roundstart
	static players[32], player, num
	get_players(players, num)
	for (new i; i < num; i++) 
	{
		player = players[i];
		if (task_exists(player+TASK_MODELCHANGE))
		{
			remove_task(player+TASK_MODELCHANGE)
			fm_cs_user_model_update(player+TASK_MODELCHANGE)
		}
	}
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{
	if (flag_get(g_hasCustomModel, id) && equal(key, "model"))
	{
		static currentModel[32]
		fm_cs_get_user_model(id, currentModel, charsmax(currentModel))
		
		if (!equal(currentModel, g_customPlayerModel[id]) && !task_exists(id+TASK_MODELCHANGE))
			fm_cs_set_user_model(id+TASK_MODELCHANGE)
		
#if defined SET_MODELINDEX_OFFSET
		fm_cs_set_user_model_index(id)
#endif
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fm_cs_set_user_model(taskid)
{
	taskid -= TASK_MODELCHANGE;
	set_user_info(taskid, "model", g_customPlayerModel[taskid])
}

stock fm_cs_set_user_model_index(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_MODELINDEX, g_customModelIndex[id])
}

stock fm_cs_reset_user_model_index(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	switch (fm_cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, DEFAULT_MODELINDEX_T[random(4)]))
		}
		case CS_TEAM_CT:
		{
			set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, DEFAULT_MODELINDEX_CT[random(4)]))
		}
	}
}

stock fm_cs_get_user_model(id, model[], len)
{
	get_user_info(id, "model", model, len)
}

stock fm_cs_reset_user_model(id)
{
	dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id))
#if defined SET_MODELINDEX_OFFSET
	fm_cs_reset_user_model_index(id)
#endif
}

stock fm_cs_user_model_update(taskid)
{
	static Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_modelChangeTargetTime >= MODELCHANGE_DELAY)
	{
		fm_cs_set_user_model(taskid)
		g_modelChangeTargetTime = current_time
	}
	else
	{
		set_task((g_modelChangeTargetTime + MODELCHANGE_DELAY) - current_time, "fm_cs_set_user_model", taskid)
		g_modelChangeTargetTime = g_modelChangeTargetTime + MODELCHANGE_DELAY
	}
}

stock CsTeams:fm_cs_get_user_team(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return CS_TEAM_UNASSIGNED;
	
	return CsTeams:get_pdata_int(id, OFFSET_CSTEAMS);
}
