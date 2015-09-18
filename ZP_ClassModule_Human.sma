#include <amxmodx>
#include <fakemeta>
#include <cvar_util>
#include <flags32>

#include <ZP_Core>
#include <ZP_GunModule>
#include <ZP_ClassModule>
#include <ZP_ClassModule_Human_Const>

new const Plugin [] = "ZP Human Class Addon";
new const Version[] = "0.0.1";
new const Author [] = "Tirant";

#define MAXPLAYERS 32

new g_iHumanType;

new Array:g_aHumanClasses
new Trie:g_tClassNames
new g_humanClassCount

new g_humanClass[eClassManager][MAXPLAYERS+1];

enum _:eWeaponAmmoOffsets {
	OFFSET_AMMO_AWP = 377,
	OFFSET_AMMO_SCOUT, // AK47, G3SG1
	OFFSET_AMMO_M249,
	OFFSET_AMMO_M4A1, // FAMAS, AUG, SG550, GALIL, SG552
	OFFSET_AMMO_M3, // XM1014
	OFFSET_AMMO_USP, // UMP45, MAC10
	OFFSET_AMMO_FIVESEVEN, // P90
	OFFSET_AMMO_DEAGLE,
	OFFSET_AMMO_P228,
	OFFSET_AMMO_GLOCK18, // MP5NAVY, TMP, ELITE
	OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_HEGRENADE,
	OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_C4
};

new const _CSW_to_offset[] = {
	0, OFFSET_AMMO_P228, OFFSET_AMMO_SCOUT, OFFSET_AMMO_HEGRENADE, OFFSET_AMMO_M3, OFFSET_AMMO_C4, OFFSET_AMMO_USP, OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_GLOCK18, OFFSET_AMMO_FIVESEVEN, OFFSET_AMMO_USP, OFFSET_AMMO_M4A1, OFFSET_AMMO_M4A1, OFFSET_AMMO_M4A1, OFFSET_AMMO_USP, OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_AWP, OFFSET_AMMO_GLOCK18, OFFSET_AMMO_M249, OFFSET_AMMO_M3, OFFSET_AMMO_M4A1, OFFSET_AMMO_GLOCK18, OFFSET_AMMO_SCOUT, OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_DEAGLE, OFFSET_AMMO_M4A1, OFFSET_AMMO_SCOUT, 0, OFFSET_AMMO_FIVESEVEN
};

new g_giveWeaponsBitsum;
enum _:eWeaponBits ( <<=1 ) {
	PRIM_WEAPONS = 1,
	SEC_WEAPONS,
	HE_GREN,
	SMOKE_GREN,
	FLASH_GREN
}
				
enum _:eCvars {
	CVAR_HEGREN = 0,
	CVAR_SMOKE,
	CVAR_FLASH,
	CVAR_WPNTYPE,
	CVAR_GIVEWPNS
}
new g_pCvars[eCvars];

public plugin_precache() {
	g_iHumanType = zp_class_register_type("Human", false);
	
	g_aHumanClasses = ArrayCreate(eHumanClassInfo);
	g_tClassNames = TrieCreate();
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	g_pCvars[CVAR_HEGREN	] = CvarRegister("zp_human_class_hegrenade", "1", "How many HE grenades to give a human", FCVAR_SERVER, .hasMin = true, .minValue = 1.0);
	g_pCvars[CVAR_SMOKE	] = CvarRegister("zp_human_class_smokegrenade", "1", "How many smoke grenades to give a human", FCVAR_SERVER, .hasMin = true, .minValue = 1.0);
	g_pCvars[CVAR_FLASH	] = CvarRegister("zp_human_class_flashbang", "2", "How many flashbangs to give a human", FCVAR_SERVER, .hasMin = true, .minValue = 1.0);
	g_pCvars[CVAR_WPNTYPE	] = CvarRegister("zp_human_class_wpntype", "0", "Forces primary and secondary weapons on their menus", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0);
	g_pCvars[CVAR_GIVEWPNS	] = CvarRegister("zp_human_class_weapons", "abcde", "What weapons to give a player from their class", FCVAR_SERVER);
	CvarHookChange(g_pCvars[CVAR_GIVEWPNS], "hookBitsumChange");
	
	static szTemp[32];
	get_pcvar_string(g_pCvars[CVAR_GIVEWPNS], szTemp, 31);
	g_giveWeaponsBitsum = read_flags(szTemp);
}

public plugin_natives() {
	register_library("ZP_ClassModule_Human");
	
	register_native("zp_class_human_get_current", "_get_user_human_class", 1);
	register_native("zp_class_human_set_next", "_set_next_human_class", 1);
	register_native("zp_class_human_show_menu", "_show_human_class_menu", 1);
	register_native("zp_class_human_register", "_register_human_class", 0);
	register_native("zp_class_human_get_localid", "_get_human_class_localid", 1);
	register_native("zp_class_human_get_globalid", "_get_human_class_globalid", 0);
	register_native("zp_class_human_get_typeid", "_get_human_typeid", 1);
}

