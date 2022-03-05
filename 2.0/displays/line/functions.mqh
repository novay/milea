//+------------------------------------------------------------------+
//  ShowLines
//+------------------------------------------------------------------+
void showLines() {

   double aux_tp_buy = 0, aux_tp_sell = 0; // TakeProfit(next positions) = take_profit * pipvalue
   double buy_tar = 0, sell_tar = 0;   // local results
   double buy_a = 0, sell_a = 0;       // sum: # of total opened Lots
   double buy_b = 0, sell_b = 0;       // sum: price payed for all positions
   double buy_pip = 0, sell_pip = 0;   // terminal value: tick_value / Lots
   double buy_v[max_open_positions],   // array: # of Lots of this index; if progression = 0, it is always 1; if prog. = 2 then: 1, 2, 4, 8, ...
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
      aux_tp_buy = TakeProfit(buy_lots[0]);
   } else if(progression == 0) {
      aux_tp_buy = TakeProfit(buy_lots[0]);
   } else if(progression == 1) {
      aux_tp_buy = buys * TakeProfit(buy_lots[0]);
   } else if(progression == 2) {
      aux_tp_buy = TakeProfit(buy_lots[buys - 1]);
   } else if(progression == 3) {
      aux_tp_buy = TakeProfit(buy_lots[buys - 1]);
   }

   if(sells <= 1) {
      aux_tp_sell = TakeProfit(sell_lots[0]);
   } else if(progression == 0) {
      aux_tp_sell = TakeProfit(sell_lots[0]);
   } else if(progression == 1) {
      aux_tp_sell = sells * TakeProfit(sell_lots[0]);
   } else if(progression == 2) {
      aux_tp_sell = TakeProfit(sell_lots[sells - 1]);
   } else if(progression == 3) {
      aux_tp_sell = TakeProfit(sell_lots[sells - 1]);
   }

   double tp_buy = aux_tp_buy;
   double tp_sell = aux_tp_sell;

   if(buys >= 1) {

      buy_pip = PipValue(buy_lots[0]);
      for(i = 0; i < max_open_positions; i++) buy_v[i] = 0;

      for(i = 0; i < buys; i++) {
         buy_v[i] = MathRound(buy_lots[i] / buy_lots[0]);
         //Print(StringConcatenate("buy_v[",i,"] = ",buy_v[i]));
      }

      for(i = 0; i < buys; i++) {
         buy_a = buy_a + buy_v[i];
         buy_b = buy_b + buy_price[i] * buy_v[i];
      }

      buy_tar = aux_tp_buy / (buy_pip / market_point);
      //Print(StringConcatenate("buy_tar 1: ",buy_tar));
      buy_tar = buy_tar + buy_b;
      //Print(StringConcatenate("buy_tar 2: ",buy_tar));
      buy_tar = buy_tar / buy_a;
      //Print(StringConcatenate("RESULT BUY: ",buy_tar));

      swapDiff = MathAbs(CalculateTicksByPrice(total_buy_lots, total_buy_swap));
      line_buy = buy_tar + swapDiff;

      // TODO show the correct takeprofit buy line
      // calculate new line if there are hedge sell lots
      if(total_hedge_sell_lots > 0) {
         hedgeSellDiff = MathAbs(CalculateTicksByPrice(total_hedge_sell_lots, total_hedge_sell_profit));
         line_buy = line_buy + hedgeSellDiff;
      }

      HorizontalLine(line_buy, "TakeProfit_buy", DodgerBlue, STYLE_SOLID, 2);
      //debug_comment_dyn+="\nline_buy: "+DoubleToString(line_buy,3);

      market_channel = buy_tar / market_tick_size;    // market_channel=line_buy - line_sell

      // calculate trailing stop line
      if(buy_close_profit > 0) {
         buy_tar = buy_close_profit / (buy_pip / market_point);
         buy_tar = buy_tar + buy_b;
         line_buy_ts = buy_tar / buy_a;
         HorizontalLine(line_buy_ts, "ProfitLock_buy", DodgerBlue, STYLE_DASH, 1);
      }

      // #027: extern option to hide forecast lines
      // #029: hide forecast lines, if trailing stop is active
      if(ShowForecast && line_buy_ts == 0) {
         // #022: show next line_buy/line_sell
         // #045: Fine tuning lines buy/sell next based on profit instead of Distance
         if(GSProgression == 0) line_buy_next = buy_price[buys - 1] - market_ticks_per_grid;
         else if(GSProgression == 1) line_buy_next = buy_price[buys - 1] - buys * market_ticks_per_grid;
         else if(GSProgression == 2) line_buy_next = buy_price[buys - 1] + CalculateTicksByPrice(buy_lots[buys - 1], StopLoss(buy_lots[buys - 1], buys));
         else if(GSProgression == 3) line_buy_next = buy_price[buys - 1] + CalculateTicksByPrice(buy_lots[buys - 1], StopLoss(buy_lots[buys - 1], buys));

         HorizontalLine(line_buy_next, "Next_buy", DodgerBlue, STYLE_DASHDOT, 1);

         // #020: show line, where the next line_buy /line_sell would be, if it would be opened right now
         if(account_state != as_green && total_buy_profit < 0) {
            myVal = MathRound(buy_lots[buys - 1] / buy_lots[0]);
            buy_a += myVal;
            buy_b = (buy_b + market_price_sell * myVal);
            buy_tar = aux_tp_buy / (buy_pip / market_point);
            line_buy_tmp = (buy_tar + buy_b) / buy_a + swapDiff;
            if(line_buy_tmp > 0)
               HorizontalLine(line_buy_tmp, "NewTakeProfit_buy", clrDarkViolet, STYLE_DASHDOTDOT, 1);
         }
      }
   }

   if(sells >= 1) {

      sell_pip = PipValue(sell_lots[0]);
      for(i = 0; i < max_open_positions; i++) sell_v[i] = 0;

      for(i = 0; i < sells; i++) {
         sell_v[i] = MathRound(sell_lots[i] / sell_lots[0]);
      }
      // in one loop?
      for(i = 0; i < sells; i++) {
         sell_a = sell_a + sell_v[i];
         sell_b = sell_b + sell_price[i] * sell_v[i];
      }

      sell_tar = -1 * (aux_tp_sell / (sell_pip / market_point));
      sell_tar = sell_tar + sell_b;
      sell_tar = sell_tar / sell_a;

      swapDiff = MathAbs(CalculateTicksByPrice(total_sell_lots, total_sell_swap));
      line_sell = sell_tar - swapDiff;

      // TODO show the correct takeprofit sell line
      // calculate new line if there are hedge buy lots
      if(total_hedge_buy_lots > 0) {
         hedgeSellDiff = MathAbs(CalculateTicksByPrice(total_hedge_buy_lots, total_hedge_buy_profit));
         line_sell = line_sell - hedgeSellDiff;
      }

      HorizontalLine(line_sell, "TakeProfit_sell", Tomato, STYLE_SOLID, 2);

      market_channel -= sell_tar / market_tick_size;     // market_channel=line_buy - line_sell
      if(buys > 0 && sells > 0) {                        // only valid, if both direction have positions
         market_channel = MathAbs(market_channel);
      } else {
         market_channel = 0;
      }

      // calculate trailing stop line
      if(sell_close_profit > 0) {
         sell_tar = -1 * (sell_close_profit / (sell_pip / market_point));
         sell_tar = sell_tar + sell_b;
         line_sell_ts = sell_tar / sell_a;
         HorizontalLine(line_sell_ts, "ProfitLock_sell", Tomato, STYLE_DASH, 1);
      }

      // #027: extern option to hide forecast lines
      // #029: hide forecast lines, if trailing stop is active
      if(ShowForecast && line_sell_ts == 0) {
         // #022: show next line_buy/line_sell
         // line_sell_next=sell_price[sells-1]+CalculateVolume(sells)/Lots*market_ticks_per_grid;
         // #045: Fine tuning lines buy/sell next based on profit instead of Distance
         if(GSProgression == 0) line_sell_next = sell_price[sells - 1] + market_ticks_per_grid;
         else if(GSProgression == 1) line_sell_next = sell_price[sells - 1] + sells * market_ticks_per_grid;
         else if(GSProgression == 2) line_sell_next = sell_price[sells - 1] - CalculateTicksByPrice(sell_lots[sells - 1], StopLoss(sell_lots[sells - 1], sells));
         else if(GSProgression == 3) line_sell_next = sell_price[sells - 1] - CalculateTicksByPrice(sell_lots[sells - 1], StopLoss(sell_lots[sells - 1], sells));
         HorizontalLine(line_sell_next, "Next_sell", Tomato, STYLE_DASHDOT, 1);

         // #020: show line, where the next line_buy /line_sell would be, if it would be opened at the actual price
         if(account_state != as_green && total_sell_profit < 0) {
            myVal = MathRound(sell_lots[sells - 1] / sell_lots[0]);
            sell_a += myVal;
            sell_b = (sell_b + market_price_buy * myVal);
            sell_tar = -1 * (aux_tp_sell / (sell_pip / market_point));
            line_sell_tmp = (sell_b - (aux_tp_sell / (sell_pip / market_point))) / sell_a - swapDiff;

            if(line_sell_tmp > 0)
               HorizontalLine(line_sell_tmp, "NewTakeProfit_sell", clrDarkViolet, STYLE_DASHDOTDOT, 1);
         }
      }
   }

