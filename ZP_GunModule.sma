#include <amxmodx>
#include <fakemeta>
#include <flags32>
#include <cvar_util>

#include <ZP_Core>
#include <ZP_GunModule_Const>
#include <ZP_CommandModule>

new const Plugin [] = "ZP Gun Module";
new const Version[] = "0.0.1";
new const Author [] = "Tirant";

#define MENU_OFFSET 25

enum _:eMenuInfo {
	menu_csw = 0,
	menu_endstring
}

enum eCvars {
	CVAR_RandomWeapons = 0,
	CVAR_UseGunPrices,
	CVAR_Weapons1[33],
	CVAR_Weapons2[33]
};

enum _:CvarModes {
	Pointer,
	Value
};

new g_pCvars[CvarModes][eCvars];
new g_pCvarGunPrice[CvarModes][CSW_P90+1];

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

new const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "w;eapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" };

new const g_iWpnPriceDefaults[] = {
			-1, 600, -1, 2750, -1, 3000, -1, 1400,
			3500, -1, 1000, 750, 1700, 4200,
			2000, 2250, 400, 400, 4750, 1500, 5750,
			1700, 3100, 1250, 5000, -1, 650, 3500,
			2500, -1, 2350};

enum eForwardedEvents {
	fwDummy = 0,
	fwShowGunsMenuPre,
	fwShowGunsMenuPost,
	fwGunGiven
};
new g_Forwards[eForwardedEvents];
			
