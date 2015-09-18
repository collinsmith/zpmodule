#include <amxmodx>
#include <cvar_util>
#include <colorchat>
#include <ZP_Core>
#include <ZP_CommandModule>

static const Plugin [] = "ZP Command Module";
static const Version[] = "0.0.1";
static const Author [] = "Tirant";

/**
 * Enumerated constants representing everything that a function needs
 * in order to act as a command.
 */
enum _:eFunctionInfo {
	Name[32],
	Desc[64],
	PluginID,
	FuncID,
	Flags
}

/**
 * Array object storing all functions registered when creating a new
 * command.  When two commands are registered that target the same
 * function, then the second command is thrown out and a pointer is
 * given to the first version of the command in order to help save
 * some memory.
 */
static Array:g_aFunctions;

/**
 * Trie storing all commands that are used within this plugin.  Each
 * command is stored in lower case, and their cell contain the index
 * of the function handle tied with this command.
 */
static Trie:g_tCommands;

/**
 * Array object storing trie structures for every plugin registered.
 * There is a separate trie for each plugin in order to ensure that
 * each function is unique and two functions with the same name, but
 * in separate plugins do not conflict.  Data is added to these tries
 * only when a new command is registered.
 */
static Array:g_aFunctionNames;

/**
 * Integer value representing the total number of functions registered
 * in this plugin.
 */
static g_functionNum;

/**
 * Enumerated constants representing the different bits associated with
 * a given flag.  These bits are checked when a command is said, in
 * order to determins whether or not to forward the command's handle.
 */
enum _:eSayBits ( <<=1 )
{
	SAY_ALL = 1,
	SAY_TEAM,
	ZOMBIE_ONLY,
	HUMAN_ONLY,
	ALIVE_ONLY,
	DEAD_ONLY
}

/**
 * Trie storing all command prefixes that preceed each command.
 */
static Trie:g_tPrefixes;

/**
 * String that stores a cached HTML format for the initial header of
 * the command list motd.  This is recached whenever the command
 * prefixes change.
 */
static g_szCommandListMotD[256];

/**
 * String that stores a cached HTML format table for all commands
 * registered with this plugin.  The command displayed is the first
 * version of that command registered.  This is appended when a
 * newfunction is registered.
 */
static g_szCommandTable[1792];

/**
 * String that stores a cached version of all commands registered
 * with this plugin.  This is used whenever a client requests to
 * see the command list.  This is appended when a new function is
 * registered.
 */
static g_szCommandList[160];

/**
 * Cvar pointer that points to the Cvar that controls which symbols
 * should preceed commands.
 */
static g_pcvar_prefix;

/**
 * Enumerated constants representing the various forwards this
 * plugin executes.
 */
enum eForwardedEvents
{
	fwDummy = 0,
	fwCommandEnteredPre,
	fwCommandEnteredPost
}

/**
 * An array of fields containing values for all enumerated constants
 * located in {@link eForwardedEvents}.  These values are assigned
 * forward pointers and executed addordingly.
 */
static g_Forwards[eForwardedEvents];

