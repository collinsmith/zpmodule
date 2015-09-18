#if defined _ZP_GunModule
#endinput
#endif
#define _ZP_GunModule

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_GunModule
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_GunModule
	#endif
#else
	#pragma library ZP_GunModule
#endif

#include <ZP_GunModule_Const>
#include <flags32>

forward zp_guns_menu_shown_pre(id, flags[], menuName[]);
forward zp_guns_menu_shown_post(id, const flags[], const menuName);
forward zp_guns_gun_given(id, csw);

native zp_show_guns_menu(id, const szFlags[], const szMenuName[] = "Weapon Menu");

stock zp_show_guns_menu_bits(id, weaponBits, const szMenuName[] = "Weapon Menu") {
	static szTemp[33];
	get_flags32(weaponBits, szTemp, 32);
	zp_show_guns_menu(id, szTemp, szMenuName);
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
