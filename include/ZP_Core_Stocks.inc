#if defined _ZP_Core_S
#endinput
#endif
#define _ZP_Core_S

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <colorchat>

#include <ZP_Core_Const>
#include <ZP_Log>

/**
 * Used to precache a player model file. This stock will format a model
 * name as the correct file location before returning the 
 * {@link zp_core_precache_model(file)} value of the precache.
 * 
 * @param model		The name of the model to precache
 * 			(gign, gsg9, urban, terror, classic, etc).
 * @return		True if the file is precached, false otherwise.
 */
stock bool:zp_core_precache_player_model(model[]) {
	static temp[64];
	formatex(temp, 63, "models/player/%s/%s.mdl", model, model);
	
	return zp_core_precache(temp);
}

/**
 * Used to precache a model file.
 * 
 * @param model		The path of the model to precache.
 * @return		True if the file is precached, false otherwise.
 */
stock bool:zp_core_precache_model(model[]) {
	if (file_exists(model)) {
		engfunc(EngFunc_PrecacheModel, model);
		return true;
	}
	
	zp_core_log_error("Invalid file/path specified (^"%s^")", model);
	return false;
}

/**
 * Used to precache a sound file. This stock will format a sound
 * name as the correct file location before returning the 
 * {@link zp_core_precache(file)} value of the precache.
 * 
 * @param sound		The name of the sound to precache
 * @return		True if the file is precached, false otherwise.
 */
stock bool:zp_core_precache_sound(sound[]) {
	static temp[64];
	formatex(temp, 63, "sound/%s", sound);
	
	return zp_core_precache(temp);
}

/**
 * Used to check whether or not a file exists before attempting to
 * precache that file.  If a file does not exist, it is logged and
 * caught to not crash the server.
 * 
 * @note		The file path should include the folder type
 * 			models, sound, sprites, etc.
 * 
 * @param file		The file (with path/extension) to precache.
 * @return		True if successful, false otherwise.
 */
stock bool:zp_core_precache(file[]) {
	if (file_exists(file)) {
		engfunc(EngFunc_PrecacheGeneric, file);
		return true;
	}
	
	zp_core_log_error("Invalid file/path specified (^"%s^")", file);
	return false;
}

/**
 * Logs an error into the core mod. This error will show up in the amxx
 * logs, as well as in the ZP logs. Should only be used when reporting
 * a native error.
 * 
 * @param error		The message to display in the log.
 */
stock zp_core_log_error(error[], any:...) {
	static numArguments;
	numArguments = numargs();
	
	if (numArguments == 1) {
		sendErrorMessage(error);
	} else {
		static buffer[128];
		vformat(buffer, 127, error, 2);
		sendErrorMessage(buffer);
	}
}

/**
 * Actually sends the error messages.
 * 
 * @param error		The formatted error message to log.
 */
static stock sendErrorMessage(error[]) {
	zp_log(error);
	log_error(AMX_ERR_NATIVE, "%s %s", ZP_Pre, error);
}

stock zp_print_color(id, szMsg[], any:...) {
	static numArguments;
	numArguments = numargs();
	
	if (numArguments == 2) {
		client_print_color(id, DontChange, "%s %s", ZP_PreFormat, szMsg);
	} else {
		static buffer[192];
		vformat(buffer, 191, szMsg, 3);
		client_print_color(id, DontChange, "%s %s", ZP_PreFormat, buffer);
	}
}

stock zp_get_homefolder(output[], len) {
	get_configsdir(output, len);
	add(output, len, ZP_HomeFolder);
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
