#if defined _flags32_included
#endinput
#endif
#define _flags32_included

#include <amxmodx>

stock const __flags[] = "abcdefghijklmnopqrstuvwxyz012345";

stock const __shifts[] = {
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,26,27,28,29,30,31,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,
	23,24,25,-1,-1,-1,-1,-1
};

stock get_flags32(flags, output[], len) {
	new pos;
	for (new i; i < 32 && pos < len; i++) {
		if(flags & 1<<i) {
			output[pos++] = __flags[i];
		}
	}
	
	output[pos] = EOS;
	return pos;
}

stock read_flags32(const flags[]) {
	new ret, shift;
	for (new i, c; (c = flags[i]); i++) {
		shift = __shifts[c];
		if(shift >= 0) {
			ret |= 1<<shift;
		}
	}
	
	return ret;
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
