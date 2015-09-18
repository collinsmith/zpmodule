#if defined _ZP_ClassModule_C
	#endinput
#endif
#define _ZP_ClassModule_C

#define CLASSTYPE_NONE -1
#define CLASSGROUP_NONE -1
#define CLASS_NONE -1
#define ABILITY_NONE -1

/**
 * Enumerated constants representing the types of information
 * a classtype module might store.
 * 
 * @Current		The current class of a user.
 * @Next		The next class of a user.
 */
enum _:ClassManager {
	Current = 0,
	Next
};

enum _:ParamClass {
	ParamClass_groupid = 1,
	ParamClass_localid,
	ParamClass_name,
	ParamClass_desc,
	ParamClass_health,
	ParamClass_speed,
	ParamClass_gravity,
	ParamClass_xpreq,
	ParamClass_model
};

enum _:Class {
	GroupID,
	LocalID,
	ClassName[32],
	ClassDesc[32],
	ModelID,
	Float:Health,
	Float:Speed,
	Float:Gravity,
	Array:AbilityList,
	XPReq,
	AdminLevel,
	CurNumber,
	MaxNumber
};

enum _:ParamClassGroup {
	ParamClassGroup_typeid = 1,
	ParamClassGroup_name
}

enum _:ClassGroup {
	TypeID,			// Type this is tied to
	GroupName[32],		// Name of group "Standard Zombies"
	Array:ClassList		// List of all class IDs { 1, 4, 5, 7 }
};

enum _:ParamClassType {
	ParamClassType_teamid = 1,
	ParamClassType_name,
	ParamClassType_defclass
}

enum _:ClassType {
	bool:TeamID,		// Whether this is a zombie team type or not
	TypeName[32],		// Name of type "Zombies"
	Array:GroupList,	// List of all group IDs { 0, 2, 3 }
	DefaultClass[Class]	// Default stats for a class of this type are here
};

enum _:ParamClassAbility {
	ParamClassAbility_name = 1,
	ParamClassAbility_desc
}

enum _:ClassAbility {
	AbilityName[32],
	AbilityDesc[64]
};

enum _:ClassKeys {
	ck_GroupID,
	ck_LocalID,
	ck_Name,
	ck_Desc,
	ck_ModelID,
	ck_Health,
	ck_Speed,
	ck_Gravity,
	ck_Abilities,
	ck_XPReq,
	ck_AdminLevel,
	ck_CurNumber,
	ck_MaxNumber
}

stock const _keyNames[ClassKeys][] = {
	"GROUPID",
	"LOCALID",
	"NAME",
	"DESCRIPTION",
	"MODEL",
	"HEALTH",
	"SPEED",
	"GRAVITY",
	"ABILITIES",
	"XP REQ",
	"ADMIN FLAGS",
	"CUR NUM",
	"MAX NUM"
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
