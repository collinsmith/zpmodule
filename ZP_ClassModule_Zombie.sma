#include <amxmodx>
#include <cvar_util>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <cs_ham_bots_api>
#include <cs_weap_models_api>
#include <arraycopy>

#include <ZP_Core>
#include <ZP_ClassModule>
#include <ZP_ClassModule_Zombie_Const>
#include <ZP_CommandModule>
#include <ZP_ClassModule_FileSystem>

static const Plugin [] = "ZP Zombie Class Addon";
static const Version[] = "0.0.1";
static const Author [] = "Tirant";

static const g_szTypeName[] = "ZP Zombie";
static const g_szClawModelPath[] = "models/zombie_plague/%s.mdl";
static g_szDefaultClawModel[64];

static g_iZombieType;

static Array:g_aZombieClasses;
static Trie:g_tClassNames;
static g_zombieClassCount;

static Trie:g_tZombieClassKeys;

static g_zombieClass[ClassManager][MAXPLAYERS+1];

enum _:eCvars {
	KB_Enabled = 0,
	KB_Damage,
	KB_ZVelocity,
	Float:KB_Ducking,
	Float:KB_Distance
};

enum _:CvarModes {
	Pointer,
	Value
};

static g_pCvars[CvarModes][eCvars];

static g_defaultClass[Class];
static g_defaultZombieClass[ZombieClass];

public zp_fw_class_data_struc_init_pos() {
	formatex(g_szDefaultClawModel, 63, g_szClawModelPath, ZOMBIE_DEFAULT_CLAW);
	if (!zp_core_precache_model(g_szDefaultClawModel)) {
		set_fail_state("Could not precache needed default zombie claw model!");
	}

	formatDefaultClass();
	g_iZombieType = zp_class_register_type(true, g_szTypeName, g_defaultClass);
	
	g_defaultZombieClass[GlobalID	] = CLASS_NONE;
	copy(g_defaultZombieClass[Claw	], 63, g_szDefaultClawModel);
	g_defaultZombieClass[Knockback	] = _:ZOMBIE_DEFAULT_KNOCKBACK;
	
	g_aZombieClasses = ArrayCreate(ZombieClass);
	g_tClassNames = TrieCreate();
	
	new fwDummy, fwDataStructInit = CreateMultiForward("zp_fw_class_zombie_register", ET_IGNORE);
	ExecuteForward(fwDataStructInit, fwDummy);
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	RegisterHam(Ham_TraceAttack, "player", "ham_TraceAttack");
	RegisterHamBots(Ham_TraceAttack, "ham_TraceAttack");
	
	g_pCvars[Pointer][KB_Enabled  ] = CvarRegister("zp_knockback", "0", "Enable weapon knockback (note: pain shock free increases knockback effect)", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0 );
	CvarCache(g_pCvars[Pointer][KB_Enabled   ], CvarType_Int, g_pCvars[Value][KB_Enabled   ]);
	g_pCvars[Pointer][KB_Damage   ] = CvarRegister("zp_knockback_damage", "1", "Use damage on knockback calculation", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0 );
	CvarCache(g_pCvars[Pointer][KB_Damage    ], CvarType_Int, g_pCvars[Value][KB_Damage    ]);
	g_pCvars[Pointer][KB_ZVelocity] = CvarRegister("zp_knockback_zvel", "0", "Should knockback affect vertical velocity", FCVAR_SERVER, .hasMin = true, .minValue = 0.0, .hasMax = true, .maxValue = 1.0 );
	CvarCache(g_pCvars[Pointer][KB_ZVelocity ], CvarType_Int, g_pCvars[Value][KB_ZVelocity ]);
	g_pCvars[Pointer][KB_Ducking  ] = CvarRegister("zp_knockback_ducking", "0.25", "Knockback multiplier for crouched zombies (0 = knockback disabled when ducking)", FCVAR_SERVER, .hasMin = true, .minValue = 0.0 );
	CvarCache(_:g_pCvars[Pointer][KB_Ducking ], CvarType_Float, g_pCvars[Value][KB_Ducking ]);
	g_pCvars[Pointer][KB_Distance ] = CvarRegister("zp_knockback_distance", "500", "Max distance for knockback to take effect", FCVAR_SERVER, .hasMin = true, .minValue = 0.0 );
	CvarCache(_:g_pCvars[Pointer][KB_Distance], CvarType_Float, g_pCvars[Value][KB_Distance]);
	
	zp_command_register("zombieclass",	"_showZombieClassMenu", _, "Displays the zombie class menu");
	zp_command_register("zclass",		"_showZombieClassMenu");
	zp_command_register("zclassmenu",	"_showZombieClassMenu");
}

