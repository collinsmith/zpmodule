#if defined _ZP_ClassModule_Human_C
	#endinput
#endif
#define _ZP_ClassModule_Human_C

#include <amxconst>

#define HUMAN_DEFAULT_HEALTH 100.0
#define HUMAN_DEFAULT_SPEED 220.0
#define HUMAN_DEFAULT_GRAVITY 1.0
#define HUMAN_DEFAULT_EXP 0
#define HUMAN_DEFAULT_ADMIN ADMIN_ALL
#define HUMAN_DEFAULT_MODEL ""
#define HUMAN_DEFAULT_PRIMARY ""
#define HUMAN_DEFAULT_SECONDARY ""
#define HUMAN_DEFAULT_GRENADES "a"

enum _:eHumanClassInfo {
	GlobalID,
	Primary,
	Secondary,
	Grenades
}

enum _:eHumanParamOrder {
	hParam_name = 1,
	hParam_desc,
	hParam_model,
	hParam_primary,
	hParam_secondary,
	hParam_grenades
}

enum _:ZPWeapons_Grenades ( <<=1 ) {
	ZP_HEGRENADE = 1,
	ZP_SMOKEGRENADE,
	ZP_FLASHBANG,
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
