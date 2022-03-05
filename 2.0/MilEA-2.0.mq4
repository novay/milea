#define DEMO 1
#define max_open_positions 100   // maximum number of open positions, was constant = 50 before
#define max_auto_open_positions 90  // maximum number of automatic open positions, 10 positions for hedge trading

#include <stdlib.mqh>
#include <stderror.mqh>

#define ea_version "2.00"
#define ea_name "MilEA " + ea_version

#property version ea_version
#property strict

string Key = ea_name;
string KeyHedging = "Reverse";
int UserSlippage = 2;

#include "includes/inputs.mqh"
#include "indicators/indicators.mqh"
#include "libraries/OrderSendReliable.mqh"
#include "includes/variables.mqh"
#include "displays/displays.mqh"


// ------------------------------------------------------------------------------------------------
// START
// ------------------------------------------------------------------------------------------------
void OnTick() {

   #ifdef DEMO
      if(!IsDemo()) {
         stop_all = 0;
         MessageBox("Only work on DEMO account!", "S O R R Y !", MB_OK);
         stop_all = 1 / stop_all;
         return;
      }
   #endif

   max_float = MathMin(max_float, AccountProfit());

   // Do this only one time after starting the program
   if(is_first_loop) {
      if(AccountCurrency() == "EUR") market_symbol = "€";
      if(MarketInfo(Symbol(), MODE_DIGITS) == 4 || MarketInfo(Symbol(), MODE_DIGITS) == 2) {
         slippage = UserSlippage;
         market_chart_multiplier = 1;
      } else if(MarketInfo(Symbol(), MODE_DIGITS) == 5 || MarketInfo(Symbol(), MODE_DIGITS) == 3) {
         market_chart_multiplier = 10;
         slippage = market_chart_multiplier * UserSlippage;
      }

      // do we have any data from previous session?
      ReadIniData();

      debug_comment_stat += "\nNew program start at " + TimeToStr(TimeCurrent());
      is_first_loop = false;
   }

   // Pastikan AutoTrading telah aktif.
   if(IsTradeAllowed() == false) {
      Comment(ea_name + "\n\nTrade not allowed.");
      return;
   }

   market_price_buy  = MarketInfo(Symbol(), MODE_ASK);
   market_price_sell = MarketInfo(Symbol(), MODE_BID);
   market_tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
   market_spread     = MarketInfo(Symbol(), MODE_SPREAD);
   market_digits     = (int)MarketInfo(Symbol(), MODE_DIGITS);
   market_tick_size  = MarketInfo(Symbol(), MODE_TICKSIZE);
   market_point      = MarketInfo(Symbol(), MODE_POINT);

   // Koreksi Slippage
   if(slippage > UserSlippage) {
      market_point = market_point * 10;
   }

   market_time = TimeCurrent();
   market_ticks_per_grid = - CalculateTicksByPrice(Lots, StopLoss(Lots, 1)) - market_spread * market_tick_size;

   // #025: use equity percentage instead of unpayable position
   if(AccountEquity() > max_equity) {
      max_equity = AccountEquity();
   }

   // Updating current status:
   InitVars();
   UpdateVars();
   SortByLots();
   showData();
   showLines();

   // #023: implement account state by 3 colored button
   checkAccountState();

   // #010: implement button: Stop & Close
   if(stop_all) {
      // Closing all open orders
      SetButtonText("btnStopAll", "Continue");
      SetButtonColor("btnStopAll", colCodeRed, colFontLight);
      closeAllBuys();
      closeAllSells();
   } else {
      HandleCycleRisk();
      robot();
      HandleHedging();

      if(GridPartiallyClose > 0) {
         thinOutTheGrid();
      }
   }

   return;
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit() {
   // #047: add panel right upper corner
   ObjectDelete("panel_1_01");
   ObjectDelete("panel_1_02");
   ObjectDelete("panel_1_03");
   ObjectDelete("panel_1_04");
   ObjectDelete("panel_1_05");
   ObjectDelete("panel_1_06");
   ObjectDelete("panel_1_07");
   ObjectDelete("panel_1_08");
   ObjectDelete("panel_1_09");
   ObjectDelete("panel_1_10");
   ObjectDelete("panel_1_11");

   // implement buttons
   DrawButton("btnhedgeBuy", "Buy", btn_left_axis, btn_top_axis, btn_width, btn_height, false, colNeutral, clrBlack);
   DrawButton("btnhedgeSell", "Sell", btn_left_axis + btn_next_left, btn_top_axis, btn_width, btn_height, false, colNeutral, clrBlack);
   DrawButton("btnCloseLastBuy", "Cl. Last B", btn_left_axis, btn_top_axis + btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
   DrawButton("btnCloseLastSell", "Cl. Last S", btn_left_axis + btn_next_left, btn_top_axis + btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
   DrawButton("btnCloseAllBuys", "Cl. All Bs", btn_left_axis, btn_top_axis + 2 * btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
   DrawButton("btnCloseAllSells", "Cl. All Ss", btn_left_axis + btn_next_left, btn_top_axis + 2 * btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
   DrawButton("btnShowComment", "Show/Hide Comment", 5, btn_top_axis, btn_width * 2, btn_height, false, colNeutral, colCodeYellow);

   DrawButton("btnstopNextCycle", "Stop Next Cycle", btn_left_axis + 2 * btn_next_left, btn_top_axis, (int)(btn_width * 1.5), btn_height, false, colNeutral, clrBlack);
   DrawButton("btnrestAndRealize", "Rest & Realize", btn_left_axis + 2 * btn_next_left, btn_top_axis + btn_next_top, (int)(btn_width * 1.5), btn_height, false, colNeutral, clrBlack);
   DrawButton("btnStopAll", "Stop & Close", btn_left_axis + 2 * btn_next_left, btn_top_axis + 2 * btn_next_top, (int)(btn_width * 1.5), btn_height, false, colNeutral, clrBlack);

   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   DeleteButton("btnStopAll");
   DeleteButton("btnrestAndRealize");
   DeleteButton("btnstopNextCycle");

   DeleteButton("btnhedgeBuy");
   DeleteButton("btnhedgeSell");
   DeleteButton("btnCloseLastBuy");
   DeleteButton("btnCloseLastSell");
   DeleteButton("btnCloseAllBuys");
   DeleteButton("btnCloseAllSells");
}

// ------------------------------------------------------------------------------------------------
// Main auto trading method
// ------------------------------------------------------------------------------------------------
void robot() 
{
   int ticket = - 1;
   bool closed = FALSE;

   double local_total_buy_profit = 0, local_total_sell_profit = 0;

   // *************************
   // ACCOUNT RISK CONTROL
   // *************************
   if(((100 - (100 * AccountRisk)) / 100)*AccountBalance() > AccountEquity()) {
      // #012: make account risk save: all positions will be cleared and trading will be paused by stop&close button
      stop_all = 1;
   }

   local_total_buy_profit = total_buy_profit;
   local_total_sell_profit = total_sell_profit;

   // check if there is a hedge trade open
   // if the hedge trade is buy and it is max trade lot
   // then calculate new local_total_sell_profit with the hedge buy order
   if(hedge_buys > 0) {
      // max hedge lot means this is a correction lot
      local_total_sell_profit = total_sell_profit + total_hedge_buy_profit;
   }

   // if the hedge trade is sell and it is max trade lot
   // then calculate new local_total_buy_profit with the hedge sell order
   if(hedge_sells > 0) {
      // max hedge lot means this is a correction lot
      local_total_buy_profit = total_buy_profit + total_hedge_sell_profit;
   }

   // **************************************************
   // BUYS==0
   // **************************************************
   // there are not buys check the indicators and open new buy order
   // if(buys == 0 && Time_to_Trade()) {
   if(buys == 0) {

      if (ATREnable) {
         Distance = ATRGridSize();
         TakeProfit = ATRTPMultiplier * ATRGridSize() / ATRMultiplier; // maybe fixed take profit better?
      }
      // #019: new button: Stop Next Cyle, which trades normally, until cycle is closed
      if (BBEnable || STOEnable || RSIEnable) {
         if(!stop_next_cycle && !rest_and_realize && IndicatorsBuy()) {
            ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
            if(sells == 0 && BothCycle) {
               ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
            }
         }
      } else {
         if(!stop_next_cycle && !rest_and_realize) {
            ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
         }
      }
   }

   // **************************************************
   // BUYS == 1
   // **************************************************
   if(buys == 1) {

      if(!stop_next_cycle && !rest_and_realize && MaxPosition > 1) {
         // CASE 1 >>> We reach Stop Loss (grid size)
         if(buy_profit[buys - 1] <= StopLoss(buy_lots[buys - 1], 1)) {
            // We are going to open a new order. Volume depends on chosen progression.
            NewGridOrder(OP_BUY, false);
         }
      }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(buy_max_profit == 0 && local_total_buy_profit > TakeProfit(buy_lots[0])) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * buy_max_profit;
      }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(buy_max_profit > 0 && local_total_buy_profit > buy_max_profit) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * local_total_buy_profit;
      }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(buy_max_profit > 0 && buy_close_profit > 0
            && buy_max_profit >= buy_close_profit && local_total_buy_profit < buy_close_profit) {
         // At this point all order are closed.
         // Global vars will be updated thanks to UpdateVars() on next start() execution
         closeAllBuys();
      }
   } // if (buys==1)

   // **************************************************
   // BUYS > 1
   // **************************************************
   if(buys > 1) {

      // CASE 1 >>> We reach Stop Loss (grid size)
      if(buy_profit[buys - 1] <= StopLoss(buy_lots[buys - 1], buys)) {
         // We are going to open a new order if we have less than 90 orders opened.
         // Volume depends on chosen progression.
         if(buys < max_auto_open_positions) {
            if(buys < MaxPosition && !buy_max_order_lot_open) {
               NewGridOrder(OP_BUY, false);
            }
         }
      }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(buy_max_profit == 0 && progression == 0 && local_total_buy_profit > TakeProfit(buy_lots[0])) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * buy_max_profit;
         if (!buy_chased && ProfitChasing > 0) {
            if (buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
            }
            buy_chased = true;
         }
      }
      if(buy_max_profit == 0 && progression == 1 && local_total_buy_profit > buys * TakeProfit(buy_lots[0])) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * buy_max_profit;
         if(!buy_chased && ProfitChasing > 0) {
            if (buys < max_auto_open_positions && buys < MaxPosition)
               ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
            buy_chased = true;
         }
      }
      if(buy_max_profit == 0 && progression == 2 && local_total_buy_profit > TakeProfit(buy_lots[buys - 1])) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * buy_max_profit;
         if(!buy_chased && ProfitChasing > 0) {
            if (buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
            }
            buy_chased = true;
         }
      }
      if(buy_max_profit == 0 && progression == 3 && local_total_buy_profit > TakeProfit(buy_lots[buys - 1])) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * buy_max_profit;
         if(!buy_chased && ProfitChasing > 0) {
            if (buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
            }
            buy_chased = true;
         }
      }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(buy_max_profit > 0 && local_total_buy_profit > buy_max_profit) {
         buy_max_profit = local_total_buy_profit;
         buy_close_profit = ProfitLock * local_total_buy_profit;
      }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(buy_max_profit > 0 && buy_close_profit > 0 && buy_max_profit >= buy_close_profit
            && local_total_buy_profit < buy_close_profit) {
         // At this point all order are closed.
         // Global vars will be updated thanks to UpdateVars() on next start() execution
         closeAllBuys();
      }
   } // if (buys>1)

   debug_comment_close_buys
      = "\nbuys will be closed if:\n" +
        "    - buy max profit: " + DoubleToString(buy_max_profit, 2) + " > buy close profit: " + DoubleToString(buy_close_profit, 2) + "     AND \n" +
        "    - total buy profit: " + DoubleToString(local_total_buy_profit, 2) + " < buy close profit: " + DoubleToString(buy_close_profit, 2) + "\n";

   // **************************************************
   // SELLS==0
   // **************************************************
   // there are not sells check the indicators and open new buy order
   // if(sells == 0 && Time_to_Trade()) {
   if(sells == 0) {

      if(ATREnable) {
         Distance = ATRGridSize();
         TakeProfit = ATRTPMultiplier * ATRGridSize() / ATRMultiplier;
      }
      // #019: new button: Stop Next Cyle, which trades normally, until cycle is closed
      if(BBEnable || STOEnable || RSIEnable) {
         if(!stop_next_cycle && !rest_and_realize && IndicatorsSell()) {
            ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
            if(buys == 0 && BothCycle) {
               ticket = OrderSendReliable(Symbol(), OP_BUY, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
            }
         }
      } else {
         if(!stop_next_cycle && !rest_and_realize) {
            ticket = OrderSendReliable(Symbol(), OP_SELL, CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
         }
      }
   }

   // **************************************************
   // SELLS == 1
   // **************************************************
   if(sells == 1) {

      // CASE 1 >>> We reach Stop Loss (grid size)
      if(!stop_next_cycle && !rest_and_realize && MaxPosition > 1) {
         if(sell_profit[sells - 1] <= StopLoss(sell_lots[sells - 1], 1)) {
            // We are going to open a new order. Volume depends on chosen progression.
            NewGridOrder(OP_SELL, false);
         }
      }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(sell_max_profit == 0 && local_total_sell_profit > TakeProfit(sell_lots[0])) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * sell_max_profit;
      }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(sell_max_profit > 0 && local_total_sell_profit > sell_max_profit) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * local_total_sell_profit;
      }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(sell_max_profit > 0 && sell_close_profit > 0
            && sell_max_profit >= sell_close_profit && local_total_sell_profit < sell_close_profit) {
         // At this point all order are closed.
         // Global vars will be updated thanks to UpdateVars() on next start() execution
         closeAllSells();
      }
   } // if (sells==1)

   // **************************************************
   // SELLS>1
   // **************************************************
   if(sells > 1) {

      // CASE 1 >>> We reach Stop Loss (grid size)
      if(sell_profit[sells - 1] <= StopLoss(sell_lots[sells - 1], sells)) {
         // We are going to open a new order if we have less than 90 orders opened.
         // Volume depends on chosen progression.
         if(sells < max_auto_open_positions) {
            if(sells < MaxPosition && !sell_max_order_lot_open) {
               NewGridOrder(OP_SELL, false);
            }
         }
      }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(sell_max_profit == 0 && progression == 0 && local_total_sell_profit > TakeProfit(sell_lots[0])) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * sell_max_profit;
         if(!sell_chased && ProfitChasing > 0) {
            if(buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_SELL, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
            }
            sell_chased = true;
         }
      }
      if(sell_max_profit == 0 && progression == 1 && local_total_sell_profit > sells * TakeProfit(sell_lots[0])) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * sell_max_profit;
         if(!sell_chased && ProfitChasing > 0) {
            if (buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_SELL, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
            }
            sell_chased = true;
         }
      }
      if(sell_max_profit == 0 && progression == 2 && local_total_sell_profit > TakeProfit(sell_lots[sells - 1])) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * sell_max_profit;
         if(!sell_chased && ProfitChasing > 0) {
            if(buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_SELL, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
            }
            sell_chased = true;
         }
      }
      if(sell_max_profit == 0 && progression == 3 && local_total_sell_profit > TakeProfit(sell_lots[sells - 1])) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * sell_max_profit;
         if(!sell_chased && ProfitChasing > 0) {
            if (buys < max_auto_open_positions && buys < MaxPosition) {
               ticket = OrderSendReliable(Symbol(), OP_SELL, ProfitChasing * CalculateStartingVolume(), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
            }
            sell_chased = true;
         }
      }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(sell_max_profit > 0 && local_total_sell_profit > sell_max_profit) {
         sell_max_profit = local_total_sell_profit;
         sell_close_profit = ProfitLock * sell_max_profit;
      }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(sell_max_profit > 0 && sell_close_profit > 0
            && sell_max_profit >= sell_close_profit && local_total_sell_profit < sell_close_profit) {
         // At this point all order are closed.
         // Global vars will be updated thanks to UpdateVars() on next start() execution
         closeAllSells();
      }
   } // if (sells>1)

   debug_comment_close_sells = "\nsells will be closed if:\n" +
                            "    - sell max profit: " + DoubleToString(sell_max_profit, 2) + " > sell close profit: " + DoubleToString(sell_close_profit, 2) + " AND \n" +
                            "    - total sell profit: " + DoubleToString(local_total_sell_profit, 2) + " < sell close profit: " + DoubleToString(sell_close_profit, 2);

   // #017: deal with global vars to save and restore data, while chart is closed or must be restarted by other reason
   WriteIniData();
}