public plugin_precache() {
	g_aFunctions = ArrayCreate(eFunctionInfo);

	g_aFunctionNames = ArrayCreate(1);
	for (new i; i < get_pluginsnum(); i++) {
		new Trie:tempTrie = TrieCreate();
		ArrayPushCell(g_aFunctionNames, tempTrie);
	}
	
	g_tCommands = TrieCreate();
	g_tPrefixes = TrieCreate();
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	register_clcmd("say",	   "cmdSay");
	register_clcmd("say_team", "cmdSayTeam");
	
	g_pcvar_prefix = CvarRegister("zp_command_prefixes", "/.!", "A list of all symbols that preceed commands");
	CvarHookChange(g_pcvar_prefix, "hookPrefixesAltered");
	
	static szPrefixes[32], c[2], i;
	get_pcvar_string(g_pcvar_prefix, szPrefixes, 31);
	while (szPrefixes[i] != '^0') {
		c[0] = szPrefixes[i];
		TrieSetCell(g_tPrefixes, c, i);
		i++;
	}
	
	refreshCommandMotD();
	constructCommandTable();

	zp_command_register("commands", "displayCommandList", "abcdef", "Displays a printed list of all commands");
	zp_command_register("cmds", "displayCommandList");
	
	zp_command_register("commandlist", "displayCommandMotD", "abcdef", "Displays a detailed list of all commands");
	zp_command_register("cmdlist", "displayCommandMotD");
	
	/* Forwards */
	/// Executed before a command function is executed. Can be stopped.
	g_Forwards[fwCommandEnteredPre	] = CreateMultiForward("zp_command_pre", ET_STOP, FP_CELL, FP_CELL);
	/// Executed after a command function is executed. Can't be stopped.
	g_Forwards[fwCommandEnteredPost	] = CreateMultiForward("zp_command_post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives() {
	register_library("ZP_CommandModule");
	
	register_native("zp_command_register", "_registerCommand", 0);
	register_native("zp_command_get_cid_by_name", "_getCIDByName", 0);
}

public hookPrefixesAltered(handleCvar, const oldValue[], const newValue[], const cvarName[]) {
	TrieClear(g_tPrefixes);
	
	static i;
	while (newValue[i] != '^0') {
		TrieSetCell(g_tPrefixes, newValue[i], i);
		i++;
	}
	
	refreshCommandMotD();
}

public cmdSay(id) {
	new szMessage[32];
	read_args(szMessage, 31);
	forwardCommand(id, false, szMessage);
}

public cmdSayTeam(id) {
	new szMessage[32];
	read_args(szMessage, 31);
	forwardCommand(id, true, szMessage);
}

/**
 * Private method used to help simplify checking of a command
 * to see if it is used with a correct prefix.
 *
 * @param id		The player index who entered the command.
 * @param teamCommand	True if it is a team command, false otherwise.
 * @param message	The message being sent.
 */
forwardCommand(id, bool:teamCommand, message[]) {
	if (!is_user_connected(id)) {
		return PLUGIN_HANDLED;
	}
	
	strtolower(message);
	remove_quotes(message);
	
	static szTemp[2], i;
	szTemp[0] = message[0];
	if (!TrieGetCell(g_tPrefixes, szTemp, i)) {
		return PLUGIN_CONTINUE;
	}
	
	if (TrieGetCell(g_tCommands, message[1], i)) {
		executeCommand(i, id, teamCommand);
	}
	
	return PLUGIN_CONTINUE;
}

/**
 * Private method which takes a successful command and determines
 * whether or not the cirsumstances under which is was entered
 * obey the flags for the function tied into this command.
 *
 * @param cid		The unique command id to execute.
 * @param id		The player index to execute the command onto.
 * @param teamCommand	True if it is a team command, false otherwise.
 */
executeCommand(cid, id, bool:teamCommand) {
	static commandData[eFunctionInfo];
	ArrayGetArray(g_aFunctions, cid, commandData);

	if (!(commandData[Flags]&(SAY_ALL)) && !(commandData[Flags]&(SAY_TEAM))) {
		return PLUGIN_CONTINUE;
	} else if (!teamCommand && (commandData[Flags]&(SAY_TEAM)) && !(commandData[Flags]&(SAY_ALL))) {
		return PLUGIN_CONTINUE;
	} else if (teamCommand && (commandData[Flags]&(SAY_ALL)) && !(commandData[Flags]&(SAY_TEAM))) {
		return PLUGIN_CONTINUE;
	}

	static isZombie;
	isZombie = is_user_zombie(id);
	if (!(commandData[Flags]&(ZOMBIE_ONLY)) && !(commandData[Flags]&(HUMAN_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if (!isZombie && (commandData[Flags]&(HUMAN_ONLY)) && !(commandData[Flags]&(ZOMBIE_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if (isZombie && (commandData[Flags]&(ZOMBIE_ONLY)) && !(commandData[Flags]&(HUMAN_ONLY))) {
		return PLUGIN_CONTINUE;
	}

	static isAlive;
	isAlive = is_user_alive(id);
	if (!(commandData[Flags]&(ALIVE_ONLY)) && !(commandData[Flags]&(DEAD_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if (!isAlive && (commandData[Flags]&(DEAD_ONLY)) && !(commandData[Flags]&(ALIVE_ONLY))) {
		return PLUGIN_CONTINUE;
	} else if (isAlive && (commandData[Flags]&(ALIVE_ONLY)) && !(commandData[Flags]&(DEAD_ONLY))) {
		return PLUGIN_CONTINUE;
	}
	
	ExecuteForward(g_Forwards[fwCommandEnteredPre], g_Forwards[fwDummy], id, cid);
	
	callfunc_begin_i(commandData[FuncID], commandData[PluginID]); {
	callfunc_push_int(id);
	} callfunc_end();
	
	ExecuteForward(g_Forwards[fwCommandEnteredPost], g_Forwards[fwDummy], id, cid);
	
	return PLUGIN_CONTINUE;
}

/**
 * Public method used to display all initial command tied in with a function.
 * This method will not display duplicate commands tied into a single function.
 *
 * @param id		The player index to display the command list to.
 */
public displayCommandList(id) {
	static tempstring[sizeof g_szCommandList-2];
	add(tempstring, strlen(g_szCommandList)-2, g_szCommandList);
	client_print_color(id, DontChange, "%s ^3Commands^1: %s", "^1[^4ZP^1]", tempstring);
}

/**
 * Public method used to display the command list MotD to a player.  This method
 * must combine all different pre-cached portions of the message including: the
 * header with prefixes, the command list table, and the footer.
 *
 * @param id		The player index to display the command list MotD to.
 */
public displayCommandMotD(id) {
	static szMotDText[2048];
	add(szMotDText, 2047, g_szCommandListMotD);
	add(szMotDText, 2047, g_szCommandTable);
	add(szMotDText, 2047, "</table></blockquote></font></body></html>");
	show_motd(id, szMotDText, "Modern Warfare 3 Mod: Command List");
}

/**
 * Private method used to format the header and prefixes portion of the command
 * list MotD.  This is called whenever the command prefixes change.
 */
refreshCommandMotD() {
	static tempstring[128];
	formatex(g_szCommandListMotD, 255, "<html><body bgcolor=^"#474642^"><font size=^"3^" face=^"courier new^" color=^"FFFFFF^">");
	formatex(tempstring, 127, "<center><h1>Zombie Plague: Commands v%s</h1>By %s</center><br><br>", Version, Author);
	add(g_szCommandListMotD, 255, tempstring);
	formatex(tempstring, 127, "Command Prefixes: ");
	add(g_szCommandListMotD, 255, tempstring);
	get_pcvar_string(g_pcvar_prefix, tempstring, 127);
	add(g_szCommandListMotD, 255, tempstring);
}

/**
 * Private method used to construct the initial header for the command table.
 * This method should only be called before commands are registered, because
 * this resets the entire command list table.
 */
constructCommandTable() {
	formatex(g_szCommandTable, 1791, "<br><br>Commands:<blockquote>");
	add(g_szCommandTable, 1791, "<STYLE TYPE=^"text/css^"><!--TD{color: ^"FFFFFF^"}---></STYLE><table><tr><td>Command:</td><td>&nbsp;&nbsp;Description:</td></tr>");
}

/**
 * Private method used to add a new function into all displays where it will
 * need to be displayed.
 *
 * @param command		The command that will execute the function.
 * @param description		The description to be displayed for this command.
 */
addCommandToTable(command[], description[]) {
	static tempstring[256];
	formatex(tempstring, 255, "<tr><td>%s</td><td>: %s</td></tr>", command, description);
	add(g_szCommandTable, 1791, tempstring);
	
	formatex(tempstring, 255, "^4%s^1, ", command);
	add(g_szCommandList, 159, tempstring);
}

/**
 * @see ZP_Commands.inc
 */
public _registerCommand(iPlugin, iParams) {
	if (iParams != 4) {
		return -1;
	}
	
	static newFunction[eFunctionInfo], i;
	
	// Get the command that executes this function
	get_string(1, newFunction[Name], 31);
	strtolower(newFunction[Name]);
	
	// Check if there is already a command under this name
	if (TrieGetCell(g_tCommands, newFunction[Name], i)) {
		zp_core_log_error("A command already exists under this name (%s)", newFunction[Name]);
		return -1;
	}
	
	// Get the function name for this command
	static szTemp[32];
	get_string(2, szTemp, 31);

	// Load up the trie containing all function names for comparison
	static Trie:tempTrie;
	tempTrie = ArrayGetCell(g_aFunctionNames, iPlugin);
	
	// Check if the function has already been registered
	if (TrieGetCell(tempTrie, szTemp, i)) {
		// Set the command trie to the index of the registered function
		TrieSetCell(g_tCommands, newFunction[Name], i);
		
		// Return the index of the function that was registered
		return i;
	} else {
		// Register our new function
		newFunction[FuncID] = get_func_id(szTemp, iPlugin);
		
		// If the function is invalid, then tell them
		if (newFunction[FuncID] < 0) {
			zp_core_log_error("Invalid command handle (%s)", newFunction[Name]);
			return -2;
		}
		
		// Register the new function name in the func trie
		TrieSetCell(tempTrie, szTemp, g_functionNum);
		
		// Reload the changed trie into the array cell
		ArraySetCell(g_aFunctionNames, iPlugin, tempTrie);
		
		// Set the plugin id for the function
		newFunction[PluginID] = iPlugin;
		
		// Read the flags for the function and store them
		get_string(3, szTemp, 31);
		newFunction[Flags] = read_flags(szTemp);
		
		// Read and store the description of this function
		get_string(4, newFunction[Desc], 63);
		
		// Push the new function into the function array
		ArrayPushArray(g_aFunctions, newFunction);
		
		// Add the new command to the trie
		TrieSetCell(g_tCommands, newFunction[Name], g_functionNum);
		
		// Add the command into the displays
		addCommandToTable(newFunction[Name], newFunction[Desc]);
		
		// Increase our function total by 1
		g_functionNum++;
		
		// Return the index for this function
		return g_functionNum-1;
	}
	
	return -1;
}

/**
 * @see ZP_Commands.inc
 */
public _getCIDByName(iPlugin, iParams) {
	if (iParams != 1) {
		return -1;
	}
	
	static command[32], i;
	get_string(1, command, 31);
	if (TrieGetCell(g_tCommands, command, i)) {
		return i;
	}
	
	return -1;
}