// #036: new line: margin call (free margin = 0)
// #039: fixing bug that Stop&Close buttons works only once: divide by zero, if total_buy/sell_lots = 0
   line_margincall = 0;
   if(ShowForecast && (account_state == as_yellow || account_state == as_red)) {
      double freeMargin = AccountFreeMargin();
      double maxLoss = freeMargin / market_tick_value * market_tick_size;
      //debug_comment_dyn+="\nmaxLoss: "+DoubleToString(maxLoss,3);
      if(total_buy_profit < total_sell_profit) { // calculate line_margincall for worse profit
         // formular to transfer an account price to chart diff:
         // profit (€) = tick_value * lot_size * chart diff (in ticks)
         // 30€ = 0,76 * 0.08 Lot * 500 (0,500) for USDJPY
         if(total_buy_lots > 0)
            line_margincall = market_price_buy - maxLoss / total_buy_lots;
         //debug_comment_dyn+="\nline_margincall buys: "+DoubleToString(line_margincall,3);
         if(line_margincall > 0 )
            HorizontalLine(line_margincall, "MarginCall", clrSilver, STYLE_SOLID, 5);
      } else {
         if(total_sell_lots > 0)
            line_margincall = market_price_sell + maxLoss / total_sell_lots;
         //debug_comment_dyn+="\nline_margincall sells: "+DoubleToString(line_margincall,3);
         if(maxLoss < market_price_sell)
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

void HorizontalLine(double value, string name, color c, int style, int thickness) {
   if(ObjectFind(name) == -1) {
      ObjectCreate(name, OBJ_HLINE, 0, Time[0], value);
   }
   ObjectSet(name, OBJPROP_PRICE1, value);
   ObjectSet(name, OBJPROP_STYLE, style);
   ObjectSet(name, OBJPROP_COLOR, c);
   ObjectSet(name, OBJPROP_WIDTH, thickness);
}