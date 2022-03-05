sinput string 			__ATRSettings__; 				// ***** Average True Range *****
extern bool 			ATREnable		= false;      	// Enable ATR for Grid Size
extern ENUM_TIMEFRAMES 	ATRTimeFrame 	= PERIOD_H1;  	// Time Frame
extern int 				ATRPeriod       = 5;          	// Period
extern int 				ATRShift        = 0;          	// Shift
extern double 			ATRMultiplier  	= 3.0;        	// ATR Multiplier
extern double 			ATRTPMultiplier	= 1.0;        	// TP Multiplier (Ratio of ATR)

#include "functions.mqh"