public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	if (!is_module_loaded("ZP_ClassModule")) {
		zp_command_register("guns", "cmdGuns", "abde", "Opens the guns menu to select new weapons");
		zp_command_register("weapons", "cmdGuns");
		zp_command_register("gunmenu", "cmdGuns");
	}
	
	g_pCvars[Pointer][CVAR_RandomWeapons] = CvarRegister("zp_guns_randomweapon", "0", "Whether or not to show the menu or pick a random weapon from the list", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0);
	CvarCache(g_pCvars[Pointer][CVAR_RandomWeapons], CvarType_Int, g_pCvars[Value][CVAR_RandomWeapons]);
	g_pCvars[Pointer][CVAR_UseGunPrices ] = CvarRegister("zp_guns_usegunprices", "0", "Whether or not to charge the price of a weapon then selecting", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0);
	CvarCache(g_pCvars[Pointer][CVAR_UseGunPrices ], CvarType_Int, g_pCvars[Value][CVAR_UseGunPrices ]);
	
	get_flags32(__weaponsPrimary, g_pCvars[Value][CVAR_Weapons1], 32);
	g_pCvars[Pointer][CVAR_Weapons1	    ] = CvarRegister("zp_guns_weapons1", g_pCvars[Value][CVAR_Weapons1], "List of weapons to be displayed in list 1 by default", FCVAR_SERVER);
	CvarCache(g_pCvars[Pointer][CVAR_Weapons1], CvarType_String, g_pCvars[Value][CVAR_Weapons1], 32);
	get_flags32(__weaponsSecondary, g_pCvars[Value][CVAR_Weapons2], 32);
	g_pCvars[Pointer][CVAR_Weapons2	    ] = CvarRegister("zp_guns_weapons2", g_pCvars[Value][CVAR_Weapons2], "List of weapons to be displayed in list 2 by default", FCVAR_SERVER);
	CvarCache(g_pCvars[Pointer][CVAR_Weapons2], CvarType_String, g_pCvars[Value][CVAR_Weapons2], 32);
	
	new szCvarName[32], szCvarValue[8];
	for (new i = 1; i <= CSW_P90; i++) {
		szCvarName[0] = '^0';
		copy(szCvarName, 31, g_szWpnEntNames[i]);
		replace(szCvarName, 31, "weapon_", "zp_guns_price_");
		
		szCvarValue[0] = '^0';
		num_to_str(g_iWpnPriceDefaults[i], szCvarValue, 7);
		
		g_pCvarGunPrice[Pointer][i] = CvarRegister(szCvarName, szCvarValue, "Cost of this weapon in the guns menu", FCVAR_SERVER, .hasMin = true, .minValue = -1.0);
		CvarCache(g_pCvarGunPrice[Pointer][i], CvarType_Int, g_pCvarGunPrice[Value][i]);
	}
	
	/* Forwards */
	/// Executed when a guns menu is shown. Can be stopped.
	g_Forwards[fwShowGunsMenuPre	] = CreateMultiForward("zp_guns_menu_shown_pre", ET_STOP, FP_CELL, FP_STRING, FP_STRING);
	/// Executed after a guns menu is shown. Cannot be stopped.
	g_Forwards[fwShowGunsMenuPost	] = CreateMultiForward("zp_guns_menu_shown_post", ET_IGNORE, FP_CELL, FP_STRING, FP_STRING);
	/// Executed when a player chooses a gun from the menu. Cannot be stopped.
	g_Forwards[fwGunGiven		] = CreateMultiForward("zp_guns_gun_given", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives() {
	register_library("ZP_GunModule");
	
	register_native("zp_show_guns_menu", "_show_guns_menu", 1);
}

public cmdGuns(id) {
	showDefaultWeaponsMenu(id);
}

bool:showDefaultWeaponsMenu(id, bool:showPrimary = true) {
	if (is_module_loaded("ZP_ClassModule") || is_user_zombie(id)) {
		return false;
	}
	
	if (showPrimary) {
		showGunMenu(id, g_pCvars[Value][CVAR_Weapons1], "Primary Weapons Menu");
	} else {
		showGunMenu(id, g_pCvars[Value][CVAR_Weapons2], "Secondary Weapons Menu");
	}
	
	return true;
}

public zp_PlayerSpawn_Post(id, bool:isZombie) {
	showDefaultWeaponsMenu(id);
}

showGunMenu(id, szFlags[], szMenuName[]) {
	ExecuteForward(g_Forwards[fwShowGunsMenuPre], g_Forwards[fwDummy], id, szFlags, szMenuName);
	
	if (is_user_zombie(id)) {
		return PLUGIN_CONTINUE;
	}
	
	static weaponBitsum; weaponBitsum = read_flags32(szFlags);
	if (weaponBitsum == 0) {
		zp_core_log_error("Weapon menu sent with no flags");
		return PLUGIN_CONTINUE;
	}
	
	if (g_pCvars[Value][CVAR_RandomWeapons]) {
		static randomWeapon; randomWeapon = random(strlen(szFlags));
		fm_give_item(id, g_szWpnEntNames[randomWeapon]);
		ExecuteForward(g_Forwards[fwGunGiven], g_Forwards[fwDummy], id, randomWeapon);
		showDefaultWeaponsMenu(id, false);
		
		return PLUGIN_CONTINUE;
	}
	
	if (strlen(szFlags) == 1) {
		fm_give_item(id, g_szWpnEntNames[0]);
		return PLUGIN_CONTINUE;
	}

	static menuid, menu[128], itemInfo[eMenuInfo];
	formatex(menu, 127, "\r%s", szMenuName);
	menuid = menu_create(menu, "gunMenuHandle");
	
	static curMoney, szGunPrice[32], szGunName[32], bool:wasGun;
	curMoney = fm_cs_get_user_money(id);
	for (new i = 1; i <= CSW_P90; i++) {
		if (!(weaponBitsum & (1<<i)) || g_iWpnPriceDefaults[i] == -1) {
			continue;
		}
		
		if (g_pCvarGunPrice[Value][i] != -1) {
			szGunPrice[0] = '^0';
			if (g_pCvarGunPrice[Value][i] > 0) {
				formatex(szGunPrice, 31, " \%c[$%d]", (curMoney < g_pCvarGunPrice[Value][i] ? 'r' : 'y'), g_pCvarGunPrice[Value][i]);
			}
			
			szGunName[0] = '^0';
			zp_get_weaponname(i, szGunName, 31);
			formatex(menu, 127, "%s%s", szGunName, szGunPrice);
			
			itemInfo[menu_csw] = i+MENU_OFFSET;
			menu_additem(menuid, menu, itemInfo);
			wasGun = true;
		}
	}
	
	if (!wasGun) {
		return PLUGIN_CONTINUE;
	}
	
	formatex(menu, 127, "Back");
	menu_setprop(menuid, MPROP_BACKNAME, menu);
	formatex(menu, 127, "Next");
	menu_setprop(menuid, MPROP_NEXTNAME, menu);
	//formatex(menu, 127, "Exit");
	//menu_setprop(menuid, MPROP_EXITNAME, menu);
	
	menu_display(id, menuid);
	ExecuteForward(g_Forwards[fwShowGunsMenuPost], g_Forwards[fwDummy], id, szFlags, szMenuName);
	
	return PLUGIN_CONTINUE;
}

public gunMenuHandle(id, menuid, item) {
	/*if (item == MENU_EXIT) {
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}*/
	
	if (is_user_zombie(id)) {
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	static itemInfo[eMenuInfo], dummy;
	menu_item_getinfo(menuid, item, dummy, itemInfo, eMenuInfo-1, _, _, dummy);
	for (new i; i < eMenuInfo; i++) {
		itemInfo[i] -= MENU_OFFSET;
	}
	
	static curMoney, gunPrice;
	curMoney = fm_cs_get_user_money(id);
	if (curMoney < g_pCvarGunPrice[Value][itemInfo[menu_csw]]) {
		zp_print_color(id, "^1You do not have enough money to purchase this weapon!");
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	fm_cs_set_user_money(id, curMoney-gunPrice, 1);
	fm_give_item(id, g_szWpnEntNames[itemInfo[menu_csw]]);
	ExecuteForward(g_Forwards[fwGunGiven], g_Forwards[fwDummy], id, itemInfo[menu_csw]);
	showDefaultWeaponsMenu(id, false);
	
	menu_destroy(menuid);
	return PLUGIN_HANDLED;
}

public _show_guns_menu(iPlugin, iParams) {
	if (iParams != 3) {
		zp_core_log_error("Invalid parameters entered. (Expected %d, Found %d)", 3, iParams);
		return PLUGIN_CONTINUE;
	}
	
	static id, szFlags[33], szMenuName[64];
	id = get_param(1);
	get_string(2, szFlags, 32);
	get_string(3, szMenuName, 63);
	
	showGunMenu(id, szFlags, szMenuName);
	
	return PLUGIN_CONTINUE;
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
stock fm_cs_get_user_money(id) {
	return get_pdata_int(id, 115, 5);
}

stock fm_cs_set_user_money(id, money, flash = 1) {
	set_pdata_int(id, 115, money, 5);
	
	static Money;
	if( Money || (Money = get_user_msgid("Money")) ) {
		emessage_begin(MSG_ONE_UNRELIABLE, Money, _, id); {
		ewrite_long(money);
		ewrite_byte(flash ? 1 : 0);
		} emessage_end();
	}
}

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
