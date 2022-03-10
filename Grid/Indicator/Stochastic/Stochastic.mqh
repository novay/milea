//**************************************************
// Stochastic Oscullator presets
//**************************************************
sinput string 				Stochastic_Oscullator; 			//***** Stochastic Oscullator *****
extern bool 				UseSTO    		= true; 			// Enable Stochastic Oscullator
extern bool 				STOInvert   	= false; 		// Invert Trigger
extern ENUM_TIMEFRAMES 	STOTimeFrame 	= PERIOD_M1; 	// Time Frame
extern int 					STOKLine      	= 14; 			// Period of the %K line
extern int 					STODLine      	= 5;  			// Period of the %D line
extern int 					STOSlowing 		= 3;  			// Slowing value
extern ENUM_MA_METHOD 	STOMethod 		= MODE_SMA;  	// Moving Average method
extern ENUM_STO_PRICE 	STOPrice 		= STO_LOWHIGH; // Price field parameter
extern int 					STOShift   		= 0;  			// Shift
extern double 				STOLower 		= 30; 			// Lower level
extern double 				STOUpper 		= 70; 			// Upper level

//**************************************************
// Finding buy signal using Stochastic Oscullator
//**************************************************
bool STOBuy() {
   double value = iStochastic(Symbol(), STOTimeFrame, STOKLine, STODLine, STOSlowing, STOMethod, STOPrice, MODE_SIGNAL, STOShift);
   if (!STOInvert) {
      if (value < STOLower) return(true);
      return(false);
   } else {
      if (value > STOLower && value < STOUpper ) return(true);
      return(false);
   }
}

//**************************************************
// Finding sell signal using Stochastic Oscullator
//**************************************************
bool STOSell() {
   double value = iStochastic(Symbol(), STOTimeFrame, STOKLine, STODLine, STOSlowing, STOMethod, STOPrice, MODE_SIGNAL, STOShift);
   if (!STOInvert) {
      if (value > STOUpper) return(true);
      return(false);
   } else {
      if (value > STOLower && value < STOUpper ) return(true);
      return(false);
   }
}