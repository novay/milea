sinput string ATR_for_Grid_Size; //*****     Average True Range      *****
extern bool Use_ATR           = false;      //Using ATR for Grid Size
extern ENUM_TIMEFRAMES ATR_tf = PERIOD_H1;  //Time Frame
extern int ATR_Period         = 5;          //Period
extern int ATR_shift          = 0;          //Shift;
extern double ATR_Multiplier  = 3.0;        //ATR Multiplier
extern double TP_Multiplier   = 1.0;        //TP Multiplier (Ratio of ATR)

double ATR_Grid_Size() {
   int digits, scale = 10000;
   digits = (int)MarketInfo(Symbol(), MODE_DIGITS);

   if (digits == 3 || digits == 2) scale = 100;
   if (Use_ATR) {
      return ((int)round(ATR_Multiplier * scale * iATR(Symbol(), ATR_tf, ATR_Period, ATR_shift)));
   } else {
      return Distance;
   }
}

void atr_indicators() {
	if(buys == 0 && Time_to_Trade()) {
		if (Use_ATR) {
			Distance = ATR_Grid_Size();
			take_profit = TP_Multiplier * ATR_Grid_Size() / ATR_Multiplier;
		}

		if(!stopNextCycle && !restAndRealize) {
			ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, key + "-" + (string)buys, magic, 0, Blue);
		}
	}

	if(sells == 0 && Time_to_Trade()) {
		if(Use_ATR) {
			Distance = ATR_Grid_Size();
			take_profit = TP_Multiplier * ATR_Grid_Size() / ATR_Multiplier;
		}
		if(!stopNextCycle && !restAndRealize) {
			ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, key + "-" + (string)sells, magic, 0, Red);
		}
	}
}
