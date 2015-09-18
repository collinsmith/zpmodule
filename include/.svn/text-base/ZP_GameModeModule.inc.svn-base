#if defined _ZP_GameModeModule
  #endinput
#endif
#define _ZP_GameModeModule

#include <ZP_Core>


/**
 * Registers a new game mode.
 *
 * @param name			Game mode name.
 * @return			An internal game mode ID, or -1 on failure.
 */
native zp_register_game_mode(const name[])


/**
 * Called when a game mode starts.
 *
 * @param target_player		Target player for the game mode.
 */
forward zp_game_mode_started(target_player)

/**
 * Called when a game mode is chosen for starting it
 * 
 * Returning PLUGIN_HANDLED blocks the game mode
 *
 */
forward zp_game_mode_starting()

/**
 * Called when a game mode ends.
 */
forward zp_game_mode_ended()