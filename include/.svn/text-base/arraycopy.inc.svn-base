#if defined _arraycopy
	#endinput
#endif
#define _arraycopy

#include <amxmodx>

/**
 * Copies information from one array into another.
 * 
 * @param into		The array to place the data into
 * @param from		The array to get the data from
 * @param len		The number of cells to copy
 * @param ignoretags	True to enable tag comparison, false to
 * 			ignore them.
 * @param intotag	The tagof constant for the into array
 * @param intosize	The max size of data to place into
 * 			the array
 * @param intopos	The starting position to place data
 * 			into
 * @param fromtag	The tagof constant for the from array
 * @param fromsize	The max size of data to place from
 * 			the array
 * @param frompos	The starting position to begin copying
 * 			data from
 */
stock arraycopy( any:into[], any:from[], len = sizeof into, bool:ignoretags = false, intotag = tagof into, intosize = sizeof into, intopos = 0, fromtag = tagof from, fromsize = sizeof from, frompos = 0) {
	if (!ignoretags && intotag != fromtag) {
		//So we know no elements were copied (we did not remove an element ie. returning -1)
		return 0;
	}
    
	new i
	while (i < len) {
		if (intopos >= intosize || frompos >= fromsize) {
			break;
		}
        
		into[intopos++] = from[frompos++];
		i++;
	}
    
	return i;
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
