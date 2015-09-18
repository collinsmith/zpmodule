#if defined _ZP_Log
	#endinput
#endif
#define _ZP_Log

#include <amxmodx>
#include <amxmisc>

/**
 * This is used to log ZP-specific information/errors into a
 * location where it is separate from other messages.
 **/
stock zp_log(message[], any:...) {
	static message_fmt[256], filename[96], dir[64];
	vformat(message_fmt, 255, message, 2);
	if(!dir[0]) {
		get_basedir(dir, sizeof(dir) - 1);
	}
	
	format_time(filename, 95, "%Y%m%d");
	format(filename, 95, "%s/logs/ZombiePlague_%s.log", dir, filename);
	log_to_file(filename, "%s", message_fmt);
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
