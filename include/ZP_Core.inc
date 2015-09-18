#if defined _ZP_Core
	#endinput
#endif
#define _ZP_Core

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ZombiePlagueCore
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ZombiePlagueCore
	#endif
#else
	#pragma library ZombiePlagueCore
#endif

#include <ZP_Core_Const>
#include <ZP_Core_Stocks>
#include <ZP_Log>

forward zp_fw_core_infect_pre(id);
forward zp_fw_core_infect(id);
forward zp_fw_core_infect_post(id);
forward zp_fw_core_cure_pre(id);
forward zp_fw_core_cure(id);
forward zp_fw_core_cure_post(id);
forward zp_fw_core_player_spawn_post(id, bool:isZombie);
forward zp_fw_core_player_death(killer, victim);
forward zp_fw_core_changeteam_blocked(id);
forward zp_fw_core_register_model(id);

native bool:is_user_zombie(id);
native bool:zp_core_is_user_zombie(id);

native PlayerState:zp_core_infect_user(id);
native PlayerState:zp_core_cure_user(id);

native zp_core_get_players(players[32], &count, bool:getZombies = true);
native bool:zp_core_refresh(id);
native bool:zp_core_respawn_user(id);
native zp_core_register_model(bool:isZombieModel, const model[]);
native zp_core_get_model_from_id(bool:isZombieModel, modelid, model[], len);
native zp_core_get_zombie_bits();
native zp_core_set_zombie_bits(bits);
native bool:zp_core_check_zombie_bits(csw);
