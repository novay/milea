enum ENUM_BB_OPTION { 
	ASK_BID, 
	HIGH_LOW
};

sinput string 			__BolingerBandSettings__; 		// ***** Bolinger Band *****
extern bool 			BBEnable       	= true;         // Bolinger Band is used
extern bool 			BBInvert    	= false;        // Invert Trigger
extern ENUM_TIMEFRAMES 	BBTimeFrame 	= PERIOD_M1; 	// Time Frame
extern int 				BBPeriod     	= 20;           // Period
extern double 			BBDeviation     = 3.0;          // Deviation
extern int 				BBShift      	= 0;            // Shift
extern ENUM_BB_OPTION 	BBOption 		= ASK_BID;      // Option

#include "functions.mqh"