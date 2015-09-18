#if defined _ZP_ClassModule_Human
	#endinput
#endif
#define _ZP_ClassModule_Human

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_ClassModule_Human
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_ClassModule_Human
	#endif
#else
	#pragma library ZP_ClassModule_Human
#endif

#include <ZP_ClassModule>
#include <ZP_ClassModule_Human_Const>

native zp_class_human_get_current(id, bool:getNextClass = false);

native zp_class_human_set_next(id, globalid);

native zp_class_human_show_menu(id);

native zp_class_human_register(const name[], const desc[], const model[] = HUMAN_DEFAULT_MODEL, ZPWeapons_Primary:primary = HUMAN_DEFAULT_PRIMARY, ZPWeapons_Secondary:secondary = HUMAN_DEFAULT_SECONDARY, const grenades[] = HUMAN_DEFAULT_GRENADES);

native zp_class_human_get_localid(const classname[]);

native zp_class_human_get_globalid(localid);

native zp_class_human_get_typeid()