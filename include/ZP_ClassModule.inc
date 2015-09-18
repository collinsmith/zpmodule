#if defined _ZP_ClassModule
	#endinput
#endif
#define _ZP_ClassModule

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_ClassModule
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_ClassModule
	#endif
#else
	#pragma library ZP_ClassModule
#endif

#include <ZP_Log>
#include <ZP_VarManager_Const>
#include <ZP_ClassModule_Const>

/**
 * Called after models can be registered, and directly after classes
 * can be registered. During this time, classes can be registered, but
 * it is suggested to register them during the post event, because this
 * is where any classes loaded from files should be created.
 */
forward zp_fw_class_data_struc_init_pre();

/**
 * Called after models can be registered, and directly after classes
 * can be registered.  Any classes created with plugins should be registered
 * during this time, as attributes to these classes will be applied
 * correctly.
 */
forward zp_fw_class_data_struc_init_pos();

/**
 * Executed when a player selects a class from a class menu.
 * 
 * @param id		The player index who selected the class.
 * @param class		The global class id selected.
 */
forward zp_fw_class_selected(id, class);

/**
 * Executed whenever the class module needs to query how much arbitrary
 * experience a player has.  This can be any integer value from any
 * type of experience.
 * 
 * @param id		The player index that the plugin needs the xp for.
 * @return		The amount of experience this player has.
 */
forward zp_fw_class_get_exp(id);

/**
 * Executed whenever a class is applied to a user.  This forward cannot
 * be blocked, but is a good time to apply any special attributes a class
 * type might have, such as zombie claws or human weapons.
 *
 * @param id		The player index forwarding the event.
 * @param globalid	The global class index being applied.
 */
forward zp_fw_class_applied(id, globalid);

/**
 * Registers a new class type into the class system.  Each class type
 * should have a series of groups registered under it.  Each class
 * type name must be unique, and this name will appear in the menu
 * as follows "%NAME%'s Group Menu".
 * 
 * @param isZombieTeam	True to register this class as a zombie only
 * 			class, false otherwise.
 * @param typename	The name of the class type.
 * @param (opt)		The default class to base any class who lacks
 * 			specific stats from.
 * @return		The TypeID for this class type, or the TypeID
 * 			for the class type of this name.
 */
native zp_class_register_type(bool:isZombieTeam, const typename[], const defaultClass[Class]);
native zp_class_register_type2(bool:isZombieTeam, const typename[]);

/**
 * Registers a new group of class into the class system.  Each class
 * group is a series of classes that have similarities, or likenesses
 * with one another.
 *
 * @param type		The type that this group will be bound to.
 * @param groupname	The name of this class group.
 * @return		The GroupID for this class group, or the
 * 			GroupID for the class group of this name.
 */
native zp_class_register_group(type, const groupname[]);

/**
 * Registers a new class into the type heiarchy.  This class will
 * only appear under that class type.
 * 
 * @param newClassData	An enumerated array containing all information
 * 			needed to form a class.  Make sure that all
 * 			information here is valid.
 */
native zp_class_register_class(newClassData[Class]);

/**
 * Returns the global class id of a class by using the name of that
 * class.
 * 
 * @param classname	The name of the class to check.
 * @return		The global class id for the class, -1 if
 * 			no class is found.
 */
native zp_class_get_class_by_name(const classname[]);

/**
 * Returns the group id of a group using its' name.
 * 
 * @param groupname	The name of the group to check.
 * @return		The group id for the group, -1 if
 * 			no group is found.
 */
native zp_class_get_group_by_name(const groupname[]);

/**
 * Returns the type id of a class type by using the name of that
 * class type.
 * 
 * @param typename	The name of the type to check.
 * @return		The type id for the class type, -1 if
 * 			no class type is found.
 */
native zp_class_get_type_by_name(const typename[]);

/**
 * Returns an Array: containing all classes registered inside of the
 * class module.  This should only be used to help get information for
 * all classes when it is necessary.
 * 
 * @return		An Array: of all classes.
 */
native Array:zp_class_get_class_array();

/**
 * Returns an Array: containing all groups registered inside of
 * the class module.  This should only be used to help get information
 * for all groups when it is necessary.
 * 
 * @return		An Array: of all groups.
 */
native Array:zp_class_get_group_array();

/**
 * Returns an Array: containing all class types registered inside of
 * the class module.  This should only be used to help get information
 * for all class types when it is necessary.
 * 
 * @return		An Array: of all class types.
 */
native Array:zp_class_get_type_array();

