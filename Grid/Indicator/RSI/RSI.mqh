sinput string Relative_Strength_Index; //*****   Relative Strength Index   *****
extern bool Use_RSI      = true;   //RSI is used
extern bool RSI_invert   = false;  //Invert Trigger
extern ENUM_TIMEFRAMES RSI_tf = PERIOD_M1; //Time Frame
extern int RSI_Period    = 11;  //Period
extern double RSI_Lower  = 30;  //Lower level
extern double RSI_Upper  = 70;  //Upper level
extern int RSI_Shift     = 0;   //Shift


bool RSI_Buy() {
   double RSI_Value = iRSI(Symbol(), RSI_tf, RSI_Period, PRICE_CLOSE, RSI_Shift);
   if (!RSI_invert) {
      if (RSI_Value < RSI_Lower) return(true);
      return(false);
   } else {
      if (RSI_Value > RSI_Lower && RSI_Value < RSI_Upper) return(true);
      return(false);
   }
}

bool RSI_Sell() {
   double RSI_Value = iRSI(Symbol(), RSI_tf, RSI_Period, PRICE_CLOSE, RSI_Shift);
   if (!RSI_invert) {
      if (RSI_Value > RSI_Upper) return(true);
      return(false);
   } else {
      if (RSI_Value > RSI_Lower && RSI_Value < RSI_Upper) return(true);
      return(false);
   }
}

void rsi_indicators() {
	if(buys == 0 && Time_to_Trade()) {
		if (Use_RSI) {
			if(!stopNextCycle && !restAndRealize && Indicators_Buy()) {
				ticket = OrderSendReliable(Symbol(), OP_BUY, InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
				if(sells == 0 && both_cycle) {
					ticket = OrderSendReliable(Symbol(), OP_SELL, InitLot(), MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
				}
			}
		} else {
			if(!stopNextCycle && !restAndRealize) {
				ticket = OrderSendReliable(Symbol(), OP_BUY, InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
			}
		}
	}

	if(sells == 0 && Time_to_Trade()) {
		if(Use_RSI) {
			if(!stopNextCycle && !restAndRealize && Indicators_Sell()) {
				ticket = OrderSendReliable(Symbol(), OP_SELL, InitLot(), MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
				if(buys == 0 && both_cycle) {
					ticket = OrderSendReliable(Symbol(), OP_BUY, InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
				}
			}
		} else {
			if(!stopNextCycle && !restAndRealize) {
				ticket = OrderSendReliable(Symbol(), OP_SELL, InitLot(), MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
			}
		}
   }
}