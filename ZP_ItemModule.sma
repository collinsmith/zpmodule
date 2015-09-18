#include <amxmodx>
#include <colorchat>
#include <ZP_Core>
#include <ZP_ItemModule_Const>

new const Plugin [] = "ZP Base/Engine";
new const Version[] = "0.0.1";
new const Author [] = "WiLs & Tir";

new const g_szMsgHeader[] = "^1[^4ZP^1]";

#define MENU_OFFSET 25

new Array:g_aItems;
new Trie:g_tItemNames;
new g_itemCount;

enum _:eTest ( <<=1 )
{
	HUMAN = 1,
	ZOMBIE
}

enum eForwardedEvents
{
	fwDummy = 0,
	fwItemSelected,
	fwGetMoney
}
new g_Forwards[eForwardedEvents];

enum _:eMenuInfo {
	menu_itemid = 0,
	menu_endstring
}

public plugin_precache() {
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	// Forwards
	g_Forwards[fwItemSelected] = CreateMultiForward("zp_item_selected", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[fwGetMoney    ] = CreateMultiForward("zp_get_user_money", ET_CONTINUE, FP_CELL)
}

public plugin_natives() {
	register_library("ZP_ItemModule");
	
	register_native("zp_show_item_menu",		"_showItemMenu",	 1);
	register_native("zp_register_item",		"_registerItem",	 0);
	register_native("zp_get_itemid_by_name",	"_getItemByName",	 0);
}

public _showItemMenu(id) {
	static menuid, menu[128], itemInfo[eMenuInfo], tempItemData[eItemData], iFlags,
			bool:isZombie, iCurMoney;
			
	ExecuteForward(g_Forwards[fwGetMoney], iCurMoney, id);
	isZombie = is_user_zombie(id);
	
	formatex(menu, 127, "\rExtra Items Menu (Money: %d)", iCurMoney);
	menuid = menu_create(menu, "item_menu");
	
	for (new i; i < g_itemCount; i++) {
		ArrayGetArray(g_aItems, i, tempItemData);
		iFlags = read_flags(tempItemData[Flags]);
		if ((isZombie && !(iFlags&ZOMBIE)) || (!isZombie && !(iFlags&HUMAN))) {
			continue;
		}
		
		if (tempItemData[Price] > iCurMoney) {
			formatex(menu, 127, "\d%s [%s] Cost: %d", tempItemData[Name], tempItemData[Desc], tempItemData[Price]);
		} else {
			formatex(menu, 127, "%s \y[%s] \rCost: %d", tempItemData[Name], tempItemData[Desc], tempItemData[Price]);
		} 
		
		itemInfo[menu_itemid] = i+MENU_OFFSET;
		menu_additem(menuid, menu, itemInfo);
	}
	
	formatex(menu, 127, "Back")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, 127, "Next")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, 127, "Exit")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	menu_display(id, menuid)
	
	return PLUGIN_CONTINUE;
}

public item_menu(id, menuid, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	static menuItemInfo[eMenuInfo], dummy, itemData[eItemData], iCurMoney;
	menu_item_getinfo(menuid, item, dummy, menuItemInfo, eMenuInfo-1, _, _, dummy);
	
	for (new i; i < eMenuInfo; i++) {
		menuItemInfo[i] -= MENU_OFFSET;
	}
	
	ArrayGetArray(g_aItems, menuItemInfo[menu_itemid], itemData)
	
	ExecuteForward(g_Forwards[fwGetMoney], iCurMoney, id)
	if (itemData[Price] > iCurMoney) {
		client_print_color(id, DontChange, "%s You do not have the required money for this item. ^1(^4%d^1)", g_szMsgHeader, itemData[Price]);
		_showItemMenu(id);
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	ExecuteForward(g_Forwards[fwItemSelected], g_Forwards[fwDummy], id, menuItemInfo[menu_itemid], itemData[Price])
	
	client_print_color(id, DontChange, "%s You have purchased the ^4%s ^1item", g_szMsgHeader, itemData[Name]);
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public _registerItem(iPlugin, iParams) {
	if (iParams != eItemParamOrder) {
		return -1;
	}
	
	static newItemData[eItemData], i;
	get_string(iParam_name, newItemData[Name], 31);
	
	// Check to see if there is already an item registered under this name
	if (TrieGetCell(g_tItemNames, newItemData[Name], i)) {
		zp_core_log_error("Item already registered under this name (%s)", newItemData[Name]);
		return i;
	}
	
	// Set the other information for this item
	get_string(iParam_desc, newItemData[Desc], 31);
	get_string(iParam_flags, newItemData[Flags], 7);
	newItemData[Price] = get_param(iParam_price)

	// Push the item into the items array
	ArrayPushArray(g_aItems, newItemData);
	
	// Add the item name into the list to help query names
	TrieSetCell(g_tItemNames, newItemData[Name], g_itemCount);
	
	g_itemCount++;
	
	return g_itemCount-1;
}

public _getItemByName(iPlugin, iParams) {
	static itemName[32], i;
	get_string(1, itemName, 31);
	if (TrieGetCell(g_tItemNames, itemName, i)) {
		return i;
	}
	
	return -1;
}
