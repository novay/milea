sinput string Stochastic_Oscullator; //*****     Stochastic Oscullator    *****
extern bool Use_Stoch    = true; //Stochastic Oscullator is used
extern bool STO_invert   = false; //Invert Trigger
extern ENUM_TIMEFRAMES Stoch_tf = PERIOD_M1; //Time Frame
extern int Stoch_K       = 14; //Period of the %K line
extern int Stoch_D       = 5;  //Period of the %D line
extern int Stoch_Slowing = 3;  //Slowing value
extern ENUM_MA_METHOD Stoch_Method = MODE_SMA;  //Moving Average method
extern ENUM_STO_PRICE Stoch_Price = STO_LOWHIGH; //Price field parameter
extern int Stoch_Shift   = 0;  //Shift
extern double Stoch_Lower = 30; //Lower level
extern double Stoch_Upper = 70; //Upper level


bool STO_Buy() {
   double Sto_Value = iStochastic(Symbol(), Stoch_tf, Stoch_K, Stoch_D, Stoch_Slowing, Stoch_Method, Stoch_Price, MODE_SIGNAL, Stoch_Shift);
   if (!STO_invert) {
      if (Sto_Value < Stoch_Lower) return(true);
      return(false);
   } else {
      if (Sto_Value > Stoch_Lower && Sto_Value < Stoch_Upper ) return(true);
      return(false);
   }
}

bool STO_Sell() {
   double Sto_Value = iStochastic(Symbol(), Stoch_tf, Stoch_K, Stoch_D, Stoch_Slowing, Stoch_Method, Stoch_Price, MODE_SIGNAL, Stoch_Shift);
   if (!STO_invert) {
      if (Sto_Value > Stoch_Upper) return(true);
      return(false);
   } else {
      if (Sto_Value > Stoch_Lower && Sto_Value < Stoch_Upper ) return(true);
      return(false);
   }
}

void sto_indicators() {
	if(buys == 0 && Time_to_Trade()) {
		if (Use_Stoch) {
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
		if(Use_Stoch) {
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