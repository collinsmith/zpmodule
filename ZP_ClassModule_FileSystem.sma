#pragma dynamic 8192

#include <amxmodx>
#include <amxmisc>
#include <arraycopy>

#include <ZP_Core>
#include <ZP_ClassModule>
#include <ZP_ClassModule_FileSystem_Const>

static const Plugin [] = "ZP Class File System Module";
static const Version[] = "0.0.1";
static const Author [] = "Tirant";

new Trie:g_tClassKeys;

enum _:ForwardedEvents {
	fwDummy = 0,
	fwRegisterTries,
	fwReadClassData,
	fwWriteClassData
};
static g_Forwards[ForwardedEvents];

static g_defaultClass[Class];

public plugin_init() {
	register_plugin(Plugin, Version, Author);
}

public plugin_natives() {
	register_library("ZP_ClassModule_FileSystem");
	
	register_native("zp_class_file_create_class", 	"_createFileForClass",		 1);
	register_native("zp_class_file_create_type", 	"_createDefaultClassFile",	 1);
}

public zp_fw_class_data_struc_init_pre() {
	g_defaultClass[GroupID    ] = CLASSGROUP_NONE;
	g_defaultClass[LocalID    ] = CLASS_NONE,
	g_defaultClass[ModelID    ] = -1,
	g_defaultClass[Health     ] = _:100.0;
	g_defaultClass[Speed      ] = _:1.0;
	g_defaultClass[Gravity    ] = _:1.0;
	g_defaultClass[AbilityList] = _:ArrayCreate();
	
	g_tClassKeys = TrieCreate();
	
	for (new i; i < sizeof _keyNames; i++) {
		TrieSetCell(g_tClassKeys, _keyNames[i], i);
	}
	
	g_Forwards[fwReadClassData ] = CreateMultiForward("zp_fw_class_file_read_key", ET_IGNORE, FP_STRING, FP_STRING, FP_STRING);
	g_Forwards[fwWriteClassData] = CreateMultiForward("zp_fw_class_file_write_key", ET_IGNORE, FP_STRING, FP_CELL);
	g_Forwards[fwRegisterTries ] = CreateMultiForward("zp_fw_class_file_register_tries", ET_IGNORE);
	
	ExecuteForward(g_Forwards[fwRegisterTries], g_Forwards[fwDummy]);
	
	cacheClassesFromFiles();
}

cacheClassesFromFiles() {
	static szConfigsDir[128];
	zp_get_homefolder(szConfigsDir, 127);
	mkdir(szConfigsDir);
	format(szConfigsDir, 127, "%s/%s", szConfigsDir, ZP_ClassFolder);
	mkdir(szConfigsDir);
	
	static temp[128], temp2[128], temp3[128], szFileName[35];
	static classDirHandle, classTypeDirHandle, classGroupDirHandle;
	static tempClass[Class];
	static type, group;
	
	zp_log("Loading classes from file system...");
	for (new i; i < 2; i++) {
		formatex(temp, 127, "%s/%s", szConfigsDir, _szTeamNames[i]);
		mkdir(temp);
		
		classDirHandle = open_dir(temp, szFileName, 34);
		while (next_file(classDirHandle, szFileName, 34)) {
			formatex(temp, 127, "%s/%s/%s", szConfigsDir, _szTeamNames[i], szFileName);
			
			if (!dir_exists(temp) || contain(temp, "..") != -1) {
				continue;
			}
			
			formatex(temp2, 127, "%s/%s %s%s", temp, ZP_DefClassFileName, szFileName, ZP_ClassTypeExtension);
			if (file_exists(temp2)) {
				static temp3[64];
				formatex(temp3, 63, "%s %s", ZP_DefClassFileName, szFileName);
				cacheDefaultClass(temp2, temp3, tempClass);
			} else {
				arraycopy(tempClass, g_defaultClass, Class);
			}
			
			type = zp_class_register_type(!!i, szFileName, tempClass);
			if (!zp_class_is_valid_type(type)) {
				continue;
			}
			
			classTypeDirHandle = open_dir(temp, szFileName, 34);
			while (next_file(classTypeDirHandle, szFileName, 34)) {
				formatex(temp2, 127, "%s/%s", temp, szFileName);
				
				if (!dir_exists(temp2) || contain(temp2, "..") != -1) {
					continue;
				}
				
				group = zp_class_register_group(type, szFileName);
				if (!zp_class_is_valid_group(group)) {
					continue;
				}
				
				classGroupDirHandle = open_dir(temp2, szFileName, 34);
				while (next_file(classGroupDirHandle, szFileName, 34)) {
					formatex(temp3, 127, "%s/%s", temp2, szFileName);
					
					if (!file_exists(temp3)) {
						continue;
					}
					
					cacheClassFromFile(i, group, temp2, szFileName, temp3);
				}
				close_dir(classGroupDirHandle);
			}
			close_dir(classTypeDirHandle);
		}
		close_dir(classDirHandle);
	}
}

