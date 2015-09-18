#if defined _ZP_GunModule_C
	#endinput
#endif
#define _ZP_GunModule_C

#include <amxconst>
#include <amxmodx>

stock const __weaponsSecondary = (1<<CSW_GLOCK18)|(1<<CSW_USP)|(1<<CSW_P228)|(1<<CSW_DEAGLE)|(1<<CSW_FIVESEVEN)|(1<<CSW_ELITE);
stock const __weaponsPrimary = (1<<CSW_AK47)|(1<<CSW_AUG)|(1<<CSW_AWP)|(1<<CSW_FAMAS)|(1<<CSW_G3SG1)|(1<<CSW_GALIL)|(1<<CSW_M249)|\
				(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_MAC10)|(1<<CSW_MP5NAVY)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_SG550)|\
				(1<<CSW_SG552)|(1<<CSW_TMP)|(1<<CSW_UMP45)|(1<<CSW_XM1014);

static const _weaponNames[][] = { "", "P228 Compact", "", "Schmidt Scout", "", "XM1014 M4", "", "Ingram MAC-10",
			"Steyr AUG A1", "", "Dual Elite Berettas", "FiveseveN", "UMP 45", "SG-550 Auto-Sniper",
			"IMI Galil", "Famas", "USP .45 ACP Tactical", "Glock 18C", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun",
			"M3 Super 90", "M4A1 Carbine", "Schmidt TMP", "G3SG1 Auto-Sniper", "", "Desert Eagle .50 AE", "SG-552 Commando",
			"AK-47 Kalashnikov", "", "ES P90" };
				
enum _:ZPWeapons_Primary {
	ZP_PRIM_NONE = 0,
	ZP_SCOUT = CSW_SCOUT,
	ZP_XM1014 = CSW_XM1014,
	ZP_MAC10 = CSW_MAC10,
	ZP_AUG = CSW_AUG,
	ZP_UMP45 = CSW_UMP45,
	ZP_SG550 = CSW_SG550,
	ZP_GALIL = CSW_GALIL,
	ZP_FAMAS = CSW_FAMAS,
	ZP_AWP = CSW_AWP,
	ZP_MP5NAVY = CSW_MP5NAVY,
	ZP_M249 = CSW_M249,
	ZP_M3 = CSW_M3,
	ZP_M4A1 = CSW_M4A1,
	ZP_TMP = CSW_TMP,
	ZP_G3SG1 = CSW_G3SG1,
	ZP_SG552 = CSW_SG552,
	ZP_AK47 = CSW_AK47,
	ZP_P90 = CSW_P90
}

enum _:ZPWeapons_Secondary {
	ZP_SEC_NONE = 0,
	ZP_P228 = CSW_P228,
	ZP_ELITE = CSW_ELITE,
	ZP_FIVESEVEN = CSW_FIVESEVEN,
	ZP_USP = CSW_USP,
	ZP_GLOCK18 = CSW_GLOCK18,
	ZP_DEAGLE = CSW_DEAGLE
}

stock bool:zp_is_primary_weapon(csw) {
	if (_weaponsPrimary&(1<<csw)) {
		return true;
	}
	
	return false;
}

stock bool:zp_is_secondary_weapon(csw) {
	if (_weaponsSecondary&(1<<csw)) {
		return true;
	}
	
	return false;
}

stock zp_get_weaponname(csw, string[], len) {
	copy(string, len, _weaponNames[csw]);
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
