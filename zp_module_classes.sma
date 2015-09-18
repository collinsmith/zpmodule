#include <amxmodx>

#include <ZP_Core>
#include <ZP_ClassModule_Zombie>
#include <ZP_VarManager_Const>

// Classic Zombie Attributes
new const zombieclass1_name[] = "Classic"
new const zombieclass1_info[] = "=Balanced="
new const zombieclass1_model[] = "classic"

// Raptor Zombie Attributes
new const zombieclass2_name[] = "Raptor";
new const zombieclass2_info[] = "HP-- Speed++ Knockback++";
new const zombieclass2_model[] = "bb_tanker"

public zp_fw_class_zombie_register() {
	new group = zp_class_zombie_register_group("Standard");
	new class = zp_class_zombie_register(group, zombieclass1_name, zombieclass1_info, zombieclass1_model);
	zp_class_set_class_att(class, ZP_INT_xpreq, false, 200);
	class = zp_class_zombie_register(group, zombieclass2_name, zombieclass2_info, zombieclass2_model);
	zp_class_set_class_att(class, ZP_INT_xpreq, false, 150);
}

public plugin_init() {
	register_plugin("ZP Classic Zombie", "0.0.1", "Module Version")
	
	register_clcmd("say /showmenu", "showMenu");
}

public showMenu(id) {
	zp_core_infect_user(id);
	zp_class_zombie_show_menu(id);
}

public zp_fw_class_selected(id, class) {
	zp_class_apply_class(id, class);
}

public zp_fw_class_get_exp(id) {
	return 150;
}
