//**************************************************
// Average True Range presets
//**************************************************
sinput string 				ATR_for_Grid_Size; 					// ***** Average True Range *****
extern bool 				EnableATR			= false; 		// Enable ATR for Grid Size
extern ENUM_TIMEFRAMES 	ATRTimeFrame 		= PERIOD_H1; 	// Time Frame
extern int 					ATRPeriod 			= 5; 				// Period
extern int 					ATRShift 			= 0; 				// Shift;
extern double 				ATRMultiplier  	= 3.0; 			// ATR Multiplier
extern double 				ATRTPMultiplier 	= 1.0; 			// TP Multiplier (Ratio of ATR)

//**************************************************
// Calculate grid size using Average True Range
//**************************************************
double ATRGridSize() {
	int digits, scale = 10000;
   digits = (int) MarketInfo(Symbol(), MODE_DIGITS);

   if(digits == 3 || digits == 2) scale = 100;
   if(EnableATR)
      return ((int)round(ATRMultiplier * scale * iATR(Symbol(), ATRTimeFrame, ATRPeriod, ATRShift)));
   else
      return Distance;
}