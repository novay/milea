//**************************************************
// Deal with global vars to save and restore data, while chart is 
// closed or must be restarted by other reason
//**************************************************
void ReadPrevSession() {
   if(!IsTesting()) {
      int count = GlobalVariablesTotal();
      if(count > 0) {
         // // Show or hide panel button 
         // if(GlobalVariableCheck(globalVarsID + "showComment"))
         //    showComment = (int)GlobalVariableGet(globalVarsID + "showComment");

         // // Stop On Next Cycle button
         // if(GlobalVariableCheck(globalVarsID + "stop_next_cycle"))
         //    stop_next_cycle = (int)GlobalVariableGet(globalVarsID + "stop_next_cycle");

         // // Rest & Realize button
         // if(GlobalVariableCheck(globalVarsID + "rest_and_realize"))
         //    rest_and_realize = (int)GlobalVariableGet(globalVarsID + "rest_and_realize");

         // // Stop & Close button
         // if(GlobalVariableCheck(globalVarsID + "stopAll"))
         //    stopAll = (int)GlobalVariableGet(globalVarsID + "stopAll");
      }
   }
}

//**************************************************
// Time filters functions - 
// Checking if trade time is on or no
//**************************************************
bool TradeTime() {
    if(TimeFilter == true) {
        int jam = TimeHour(TimeCurrent());
        if(StartHour > jam && jam < EndHour) {
            return(true);
        } else {
            return(false);
        }
    }
    return(true);
}

//**************************************************
// Open on New Candle - 
// returns if new bar has started
//**************************************************
bool IsNewCandle()
{
   static datetime time = Time[0];
   if(Time[0] > time)
   {
      time = Time[0];
      return (true);
   } 
   return(false);
}

//**************************************************
// Calculating lot size - 
// Based on used progression
//**************************************************
double LotSize(int positions) {
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
         factor = Fibonacci(positions);
      break;
   }

   return(factor * Lot);
}

//**************************************************
// Calculating next lot size - 
// Based on used progression
//**************************************************
double NextLotSize(int orderType) {
   if(orderType == OP_BUY && buys == 0) return(Lot);
   if(orderType == OP_SELL && sells == 0)  return(Lot);

   switch(Sequence) {
      case 0:
         return(Lot);
      break;
      case 1:
         if(orderType == OP_BUY) 
            return(buy_lots[buys - 1] + buy_lots[0]);
         else 
            return(sell_lots[sells - 1] + sell_lots[0]);
      break;
      case 2:
         if(orderType == OP_BUY) 
            return(2 * buy_lots[buys - 1]);
         else 
            return(2 * sell_lots[sells - 1]);
      break;
      case 3:
         if(orderType == OP_BUY)
            return(Fibonacci(buys + 1) * buy_lots[0]);
         else
            return(Fibonacci(sells + 1) * sell_lots[0]);
      break;
   }

   return(Lot);
}

//**************************************************
// Calculating starting lot size - 
// Based on Initial lots from properties
//**************************************************
double InitLot() {
   double volume = Lot;

   if(volume > MarketInfo(Symbol(), MODE_MAXLOT)) {
      volume = MarketInfo(Symbol(), MODE_MAXLOT);
   }

   if(volume < MarketInfo(Symbol(), MODE_MINLOT)) {
      volume = MarketInfo(Symbol(), MODE_MINLOT);
   }

   return(volume);
}

//**************************************************
// Fibonacci Sequence (1, 2, 3, 5, 8, ...)
//**************************************************
int Fibonacci(int index) 
{
   int val1 = 0, val2 = 1, val3 = 0;
   for(int i = 1; i < index; i++) {
      val3 = val2;
      val2 = val1 + val2;
      val1 = val3;
   }

   return(val2);
}

//**************************************************
// Calculating space for grid distance
//**************************************************
double DistanceGrid(double volume, int positions) {
   double grid_space;
   double grid_volume = LotSize(positions) / Lot;

   grid_space = - (grid_volume * Distance * PipValue(volume));
   return(grid_space);
}

//**************************************************
// Calculating pips value
//**************************************************
double PipValue(double volume) {
   double   pip_value   = 0;
   double   pip_tick    = market_tick_value;
   double   pip_size    = market_tick_size;
   double   pip_lots;
   int      pip_digits  = market_digits;

   if(volume != 0) {
      pip_lots = 1 / volume;

      if(pip_digits == 5 || pip_digits == 3) {
         pip_value = pip_tick * 10;
      } else if(pip_digits == 4 || pip_digits == 2) {
         pip_value = pip_tick;
      }

      pip_value = pip_value / pip_lots;
   }

   return(pip_value);
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
double StopLoss(double volume, int positions) 
{
   // volume = volume of last position only
   double aux_stop_loss;

   // #008: use Sequence for grid size as well as volume
   double myVal = LotSize(positions) / Lot;

   aux_stop_loss = - (myVal * Distance * PipValue(volume));

   // the stop loss line is calculated in ShowLines and the value to clear a position does also not use this value
   return(aux_stop_loss);
}