public plugin_natives() {
	register_library("ZP_ClassModule_Zombie");

	register_native("zp_class_zombie_show_menu",		"_showZombieClassMenu", 1);
	register_native("zp_class_zombie_register",		"_registerZombieClass", 0);
	register_native("zp_class_zombie_register_group",	"_registerZombieClassGroup", 0);
	
	register_native("zp_class_zombie_get_current",		"_getUserZombieClass", 1);
	register_native("zp_class_zombie_set_next",		"_setNextZombieClass", 1);
	register_native("zp_class_zombie_get_localid",		"_getZombieClassLocalID", 0);
	register_native("zp_class_zombie_get_globalid",		"_getZombieClassGlobalID", 0);
	register_native("zp_class_zombie_get_typeid",		"_getZombieType", 1);
}

formatDefaultClass() {
	if (g_defaultClass[Health] != ZOMBIE_DEFAULT_HEALTH) {
		g_defaultClass[GroupID    ] = CLASSGROUP_NONE,
		g_defaultClass[LocalID    ] = CLASS_NONE,
		g_defaultClass[ModelID    ] = -1,
		g_defaultClass[Health     ] = _:ZOMBIE_DEFAULT_HEALTH,
		g_defaultClass[Speed      ] = _:ZOMBIE_DEFAULT_SPEED,
		g_defaultClass[Gravity    ] = _:ZOMBIE_DEFAULT_GRAVITY,
		g_defaultClass[AbilityList] = _:ArrayCreate();
		g_defaultClass[XPReq      ] = ZOMBIE_DEFAULT_EXP,
		g_defaultClass[AdminLevel ] = ZOMBIE_DEFAULT_ADMIN,
		g_defaultClass[MaxNumber  ] = ZOMBIE_DEFAULT_MAXNUM
	}
}

public client_putinserver(id) {
	resetPlayerInfo(id);
}

public client_disconnect(id) {
	resetPlayerInfo(id);
}

resetPlayerInfo(id) {
	for (new i; i < ClassManager; i++) {
		g_zombieClass[i][id] = CLASS_NONE;
	}
}

