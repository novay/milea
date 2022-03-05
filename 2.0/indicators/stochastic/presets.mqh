sinput string 			__STOSettings__; // ***** Stochastic Oscullator *****
extern bool 			STOEnable    	= true; // Enable Stochastic Oscullator
extern bool 			STOInvert   	= false; // Invert Trigger
extern ENUM_TIMEFRAMES 	STOTimeFrame	= PERIOD_M1; // Time Frame
extern int 				STOKLine       	= 14; // Period of the %K line
extern int 				STODLine       	= 5;  // Period of the %D line
extern int 				STOSlowing 		= 3;  // Slowing value
extern ENUM_MA_METHOD 	STOMethod 		= MODE_SMA; // Moving Average method
extern ENUM_STO_PRICE 	STOPrice 		= STO_LOWHIGH; // Price field parameter
extern int 				STOShift   		= 0; // Shift
extern double 			STOLower 		= 30; // Lower level
extern double 			STOUpper 		= 70; // Upper level

#include "functions.mqh"