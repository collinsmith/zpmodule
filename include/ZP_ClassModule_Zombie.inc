#if defined _ZP_ClassModule_Zombie
	#endinput
#endif
#define _ZP_ClassModule_Zombie

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_ClassModule_Zombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_ClassModule_Zombie
	#endif
#else
	#pragma library ZP_ClassModule_Zombie
#endif

#include <ZP_ClassModule>
#include <ZP_ClassModule_Zombie_Const>

forward zp_fw_class_zombie_register();

native zp_class_zombie_get_current(id, bool:getNextClass = false);

native zp_class_zombie_set_next(id, globalid);

native zp_class_zombie_show_menu(id);

native zp_class_zombie_register(group, const name[], const desc[], const model[] = ZOMBIE_DEFAULT_MODEL, const clawmodel[] = ZOMBIE_DEFAULT_CLAW);

native zp_class_zombie_register_group(const groupname[]);

native zp_class_zombie_get_localid(const classname[]);

native zp_class_zombie_get_globalid(localid);

native zp_class_zombie_get_typeid()
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