public ham_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type) {
	if (!is_user_connected(attacker) || victim == attacker) {
		return HAM_IGNORED;
	}
	
	if (!is_user_zombie(victim) || !(damage_type & DMG_BULLET)) {
		return HAM_IGNORED;
	}
	
	if (!g_pCvars[Value][KB_Enabled]) {
		return HAM_IGNORED;
	}
	
	static Float:origin1[3], Float:origin2[3];
	pev(victim, pev_origin, origin1);
	pev(attacker, pev_origin, origin2);
	if (get_distance_f(origin1, origin2) > g_pCvars[Value][KB_Distance]) {
		return HAM_IGNORED;
	}
	
	static Float:velocity[3];
	pev(victim, pev_velocity, velocity);
	
	// Use damage on knockback calculation
	if (g_pCvars[Value][KB_Damage]) {
		xs_vec_mul_scalar(direction, damage, direction);
	}
	
	// Use weapon power on knockback calculation
	/*if (get_pcvar_num(cvar_knockbackpower) && kb_weapon_power[g_currentweapon[attacker]] > 0.0) {
		xs_vec_mul_scalar(direction, kb_weapon_power[g_currentweapon[attacker]], direction);
	}*/

	static ducking;
	ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND);
	if (ducking) {
		static Float:kbDucking;
		kbDucking = g_pCvars[Value][KB_Ducking];
		if (kbDucking == 0.0) {
			return HAM_IGNORED;
		} else {
			xs_vec_mul_scalar(direction, kbDucking, direction);
		}
	}
	
	// Apply zombie class/nemesis knockback multiplier
	static eZombieClassData[ZombieClass];
	ArrayGetArray(g_aZombieClasses, g_zombieClass[Current][victim], eZombieClassData);
	xs_vec_mul_scalar(direction, eZombieClassData[Knockback], direction);
	
	// Add up the new vector
	xs_vec_add(velocity, direction, direction);
	
	// Should knockback also affect vertical velocity?
	if (!g_pCvars[Value][KB_ZVelocity]) {
		direction[2] = velocity[2];
	}
	
	// Set the knockback'd victim's velocity
	set_pev(victim, pev_velocity, direction);
	
	return HAM_IGNORED;
}

public zp_fw_class_file_register_tries() {
	formatDefaultClass();
	g_tZombieClassKeys = TrieCreate();
	for (new i; i < ZClassKeys; i++) {
		TrieSetCell(g_tZombieClassKeys, _zombieClassKeys[i], i);
	}
}

public zp_fw_class_file_read_key(const szClassName[], const szKey[], const szValue[]) {
	if (equal(szClassName[sizeof ZP_DefClassFileName], g_szTypeName)) {
		if (equal(szClassName, ZP_DefClassFileName, charsmax(ZP_DefClassFileName))) {
			static i;
			if (TrieGetCell(g_tZombieClassKeys, szKey, i)) {
				switch (i) {
					case ck_Claw: {
						static szTemp[64];
						formatex(szTemp, 63, g_szClawModelPath, szValue);
						if (!zp_core_precache_model(szTemp)) {
							zp_core_log_error("Invalid claw model specified (%s)", szValue);
							return;
						}
						
						copy(g_defaultZombieClass[Claw], 63, szTemp);
					}
					case ck_Knockback: {
						static Float:knockback;
						knockback = str_to_float(szValue);
						if (knockback < 0.0) {
							knockback = 0.0;
						}
						
						g_defaultZombieClass[Knockback] = _:knockback;
					}
				}
			}
		} else {
			static localid;
			if (!TrieGetCell(g_tClassNames, szClassName, localid)) {
				if (linkToZombieClass(szClassName, g_defaultZombieClass) == CLASS_NONE) {
					return;
				}
			}
			
			static i;
			if (TrieGetCell(g_tZombieClassKeys, szKey, i)) {
				static tempZombieClass[ZombieClass];
				ArrayGetArray(g_aZombieClasses, localid, tempZombieClass);
				switch (i) {
					case ck_Claw: {
						static szTemp[64];
						formatex(szTemp, 63, g_szClawModelPath, szValue);
						if (!zp_core_precache_model(szTemp)) {
							zp_core_log_error("Invalid claw model specified (%s)", szValue);
							return;
						}
						
						copy(tempZombieClass[Claw], 63, szTemp);
					}
					case ck_Knockback: {
						static Float:knockback;
						knockback = str_to_float(szValue);
						if (knockback < 0.0) {
							knockback = 0.0;
						}
						
						tempZombieClass[Knockback] = _:knockback;
					}
				}
				ArraySetArray(g_aZombieClasses, localid, tempZombieClass);
			} else if (equal(szClassName, _keyNames[ck_LocalID])) {
				zp_class_set_class_att(zp_class_get_class_by_name(szClassName), ZP_INT_localid, true, localid);
			}
		}
	}
}

