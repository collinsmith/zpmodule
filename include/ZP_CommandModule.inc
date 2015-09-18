#if defined _ZP_CommandModule
	#endinput
#endif
#define _ZP_CommandModule

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_CommandModule
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_CommandModule
	#endif
#else
	#pragma library ZP_CommandModule
#endif

/**
 * Forwarded when a command is determined valid and should be sent.  At
 * this time, returning PLUGIN_HANDLED will prevent that command from
 * executing.
 *
 * @note cid		This value can be retrieved when registering a
 *			command, or by using 
 *			{@link zp_get_cid_by_name(const command[])}
 *
 * @param id		The player index forwarding this event.
 * @param cid		The function command index that is being executed.
 */
forward zp_fw_command_pre(id, cid);

/**
 * Forwarded when a command is sent to a player.
 *
 * @note cid		This value can be retrieved when registering a
 *			command, or by using 
 *			{@link zp_get_cid_by_name(const command[])}
 *
 * @param id		The player index forwarding this event.
 * @param cid		The function command index that is being executed.
 */
forward zp_fw_command_post(id, cid);

/**
 * Native used to register a new command into the ZP command
 * structure.  Once a handle is registered once, you need only register
 * any commands under that same handle again since the flags and 
 * description will not (and should not) need to change.
 *
 * @example: To register a new command with 1 variation
 *		zp_register_command("mycommand1", "forwardMyCommand", "abcdef", "An example command");
 *		zp_register_command("mycommand2", "forwardMyCommand");
 *
 * @note flags:	a - Execute only on say all
 *		b - Execute only on say_team
 *		c - Execute only if zombie
 *		d - Execute only if human
 *		e - Execute only if alive
 *		f - Execute only if dead
 *
 * @note return >=0 cid of the command
 *		 -1 Command already exists with this name
 *		 -2 Handle could not be found
 *
 * @param command	The words that will execute the given handle.
 * @param handle	The name of the PUBLIC function to execute when 
 *			the command is entered successfully.
 * @param flags		The flags describing the conditions under which
 *			this command will be executed.
 * @param description	A brief description to the purpose of this command.
 * @return		The cid (command id) of the function tied to this 
 *			command.
 */
native zp_command_register(const command[], const handle[], const flags[] = "abcdef", const description[] = "");

/**
 * Native used to retrieve the function id that this command is tied to.
 *
 * @param command	The command to get the cid from.  This would be
 * 			a command used ingame, such as "cmdlist" or
 * 			"commands".
 * @return		The cid of this function, -1 if no function found.
 */
native zp_command_get_cid_by_name(const command[]);
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
