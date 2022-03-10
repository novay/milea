//+------------------------------------------------------------------+
// WRITE labels on screen
//+------------------------------------------------------------------+
void Write(string name, string s, int x, int y, string font, int size, color c) {
   if(ObjectFind(name) == -1) {
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, 1);
   }
   ObjectSetText(name, s, size, font, c);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
}

//+------------------------------------------------------------------+
// HORIZONTAL LINE
//+------------------------------------------------------------------+
void HorizontalLine(double value, string name, color c, int style, int thickness) {
   if(ObjectFind(name) == -1) {
      ObjectCreate(name, OBJ_HLINE, 0, Time[0], value);
   }
   ObjectSet(name, OBJPROP_PRICE1, value);
   ObjectSet(name, OBJPROP_STYLE, style);
   ObjectSet(name, OBJPROP_COLOR, c);
   ObjectSet(name, OBJPROP_WIDTH, thickness);
}

//+------------------------------------------------------------------+
//  ShowLines
//+------------------------------------------------------------------+
void showLines() {

   double aux_tp_buy = 0, aux_tp_sell = 0; // CalculateTP(next positions) = take_profit * pipvalue
   double buy_tar = 0, sell_tar = 0;   // local results
   double buy_a = 0, sell_a = 0;       // sum: # of total opened min_lots
   double buy_b = 0, sell_b = 0;       // sum: price payed for all positions
   double buy_pip = 0, sell_pip = 0;   // terminal value: tick_value / min_lots
   double buy_v[max_open_positions],   // array: # of min_lots of this index; if progression = 0, it is always 1; if prog. = 2 then: 1, 2, 4, 8, ...
          sell_v[max_open_positions];

   ArrayInitialize(buy_v, 0);
   ArrayInitialize(sell_v, 0);
   double swapDiff = 0;                // swap accumulated until actual date
   double hedgeSellDiff = 0;
   double hedgeBuyDiff = 0;

   int i;
   double myVal = 1, offset = 0, spreadPart = 0, gridSizePart = 0;

// init all lines to 0 to make sure they will be removed, if not more active

   line_buy = 0;
   line_buy_tmp = 0;
   line_buy_next = 0;
   line_buy_ts = 0;
   line_sell = 0;
   line_sell_tmp = 0;
   line_sell_next = 0;
   line_sell_ts = 0;
   line_margincall = 0;

   if(buys <= 1) {
      aux_tp_buy = CalculateTP(buy_lots[0]);
   } else if(progression == 0) {
      aux_tp_buy = CalculateTP(buy_lots[0]);
   } else if(progression == 1) {
      aux_tp_buy = buys * CalculateTP(buy_lots[0]);
   } else if(progression == 2) {
      aux_tp_buy = CalculateTP(buy_lots[buys - 1]);
   } else if(progression == 3) {
      aux_tp_buy = CalculateTP(buy_lots[buys - 1]);
   }

   if(sells <= 1) {
      aux_tp_sell = CalculateTP(sell_lots[0]);
   } else if(progression == 0) {
      aux_tp_sell = CalculateTP(sell_lots[0]);
   } else if(progression == 1) {
      aux_tp_sell = sells * CalculateTP(sell_lots[0]);
   } else if(progression == 2) {
      aux_tp_sell = CalculateTP(sell_lots[sells - 1]);
   } else if(progression == 3) {
      aux_tp_sell = CalculateTP(sell_lots[sells - 1]);
   }

   double tp_buy = aux_tp_buy;
   double tp_sell = aux_tp_sell;

   if(buys >= 1) {

      buy_pip = CalculatePipValue(buy_lots[0]);
      for(i = 0; i < max_open_positions; i++) buy_v[i] = 0;

      for(i = 0; i < buys; i++) {
         buy_v[i] = MathRound(buy_lots[i] / buy_lots[0]);
         //Print(StringConcatenate("buy_v[",i,"] = ",buy_v[i]));
      }

      for(i = 0; i < buys; i++) {
         buy_a = buy_a + buy_v[i];
         buy_b = buy_b + buy_price[i] * buy_v[i];
      }

      buy_tar = aux_tp_buy / (buy_pip / ter_point);
      //Print(StringConcatenate("buy_tar 1: ",buy_tar));
      buy_tar = buy_tar + buy_b;
      //Print(StringConcatenate("buy_tar 2: ",buy_tar));
      buy_tar = buy_tar / buy_a;
      //Print(StringConcatenate("RESULT BUY: ",buy_tar));

      swapDiff = MathAbs(calculateTicksByPrice(total_buy_lots, total_buy_swap));
      line_buy = buy_tar + swapDiff;

      // TODO show the correct takeprofit buy line
      // calculate new line if there are hedge sell lots
      if(total_hedge_sell_lots > 0) {
         hedgeSellDiff = MathAbs(calculateTicksByPrice(total_hedge_sell_lots, total_hedge_sell_profit));
         line_buy = line_buy + hedgeSellDiff;
      }

      HorizontalLine(line_buy, "TakeProfit_buy", DodgerBlue, STYLE_SOLID, 2);
      //debugCommentDyn+="\nline_buy: "+DoubleToString(line_buy,3);

      ter_IkarusChannel = buy_tar / ter_tick_size;    // ter_IkarusChannel=line_buy - line_sell

      // calculate trailing stop line
      if(buy_close_profit > 0) {
         buy_tar = buy_close_profit / (buy_pip / ter_point);
         buy_tar = buy_tar + buy_b;
         line_buy_ts = buy_tar / buy_a;
         HorizontalLine(line_buy_ts, "ProfitLock_buy", DodgerBlue, STYLE_DASH, 1);
      }

      // #027: extern option to hide forecast lines
      // #029: hide forecast lines, if trailing stop is active
      if(show_forecast && line_buy_ts == 0) {
         // #022: show next line_buy/line_sell
         // #045: Fine tuning lines buy/sell next based on profit instead of Distance
         if(gs_progression == 0) line_buy_next = buy_price[buys - 1] - ter_ticksPerGrid;
         else if(gs_progression == 1) line_buy_next = buy_price[buys - 1] - buys * ter_ticksPerGrid;
         else if(gs_progression == 2) line_buy_next = buy_price[buys - 1] + calculateTicksByPrice(buy_lots[buys - 1], CalculateSL(buy_lots[buys - 1], buys));
         else if(gs_progression == 3) line_buy_next = buy_price[buys - 1] + calculateTicksByPrice(buy_lots[buys - 1], CalculateSL(buy_lots[buys - 1], buys));

         HorizontalLine(line_buy_next, "Next_buy", DodgerBlue, STYLE_DASHDOT, 1);

         // #020: show line, where the next line_buy /line_sell would be, if it would be opened right now
         if(accountState != as_green && total_buy_profit < 0) {
            myVal = MathRound(buy_lots[buys - 1] / buy_lots[0]);
            buy_a += myVal;
            buy_b = (buy_b + ter_priceSell * myVal);
            buy_tar = aux_tp_buy / (buy_pip / ter_point);
            line_buy_tmp = (buy_tar + buy_b) / buy_a + swapDiff;
            if(line_buy_tmp > 0)
               HorizontalLine(line_buy_tmp, "NewTakeProfit_buy", clrDarkViolet, STYLE_DASHDOTDOT, 1);
         }
      }
   }

   if(sells >= 1) {

      sell_pip = CalculatePipValue(sell_lots[0]);
      for(i = 0; i < max_open_positions; i++) sell_v[i] = 0;

      for(i = 0; i < sells; i++) {
         sell_v[i] = MathRound(sell_lots[i] / sell_lots[0]);
      }
      // in one loop?
      for(i = 0; i < sells; i++) {
         sell_a = sell_a + sell_v[i];
         sell_b = sell_b + sell_price[i] * sell_v[i];
      }

      sell_tar = -1 * (aux_tp_sell / (sell_pip / ter_point));
      sell_tar = sell_tar + sell_b;
      sell_tar = sell_tar / sell_a;

      swapDiff = MathAbs(calculateTicksByPrice(total_sell_lots, total_sell_swap));
      line_sell = sell_tar - swapDiff;

      // TODO show the correct takeprofit sell line
      // calculate new line if there are hedge buy lots
      if(total_hedge_buy_lots > 0) {
         hedgeSellDiff = MathAbs(calculateTicksByPrice(total_hedge_buy_lots, total_hedge_buy_profit));
         line_sell = line_sell - hedgeSellDiff;
      }

      HorizontalLine(line_sell, "TakeProfit_sell", Tomato, STYLE_SOLID, 2);

      ter_IkarusChannel -= sell_tar / ter_tick_size;     // ter_IkarusChannel=line_buy - line_sell
      if(buys > 0 && sells > 0) {                        // only valid, if both direction have positions
         ter_IkarusChannel = MathAbs(ter_IkarusChannel);
      } else {
         ter_IkarusChannel = 0;
      }

      // calculate trailing stop line
      if(sell_close_profit > 0) {
         sell_tar = -1 * (sell_close_profit / (sell_pip / ter_point));
         sell_tar = sell_tar + sell_b;
         line_sell_ts = sell_tar / sell_a;
         HorizontalLine(line_sell_ts, "ProfitLock_sell", Tomato, STYLE_DASH, 1);
      }

      // #027: extern option to hide forecast lines
      // #029: hide forecast lines, if trailing stop is active
      if(show_forecast && line_sell_ts == 0) {
         // #022: show next line_buy/line_sell
         // line_sell_next=sell_price[sells-1]+LotSize(sells)/min_lots*ter_ticksPerGrid;
         // #045: Fine tuning lines buy/sell next based on profit instead of Distance
         if(gs_progression == 0) line_sell_next = sell_price[sells - 1] + ter_ticksPerGrid;
         else if(gs_progression == 1) line_sell_next = sell_price[sells - 1] + sells * ter_ticksPerGrid;
         else if(gs_progression == 2) line_sell_next = sell_price[sells - 1] - calculateTicksByPrice(sell_lots[sells - 1], CalculateSL(sell_lots[sells - 1], sells));
         else if(gs_progression == 3) line_sell_next = sell_price[sells - 1] - calculateTicksByPrice(sell_lots[sells - 1], CalculateSL(sell_lots[sells - 1], sells));
         HorizontalLine(line_sell_next, "Next_sell", Tomato, STYLE_DASHDOT, 1);

         // #020: show line, where the next line_buy /line_sell would be, if it would be opened at the actual price
         if(accountState != as_green && total_sell_profit < 0) {
            myVal = MathRound(sell_lots[sells - 1] / sell_lots[0]);
            sell_a += myVal;
            sell_b = (sell_b + ter_priceBuy * myVal);
            sell_tar = -1 * (aux_tp_sell / (sell_pip / ter_point));
            line_sell_tmp = (sell_b - (aux_tp_sell / (sell_pip / ter_point))) / sell_a - swapDiff;

            if(line_sell_tmp > 0)
               HorizontalLine(line_sell_tmp, "NewTakeProfit_sell", clrDarkViolet, STYLE_DASHDOTDOT, 1);
         }
      }
   }

// #036: new line: margin call (free margin = 0)
// #039: fixing bug that Stop&Close buttons works only once: divide by zero, if total_buy/sell_lots = 0
   line_margincall = 0;
   if(show_forecast && (accountState == as_yellow || accountState == as_red)) {
      double freeMargin = AccountFreeMargin();
      double maxLoss = freeMargin / ter_tick_value * ter_tick_size;
      //debugCommentDyn+="\nmaxLoss: "+DoubleToString(maxLoss,3);
      if(total_buy_profit < total_sell_profit) { // calculate line_margincall for worse profit
         // formular to transfer an account price to chart diff:
         // profit (€) = tick_value * lot_size * chart diff (in ticks)
         // 30€ = 0,76 * 0.08 Lot * 500 (0,500) for USDJPY
         if(total_buy_lots > 0)
            line_margincall = ter_priceBuy - maxLoss / total_buy_lots;
         //debugCommentDyn+="\nline_margincall buys: "+DoubleToString(line_margincall,3);
         if(line_margincall > 0 )
            HorizontalLine(line_margincall, "MarginCall", clrSilver, STYLE_SOLID, 5);
      } else {
         if(total_sell_lots > 0)
            line_margincall = ter_priceSell + maxLoss / total_sell_lots;
         //debugCommentDyn+="\nline_margincall sells: "+DoubleToString(line_margincall,3);
         if(maxLoss < ter_priceSell)
            HorizontalLine(line_margincall, "MarginCall", clrSilver, STYLE_SOLID, 5);
      }
   }

// make sure, all unused lines (value=0) will be hidden
// buy lines
   if(line_buy == 0)       ObjectDelete("TakeProfit_buy");
   if(line_buy_next == 0)  ObjectDelete("Next_buy");
   if(line_buy_tmp == 0)   ObjectDelete("NewTakeProfit_buy");
   if(line_buy_ts == 0)    ObjectDelete("ProfitLock_buy");

// sell lines
   if(line_sell == 0)      ObjectDelete("TakeProfit_sell");
   if(line_sell_next == 0) ObjectDelete("Next_sell");
   if(line_sell_tmp == 0)  ObjectDelete("NewTakeProfit_sell");
   if(line_sell_ts == 0)   ObjectDelete("ProfitLock_sell");

   if(line_margincall == 0) ObjectDelete("MarginCall");
}