//+------------------------------------------------------------------+
//| CheckAccountState
//+------------------------------------------------------------------+
void checkAccountState() {
   account_state = as_green;   // init state
   code_yellow_message = "";        // #038: give user info, why account state is yellow or red
   code_red_message = "";
   double myPercentage = 0;

   // check if MaxPosition is reached:
   if(buys >= MaxPosition) account_state = as_yellow;
   if(sells >= MaxPosition) account_state = as_yellow;
   if(account_state == as_yellow) code_yellow_message = "Code YELLOW: Max positions reached";

   // #024: calculate, if margin of next position can be paid
   if(CalculateNextMargin() > AccountFreeMargin()) {
      account_state = as_red;
      code_red_message = "Code RED: Next M. " + DoubleToString(CalculateNextMargin(), 2) + " > Free M. " + DoubleToString(AccountFreeMargin(), 2);
   }

   // #025: use equity percentage instead of unpayable position
   if((100 - (100 * EquityWarning)) / 100 * max_equity > AccountEquity()) {
      account_state = as_red;
      if(code_red_message == "") {
         code_red_message = "Code RED: Equ. " + DoubleToStr(AccountEquity(), 2) + " < " + DoubleToStr((100 * EquityWarning), 0) + "% of max. equ. " + DoubleToStr(max_equity, 2);
      } else {
         code_red_message += "\nand\nEqu. " + DoubleToStr(AccountEquity(), 2) + " < " + DoubleToStr((100 * EquityWarning), 0) + "% of max. equ. " + DoubleToStr(max_equity, 2);
      }
   }

   // #026: implement hedge trades, if account state is not green
   // #053: paint comment button in status color
   switch(account_state) {
   case as_yellow:
      SetButtonColor("btnhedgeBuy", colCodeYellow, colFontDark);
      SetButtonColor("btnhedgeSell", colCodeYellow, colFontDark);
      SetButtonColor("btnCloseLastBuy", colCodeYellow, colFontDark);
      SetButtonColor("btnCloseLastSell", colCodeYellow, colFontDark);
      SetButtonColor("btnCloseAllBuys", colCodeYellow, colFontDark);
      SetButtonColor("btnCloseAllSells", colCodeYellow, colFontDark);
      SetButtonColor("btnShowComment", colCodeYellow, colFontDark);
      break;
   case as_red:
      SetButtonColor("btnhedgeBuy", colCodeRed, colFontLight);
      SetButtonColor("btnhedgeSell", colCodeRed, colFontLight);
      SetButtonColor("btnCloseLastBuy", colCodeRed, colFontLight);
      SetButtonColor("btnCloseLastSell", colCodeRed, colFontLight);
      SetButtonColor("btnCloseAllBuys", colCodeRed, colFontLight);
      SetButtonColor("btnCloseAllSells", colCodeRed, colFontLight);
      SetButtonColor("btnShowComment", colCodeRed, colFontLight);
      break;
   default:
      SetButtonColor("btnhedgeBuy", colCodeGreen, colFontLight);
      SetButtonColor("btnhedgeSell", colCodeGreen, colFontLight);
      SetButtonColor("btnCloseLastBuy", colCodeGreen, colFontLight);
      SetButtonColor("btnCloseLastSell", colCodeGreen, colFontLight);
      SetButtonColor("btnCloseAllBuys", colCodeGreen, clrRed);
      SetButtonColor("btnCloseAllSells", colCodeGreen, clrRed);
      SetButtonColor("btnShowComment", colCodeGreen, colFontLight);
      break;
   }

   return;
}