public hookBitsumChange(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
	g_giveWeaponsBitsum = read_flags(newValue);
}

public client_putinserver(id) {
	resetPlayerInfo(id);
}

public client_disconnect(id) {
	resetPlayerInfo(id);
}

resetPlayerInfo(id) {
	for (new i; i < eClassManager; i++) {
		g_humanClass[i][id] = CLASS_NONE;
	}
}

public zp_cure(id) {
	static humanClass[eHumanClassInfo];
	if (is_user_bot(id)) {
		ArrayGetArray(g_aHumanClasses, random(sizeof g_humanClassCount), humanClass);
		zp_class_apply_class(id, humanClass[GlobalID]);
	} else if (g_humanClass[Current][id] == CLASS_NONE) {
		ArrayGetArray(g_aHumanClasses, 0, humanClass);
		zp_class_apply_class(id, humanClass[GlobalID]);
		_show_human_class_menu(id);
	} else {
		zp_class_apply_class(id, g_humanClass[Current][id]);
	}
}

public zp_class_applied(id, globalid) {
	if (zp_class_get_class_int(globalid, ZP_INT_typeid) != g_iHumanType) {
		return;
	}
	
	static localid, tempHumanClass[eHumanClassInfo];
	localid = zp_class_get_class_int(globalid, ZP_INT_localid);
	ArrayGetArray(g_aHumanClasses, localid, tempHumanClass);
	
	fm_strip_user_weapons(id);
	fm_give_item(id, "weapon_knife");
	
	if (g_giveWeaponsBitsum&(PRIM_WEAPONS) && tempHumanClass[Primary] != ZP_PRIM_NONE) {
		zp_show_guns_menu_bits(id, tempHumanClass[Primary], "Primary Weapons Menu");
	}
	
	if (g_giveWeaponsBitsum&(SEC_WEAPONS) && tempHumanClass[Secondary] != ZP_SEC_NONE) {
		zp_show_guns_menu_bits(id, tempHumanClass[Secondary], "Secondary Weapons Menu");
	}
	
	if (g_giveWeaponsBitsum&(HE_GREN) && tempHumanClass[Grenades]&(ZP_HEGRENADE)) {
		fm_give_item(id, "weapon_hegrenade");
		fm_cs_set_user_bpammo(id, CSW_HEGRENADE, get_pcvar_num(g_pCvars[CVAR_HEGREN]));
	}
	
	if (g_giveWeaponsBitsum&(SMOKE_GREN) && tempHumanClass[Grenades]&(ZP_SMOKEGRENADE)) {
		fm_give_item(id, "weapon_smokegrenade");
		fm_cs_set_user_bpammo(id, CSW_SMOKEGRENADE, get_pcvar_num(g_pCvars[CVAR_SMOKE]));
	}
	
	if (g_giveWeaponsBitsum&(FLASH_GREN) && tempHumanClass[Grenades]&(ZP_FLASHBANG)) {
		fm_give_item(id, "weapon_flashbang");
		fm_cs_set_user_bpammo(id, CSW_FLASHBANG, get_pcvar_num(g_pCvars[CVAR_FLASH]));
	}
}

public zp_class_selected(id, globalid) {
	g_humanClass[Next][id] = globalid;
	if (g_humanClass[Current][id] == CLASS_NONE) {
		g_humanClass[Current][id] = globalid;
		zp_class_apply_class(id, globalid);
		zp_refresh_player(id);
	}
}

public bool:_show_human_class_menu(id) {
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}

	zp_class_show_class_menu(id, g_iHumanType, g_humanClass[Next][id]);
	
	return true;
}

public _get_user_human_class(id, bool:getNext) {
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	if (getNext) {
		return g_humanClass[Next][id];
	}
	
	return g_humanClass[Current][id];
}

public bool:_set_next_human_class(id, localid) {
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (localid < 0 || localid >= g_humanClassCount) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", localid)
		return false;
	}
	
	g_humanClass[Next][id] = localid
	return true;
}

