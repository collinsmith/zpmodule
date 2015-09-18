#if defined _ZP_ClassModule_Zombie_C
	#endinput
#endif
#define _ZP_ClassModule_Zombie_C

#define ZOMBIE_DEFAULT_HEALTH 2000.0
#define ZOMBIE_DEFAULT_SPEED 1.10
#define ZOMBIE_DEFAULT_GRAVITY 0.85
#define ZOMBIE_DEFAULT_EXP 0
#define ZOMBIE_DEFAULT_ADMIN ADMIN_ALL
#define ZOMBIE_DEFAULT_MAXNUM 0
#define ZOMBIE_DEFAULT_KNOCKBACK 1.0
#define ZOMBIE_DEFAULT_MODEL "classic"
#define ZOMBIE_DEFAULT_CLAW "v_claws"

enum _:ZombieClass {
	GlobalID,
	Claw[64],
	Float:Knockback
};

enum _:ZClassKeys {
	ck_Claw,
	ck_Knockback
}

stock const _zombieClassKeys[ZClassKeys][] = {
	"CLAW MODEL",
	"KNOCKBACK"
}

enum _:ZombieParamOrder {
	zParam_group = 1,
	zParam_name,
	zParam_desc,
	zParam_model,
	zParam_claw
};
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