public zp_fw_class_file_write_key(const szClassName[], file) {
	if (equal(szClassName[sizeof ZP_DefClassFileName], g_szTypeName)) {
		if (equal(szClassName, ZP_DefClassFileName, charsmax(ZP_DefClassFileName))) {
			fprintf(file, "^n^n; Default claw model for a zombie class^n");
			fprintf(file, "%s = %s", _zombieClassKeys[ck_Claw], ZOMBIE_DEFAULT_CLAW);
			fprintf(file, "^n^n; Default knockback for a zombie class^n");
			fprintf(file, "%s = %.2f", _zombieClassKeys[ck_Knockback], ZOMBIE_DEFAULT_KNOCKBACK);
		} else {
			static localid;
			localid = internalGetZombieClassLocalID(szClassName);
			if (localid == CLASS_NONE) {
				return;
			}
			
			static tempZombieClass[ZombieClass];
			ArrayGetArray(g_aZombieClasses, localid, tempZombieClass);
			
			fprintf(file, "^n^n; Claw model for this zombie^n");
			fprintf(file, "%s = %s", _zombieClassKeys[ck_Claw], tempZombieClass[Claw]);
			fprintf(file, "^n^n; Knockback for this zombie^n");
			fprintf(file, "%s = %.2f", _zombieClassKeys[ck_Knockback], tempZombieClass[Knockback]);
		}
	}
}

public zp_fw_core_infect(id) {
	static zombieClass[ZombieClass];
	if (is_user_bot(id)) {
		ArrayGetArray(g_aZombieClasses, random(sizeof g_zombieClassCount), zombieClass);
		zp_class_apply_class(id, zombieClass[GlobalID]);
	} else if (g_zombieClass[Current][id] == CLASS_NONE) {
		ArrayGetArray(g_aZombieClasses, 0, zombieClass);
		zp_class_apply_class(id, zombieClass[GlobalID]);
		_showZombieClassMenu(id);
	} else {
		zp_class_apply_class(id, g_zombieClass[Current][id]);
	}
	
	if (g_zombieClass[Current][id] == CLASS_NONE) {
		cs_set_player_view_model(id, CSW_KNIFE, g_szDefaultClawModel);
	} else {
		static zombieClassData[ZombieClass];
		ArrayGetArray(g_aZombieClasses, g_zombieClass[Current][id], zombieClassData);
		cs_set_player_view_model(id, CSW_KNIFE, zombieClassData[Claw]);
	}
	cs_set_player_weap_model(id, CSW_KNIFE, "");
}

public zp_fw_core_cure(id) {
	cs_reset_player_view_model(id, CSW_KNIFE);
	cs_reset_player_weap_model(id, CSW_KNIFE);
}

public zp_fw_class_selected(id, globalid) {
	g_zombieClass[Next][id] = globalid;
	if (g_zombieClass[Current][id] == CLASS_NONE) {
		g_zombieClass[Current][id] = globalid;
		zp_class_apply_class(id, globalid);
		zp_core_refresh(id);
	}
}