cacheClassFromFile(team, group, szFilePath[], szFileName[], szFileWithPath[]) {
	replace(szFileName, 34, ZP_ClassExtension, "");
	zp_log("Found '%s'. Parsing data...", szFileName);
	
	static tempClass[Class], tempClassGroup[ClassGroup], tempClassType[ClassType], class;
	ArrayGetArray(zp_class_get_group_array(), group, tempClassGroup);
	ArrayGetArray(zp_class_get_type_array(), tempClassGroup[TypeID], tempClassType);

	tempClass[GroupID   ] = tempClassType[DefaultClass][GroupID   ];
	tempClass[LocalID   ] = tempClassType[DefaultClass][LocalID   ];
	tempClass[ModelID   ] = tempClassType[DefaultClass][ModelID   ];
	tempClass[Health    ] = _:tempClassType[DefaultClass][Health  ];
	tempClass[Speed     ] = _:tempClassType[DefaultClass][Speed   ];
	tempClass[Gravity   ] = _:tempClassType[DefaultClass][Gravity ];
	tempClass[XPReq     ] = tempClassType[DefaultClass][XPReq     ];
	tempClass[AdminLevel] = tempClassType[DefaultClass][AdminLevel];
	tempClass[CurNumber ] = tempClassType[DefaultClass][CurNumber ];
	tempClass[MaxNumber ] = tempClassType[DefaultClass][MaxNumber ];
	
	tempClass[GroupID	] = group;
	tempClass[LocalID	] = CLASS_NONE;
	copy(tempClass[ClassName], 31, szFileName);
	class = zp_class_register_class(tempClass);
	if (!zp_class_is_valid_class(class)) {
		return;
	}
	
	static key[32], value[512], i, /*temp[128], rename[32],*/ bool:isZombieModel;
	//rename[0] = '^0';
	
	static file;
	file = fopen(szFileWithPath, "rt");
	while (!feof(file)) {
		fgets(file, value, 511);
		
		replace(value, 511, "^n", "");
		if (!value[0] || value[0] == ';') {
			continue;
		}
		
		strtok(value, key, 31, value, 511, '=');
		trim(key);
		trim(value);
		
		if (TrieGetCell(g_tClassKeys, key, i)) {
			switch (i) {
				case ck_GroupID: {
					// Not allowed to change
				}
				case ck_LocalID: {
					ExecuteForward(g_Forwards[fwReadClassData], g_Forwards[fwDummy], szFileName, key, value);
				}
				case ck_Name: {
					// Not allowed to change, but rename file if internal change
					/*if (!equal(szFileName, value)) {
						copy(rename, 31, value);
					}*/
				}
				case ck_Desc: {
					zp_class_set_class_att(class, ZP_SZ_desc, true, value);
				}
				case ck_ModelID: {
					isZombieModel = !!team;
					zp_class_set_class_att(class, ZP_INT_modelid, true, zp_core_register_model(isZombieModel, value));
				}
				case ck_Health: {
					zp_class_set_class_att(class, ZP_FL_health, true, str_to_float(value));
				}
				case ck_Speed: {
					zp_class_set_class_att(class, ZP_FL_speed, true, str_to_float(value));
				}
				case ck_Gravity: {
					zp_class_set_class_att(class, ZP_FL_gravity, true, str_to_float(value));
				}
				case ck_Abilities: {
					while (value[0] != '^0' && strtok(value, key, 31, value, 511, ',')) {
						trim(key);
						zp_class_add_ability(class, zp_class_register_ability(key));
					}
				}
				case ck_XPReq: {
					zp_class_set_class_att(class, ZP_INT_xpreq, true, str_to_num(value));
				}
				case ck_AdminLevel: {
					zp_class_set_class_att(class, ZP_INT_adminlvl, true, read_flags(value));
				}
				case ck_CurNumber: {
					zp_class_set_class_att(class, ZP_INT_curnumber, true, 0);
				}
				case ck_MaxNumber: {
					zp_class_set_class_att(class, ZP_INT_maxnumber, true, str_to_num(value));
				}
			}
		} else {
			ExecuteForward(g_Forwards[fwReadClassData], g_Forwards[fwDummy], szFileName, key, value);
		}
	}
	fclose(file);
	
	/*if (rename[0] != '^0') {
		formatex(temp, 127, "%s/%s", szFilePath, rename);
		rename_file(szFileWithPath, temp, 1);
	}*/
}

