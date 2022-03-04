enum BB_OPTIONS {
	ASK_BID, 
	HIGH_LOW
};

//+------------------------------------------------------------------+
//| Presets                                             			 |
//+------------------------------------------------------------------+
sinput string LineBB; 								// -- Bolinger Band --
extern bool 			BBEnable    = true;         // Enable Bolinger Band
extern bool 			BBInvert   	= false;        // Invert Trigger
extern ENUM_TIMEFRAMES 	BBTimeFrame = PERIOD_M1; 	// Time Frame
extern int 				BBPeriod   	= 20;           // Period
extern double 			BBDeviation = 3.0;          // Deviation
extern int 				BBShift    	= 0;            // Shift
extern BB_OPTIONS 		BBOption 	= ASK_BID; 		// Option

bool bb_buy() {
   double BBL = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, BBShift);
   double BBU = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, BBShift);
   if (!BBInvert) {
      if (BBOption == ASK_BID && Ask < BBL) return(true);
      if (BBOption == HIGH_LOW && Low[0] < BBL) return(true);
      
      return(false);
   } else {
      if (BBOption == ASK_BID && Ask > BBU) return(true);
      if (BBOption == HIGH_LOW && Low[0] > BBU) return(true);

      return(false);
   }
}

bool bb_sell() {
   double BBL = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, BBShift);
   double BBU = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, BBShift);
   if (!BBInvert) {
      if (BBOption == ASK_BID && Bid > BBU) return(true);
      if (BBOption == HIGH_LOW && High[0] > BBU) return(true);

      return(false);
   } else {
      if (BBOption == ASK_BID && Bid < BBL) return(true);
      if (BBOption == HIGH_LOW && High[0] < BBL) return(true);

      return(false);
   }
}

void bb_indicators() {
	if(buys == 0 && Time_to_Trade()) {
		if (BBEnable) {
			if(!stopNextCycle && !restAndRealize && Indicators_Buy()) {
				ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
				if(sells == 0 && both_cycle) {
					ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
				}
			}
		} else {
			if(!stopNextCycle && !restAndRealize) {
				ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
			}
		}
	}

	if(sells == 0 && Time_to_Trade()) {
		if(BBEnable) {
			if(!stopNextCycle && !restAndRealize && Indicators_Sell()) {
				ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
				if(buys == 0 && both_cycle) {
					ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
				}
			}
		} else {
			if(!stopNextCycle && !restAndRealize) {
				ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
			}
		}
   }
}