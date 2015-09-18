#if defined _ZP_VarManager_Included
	#endinput
#endif
#define _ZP_VarManager_Included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_VarManager
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_VarManager
	#endif
#else
	#pragma library ZP_VarManager
#endif

#include <ZP_VarManager_Const>

/**
 * Called whenever a plugin requests a field value from another plugin.
 * 
 * @param id		The player index to retrieve the information from.
 * @param field		The field of which to retrieve the data (located in
 * 			the {@link ZP_VarManager_Const.ZPData} enum).
 * @return		The value the player is requesting.
 */
forward zp_fw_varmanager_get(id, field);

/**
 * Called whenever a plugin requests a field value from another plugin to
 * be changed.
 * 
 * @param id		The player index to change the information.
 * @param field		The field of which to change the data (located in
 * 			the {@link ZP_VarManager_Const.ZPData} enum).
 * @param value		The amount to change the data to.
 * @param string	The string value of the change (if the field takes
 * 			a string.
 * @return		The value the player is requesting (after change).
 */
forward zp_fw_varmanager_set(id, field, any:value, const string[]);

/**
 * Retrieves a specific player field from another plugin in the ZP plugin
 * family.
 * 
 * @param id		The player index to retrieve the information from.
 * @param field		The field of which to retrieve the data (located in
 * 			the {@link ZP_VarManager_Const.ZPData} enum).
 * @return		The information requested.
 * 
 * @see below
 */
native zp_get(id, field, any:...);

/**
 * Retrieves a specific player field from another plugin in the ZP plugin
 * family.
 * 
 * @param id		The player index to retrieve the information from.
 * @param field		The field of which to retrieve the data (located in
 * 			the {@link ZP_VarManager_Const.ZPData} enum).
 * @return		The information requested.
 * 
 * @see below
 */
native zp_set(id, field, any:...);

/**
 * Proper usage of zp_set and zp_get
 * 
 * new Float:health = Float:zp_get(id, ZP_FL_health);
 * 
 * new Float:health;
 * zp_get(id, ZP_FL_health, health);
 * 
 * new Float:health = zp_set(id, ZP_FL_health, 120.0);
 * client_print(id, print_chat, "You're health is now %.1f", health);
 * --> Your health is now 120.0
 * 
 * new class_description[32];
 * zp_get(id, ZP_SZ_desc, class_description, 31);
 * 
 * // Even though you're not allowed to do this
 * zp_set(id, ZP_SZ_desc, "I've changed it!");
 */
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
