//**************************************************
// Relative Strength Index presets
//**************************************************
sinput string 				Relative_Strength_Index; 		// ***** Relative Strength Index *****
extern bool 				UseRSI     		= true;   		// Enable RSI
extern bool 				RSIInvert  		= false;  		// Invert Trigger
extern ENUM_TIMEFRAMES 	RSITimeFrame 	= PERIOD_M1; 	// Time Frame
extern int 					RSIPeriod 		= 11;  			// Period
extern double 				RSILower  		= 30;  			// Lower level
extern double 				RSIUpper  		= 70;  			// Upper level
extern int 					RSIShift   		= 0;   			// Shift

//**************************************************
// Finding buy signal using Relative Strength Index
//**************************************************
bool RSIBuy() {
   double value = iRSI(Symbol(), RSITimeFrame, RSIPeriod, PRICE_CLOSE, RSIShift);
   if (!RSIInvert) {
      if (value < RSILower) return(true);
      return(false);
   } else {
      if (value > RSILower && value < RSIUpper) return(true);
      return(false);
   }
}

//**************************************************
// Finding sell signal using Relative Strength Index
//**************************************************
bool RSISell() {
   double value = iRSI(Symbol(), RSITimeFrame, RSIPeriod, PRICE_CLOSE, RSIShift);
   if (!RSIInvert) {
      if (value > RSIUpper) return(true);
      return(false);
   } else {
      if (value > RSILower && value < RSIUpper) return(true);
      return(false);
   }
}