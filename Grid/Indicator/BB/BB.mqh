enum BB_OPTIONS {
	ASK_BID, 
	HIGH_LOW
};

//**************************************************
// Bolinger Band presets
//**************************************************
sinput string 				Bolinger_Band; 				// ***** Bolinger Band *****
extern bool 				UseBB       = true;        // Enable Bolinger Band
extern bool 				BBInvert   	= false;       // Invert Trigger
extern ENUM_TIMEFRAMES 	BBTimeFrame = PERIOD_M1; 	// Time Frame
extern int 					BBPeriod   	= 20;          // Period
extern double 				BBDeviation = 3.0;         // Deviation
extern int 					BBShift    	= 0;           // Shift
extern BB_OPTIONS 		BBOption 	= ASK_BID; 		// Option

//**************************************************
// Finding buy signal using Bolinger Band
//**************************************************
bool BBBuy() {
   double bb_lower = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, BBShift);
   double bb_upper = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, BBShift);
   if (!BBInvert) {
      if (BBOption == ASK_BID && Ask < bb_lower) return(true);
      if (BBOption == HIGH_LOW && Low[0] < bb_lower) return(true);
      
      return(false);
   } else {
      if (BBOption == ASK_BID && Ask > bb_upper) return(true);
      if (BBOption == HIGH_LOW && Low[0] > bb_upper) return(true);

      return(false);
   }
}

//**************************************************
// Finding sell signal using Bolinger Band
//**************************************************
bool BBSell() {
   double bb_lower = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, BBShift);
   double bb_upper = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, BBShift);
   if (!BBInvert) {
      if (BBOption == ASK_BID && Bid > bb_upper) return(true);
      if (BBOption == HIGH_LOW && High[0] > bb_upper) return(true);

      return(false);
   } else {
      if (BBOption == ASK_BID && Bid < bb_lower) return(true);
      if (BBOption == HIGH_LOW && High[0] < bb_lower) return(true);

      return(false);
   }
}