public bool:_showZombieClassMenu(id) {
	if (!is_user_connected(id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return false;
	}
	
	if (!is_user_zombie(id)) {
		//zp_core_log_error("Player is not a zombie (%d)", id);
		return false;
	}

	zp_class_show_class_menu(id, g_iZombieType, g_zombieClass[Next][id]);
	
	return true;
}

public _getUserZombieClass(id, bool:getNext) {
	if (!is_user_connected(id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return -1;
	}
	
	if (getNext) {
		return g_zombieClass[Next][id];
	}
	
	return g_zombieClass[Current][id];
}

public bool:_setNextZombieClass(id, localid) {
	if (!is_user_connected(id)) {
		zp_core_log_error("Invalid Player (%d)", id);
		return false;
	}
	
	if (localid < 0 || localid >= g_zombieClassCount) {
		zp_core_log_error("Invalid zombie class (%d)", localid);
		return false;
	}
	
	g_zombieClass[Next][id] = localid;
	return true;
}

public _registerZombieClass(iPlugin, iParams) {
	if (iParams < 2 || iParams > (ZombieParamOrder-1)) {
		return CLASS_NONE;
	}
	
	// Set basic information this class will need
	static tempClass[Class];
	arraycopy(tempClass, g_defaultClass, Class);
	
	tempClass[GroupID	] = get_param(zParam_group);
	if (!zp_class_is_valid_group(tempClass[GroupID])) {
		return CLASS_NONE;
	}
	
	tempClass[LocalID	] = g_zombieClassCount;
	
	
	// Cache strings from the parameters
	get_string(zParam_name, tempClass[ClassName], 31);
	get_string(zParam_desc, tempClass[ClassDesc], 31);
	
	static model[32];
	get_string(zParam_model, model, 31);
	
	// Set global class attributes
	tempClass[ModelID	] = zp_core_register_model(true, model);
	tempClass[AbilityList	] = _:ArrayCreate();
	
	// Attempt to register the class into the global system
	static tempZombieClass[ZombieClass];
	arraycopy(tempZombieClass, g_defaultZombieClass, ZombieClass);
	
	tempZombieClass[GlobalID] = zp_class_register_class(tempClass);
	
	// Check and see if the class failed to register
	if (tempZombieClass[GlobalID] == CLASS_NONE) {
		return CLASS_NONE;
	}
	
	// Load the strings from the parameters
	get_string(zParam_claw, tempZombieClass[Claw], 63);
	format(tempZombieClass[Claw], 63, g_szClawModelPath, tempZombieClass[Claw]);
	if (!zp_core_precache_model(tempZombieClass[Claw])) {
		zp_core_log_error("Failed to locate claw model ^"%s^", using default instead", tempZombieClass[Claw])
		copy(tempZombieClass[Claw], 63, g_szDefaultClawModel);
	}
	
	linkToZombieClass( tempClass[ClassName], tempZombieClass);
	
	return tempZombieClass[GlobalID];
}

linkToZombieClass(const szClassName[], tempZombieClass[ZombieClass]) {
	if (zp_class_get_class_by_name(szClassName) == CLASS_NONE) {
		zp_core_log_error("Registeration ordering error. Must register primary class before extension class. (%s)", szClassName);
		return CLASS_NONE;
	}
	
	static i;
	if (TrieGetCell(g_tClassNames, szClassName, i)) {
		ArraySetArray(g_aZombieClasses, i, tempZombieClass);
		return i;
	}
	
	ArrayPushArray(g_aZombieClasses, tempZombieClass);
	TrieSetCell(g_tClassNames, szClassName, g_zombieClassCount);
	
	g_zombieClassCount++;
	
	return (g_zombieClassCount-1);
}

public _registerZombieClassGroup(iPlugin, iParams) {
	if (iParams != 1) {
		zp_core_log_error("Invalid parameter number.  (Expected %d, Found %d)", 1, iParams);
		return CLASSGROUP_NONE;
	}
	
	static groupName[32];
	get_string(1, groupName, 31);
	return zp_class_register_group(g_iZombieType, groupName);
}

public _getZombieClassLocalID(iPlugin, iParams) {
	if(iParams != 1) {
		return CLASS_NONE;
	}

	new className[32];
	get_string(1, className, 31);
	return internalGetZombieClassLocalID(className);
}

internalGetZombieClassLocalID(const className[]) {
	new iClass;
	if (TrieGetCell(g_tClassNames, className, iClass)) {
		return iClass;
	}
		
	return CLASS_NONE;
}

public _getZombieClassGlobalID(localid) {
	if (localid < 0 || localid >= g_zombieClassCount) {
		zp_core_log_error("Invalid zombie class id (%d)", localid);
		return CLASS_NONE;
	}
	
	static tempZombieClass[ZombieClass];
	ArrayGetArray(g_aZombieClasses, localid, tempZombieClass);
	return tempZombieClass[GlobalID];
}

public _getZombieType() {
	return g_iZombieType;
}
