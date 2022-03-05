sinput string 			__RSISettings__; // ***** Relative Strength Index *****
extern bool 			RSIEnable      	= true;   // Enable RSI
extern bool 			RSIInvert   	= false;  // Invert Trigger
extern ENUM_TIMEFRAMES 	RSITimeFrame 	= PERIOD_M1; // Time Frame
extern int 				RSIPeriod    	= 11;  // Period
extern double 			RSILower  		= 30;  // Lower level
extern double 			RSIUpper  		= 70;  // Upper level
extern int 				RSIShift 		= 0;   // Shift

#include "functions.mqh"