//+------------------------------------------------------------------+
//| CalculateVolume                                                                 |
//+------------------------------------------------------------------+
double calculateVolume(int positions) {
   int factor = 0;
   int i = 0;

   if(positions == 0) return(Lots);

   switch(GSProgression) {
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

   return(factor * Lots);
}

//+------------------------------------------------------------------+
//| CalculateNextVolume                                                                 |
//+------------------------------------------------------------------+
double CalculateNextVolume(int orderType) {
   if(orderType == OP_BUY && buys == 0) return(Lots);
   if(orderType == OP_SELL && sells == 0)  return(Lots);

   // next volume must be calulated by actual positions + 1
   switch(progression) {
   case 0:
      return(Lots);
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

   return(Lots);
}

//+------------------------------------------------------------------+
//| CalculateMargin                                                  |
//+------------------------------------------------------------------+
double CalculateNextMargin() {
   double leverage = 100 / AccountLeverage();

   if(buys + sells == 0)
      return(Lots * leverage * market_mode_required);
   if(buys > sells) {
      return(CalculateNextVolume(OP_BUY) * leverage  * market_mode_required);
   } else {
      return(CalculateNextVolume(OP_SELL) * leverage * market_mode_required);
   }
}

//+------------------------------------------------------------------+
//| CALCULATE STARTING VOLUME                                        |
//+------------------------------------------------------------------+
double CalculateStartingVolume() {
   double volume;
   volume = Lots;

   if(volume > MarketInfo(Symbol(), MODE_MAXLOT)) {
      volume = MarketInfo(Symbol(), MODE_MAXLOT);
   }

   if(volume < MarketInfo(Symbol(), MODE_MINLOT)) {
      volume = MarketInfo(Symbol(), MODE_MINLOT);
   }
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

   // #008: use progression for grid size as well as volume
   double myVal = calculateVolume(positions) / Lots;

   aux_stop_loss = - (myVal * Distance * PipValue(volume));

   // the stop loss line is calculated in ShowLines and the value to clear a position does also not use this value
   return(aux_stop_loss);
}

//+------------------------------------------------------------------+
//|  CalulateFibonacci                                                                |
//+------------------------------------------------------------------+
int FiboSequence(int index) {
   int val1 = 0;
   int val2 = 1;
   int val3 = 0;

   for(int i = 1; i < index; i++) { // use this for: 1, 1, 2, 3, 5, 8, 13, 21, ...
      val3 = val2;
      val2 = val1 + val2;
      val1 = val3;
   }

   return val2;
}

//+------------------------------------------------------------------+
// closeAllSells
//+------------------------------------------------------------------+
void closeAllSells() {
   sell_max_profit = 0;
   sell_close_profit = 0;

   if(sells > 0) {
      closeAllhedgeBuys();
      for(int i = 0; i <= sells - 1; i++) {
         bool retVal = OrderCloseReliable(sell_tickets[i], sell_lots[i], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
      }
      ObjectDelete("TakeProfit_sell");
      ObjectDelete("ProfitLock_sell");
      ObjectDelete("Next_sell");
      ObjectDelete("NewTakeProfit_sell");
      line_sell = 0;
      line_sell_tmp = 0;
      line_sell_next = 0;
      line_sell_ts = 0;
   }
}

//+------------------------------------------------------------------+
// CloseAllBuys
//+------------------------------------------------------------------+
void closeAllBuys() {
   buy_max_profit = 0;
   buy_close_profit = 0;

   if(buys > 0) {
      closeAllhedgeSells();
      for(int i = 0; i <= buys - 1; i++) {
         bool retVal = OrderCloseReliable(buy_tickets[i], buy_lots[i], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
      }
      ObjectDelete("TakeProfit_buy");
      ObjectDelete("ProfitLock_buy");
      ObjectDelete("Next_buy");
      ObjectDelete("NewTakeProfit_buy");
      line_buy = 0;
      line_buy_tmp = 0;
      line_buy_next = 0;
      line_buy_ts = 0;
   }
}

//+------------------------------------------------------------------+
// closeAllhedgeSells
//+------------------------------------------------------------------+
void closeAllhedgeSells() {
   if(hedge_sells > 0) {
      for(int i = 0; i <= hedge_sells - 1; i++) {
         bool retVal = OrderCloseReliable(hedge_sell_tickets[i], hedge_sell_lots[i], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
      }
   }
}

//+------------------------------------------------------------------+
// closeAllhedgeBuys
//+------------------------------------------------------------------+
void closeAllhedgeBuys() {
   if(hedge_buys > 0) {
      for(int i = 0; i <= hedge_buys - 1; i++) {
         bool retVal = OrderCloseReliable(hedge_buy_tickets[i], hedge_buy_lots[i], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
      }
   }
}

//+------------------------------------------------------------------+
// CloseBuyHedgeAndFirstSellOrder
//+------------------------------------------------------------------+
void closeBuyHedgeAndFirstSellOrder() {
   buy_max_hedge_profit = 0;
   buy_close_hedge_profit = 0;

   bool retVal = OrderCloseReliable(sell_tickets[0], sell_lots[0], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
   closeAllhedgeBuys();
}

//+------------------------------------------------------------------+
// closeBuyHedgeAndFirstSellOrder
//+------------------------------------------------------------------+
void closeBuyHedgeAndLastAndSecondLastSellOrder() {

   closeAllhedgeBuys();
   bool retVal = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
   bool retVal2 = OrderCloseReliable(sell_tickets[sells - 2], sell_lots[sells - 2], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
}

//+------------------------------------------------------------------+
// closeSellHedgeAndFirstBuyOrder
//+------------------------------------------------------------------+
void closeSellHedgeAndFirstBuyOrder() {
   sell_max_hedge_profit = 0;
   sell_close_hedge_profit = 0;

   bool retVal = OrderCloseReliable(buy_tickets[0], buy_lots[0], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
   closeAllhedgeSells();
}

//+------------------------------------------------------------------+
// closeBuyHedgeAndLastAndSecondLastBuyOrder
//+------------------------------------------------------------------+
void closeSellHedgeAndLastAndSecondLastBuyOrder() {

   closeAllhedgeSells();
   bool retVal = OrderCloseReliable(buy_tickets[buys - 1], buy_lots[buys - 1], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
   bool retVal2 = OrderCloseReliable(buy_tickets[buys - 2], buy_lots[buys - 2], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
}

//+------------------------------------------------------------------+
// closeLastAndFirstBuyOrder
//+------------------------------------------------------------------+
void closeLastAndFirstBuyOrder() {

   bool retVal = OrderCloseReliable(buy_tickets[0], buy_lots[0], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
   bool retVal2 = OrderCloseReliable(buy_tickets[buys - 1], buy_lots[buys - 1], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
}

//+------------------------------------------------------------------+
// CloseLastAndFirstSellOrder
//+------------------------------------------------------------------+
void closeLastAndFirstSellOrder() {

   bool retVal = OrderCloseReliable(sell_tickets[0], sell_lots[0], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
   bool retVal2 = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), slippage, Red);
}

//+------------------------------------------------------------------+
//| NewGridOrder                                                     |
//+------------------------------------------------------------------+
void NewGridOrder(int orderType, bool ishedgely) {

   int ticket;
   double next_lot = Lots;

   // #018: rename button: stop next cyle to rest and realize; does not open new positions until cycle is closed
   // #019: Button: Stop On Next Cycle is still at Robot()
   if(rest_and_realize && !ishedgely) return;
   if(orderType == OP_BUY) {
      // new buy:
      if(progression == 0) next_lot = Lots;
      if(progression == 1) next_lot = buy_lots[buys - 1] + buy_lots[0];
      if(progression == 2) next_lot = 2 * buy_lots[buys - 1];
      if(progression == 3) next_lot = FiboSequence(buys + 1) * Lots;

      ticket = OrderSendReliable(Symbol(), OP_BUY, next_lot, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
   } else {
      // new sell:
      if(progression == 0) next_lot = Lots;
      if(progression == 1) next_lot = sell_lots[sells - 1] + sell_lots[0];
      if(progression == 2) next_lot = 2 * sell_lots[sells - 1];
      if(progression == 3) next_lot = FiboSequence(sells + 1) * Lots;

      ticket = OrderSendReliable(Symbol(), OP_SELL, next_lot, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
   }
}

//+------------------------------------------------------------------+
//| NewGridOrder                                                     |
//+------------------------------------------------------------------+
void NewGridOrderMaxPos(int orderType) {
   int ticket;

   // TODO test the order progressions
   if(rest_and_realize) return;
   if(orderType == OP_BUY) {
      // new hedging buy order
      if(progression == 0) ticket = OrderSendReliable(Symbol(), OP_BUY, Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)hedge_buys, magic, 0, Blue);
      if(progression == 1) ticket = OrderSendReliable(Symbol(), OP_BUY, MaxPosition * Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)hedge_buys, magic, 0, Blue);
      if(progression == 2) ticket = OrderSendReliable(Symbol(), OP_BUY, (2 * MaxPosition) * Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)hedge_buys, magic, 0, Blue);
      if(progression == 3) ticket = OrderSendReliable(Symbol(), OP_BUY, FiboSequence(MaxPosition) * Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key + "-" + (string)hedge_buys, magic, 0, Blue);
   } else {
      // new hedging sell order
      if(progression == 0) ticket = OrderSendReliable(Symbol(), OP_SELL, buy_lots[0], MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)hedge_sells, magic, 0, Red);
      if(progression == 1) ticket = OrderSendReliable(Symbol(), OP_SELL, MaxPosition * Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)hedge_sells, magic, 0, Red);
      if(progression == 2) ticket = OrderSendReliable(Symbol(), OP_SELL, (2 * MaxPosition) * Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)hedge_sells, magic, 0, Red);
      if(progression == 3) ticket = OrderSendReliable(Symbol(), OP_SELL, FiboSequence(MaxPosition) * Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key + "-" + (string)hedge_sells, magic, 0, Red);
   }
}

//+------------------------------------------------------------------+
//| NewGridOrder                                                     |
//+------------------------------------------------------------------+
void NewHedgingOrder(int orderType) {
   int ticket;

   // TODO test the order progressions
   if(rest_and_realize) return;
   if(orderType == OP_BUY) {
      
      // new hedging buy order
      if(progression == 0) ticket = OrderSendReliable(Symbol(), OP_BUY, Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, hedge_magic, 0, Blue);
      if(progression == 1) ticket = OrderSendReliable(Symbol(), OP_BUY, MaxPosition * Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, hedge_magic, 0, Blue);
      if(progression == 2) ticket = OrderSendReliable(Symbol(), OP_BUY, (2 * MaxPosition) * Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, hedge_magic, 0, Blue);
      if(progression == 3) ticket = OrderSendReliable(Symbol(), OP_BUY, FiboSequence(MaxPosition) * Lots, MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, hedge_magic, 0, Blue);
   } else {
      
      // new hedging sell order
      if(progression == 0) ticket = OrderSendReliable(Symbol(), OP_SELL, Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, hedge_magic, 0, Red);
      if(progression == 1) ticket = OrderSendReliable(Symbol(), OP_SELL, MaxPosition * Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, hedge_magic, 0, Red);
      if(progression == 2) ticket = OrderSendReliable(Symbol(), OP_SELL, (2 * MaxPosition) * Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, hedge_magic, 0, Red);
      if(progression == 3) ticket = OrderSendReliable(Symbol(), OP_SELL, FiboSequence(MaxPosition) * Lots, MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, hedge_magic, 0, Red);
   }
}

//+------------------------------------------------------------------+
//|  handle Hedging order profit                                     |
//+------------------------------------------------------------------+
void HandleCycleRisk() {

   if(UseTradeCycleRisk) {

      double local_total_buy_profit = 0, local_total_sell_profit = 0;

      local_total_buy_profit = total_buy_profit;
      local_total_sell_profit = total_sell_profit;

      if(hedge_buys > 0) {
         // max hedge lot means this is a correction lot
         local_total_sell_profit = total_sell_profit + total_hedge_buy_profit;
      }

      // if the hedge trade is sell and it is max trade lot
      // then calculate new local_total_buy_profit with the hedge sell order
      if(hedge_sells > 0) {
         local_total_buy_profit = total_buy_profit + total_hedge_sell_profit;
      }

      if((CycleEquityRisk * AccountBalance()) * -1 > local_total_sell_profit) {
         closeAllSells();
      }

      if((CycleEquityRisk * AccountBalance()) * -1 > local_total_buy_profit) {
         closeAllBuys();
      }
   }
}

//+------------------------------------------------------------------+
//|  handle Hedging order profit                                     |
//+------------------------------------------------------------------+
void HandleHedging() {

   if(EnableHedging) { // hedging is active but not open
      // double hedgeAmountStart = (hedgingEquityStart * AccountBalance()) * -1;
      if(!isHedgingSellActive() && buys >= MaxPosition) {
         if(buy_profit[buys - 1] <= StopLoss(buy_lots[buys - 1], buys)) {
            NewHedgingOrder(OP_SELL);
            NewGridOrderMaxPos(OP_BUY);
         }
      }
      if(!isHedgingBuyActive() && sells >= MaxPosition) {
         if(sell_profit[sells - 1] <= StopLoss(sell_lots[sells - 1], sells)) {
            NewHedgingOrder(OP_BUY);
            NewGridOrderMaxPos(OP_SELL);
         }
      }
   }

   if(isHedgingBuyActive()) {
      if(total_hedge_buy_profit > 0) {
         double sum_buy_profit = total_hedge_buy_profit + sell_profit[0]; // hedge - first order
         if(buy_max_hedge_profit == 0 && sum_buy_profit > TakeProfit(Lots)) { // fixed 10%
            buy_max_hedge_profit = sum_buy_profit;
            buy_close_hedge_profit = ProfitLock * sum_buy_profit;
         }

         if(buy_max_hedge_profit > 0 && sum_buy_profit > buy_max_hedge_profit) {
            buy_max_hedge_profit = sum_buy_profit;
            buy_close_hedge_profit = ProfitLock * buy_max_hedge_profit;
         }

         if(buy_max_hedge_profit > 0 && buy_close_hedge_profit > 0
               && buy_max_hedge_profit >= buy_close_hedge_profit && sum_buy_profit < buy_close_hedge_profit) {
            // At this point all order are closed.
            // Global vars will be updated thanks to UpdateVars() on next start() execution
            closeBuyHedgeAndFirstSellOrder();
         }
      }
      // close heding order faster by reverse trend
      if((sell_profit[sells - 1] + sell_profit[sells - 2]) > 0) {
         double sum_buy_profit = total_hedge_buy_profit + (sell_profit[sells - 1] + sell_profit[sells - 2]); // hedge + last order + last order -2
         if(sum_buy_profit > TakeProfit(Lots)) {
            closeBuyHedgeAndLastAndSecondLastSellOrder();
         }
      }
   }

   if(isHedgingSellActive()) {
      if(total_hedge_sell_profit > 0) {
         double sum_sell_profit = total_hedge_sell_profit + buy_profit[0]; // hedge - first order
         if(sell_max_hedge_profit == 0 && sum_sell_profit > TakeProfit(Lots)) { // fixed 10%
            sell_max_hedge_profit = sum_sell_profit;
            sell_close_hedge_profit = ProfitLock * sum_sell_profit;
         }

         if(sell_max_hedge_profit > 0 && sum_sell_profit > sell_max_hedge_profit) {
            sell_max_hedge_profit = sum_sell_profit;
            sell_close_hedge_profit = ProfitLock * sell_max_hedge_profit;
         }

         if(sell_max_hedge_profit > 0 && sell_close_hedge_profit > 0
               && sell_max_hedge_profit >= sell_close_hedge_profit && sum_sell_profit < sell_close_hedge_profit) {
            // At this point all order are closed.
            // Global vars will be updated thanks to UpdateVars() on next start() execution
            closeSellHedgeAndFirstBuyOrder();
         }
      }
      if((buy_profit[buys - 1] + buy_profit[buys - 2]) > 0) {
         double sum_sell_profit = total_hedge_sell_profit + buy_profit[buys - 1] + buy_profit[buys - 2]; // hedge + last order + last order -2
         if(sum_sell_profit > TakeProfit(Lots)) {
            closeSellHedgeAndLastAndSecondLastBuyOrder();
         }
      }
   }
}

//+------------------------------------------------------------------+
//|  isHedgingBuyActive                                              |
//+------------------------------------------------------------------+
bool isHedgingBuyActive() {

   if(is_buy_hedging_order_active) {
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//|  isHedgingSellActive                                             |
//+------------------------------------------------------------------+
bool isHedgingSellActive() {

   if(is_sell_hedging_order_active) {
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//|  thinOutTheGrid                                                  |
//+------------------------------------------------------------------+
void thinOutTheGrid() {

   // TODO lockProfit
   // double buy_close_profit_trail_orders = 0, sell_close_profit_trail_orders = 0;
   // check if MaxPosition is reached:
   if(buys >= GridPartiallyClose && !isHedgingSellActive()) {
      // calculate profit of the first and last buy order
      // trail the profit of the last and first buy order
      // close the first and the last buy order at trailed profit

      if(buy_profit[buys - 1] > 0) {
         double buy_profit_first_and_last = buy_profit[buys - 1] + buy_profit[0];
         if(buy_profit_first_and_last > TakeProfit(buy_lots[0])) {
            closeLastAndFirstBuyOrder();
         }
      }
   }

   if(sells >= GridPartiallyClose && !isHedgingBuyActive()) {
      // calculate profit of the first and last sell order
      // trail the profit of the last and first sell order
      // close the first and the last sell order at trailed profit

      if(sell_profit[sells - 1] > 0) {
         double sell_profit_first_and_last = sell_profit[sells - 1] + sell_profit[0];
         if(sell_profit_first_and_last > TakeProfit(sell_lots[0])) {
            closeLastAndFirstSellOrder();
         }
      }
   }
}

// ------------------------------------------------------------------------------------------------
// SHOW DATA
// ------------------------------------------------------------------------------------------------
void showData() {

   string txt;
   string cycleRisttext = "";
   double aux_tp_buy = 0, aux_tp_sell = 0;
   // #002: correct message of fibo progression
   string info_money_management[4];
   string info_activation[2];

   info_money_management[0] = "Fixed Lot";
   info_money_management[1] = "D´Alembert";
   info_money_management[2] = "Martingale";
   info_money_management[3] = "Fibonacci";
   info_activation[0] = "Disabled";
   info_activation[1] = "Enabled";

   if(buys <= 1 ) aux_tp_buy = TakeProfit(buy_lots[0]);
   else if(progression == 0) aux_tp_buy = TakeProfit(buy_lots[0]);
   else if(progression == 1) aux_tp_buy = buys * TakeProfit(buy_lots[0]);
   else if(progression == 2) aux_tp_buy = TakeProfit(buy_lots[buys - 1]);
   else if(progression == 3) aux_tp_buy = TakeProfit(buy_lots[buys - 1]);

   if(sells <= 1) aux_tp_sell = TakeProfit(sell_lots[0]);
   else if(progression == 0) aux_tp_sell = TakeProfit(sell_lots[0]);
   else if(progression == 1) aux_tp_sell = sells * TakeProfit(sell_lots[0]);
   else if(progression == 2) aux_tp_sell = TakeProfit(sell_lots[sells - 1]);
   else if(progression == 3) aux_tp_sell = TakeProfit(sell_lots[sells - 1]);

   // #008: use progression for grid size as well as volume
   string info_GSProgression;
   if(GSProgression == 0) {
      info_GSProgression = "\nGS progression: Disabled";
   } else {
      info_GSProgression = "\nGS progression: " + info_money_management[GSProgression];
   }

   if(UseTradeCycleRisk) {
      cycleRisttext =  "\nCycle risk: " + DoubleToStr(100 * CycleEquityRisk, 2) + "%";
   }

   // #051: change info of panel and comment
   txt = "\n" + ea_name +
         "\nServer Time: " + TimeToStr(market_time, TIME_DATE | TIME_SECONDS) +
         "\n" +
         "\nBUY ORDERS" +
         "\nNumber of orders: " + (string)buys +
         "\nTotal lots: " + DoubleToStr(total_buy_lots, 2) +
         "\nProfit goal: " + market_symbol + DoubleToStr(aux_tp_buy, 2) +
         "\nMaximum profit reached: " + market_symbol + DoubleToStr(buy_max_profit, 2) +
         "\nProfit locked: " + market_symbol + DoubleToStr(buy_close_profit, 2) +
         "\nSellHedging: " + market_symbol + DoubleToStr(total_hedge_sell_profit, 2) +
         "\n" +
         "\nSELL ORDERS" +
         "\nNumber of orders: " + (string)sells +
         "\nTotal lots: " + DoubleToStr(total_sell_lots, 2) +
         "\nProfit goal: " + market_symbol + DoubleToStr(aux_tp_sell, 2) +
         "\nMaximum profit reached: " + market_symbol + DoubleToStr(sell_max_profit, 2) +
         "\nProfit locked: " + market_symbol + DoubleToStr(sell_close_profit, 2) +
         "\nBuyHedging: " + market_symbol + DoubleToStr(total_hedge_buy_profit, 2)
         + "\n";

   if(line_margincall > 0) txt += "\nLine: \"margin call\": " + DoubleToString(line_margincall, 3);

   // #038: give user info, why account state is yellow or red
   if(code_yellow_message != "") txt += "\n" + code_yellow_message;
   if(code_red_message != "") txt += "\n" + code_red_message;

   txt +=
      "\nCurrent drawdown: " + DoubleToString((max_equity - AccountEquity()), 2) + " " + market_symbol + " (" + DoubleToString((max_equity - AccountEquity()) / max_equity * 100, 2) + " %)" +
      "\nMax. drawdown: " + DoubleToString(max_float, 2) + " " + market_symbol +
      "\n\nSETTINGS: " +
      "\nGrid size: " + (string)Distance +
      info_GSProgression +
      "\nTake profit: " + (string)TakeProfit +
      "\nProfit locked: " + DoubleToStr(100 * ProfitLock, 2) + "%" +
      "\nMinimum lots: " + DoubleToStr(Lots, 2) +
      "\nEquity warning: " + DoubleToStr(100 * EquityWarning, 2) + "%" +
      "\nAccount risk: " + DoubleToStr(100 * AccountRisk, 2) + "%" +
      cycleRisttext +
      "\nProgression: " + info_money_management[progression] +
      "\nMax Positions: " + (string)MaxPosition +
      //"\nTradeTime: " + (string)Time_to_Trade() +
   // #004 new setting: MaxSpread; trades only, if spread <= max spread:
      "\nMax Spread: " +(string)MaxSpread + " pts; actual spread: " + (string)MarketInfo(Symbol(), MODE_SPREAD) + " pts";

   ObjectSetInteger(0, "btnShowComment", OBJPROP_STATE, 0);   // switch color back to not selected
   if(show_comment) {
      // #050: show/hide buttons together with comment
      if(ObjectFind(0, "btnhedgeBuy") == -1) {
         DrawButton("btnhedgeBuy", "Buy", btn_left_axis, btn_top_axis, btn_width, btn_height, false, colNeutral, clrBlack);
         DrawButton("btnhedgeSell", "Sell", btn_left_axis + btn_next_left, btn_top_axis, btn_width, btn_height, false, colNeutral, clrBlack);
         DrawButton("btnCloseLastBuy", "Cl. Last B", btn_left_axis, btn_top_axis + btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
         DrawButton("btnCloseLastSell", "Cl. Last S", btn_left_axis + btn_next_left, btn_top_axis + btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
         DrawButton("btnCloseAllBuys", "Cl. All Bs", btn_left_axis, btn_top_axis + 2 * btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
         DrawButton("btnCloseAllSells", "Cl. All Ss", btn_left_axis + btn_next_left, btn_top_axis + 2 * btn_next_top, btn_width, btn_height, false, colNeutral, clrBlack);
         DrawButton("btnShowComment", "Show/Hide Comment", 5, btn_top_axis, btn_width * 2, btn_height, false, colNeutral, colCodeYellow);

         DrawButton("btnstopNextCycle", "Stop Next Cycle", btn_left_axis + 2 * btn_next_left, btn_top_axis, (int)(btn_width * 1.5), btn_height, false, colNeutral, clrBlack);
         DrawButton("btnrestAndRealize", "Rest & Realize", btn_left_axis + 2 * btn_next_left, btn_top_axis + btn_next_top, (int)(btn_width * 1.5), btn_height, false, colNeutral, clrBlack);
         DrawButton("btnStopAll", "Stop & Close", btn_left_axis + 2 * btn_next_left, btn_top_axis + 2 * btn_next_top, (int)(btn_width * 1.5), btn_height, false, colNeutral, clrBlack);
      }

      // set state off all buttons to: Not Selected
      ObjectSetInteger(0, "btnhedgeBuy", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnhedgeSell", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnCloseLastBuy", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnCloseLastSell", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnCloseAllBuys", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnCloseAllSells", OBJPROP_STATE, 0);   // switch color back to not selected

      ObjectSetInteger(0, "btnstopNextCycle", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnrestAndRealize", OBJPROP_STATE, 0);   // switch color back to not selected
      ObjectSetInteger(0, "btnStopAll", OBJPROP_STATE, 0);   // switch color back to not selected
      //
      // #019: implement button: Stop On Next Cycle
      if(stop_next_cycle) {
         SetButtonText("btnstopNextCycle", "Continue");
         // set color to red, if everything is closed
         if(sells + buys == 0) {
            SetButtonColor("btnstopNextCycle", colCodeRed, colFontLight);
         } else {
            SetButtonColor("btnstopNextCycle", colCodeYellow, colFontDark);
         }
      } else {
         SetButtonText("btnstopNextCycle", "Stop Next Cycle");
         SetButtonColor("btnstopNextCycle", colPauseButtonPassive, colFontLight);
      }

      // #011 #018: implement button: Stop On Next Cycle
      if(rest_and_realize) {
         SetButtonText("btnrestAndRealize", "Continue");
         if(sells + buys == 0) {
            SetButtonColor("btnrestAndRealize", colCodeRed, colFontLight);
         } else {
            SetButtonColor("btnrestAndRealize", colCodeYellow, colFontDark);
         }
      } else {
         SetButtonText("btnrestAndRealize", "Rest & Realize");
         SetButtonColor("btnrestAndRealize", colPauseButtonPassive, colFontLight);
      }

      // #010: implement button: Stop & Close
      if(stop_all) {
         SetButtonText("btnStopAll", "Continue");
         SetButtonColor("btnStopAll", colCodeRed, colFontLight);
      } else {
         SetButtonText("btnStopAll", "Stop & Close");
         SetButtonColor("btnStopAll", colPauseButtonPassive, colFontLight);
      }

   } else {
      DeleteButton("btnStopAll");
      DeleteButton("btnrestAndRealize");
      DeleteButton("btnstopNextCycle");

      DeleteButton("btnhedgeBuy");
      DeleteButton("btnhedgeSell");
      DeleteButton("btnCloseLastBuy");
      DeleteButton("btnCloseLastSell");
      DeleteButton("btnCloseAllBuys");
      DeleteButton("btnCloseAllSells");
   }

   if(show_comment)
      Comment("\n\n" + txt);
   else
      Comment("");

   // #047: add panel right upper corner
   if(ShowForecast) {
      if(total_buy_profit + total_sell_profit > 0)
         instrumentCol = colInPlus;
      else
         instrumentCol = colInMinus;

      Write("panel_1_01", ChartSymbol(0), 5, 22, "Arial", 14, instrumentCol);
      if(market_spread > MaxSpread)
         Write("panel_1_02", "Spread: " + DoubleToString(market_spread / 10, 1), 5, 42, "Arial", 10, colCodeRed);
      else
         Write("panel_1_02", "Spread: " + DoubleToString(market_spread / 10, 1), 5, 42, "Arial", 10, panelCol);

      Write("panel_1_03", DoubleToString(CalculatePriceByTickDiff(relativeVolume, market_tick_size * 10), 2) + " " + market_symbol + " / Pip", 5, 58, "Arial", 10, panelCol);
      Write("panel_1_04", "Balance: " + DoubleToString(AccountBalance(), 2) + " " + market_symbol, 5, 74, "Arial", 10, panelCol);
      Write("panel_1_05", "Equity: " + DoubleToString(AccountEquity(), 2) + " " + market_symbol, 5, 90, "Arial", 10, panelCol);
      Write("panel_1_06", "Free Margin: " + DoubleToString(AccountFreeMargin(), 2) + " " + market_symbol, 5, 106, "Arial", 10, panelCol);
      Write("panel_1_07", "P/L Sym. " + DoubleToString(total_buy_profit + total_sell_profit, 2) + " " + market_symbol, 5, 122, "Arial", 14, instrumentCol);
      if(total_buy_profit < 0)
         Write("panel_1_08", "P/L Buy: " + DoubleToStr(total_buy_profit, 2) + " " + market_symbol, 5, 144, "Arial", 10, colInMinus);
      else
         Write("panel_1_08", "P/L Buy: " + DoubleToStr(total_buy_profit, 2) + " " + market_symbol, 5, 144, "Arial", 10, colInPlus);
      if(total_sell_profit < 0)
         Write("panel_1_09", "P/L sell: " + DoubleToStr(total_sell_profit, 2) + " " + market_symbol, 5, 160, "Arial", 10, colInMinus);
      else
         Write("panel_1_09", "P/L sell: " + DoubleToStr(total_sell_profit, 2) + " " + market_symbol, 5, 160, "Arial", 10, colInPlus);

      double accountPL = AccountProfit();
      if(accountPL < 0)
         Write("panel_1_10", "P/L Acc. " + DoubleToString(accountPL, 2) + " " + market_symbol, 5, 176, "Arial", 10, colInMinus);
      else
         Write("panel_1_10", "P/L Acc. " + DoubleToString(accountPL, 2) + " " + market_symbol, 5, 176, "Arial", 10, colInPlus);
      //double pips2go_Buys = (line_buy-market_price_sell)*market_tick_size;
      double pips2go_Buys = MathAbs(line_buy / market_tick_size - market_price_sell / market_tick_size) / 10;
      double pips2go_Sells = MathAbs(line_sell / market_tick_size - market_price_buy / market_tick_size) / 10;
      Write("panel_1_11", "Pips2Go B " + DoubleToString(pips2go_Buys, 0) + " S " + DoubleToStr(pips2go_Sells, 0), 5, 192, "Arial", 10, panelCol);
   }
}

//+---------------------------------------------------------------------------+
//  Local variable methods
//+---------------------------------------------------------------------------+

// ------------------------------------------------------------------------------------------------
// INIT VARS
// ------------------------------------------------------------------------------------------------
void InitVars() {
   // Reset number of buy/sell orders
   buys = 0;
   sells = 0;
   hedge_buys = 0;
   hedge_buys = sells;

   // Reset hegding indicators
   is_buy_hedging_active = false;
   is_sell_hedging_active = false;
   is_buy_hedging_order_active = false;
   is_sell_hedging_order_active = false;
   buy_max_order_lot_open = false;
   sell_max_order_lot_open = false;

   // Reset arrays
   for(int i = 0; i < max_open_positions; i++) {
      buy_tickets[i] = 0;
      buy_lots[i] = 0;
      buy_profit[i] = 0;
      buy_price[i] = 0;
      sell_tickets[i] = 0;
      sell_lots[i] = 0;
      sell_profit[i] = 0;
      sell_price[i] = 0;
      hedge_buy_tickets[i] = 0;
      hedge_sell_tickets[i] = 0;
      hedge_buy_lots[i] = 0;
      hedge_sell_lots[i] = 0;
      hedge_buy_profit[i] = 0;
      hedge_sell_profit[i] = 0;
      hedge_buy_price[i] = 0;
      hedge_sell_price[i] = 0;
   }

   // #021: new setting: max_open_positions
   // if not used, set it to maximum => no restriction
   if(MaxPosition == 0) MaxPosition = max_auto_open_positions;

   // #030: disable equity and account risk by setting them to 0
   // #025: use equity percentage instead of unpayable position
   if(EquityWarning == 0) EquityWarning = 1.0;
   if(AccountRisk == 0) AccountRisk = 1.0;
}

// ------------------------------------------------------------------------------------------------
// UPDATE VARS
// ------------------------------------------------------------------------------------------------
void UpdateVars() {
   double max_lot = 0;
   int aux_buys = 0, aux_sells = 0;
   int aux_hedge_buys = 0, aux_hedge_sells = 0;
   double aux_total_buy_profit = 0, aux_total_sell_profit = 0;
   double aux_hedge_total_buy_profit = 0, aux_hedge_total_sell_profit = 0;
   double aux_total_buy_swap = 0, aux_total_sell_swap = 0, aux_hedge_total_buy_swap = 0, aux_hedge_total_sell_swap = 0;
   double aux_total_buy_lots = 0, aux_total_sell_lots = 0;
   double aux_hedge_total_buy_lots = 0, aux_hedge_total_sell_lots = 0;

   if(progression == 0) max_lot = Lots;
   if(progression == 1) max_lot = MaxPosition * Lots;
   if(progression == 2) max_lot = 2 * MaxPosition * Lots;
   if(progression == 3) max_lot = FiboSequence(MaxPosition) * Lots;

   // We are going to introduce data from opened orders in arrays
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true) {
         if(OrderSymbol() == Symbol()) {
            if(OrderMagicNumber() == magic && OrderType() == OP_BUY) {
               buy_tickets[aux_buys] = OrderTicket();
               buy_lots[aux_buys] = OrderLots();
               if(buy_lots[aux_buys] == max_lot) {
                  buy_max_order_lot_open = true;
               }

               buy_profit[aux_buys] = OrderProfit() + OrderCommission() + OrderSwap();
               buy_price[aux_buys] = OrderOpenPrice();
               aux_total_buy_profit = aux_total_buy_profit + buy_profit[aux_buys];
               aux_total_buy_lots = aux_total_buy_lots + buy_lots[aux_buys];
               aux_total_buy_swap += OrderSwap();
               aux_buys++;
            }
            // hedge opened buy orders - this is used for corrections
            if(OrderMagicNumber() == hedge_magic && OrderType() == OP_BUY) {
               hedge_buy_tickets[aux_hedge_buys] = OrderTicket();
               hedge_buy_lots[aux_hedge_buys] = OrderLots();
               hedge_buy_profit[aux_hedge_buys] = OrderProfit() + OrderCommission() + OrderSwap();
               hedge_buy_price[aux_hedge_buys] = OrderOpenPrice();
               aux_hedge_total_buy_profit = aux_hedge_total_buy_profit + hedge_buy_profit[aux_hedge_buys];
               aux_hedge_total_buy_lots = aux_hedge_total_buy_lots + hedge_buy_lots[aux_hedge_buys];
               aux_hedge_total_buy_swap += OrderSwap();
               aux_hedge_buys++;
            }
            if(OrderMagicNumber() == magic && OrderType() == OP_SELL) {
               sell_tickets[aux_sells] = OrderTicket();
               sell_lots[aux_sells] = OrderLots();
               if(sell_lots[aux_sells] == max_lot) {
                  sell_max_order_lot_open = true;
               }

               sell_profit[aux_sells] = OrderProfit() + OrderCommission() + OrderSwap();
               sell_price[aux_sells] = OrderOpenPrice();
               aux_total_sell_profit = aux_total_sell_profit + sell_profit[aux_sells];
               aux_total_sell_lots = aux_total_sell_lots + sell_lots[aux_sells];
               aux_total_sell_swap += OrderSwap();
               aux_sells++;
            }
            // manuel opened sell orders - this is used for corrections
            if(OrderMagicNumber() == hedge_magic && OrderType() == OP_SELL) {
               hedge_sell_tickets[aux_hedge_sells] = OrderTicket();
               hedge_sell_lots[aux_hedge_sells] = OrderLots();
               hedge_sell_profit[aux_hedge_sells] = OrderProfit() + OrderCommission() + OrderSwap();
               hedge_sell_price[aux_hedge_sells] = OrderOpenPrice();
               aux_hedge_total_sell_profit = aux_hedge_total_sell_profit + hedge_sell_profit[aux_hedge_sells];
               aux_hedge_total_sell_lots = aux_hedge_total_sell_lots + hedge_sell_lots[aux_hedge_sells];
               aux_hedge_total_sell_swap += OrderSwap();
               aux_hedge_sells++;
            }
         }
      }
   }

   // Update global vars
   buys                    = aux_buys;
   sells                   = aux_sells;
   hedge_buys             = aux_hedge_buys;
   hedge_sells            = aux_hedge_sells;
   total_buy_profit        = aux_total_buy_profit;
   total_sell_profit       = aux_total_sell_profit;
   total_hedge_buy_profit = aux_hedge_total_buy_profit;
   total_hedge_sell_profit = aux_hedge_total_sell_profit;
   total_buy_lots          = aux_total_buy_lots;
   total_sell_lots         = aux_total_sell_lots;
   total_hedge_buy_lots   = aux_hedge_total_buy_lots;
   total_hedge_sell_lots  = aux_hedge_total_sell_lots;

   if(total_hedge_buy_lots > 0 ) {
      is_buy_hedging_order_active = true;
   }

   if(total_hedge_sell_lots > 0 ) {
      is_sell_hedging_order_active = true;
   }

   total_buy_swap          = aux_total_buy_swap;
   total_sell_swap         = aux_total_sell_swap;
   total_hedge_buy_swap   = aux_hedge_total_buy_swap;
   total_hedge_sell_swap  = aux_hedge_total_sell_swap;

   relativeVolume = MathAbs(total_buy_lots - total_sell_lots);
}

// ------------------------------------------------------------------------------------------------
// SORT BY LOTS
// ------------------------------------------------------------------------------------------------
void SortByLots() {
   int aux_tickets;
   double aux_lots, aux_profit, aux_price;

   // We are going to sort orders by volume
   // m[0] smallest volume m[size-1] largest volume

   // BUY ORDERS
   for(int i = 0; i < buys - 1; i++) {
      for(int j = i + 1; j < buys; j++) {
         if(buy_lots[i] > 0 && buy_lots[j] > 0) {
            // at least 2 orders
            if(buy_lots[j] < buy_lots[i]) {
               // sorting
               // ...lots...
               aux_lots = buy_lots[i];
               buy_lots[i] = buy_lots[j];
               buy_lots[j] = aux_lots;
               // ...tickets...
               aux_tickets = buy_tickets[i];
               buy_tickets[i] = buy_tickets[j];
               buy_tickets[j] = aux_tickets;
               // ...profits...
               aux_profit = buy_profit[i];
               buy_profit[i] = buy_profit[j];
               buy_profit[j] = aux_profit;
               // ...and open price
               aux_price = buy_price[i];
               buy_price[i] = buy_price[j];
               buy_price[j] = aux_price;
            }
         }
      }
   }

   // SELL ORDERS
   for(int i = 0; i < sells - 1; i++) {
      for(int j = i + 1; j < sells; j++) {
         if(sell_lots[i] > 0 && sell_lots[j] > 0) {
            // at least 2 orders
            if(sell_lots[j] < sell_lots[i]) {
               // sorting...
               // ...lots...
               aux_lots = sell_lots[i];
               sell_lots[i] = sell_lots[j];
               sell_lots[j] = aux_lots;
               // ...tickets...
               aux_tickets = sell_tickets[i];
               sell_tickets[i] = sell_tickets[j];
               sell_tickets[j] = aux_tickets;
               // ...profits...
               aux_profit = sell_profit[i];
               sell_profit[i] = sell_profit[j];
               sell_profit[j] = aux_profit;
               // ...and open price
               aux_price = sell_price[i];
               sell_price[i] = sell_price[j];
               sell_price[j] = aux_price;
            }
         }
      }
   }
}

//+---------------------------------------------------------------------------+
//  Global variable methods
//+---------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| WrtieIniData()                                                                 |
// #017: deal with global vars to save and restore data, while chart is closed or must be restarted by other reason
//+------------------------------------------------------------------+
void WriteIniData() {
   // #016: Save status of buttons in global vars
   if(!IsTesting()) {
      // implement button: Stop & Close
      // implement button: Stop On Next Cycle
      GlobalVariableSet(global_id + "stopNextCycle", stop_next_cycle);
      GlobalVariableSet(global_id + "restAndRealize", rest_and_realize);
      GlobalVariableSet(global_id + "stopAll", stop_all);
      // button to show or hide comment
      GlobalVariableSet(global_id + "showComment", show_comment);
      // save max equity at global vars
      GlobalVariableSet(global_id + "max_equity", NormalizeDouble(max_equity, 2));
   }
}

//+------------------------------------------------------------------+
//| ReadIniData()                                                                 |
// #017: deal with global vars to save and restore data,
// while chart is closed or must be restarted by other reason
//+------------------------------------------------------------------+
void ReadIniData() {
   // #016: read status of buttons from global vars
   if(!IsTesting()) {
      int count = GlobalVariablesTotal();
      if(count > 0) {
         // #011 #018 #019: implement button: Stop On Next Cycle
         if(GlobalVariableCheck(global_id + "stopNextCycle"))
            stop_next_cycle = (int)GlobalVariableGet(global_id + "stopNextCycle");

         if(GlobalVariableCheck(global_id + "restAndRealize"))
            rest_and_realize = (int)GlobalVariableGet(global_id + "restAndRealize");

         // #010: implement button: Stop & Close
         if(GlobalVariableCheck(global_id + "stopAll"))
            stop_all = (int)GlobalVariableGet(global_id + "stopAll");

         // #044: Add button to show or hide comment
         if(GlobalVariableCheck(global_id + "showComment"))
            show_comment = (int)GlobalVariableGet(global_id + "showComment");

         // #037: save max equity at global vars
         if(GlobalVariableCheck(global_id + "max_equity"))
            max_equity = NormalizeDouble(GlobalVariableGet(global_id + "max_equity"), 2);
      }
   }
}

//+---------------------------------------------------------------------------+
//  BUTTON methods
//+---------------------------------------------------------------------------+
#include "displays/button/functions.mqh"

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam,
                  const string &sparam) {
   int retVal = 0;
   if(id == CHARTEVENT_OBJECT_CLICK) {
      string clickedObject = sparam;

      // #019: implement button: Stop On Next Cycle
      if(clickedObject == "btnstopNextCycle") { //stop on Next Cycle
         if(stop_next_cycle)
            stop_next_cycle = 0;
         else {
            retVal = MessageBox("Trading as normal, until a cycle is successfully closed?", "   S T O P  N E X T  C Y C L E :", MB_YESNO);
            if(retVal == IDYES)
               stop_next_cycle = 1;
         }
      }
      // #011 #018: implement button: Stop On Next Cycle
      if(clickedObject == "btnrestAndRealize") { //stop on Next Cycle
         if(rest_and_realize)
            rest_and_realize = 0;
         else {
            retVal = MessageBox("Do not open any new position. Close cycle successfully, if possible.", "   R E S T  &  R E A L I Z E :", MB_YESNO);
            if(retVal == IDYES)
               rest_and_realize = 1;
         }
      }
      // #010: implement button: Stop & Close All
      if(clickedObject == "btnStopAll") { //stop trading and close all positions
         if(stop_all)
            stop_all = 0;
         else {
            retVal = MessageBox("Close all positons and stop trading?", "   S T O P  &  C L O S E :", MB_YESNO);
            if(retVal == IDYES)
               stop_all = 1;
         }
      }
      // #044: Add button to show or hide comment
      if(clickedObject == "btnShowComment") { //stop on Next Cycle
         if(show_comment)
            show_comment = 0;
         else
            show_comment = 1;
      }
      // #026: implement hedge trades, if account state is not green
      if(clickedObject == "btnhedgeBuy") {
         if(true/*account_state==as_yellow || account_state==as_red*/) { // execute this button only, if account state is not green

            retVal = MessageBox("Buy " + (string)CalculateNextVolume(OP_BUY) + " Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
            if(retVal == IDYES)
               OrderSendReliable(Symbol(), OP_BUY, CalculateNextVolume(OP_BUY), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, Key, magic, 0, Blue);
         }
      }
      if(clickedObject == "btnhedgeSell") {
         if(true/*account_state==as_yellow || account_state==as_red*/) { // execute this button only, if account state is not green
            retVal = MessageBox("Sell " + (string)CalculateNextVolume(OP_SELL) + " Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
            if(retVal == IDYES)
               OrderSendReliable(Symbol(), OP_SELL, CalculateNextVolume(OP_SELL), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, Key, magic, 0, Blue);
         }
      }
      // #034: implement hedge closing trades, if account state is not green
      if(clickedObject == "btnCloseLastBuy") {
         if(total_buy_lots > 0) {
            if(true/*account_state==as_yellow || account_state==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close last buy " + (string)buy_lots[buys - 1] + "Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  retVal = OrderCloseReliable(buy_tickets[buys - 1], buy_lots[buys - 1], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
                  rest_and_realize = 1; // set status, that not a new position will be opened directly after closing all
               }
            }
         }
      }
      if(clickedObject == "btnCloseLastSell") {
         if(total_sell_lots > 0) {
            if(true/*account_state==as_yellow || account_state==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close last sell " + (string)sell_lots[sells - 1] + "Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  retVal = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), slippage, Blue);
                  rest_and_realize = 1; // set status, that not a new position will be opened directly after closing all
               }
            }
         }
      }
      // #035: implement hedge closing trades, if account state is not green
      if(clickedObject == "btnCloseAllBuys") {
         if(total_buy_lots > 0) {
            if(true/*account_state==as_yellow || account_state==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close all " + (string)total_buy_lots + "buy Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  closeAllBuys();
                  // set status, that not a new position will be opened directly after alosing all
                  if(rest_and_realize == 0) // if not already choosen by use, set the other pause option
                     stop_next_cycle = 1;
               }
            }
         }
      }
      if(clickedObject == "btnCloseAllSells") {
         if(total_sell_lots > 0) {
            if(true/*account_state==as_yellow || account_state==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close all " + (string)total_sell_lots + "sell Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  closeAllSells();
                  // set status, that not a new position will be opened directly after alosing all
                  if(rest_and_realize == 0) // if not already choosen by use, set the other pause option
                     stop_next_cycle = 1;
               }
            }
         }
      }
      WriteIniData();
   }
}

//+---------------------------------------------------------------------------+
//  LINE methods and Chart Events
//+---------------------------------------------------------------------------+
//+---------------------------------------------------------------------------+
//  UTIL methods
//+---------------------------------------------------------------------------+
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

