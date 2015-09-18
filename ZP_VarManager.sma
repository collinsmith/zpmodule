/**
 * This plugin is used to create a system similar to the fakemeta
 * pev/set_pev methods for controlling information between plugins.
 * This is useful for changing basic player-related information, or
 * retrieving it whenever needbe, and also to add new material with
 * relative ease.  There is a major drawback to this system though,
 * it is relativly slow, and plugins determine what kind of support
 * should be provided.  Be very careful when modifying strings, such
 * as modelnames which should only be handled by the core engine.
 */
#include <amxmodx>
#include <ZP_Core>
#include <ZP_VarManager_Const>

new const Plugin [] = "ZP Variable Manager";
new const Version[] = "0.0.1";
new const Author [] = "Tirant";

/**
 * Enumerated constants representing the various forwards
 * that this plugin sends.
 */
enum ForwardedEvents {
	fwDummy = 0,
	fwGet,
	fwSet
};

/**
 * An array of forwards created from the list located
 * at {@link ForwardedEvents}
 */
new g_Forwards[ForwardedEvents];

/**
 * String used to help transfer string information between plugins.
 */
static g_szReturn[128];

public plugin_init() {
	register_plugin(Plugin, Version, Author)
	
	/* Forwards */
	/// Called when a plugin requests information from another. Cannot be stopped.
	g_Forwards[fwGet] = CreateMultiForward("zp_fw_varmanager_get", ET_IGNORE, FP_CELL, FP_CELL);
	/// Called when a plugin requests to change information from another. Cannot be stopped.
	g_Forwards[fwSet] = CreateMultiForward("zp_fw_varmanager_set", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING);
}

public plugin_natives() {
	register_library("ZP_VarManager");
	
	register_native("zp_get",			"_zpGet",		 0);
	register_native("zp_set",			"_zpSet",		 0);
	register_native("zp_varmanager_set_ret_string",	"_setReturnString",	 0);
}

/**
 * @see ZP_VarManager.inc
 */
public bool:_setReturnString(iPlugin, iParams) {
	if(iParams != 2) {
		zp_core_log_error("Invalid parameter number. (Expected %d, Found %d)", 2, iParams);
		return false;
	}
	
	get_string(1, g_szReturn, get_param(2));
	
	return true;
}

/**
 * @see ZP_VarManager.inc
 */
public _zpGet(iPlugin, iParams) {
	static retValue;
	switch (get_param(2)) {
		// Integer
		case 0.._zp_last_int: {
			ExecuteForward(g_Forwards[fwGet], retValue, get_param(1));
			set_param_byref(3, retValue);
			return retValue;
		}
		// Floating point
		case _zp_first_float.._zp_last_float: {
			ExecuteForward(g_Forwards[fwGet], retValue, get_param(1));
			set_param_byref(3, retValue);
			return retValue;
		}
		// String
		case _zp_first_string.._zp_last_string: {
			ExecuteForward(g_Forwards[fwGet], retValue, get_param(1));
			set_string(3, g_szReturn, get_param(4));
		}
	}
	
	return -1;
}

/**
 * @see ZP_VarManager.inc
 */
public _zpSet(iPlugin, iParams) {
	static retValue;
	switch (get_param(2)) {
		// Integer
		case 0.._zp_last_int: {
			ExecuteForward(g_Forwards[fwSet], retValue, get_param(1), get_param_byref(3), "");
			return retValue;
		}
		// Floating point
		case _zp_first_float.._zp_last_float: {
			ExecuteForward(g_Forwards[fwSet], retValue, get_param(1), get_param_byref(3), "");
			return retValue;
		}
		// String
		case _zp_first_string.._zp_last_string: {
			ExecuteForward(g_Forwards[fwSet], retValue, get_param(1), 0, g_szReturn);
		}
	}
	
	return -1;
}