public _register_human_class(iPlugin, iParams) {
	if (iParams < 2 || iParams > eHumanParamOrder) {
		return -1;
	}
	
	// Set basic information this class will need
	static newClassData[eClassData];
	newClassData[TypeID	] = g_iHumanType;
	newClassData[LocalID	] = g_humanClassCount;
	
	// Cache strings from the parameters
	get_string(hParam_name, newClassData[Name], 31);
	get_string(hParam_desc, newClassData[Desc], 31);
	
	static model[32];
	get_string(hParam_model, model, 31);
	
	// Set global class attributes
	newClassData[ModelID	] = zp_register_model(false, model);
	newClassData[Health	] = _:HUMAN_DEFAULT_HEALTH;
	newClassData[Speed	] = _:HUMAN_DEFAULT_SPEED;
	newClassData[Gravity	] = _:HUMAN_DEFAULT_GRAVITY;
	newClassData[XPReq	] = HUMAN_DEFAULT_EXP;
	newClassData[AdminLevel	] = HUMAN_DEFAULT_ADMIN;
	
	static newHumanClassData[eHumanClassInfo], szTemp[33], bool:bForceWeaponType;
	bForceWeaponType = (get_pcvar_num(g_pCvars[CVAR_WPNTYPE]) ? true : false);

	get_string(hParam_primary, szTemp, 32);
	newHumanClassData[Primary] = read_flags32(szTemp);

	// Load the primary weapon
	if (newHumanClassData[Primary] == 0) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class parameter. No weapon 1 selected on class ^"%s^"", newClassData[Name]);
		return -1;
	} else if (bForceWeaponType) {
		for (new i; i <= CSW_P90; i++) {
			if (zp_is_primary_weapon(i)) {
				newHumanClassData[Primary] &= ~(1 << i);
			}
		}
	}

	get_string(hParam_secondary, szTemp, 32);
	newHumanClassData[Secondary] = read_flags32(szTemp);
	
	// Load the secondary weapon
	if (newHumanClassData[Secondary] == 0) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class parameter. No weapon 2 selected on class ^"%s^"", newClassData[Name]);
		return -1;
	} else if (bForceWeaponType) {
		for (new i; i <= CSW_P90; i++) {
			if (zp_is_secondary_weapon(i)) {
				newHumanClassData[Secondary] &= ~(1 << i);
			}
		}
	}
	
	// Load the grenades
	get_string(hParam_grenades, szTemp, 31);
	newHumanClassData[Grenades] = read_flags(szTemp);
	
	// Attempt to register the class into the global system
	newHumanClassData[GlobalID] = zp_class_register_class(newClassData);
	
	// Check and see if the class failed to register
	if (newHumanClassData[GlobalID] == CLASS_NONE) {
		return -1;
	}

	// Push the class into the array
	ArrayPushArray(g_aHumanClasses, newHumanClassData);
	
	// Add the class name into the trie table
	TrieSetCell(g_tClassNames, newClassData[Name], g_humanClassCount);
	
	// Increase class counter by 1
	g_humanClassCount++;
	
	return newHumanClassData[GlobalID];
}

public _get_human_class_localid(iPlugin, iParams) {
	if(iParams != 1)
		return PLUGIN_CONTINUE;

	new className[32], iClass;
	get_string(1, className, 31)
	if (TrieGetCell(g_tClassNames, className, iClass)) {
		return iClass;
	}
		
	return -1;
}

public _get_human_class_globalid(localid) {
	if (localid < 0 || localid >= g_humanClassCount) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", localid)
		return -1;
	}
	
	static humanClassInfo[eHumanClassInfo];
	ArrayGetArray(g_aHumanClasses, localid, humanClassInfo);
	return humanClassInfo[GlobalID];
}

public _get_human_typeid() {
	return g_iHumanType;
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
 
/*
*** Copied up top ***
enum {
	OFFSET_AMMO_AWP = 377,
	OFFSET_AMMO_SCOUT, // AK47, G3SG1
	OFFSET_AMMO_M249,
	OFFSET_AMMO_M4A1, // FAMAS, AUG, SG550, GALIL, SG552
	OFFSET_AMMO_M3, // XM1014
	OFFSET_AMMO_USP, // UMP45, MAC10
	OFFSET_AMMO_FIVESEVEN, // P90
	OFFSET_AMMO_DEAGLE,
	OFFSET_AMMO_P228,
	OFFSET_AMMO_GLOCK18, // MP5NAVY, TMP, ELITE
	OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_HEGRENADE,
	OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_C4
};

static const _CSW_to_offset[] = {
	0, OFFSET_AMMO_P228, OFFSET_AMMO_SCOUT, OFFSET_AMMO_HEGRENADE, OFFSET_AMMO_M3, OFFSET_AMMO_C4, OFFSET_AMMO_USP, OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_GLOCK18, OFFSET_AMMO_FIVESEVEN, OFFSET_AMMO_USP, OFFSET_AMMO_M4A1, OFFSET_AMMO_M4A1, OFFSET_AMMO_M4A1, OFFSET_AMMO_USP, OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_AWP, OFFSET_AMMO_GLOCK18, OFFSET_AMMO_M249, OFFSET_AMMO_M3, OFFSET_AMMO_M4A1, OFFSET_AMMO_GLOCK18, OFFSET_AMMO_SCOUT, OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_DEAGLE, OFFSET_AMMO_M4A1, OFFSET_AMMO_SCOUT, 0, OFFSET_AMMO_FIVESEVEN
};*/

stock fm_cs_get_user_bpammo(client, weapon) {
	return get_pdata_int(client, _CSW_to_offset[weapon], EXTRAOFFSET);
}

stock fm_cs_set_user_bpammo(client, weapon, ammo) {
	set_pdata_int(client, _CSW_to_offset[weapon], ammo, EXTRAOFFSET);
}
