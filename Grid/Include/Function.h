void IsBooting(bool var) {
    if(var) {
        if(AccountCurrency() == "USD") market_symbol = "$";
        if(MarketInfo(Symbol(), MODE_DIGITS) == 4 || MarketInfo(Symbol(), MODE_DIGITS) == 2) {
            Slippage = MaxSlippage;
            market_multiplier = 1;
        } else if(MarketInfo(Symbol(), MODE_DIGITS) == 5 || MarketInfo(Symbol(), MODE_DIGITS) == 3) {
            market_multiplier = 10;
            Slippage = market_multiplier * MaxSlippage;
        }
        
        // Print("New program start at " + TimeToStr(TimeCurrent()));
        booting = false;
    }
}

bool TradeTime() {
    if(TimeFilter == true) {
        int jam = TimeHour(TimeCurrent());
        if(StartHour > jam && jam < EndHour) {
            return true;
        } else {
            return false;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| CalculateVolume                                                                 |
//+------------------------------------------------------------------+
double calculateVolume(int positions) {
   int factor = 0;
   int i = 0;

   if(positions == 0) return(Lot);

   switch(Sequence) {
   case 0:
      factor = 1;
      break;
   case 1:
      factor = positions;
      break;
   case 2:
      for(i = 1, factor = 1; i < positions; i++)
         factor = factor * 2;
      break;
   case 3:
      factor = FiboSequence(positions);
      break;
   }

   return(factor * Lot);
}

//+------------------------------------------------------------------+
//| CalculateNextVolume                                                                 |
//+------------------------------------------------------------------+
double CalculateNextVolume(int orderType) {
   if(orderType == OP_BUY && buys == 0) return(Lot);
   if(orderType == OP_SELL && sells == 0)  return(Lot);

   // next volume must be calulated by actual positions + 1
   switch(Sequence) {
   case 0:
      return(Lot);
      break;
   case 1:
      if(orderType == OP_BUY) {
         return(buy_lots[buys - 1] + buy_lots[0]);
      } else {
         return(sell_lots[sells - 1] + sell_lots[0]);
      }
      break;
   case 2:
      if(orderType == OP_BUY) {
         return(2 * buy_lots[buys - 1]);
      } else {
         return(2 * sell_lots[sells - 1]);
      }
      break;
   case 3:
      if(orderType == OP_BUY) {
         return(FiboSequence(buys + 1) * buy_lots[0]);
      } else {
         return(FiboSequence(sells + 1) * sell_lots[0]);
      }
      break;
   }

   return(Lot);
}

//+------------------------------------------------------------------+
//| CalculateMargin                                                  |
//+------------------------------------------------------------------+
double CalculateNextMargin() {
   double leverage = 100 / AccountLeverage();

   if(buys + sells == 0)
      return(Lot * leverage * market_mode_required);
   if(buys > sells) {
      return(CalculateNextVolume(OP_BUY) * leverage  * market_mode_required);
   } else {
      return(CalculateNextVolume(OP_SELL) * leverage * market_mode_required);
   }
}

//+------------------------------------------------------------------+
//| CALCULATE STARTING VOLUME                                        |
//+------------------------------------------------------------------+
double InitLot() {
   double volume = Lot;

   if(volume > MarketInfo(Symbol(), MODE_MAXLOT)) volume = MarketInfo(Symbol(), MODE_MAXLOT);
   if(volume < MarketInfo(Symbol(), MODE_MINLOT)) volume = MarketInfo(Symbol(), MODE_MINLOT);

   return(volume);
}

// ------------------------------------------------------------------------------------------------
// CALCULATE TICKS by PRICE
// ------------------------------------------------------------------------------------------------
double CalculateTicksByPrice(double volume, double price) {
   if(volume == 0) return(0);
   return(price * market_tick_size / market_tick_value / volume);
}

// ------------------------------------------------------------------------------------------------
// CALCULATE PRICE by TICK DIFFERENCE
// ------------------------------------------------------------------------------------------------
double CalculatePriceByTickDiff(double volume, double diff) {
   return(market_tick_value * volume * diff / market_tick_size);
}

// ------------------------------------------------------------------------------------------------
// CALCULATE PIP VALUE
// ------------------------------------------------------------------------------------------------
double PipValue(double volume) {
   double aux_mm_value = 0;

   double aux_mm_tick_value = market_tick_value;
   double aux_mm_tick_size = market_tick_size;
   int aux_mm_digits = market_digits;
   double aux_mm_veces_lots;

   if(volume != 0) {
      aux_mm_veces_lots = 1 / volume;
      if(aux_mm_digits == 5 || aux_mm_digits == 3) {
         aux_mm_value = aux_mm_tick_value * 10;
      } else if(aux_mm_digits == 4 || aux_mm_digits == 2) {
         aux_mm_value = aux_mm_tick_value;
      }
      aux_mm_value = aux_mm_value / aux_mm_veces_lots;
   }

   return(aux_mm_value);
}

// ------------------------------------------------------------------------------------------------
// CALCULATE TAKE PROFIT
// ------------------------------------------------------------------------------------------------
double TakeProfit(double volume) {
   double aux_take_profit;

   aux_take_profit = TakeProfit * PipValue(volume);

   return(aux_take_profit);
}

// ------------------------------------------------------------------------------------------------
// CALCULATE STOP LOSS
// ------------------------------------------------------------------------------------------------
double StopLoss(double volume, int positions) {
   // volume = volume of last position only
   double aux_stop_loss;

   // #008: use Sequence for grid size as well as volume
   double myVal = calculateVolume(positions) / Lot;

   aux_stop_loss = - (myVal * Distance * PipValue(volume));

   // the stop loss line is calculated in ShowLines and the value to clear a position does also not use this value
   return(aux_stop_loss);
}


int FiboSequence(int index) {
   int val1 = 0, val2 = 1, val3 = 0;
   for(int i = 1; i < index; i++) {
      val2 += val1;
   }
   return val2;
}