/**
 * Displays a menu to a given player displaying all classes registered
 * under the given class type id.
 * 
 * @note		If no classes have been registered, this
 * 			will obviously not work.
 * 
 * @param id		The player index to display the menu to.
 * @param nextclass	The next class (globalid) that a user has selected in order to grey out that class.
 * @param type		The class type to display.
 * @param group		The class group to display.
 */
native zp_class_show_class_menu(id, nextclass, type = CLASSTYPE_NONE, group = CLASSGROUP_NONE);

/**
 * Applies a given class to a player immediatly.  This will update
 * all information such as health, speed, gravity and model on a
 * user.
 * 
 * @param id		The player index to apply the class to.
 * @param globalid	The global class index to apply.
 */
native zp_class_apply_class(id, globalid);

/**
 * Returns the global class id that is currently applied to a user.
 * 
 * @param id		The player index to retrieve the class from.
 * @return		The global class id that this player is
 * 			currently using. CLASS_NONE if this player
 * 			has no valid class applied.
 */
native zp_class_get_user_globalid(id);

/**
 * Returns whether a specific class type is valid
 * 
 * @param type		The typeid of the class type to check
 * @return		True if the class type is valid, false otherwise.
 */
native zp_class_is_valid_type(type);

/**
 * Returns whether a specific class group is valid
 * 
 * @param group		The groupid of the class group to check
 * @return		True if the class group is valid, false otherwise.
 */
native zp_class_is_valid_group(group);

/**
 * Returns whether a specific class is valid
 * 
 * @param class		The class id of the class to check
 * @return		True if the class is valid, false otherwise.
 */
native zp_class_is_valid_class(class);

/**
 * Retrieves an attribute from a class using the classes id. Formatted
 * like the fakemeta pev() native.
 * 
 * @note		The valid fields to be returned are:
 * 			ZP_INT_groupid		Class group id
 * 			ZP_INT_localid		Local id for this class
 * 			ZP_INT_modelid		Model id for this class
 * 			ZP_INT_xpreq		The required experience
 * 			ZP_INT_adminlevel	The admin requirement
 * 			ZP_INT_curnumber	The current number of people using this class
 * 			ZP_INT_maxnumber	The maximum number of people that can use this class
 * 			ZP_FL_health		The health of this class
 * 			ZP_FL_speed		The speed of this class
 * 			ZP_FL_gravity		The gravity of this class
 * 			ZP_SZ_name		The name for this class
 * 			ZP_SZ_desc		The description for this class
 * 
 * @param class		The class to look up.
 * @param field		The attribute to query (see above).
 * @param (opt)		The location to place the return value into.
 * @param (opt)		The length of the string to return (if string field).
 * @return		The value of the attribute.
 */
native zp_class_get_class_att(class, field, any:...);

/**
 * Sets an attribute in a class using the classes id. Formatted
 * like the fakemeta set_pev() native.
 * 
 * @note		The valid fields to be changed are:
 * 			ZP_INT_localid		Local id for this class
 * 			ZP_INT_modelid		Model id for this class
 * 			ZP_INT_xpreq		The required experience
 * 			ZP_INT_adminlevel	The admin requirement
 * 			ZP_INT_curnumber	The current number of people using this class
 * 			ZP_INT_maxnumber	The maximum number of people that can use this class
 * 			ZP_FL_health		The health of this class
 * 			ZP_FL_speed		The speed of this class
 * 			ZP_FL_gravity		The gravity of this class
 * 			ZP_SZ_desc		The description for this class
 * 
 * @param class		The class to change.
 * @param field		The attribute to change (see above).
 * @param forceValue	True to override any current value, false to only
 * 			override the default setting for this class of this type.
 * @param (opt)		The new value for this field.
 * @return		The value of the attribute.
 */
native zp_class_set_class_att(class, field, bool:forceValue = false, any:...);

/**
 * Sets the default class for a given type.  These are the settings
 * that are automatically applied to a class created without such
 * settings.
 * 
 * @param type		The class type to apply the default class to
 * @param defaultClass	The default class with the default settings
 */
native zp_class_set_def_class_type(type, defaultClass[Class]);

/**
 * Needs documentation
 */
native zp_class_register_ability(const name[], const desc[] = "");
native zp_class_is_valid_ability(ability);
native zp_class_get_ability_by_name(const ability[]);
//-1 = invalid, 0 = no change, 1 = ability added
native zp_class_add_ability(class, ability);
native zp_class_rem_ability(class, ability);
native zp_class_get_ability_array(class, ability);
//returns array
native zp_class_get_ability_name(ability);
//-1 = invalid, 0+ = internal id
native zp_class_class_has_ability(class, ability);
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
