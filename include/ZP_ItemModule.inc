#if defined _ZP_ItemModule_C
	#endinput
#endif
#define _ZP_ItemModule_C

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZP_ItemModule
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZP_ItemModule
	#endif
#else
	#pragma library ZP_ItemModule
#endif

#include <ZP_ItemModule_Const>

/**
 * Called when an item on the menu is selected.  At this time,
 * it is known that the player has the proper amount of currency
 * to buy this item, so this forward should be used by the item
 * register plugin to award the item, whatever it may be.
 * 
 * @param id		The player index purchasing the item.
 * @param itemid	The item index being purchased.
 * @param cost		The cost of the item. Ideally handled through
 * 			the plugin that manages currency (ammo packs).
 */
forward zp_item_selected(id, itemid, cost)

/**
 * Called when the item menu is displayed, or a price check is needed
 * on an item. This forward should be used to return the current amount
 * of money that a player has.
 *
 * @param id		The player index that the plugin is requesting
 * 			the money from.
 */
forward zp_get_user_money(id)

/**
 * Displays the item menu to a given player. This menu will 
 * automatically handle which items should be displayed, depending
 * on the player flags that items are assigned.
 * 
 * @param id		The player index that the menu is displayed to.
 */
native zp_show_item_menu(id);

/**
 * Registers an item into the item menu.  This item will not be able to
 * handle any player modifications itself, so any effects that an item
 * gives a player must be awarded through {@link zp_item_selected(id, itemid, cost)}
 * where the itemid is the return value from the item when registered.
 *
 * @param name		The name of this item.
 * @param desc		A brief description of the effects of the item.
 * @param flags		Flags that will be set for this item to determine
 * 			when, and who it will be available to.  By default
 * 			items are available to both teams.
 *			'a' = Zombies Only
 *			'b' = Humans Only
 * @param price		The cost of this item.
 * @return		The itemid of this item, -1 if the item fails
 * 			to register for whatever reason.
 */
native zp_register_item(const name[], const desc[], const flags[] = "ab", price);

/**
 * Retrieves the itemid for an item using the name of that item.
 *
 * @param itemname	The exact name of the item
 * @return		The itemid of the item if found, -1 if no item
 *			could be found matching the item.
 */
native zp_get_itemid_by_name(const itemname[]);
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