public _createFileForClass(class, Array:aClasses, Array:aClassGroups, Array:aClassTypes) {
	if (!zp_class_is_valid_class(class)) {
		return;
	}
	
	static tempClass[Class], tempClassGroup[ClassGroup], tempClassType[ClassType];
	ArrayGetArray(aClasses, class, tempClass);
	ArrayGetArray(aClassGroups, tempClass[GroupID], tempClassGroup);
	ArrayGetArray(aClassTypes, tempClassGroup[TypeID], tempClassType);
	
	static temp1[128], temp2[128];
	zp_get_homefolder(temp1, 127);
	formatex(temp2, 127, "%s/%s/%s/%s/%s", temp1, ZP_ClassFolder, _szTeamNames[tempClassType[TeamID]], tempClassType[TypeName], tempClassGroup[GroupName]);
	format(temp1, 127, "%s/%s%s", temp2, tempClass[ClassName], ZP_ClassExtension);
	
	if (file_exists(temp1)) {
		return;
	}
		
	if (!dir_exists(temp2)) {
		zp_get_homefolder(temp2, 127);
		mkdir(temp2);
		
		formatex(temp1, 127, "%s/%s", temp2, ZP_ClassFolder);
		mkdir(temp1);
		
		formatex(temp2, 127, "%s/%s", temp1, _szTeamNames[tempClassType[TeamID]]);
		mkdir(temp2);
		
		formatex(temp1, 127, "%s/%s", temp2, tempClassType[TypeName]);
		mkdir(temp1);
		
		formatex(temp2, 127, "%s/%s", temp1, tempClassGroup[GroupName]);
		mkdir(temp2);
		
		formatex(temp1, 127, "%s/%s%s", temp2, tempClass[ClassName], ZP_ClassExtension);
	}

	static file;
	do {
		file = fopen(temp1, "wt");
	} while (!file);

	zp_log("Generating class file for '%s'", tempClass[ClassName]);
	fprintf(file, "; Generated for %s v%s^n", ZP_Plugin, ZP_Version);
	fprintf(file, "; Class system developed by Tirant^n");
	fprintf(file, "; ^n");
	fprintf(file, "; Team: %s^n", _szTeamNames[tempClassType[TeamID]]);
	fprintf(file, "; Type: %s^n", tempClassType[TypeName]);
	fprintf(file, "; Group: %s^n", tempClassGroup[GroupName]);
	fprintf(file, "; Class: %s^n", tempClass[ClassName]);
	fprintf(file, "^n");
	fprintf(file, "; The name of this class^n");
	fprintf(file, "%s = %s", _keyNames[ck_Name], tempClass[ClassName]);
	fprintf(file, "^n^n; The description for this class^n");
	fprintf(file, "%s = %s", _keyNames[ck_Desc], tempClass[ClassDesc]);
	fprintf(file, "^n^n; The model for this class^n");
	zp_core_get_model_from_id(tempClassType[TeamID], tempClass[ModelID], temp2, 127);
	fprintf(file, "%s = %s", _keyNames[ck_ModelID], temp2);
	fprintf(file, "^n^n; Health for this class^n");
	fprintf(file, "%s = %d", _keyNames[ck_Health], floatround(tempClass[Health]));
	fprintf(file, "^n^n; Speed for this class^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_Speed], tempClass[Speed]);
	fprintf(file, "^n^n; Gravity for this class^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_Gravity], tempClass[Gravity]);
	
	fprintf(file, "^n^n; Abilities for this class^n");
	static size;
	size = ArraySize(tempClass[AbilityList]);
	if (size > 0) {
		static temp3[512], ability;
		formatex(temp3, 511, "%s = ", _keyNames[ck_Abilities]);
		for (new i; i < size; i++) {
			ability = ArrayGetCell(tempClass[AbilityList], i);
			format(temp3, 511, "%s, %s", zp_class_get_ability_name(ability));
		}
	} else {
		fprintf(file, "%s = ", _keyNames[ck_Abilities]);
	}
	
	fprintf(file, "^n^n; XP Requirement for this class^n");
	fprintf(file, "%s = %d", _keyNames[ck_XPReq], tempClass[XPReq]);
	fprintf(file, "^n^n; Admin flags required this class^n");
	get_flags(tempClass[AdminLevel], temp2, 127);
	fprintf(file, "%s = %s", _keyNames[ck_AdminLevel], temp2);
	fprintf(file, "^n^n; Maximum number of people who can use this class at once^n");
	fprintf(file, "%s = %d", _keyNames[ck_MaxNumber], tempClass[MaxNumber]);
	
	ExecuteForward(g_Forwards[fwWriteClassData], g_Forwards[fwDummy], tempClass[ClassName], file);
	
	fclose(file);
}

cacheDefaultClass(szFilePath[], szFileName[], tempClass[Class]) {
	zp_log("Caching default class %s...", szFilePath);
	arraycopy(tempClass, g_defaultClass, Class);
	static key[32], value[512], i, bool:isZombieModel;
	
	static file;
	file = fopen(szFilePath, "rt");
	while (!feof(file)) {
		fgets(file, value, 511);
		
		replace(value, 511, "^n", "");
		if (!value[0] || value[0] == ';') {
			continue;
		}
		
		strtok(value, key, 31, value, 511, '=');
		trim(key);
		trim(value);
		
		if (TrieGetCell(g_tClassKeys, key, i)) {
			switch (i) {
				case ck_GroupID: {
					// ...
				}
				case ck_LocalID: {
					// ...
				}
				case ck_Name: {
					// ...
				}
				case ck_Desc: {
					// ...
				}
				case ck_ModelID: {
					tempClass[ModelID	] = zp_core_register_model(isZombieModel, value);
				}
				case ck_Health: {
					tempClass[Health	] = _:str_to_float(value);
				}
				case ck_Speed: {
					tempClass[Speed		] = _:str_to_float(value);
				}
				case ck_Gravity: {
					tempClass[Gravity	] = _:str_to_float(value);
				}
				case ck_Abilities: {
					tempClass[AbilityList	] = _:ArrayCreate();
					while (value[0] != '^0' && strtok(value, key, 31, value, 511, ',')) {
						trim(key);
						ArrayPushCell(tempClass[AbilityList], zp_class_register_ability(key));
					}
				}
				case ck_XPReq: {
					tempClass[XPReq		] = str_to_num(value);
				}
				case ck_AdminLevel: {
					tempClass[AdminLevel	] = str_to_num(value);
				}
				case ck_CurNumber: {
					// ...
				}
				case ck_MaxNumber: {
					tempClass[MaxNumber	] = str_to_num(value);
				}
			}
		} else {
			ExecuteForward(g_Forwards[fwReadClassData], g_Forwards[fwDummy], szFileName, key, value);
		}
	}
	fclose(file);
}

public _createDefaultClassFile(type) {
	if (!zp_class_is_valid_type(type)) {
		return;
	}
	
	static tempClassType[ClassType];
	ArrayGetArray(zp_class_get_type_array(), type, tempClassType);
	
	static temp1[128], temp2[128];
	zp_get_homefolder(temp1, 127);
	formatex(temp2, 127, "%s/%s/%s/%s", temp1, ZP_ClassFolder, _szTeamNames[tempClassType[TeamID]], tempClassType[TypeName]);
	formatex(temp1, 127, "%s/%s %s%s", temp2, ZP_DefClassFileName, tempClassType[TypeName], ZP_ClassTypeExtension);
	
	if (file_exists(temp1)) {
		return;
	}
		
	if (!dir_exists(temp2)) {
		zp_get_homefolder(temp1, 127);
		mkdir(temp1);
		
		formatex(temp2, 127, "%s/%s", temp1, ZP_ClassFolder);
		mkdir(temp2);
		
		formatex(temp1, 127, "%s/%s", temp2, _szTeamNames[tempClassType[TeamID]]);
		mkdir(temp1);
		
		formatex(temp2, 127, "%s/%s", temp1, tempClassType[TypeName]);
		mkdir(temp2);
		
		formatex(temp1, 127, "%s/%s %s%s", temp2, ZP_DefClassFileName, tempClassType[TypeName], ZP_ClassTypeExtension);
	}
	
	static file;
	do {
		file = fopen(temp1, "wt");
	} while (!file);

	zp_log("Generating default class type file for '%s'", tempClassType[TypeName]);
	fprintf(file, "; Generated for %s v%s^n", ZP_Plugin, ZP_Version);
	fprintf(file, "; Class system developed by Tirant^n");
	fprintf(file, "; ^n");
	fprintf(file, "; Team: %s^n", _szTeamNames[tempClassType[TeamID]]);
	fprintf(file, "; Type: %s^n", tempClassType[TypeName]);
	fprintf(file, "^n");
	fprintf(file, "; Default model for this class type^n");
	zp_core_get_model_from_id(tempClassType[TeamID], -1, temp2, 127);
	fprintf(file, "%s = %s", _keyNames[ck_ModelID], temp2);
	fprintf(file, "^n^n; Default health for this class type^n");
	fprintf(file, "%s = %d", _keyNames[ck_Health], floatround(tempClassType[DefaultClass][Health]));
	fprintf(file, "^n^n; Default speed for this class type^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_Speed], tempClassType[DefaultClass][Speed]);
	fprintf(file, "^n^n; Default gravity for this class type^n");
	fprintf(file, "%s = %.2f", _keyNames[ck_Gravity], tempClassType[DefaultClass][Gravity]);
	
	fprintf(file, "^n^n; Default abilities for this class type^n");
	static size;
	size = ArraySize(tempClassType[DefaultClass][AbilityList]);
	if (size > 0) {
		static temp3[512], ability;
		formatex(temp3, 511, "%s = ", _keyNames[ck_Abilities]);
		for (new i; i < size; i++) {
			ability = ArrayGetCell(tempClassType[DefaultClass][AbilityList], i);
			format(temp3, 511, "%s, %s", zp_class_get_ability_name(ability));
		}
	} else {
		fprintf(file, "%s = ", _keyNames[ck_Abilities]);
	}
	
	fprintf(file, "^n^n; Default XP requirement for this class type^n");
	fprintf(file, "%s = %d", _keyNames[ck_XPReq], tempClassType[DefaultClass][XPReq]);
	fprintf(file, "^n^n; Default admin flags required this class type^n");
	get_flags(tempClassType[DefaultClass][AdminLevel], temp2, 127);
	fprintf(file, "%s = %s", _keyNames[ck_AdminLevel], temp2);
	fprintf(file, "^n^n; Default max number of people who can use a class of this type^n");
	fprintf(file, "%s = %d", _keyNames[ck_MaxNumber], tempClassType[DefaultClass][MaxNumber]);
	
	formatex(temp2, 127, "%s %s", ZP_DefClassFileName, tempClassType[TypeName]);
	ExecuteForward(g_Forwards[fwWriteClassData], g_Forwards[fwDummy], temp2, file);
	
	fclose(file);
}
