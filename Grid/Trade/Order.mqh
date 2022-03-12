void NewGridOrder(int orderType, int magic, double sl = 0, double tp = 0, double init_lot = 0) {
   int ticket;
   double next_lot = Lot;

   if(rest_and_realize) return;

   if(orderType == OP_BUY) {
      if(Sequence == 0) next_lot = Lot;
      if(Sequence == 1) next_lot = buy_lots[buys - 1] + buy_lots[0];
      if(Sequence == 2) next_lot = 2 * buy_lots[buys - 1];
      if(Sequence == 3) next_lot = Fibonacci(buys + 1) * Lot;
      if(init_lot != 0) next_lot = init_lot;

      if(magic == Magic1 && next_lot >= MaxLot1) next_lot = MaxLot1;
      if(magic == Magic2 && next_lot >= MaxLot2) next_lot = MaxLot2;

      ticket = OrderSendReliable(Symbol(), OP_BUY, next_lot, MarketInfo(Symbol(), MODE_ASK), Slippage, sl, tp, Key, magic, 0, Blue);
   } else {
      if(Sequence == 0) next_lot = Lot;
      if(Sequence == 1) next_lot = sell_lots[sells - 1] + sell_lots[0];
      if(Sequence == 2) next_lot = 2 * sell_lots[sells - 1];
      if(Sequence == 3) next_lot = Fibonacci(sells + 1) * Lot;
      if(init_lot != 0) next_lot = init_lot;

      if(magic == Magic1 && next_lot >= MaxLot1) next_lot = MaxLot1;
      if(magic == Magic2 && next_lot >= MaxLot2) next_lot = MaxLot2;

      ticket = OrderSendReliable(Symbol(), OP_SELL, next_lot, MarketInfo(Symbol(), MODE_BID), Slippage, sl, tp, Key, magic, 0, Red);
   }
}

//**************************************************
// Close all buys & sells position
//**************************************************
void CloseAll() {
   CloseAllSells();
   CloseAllBuys();
}

//**************************************************
// Close all sells position
//**************************************************
void CloseAllSells() {
   if(sells > 0) {
      CloseAllHedgeBuys();
      for(int i = 0; i <= sells - 1; i++) {
         bool retVal = OrderCloseReliable(sell_tickets[i], sell_lots[i], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
      }
   }
}

//**************************************************
// Close all buys position
//**************************************************
void CloseAllBuys() {
   if(buys > 0) {
      CloseAllHedgeSells();
      for(int i = 0; i <= buys - 1; i++) {
         bool retVal = OrderCloseReliable(buy_tickets[i], buy_lots[i], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
      }
   }
}



// **************************************************
// Close all hedge sells position
// **************************************************
void CloseAllHedgeSells() {
   if(hedge_sells > 0) {
      for(int i = 0; i <= hedge_sells - 1; i++) {
         bool retVal = OrderCloseReliable(hedge_sell_tickets[i], hedge_sell_lots[i], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
      }
   }
}

// **************************************************
// Close all hedge buys position
// **************************************************
void CloseAllHedgeBuys() {
   if(hedge_buys > 0) {
      for(int i = 0; i <= hedge_buys - 1; i++) {
         bool retVal = OrderCloseReliable(hedge_buy_tickets[i], hedge_buy_lots[i], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
      }
   }
}

//+------------------------------------------------------------------+
// CloseBuyHedgeAndFirstSellOrder
//+------------------------------------------------------------------+
void closeBuyHedgeAndFirstSellOrder() {

   bool retVal = OrderCloseReliable(sell_tickets[0], sell_lots[0], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
   CloseAllHedgeBuys();
}

//+------------------------------------------------------------------+
// closeBuyHedgeAndFirstSellOrder
//+------------------------------------------------------------------+
void closeBuyHedgeAndLastAndSecondLastSellOrder() {

   CloseAllHedgeBuys();
   bool retVal = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
   bool retVal2 = OrderCloseReliable(sell_tickets[sells - 2], sell_lots[sells - 2], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
}

//+------------------------------------------------------------------+
// closeSellHedgeAndFirstBuyOrder
//+------------------------------------------------------------------+
void closeSellHedgeAndFirstBuyOrder() {

   bool retVal = OrderCloseReliable(buy_tickets[0], buy_lots[0], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
   CloseAllHedgeSells();
}

//+------------------------------------------------------------------+
// closeBuyHedgeAndLastAndSecondLastBuyOrder
//+------------------------------------------------------------------+
void closeSellHedgeAndLastAndSecondLastBuyOrder() {

   CloseAllHedgeSells();
   bool retVal = OrderCloseReliable(buy_tickets[buys - 1], buy_lots[buys - 1], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
   bool retVal2 = OrderCloseReliable(buy_tickets[buys - 2], buy_lots[buys - 2], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
}

//+------------------------------------------------------------------+
// closeLastAndFirstBuyOrder
//+------------------------------------------------------------------+
void closeLastAndFirstBuyOrder() {

   bool retVal = OrderCloseReliable(buy_tickets[0], buy_lots[0], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
   bool retVal2 = OrderCloseReliable(buy_tickets[buys - 1], buy_lots[buys - 1], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
}

//+------------------------------------------------------------------+
// CloseLastAndFirstSellOrder
//+------------------------------------------------------------------+
void closeLastAndFirstSellOrder() {

   bool retVal = OrderCloseReliable(sell_tickets[0], sell_lots[0], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
   bool retVal2 = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
}



//+------------------------------------------------------------------+
//| NewOrder                                                     |
//+------------------------------------------------------------------+
void NewOrderMaxPos(int orderType) {
   int ticket;

   // TODO test the order Sequences
   if(rest_and_realize) return;
   if(orderType == OP_BUY) {
      // new hedging buy order
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_BUY, Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key, Magic1, 0, Blue);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_BUY, MaxOrders * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key, Magic1, 0, Blue);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_BUY, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key, Magic1, 0, Blue);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_BUY, Fibonacci(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key, Magic1, 0, Blue);
   } else {
      // new hedging sell order
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_SELL, buy_lots[0], MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key, Magic1, 0, Red);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_SELL, MaxOrders * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key, Magic1, 0, Red);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_SELL, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key, Magic1, 0, Red);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_SELL, Fibonacci(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key, Magic1, 0, Red);
   }
}

//+------------------------------------------------------------------+
//| NewOrder                                                     |
//+------------------------------------------------------------------+
void NewHedgingOrder(int orderType) {
   int ticket;

   // TODO test the order Sequences
   if(rest_and_realize) return;
   if(orderType == OP_BUY) {
      
      // new hedging buy order
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_BUY, Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, Magic2, 0, Blue);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_BUY, MaxOrders * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, Magic2, 0, Blue);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_BUY, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, Magic2, 0, Blue);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_BUY, Fibonacci(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, Magic2, 0, Blue);
   } else {
      
      // new hedging sell order
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_SELL, Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_SELL, MaxOrders * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_SELL, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_SELL, Fibonacci(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
   }
}

//+------------------------------------------------------------------+
//|  handle Hedging order profit                                     |
//+------------------------------------------------------------------+
void HandleCycleRisk() {

   // if(UseTradeCycleRisk) {

   //    double local_total_buy_profit = 0, local_total_sell_profit = 0;

   //    local_total_buy_profit = total_buy_profit;
   //    local_total_sell_profit = total_sell_profit;

   //    if(hedge_buys > 0) {
   //       // max hedge lot means this is a correction lot
   //       local_total_sell_profit = total_sell_profit + total_hedge_buy_profit;
   //    }

   //    // if the hedge trade is sell and it is max trade lot
   //    // then calculate new local_total_buy_profit with the hedge sell order
   //    if(hedge_sells > 0) {
   //       local_total_buy_profit = total_buy_profit + total_hedge_sell_profit;
   //    }

   //    if((CycleEquityRisk * AccountBalance()) * -1 > local_total_sell_profit) {
   //       CloseAllSells();
   //    }

   //    if((CycleEquityRisk * AccountBalance()) * -1 > local_total_buy_profit) {
   //       CloseAllBuys();
   //    }
   // }
}

//+------------------------------------------------------------------+
//|  handle Hedging order profit                                     |
//+------------------------------------------------------------------+
void HandleHedging() {

   // if(EnableHedging) { // hedging is active but not open
   //    // double hedgeAmountStart = (hedgingEquityStart * AccountBalance()) * -1;
   //    if(!isHedgingSellActive() && buys >= MaxOrders) {
   //       if(buy_profit[buys - 1] <= StopLoss(buy_lots[buys - 1], buys)) {
   //          NewHedgingOrder(OP_SELL);
   //          NewOrderMaxPos(OP_BUY);
   //       }
   //    }
   //    if(!isHedgingBuyActive() && sells >= MaxOrders) {
   //       if(sell_profit[sells - 1] <= StopLoss(sell_lots[sells - 1], sells)) {
   //          NewHedgingOrder(OP_BUY);
   //          NewOrderMaxPos(OP_SELL);
   //       }
   //    }
   // }

   // if(isHedgingBuyActive()) {
   //    if(total_hedge_buy_profit > 0) {
   //       double sum_buy_profit = total_hedge_buy_profit + sell_profit[0]; // hedge - first order
   //       if(buy_max_hedge_profit == 0 && sum_buy_profit > TakeProfit(Lot)) { // fixed 10%
   //          buy_max_hedge_profit = sum_buy_profit;
   //          buy_close_hedge_profit = ProfitLock * sum_buy_profit;
   //       }

   //       if(buy_max_hedge_profit > 0 && sum_buy_profit > buy_max_hedge_profit) {
   //          buy_max_hedge_profit = sum_buy_profit;
   //          buy_close_hedge_profit = ProfitLock * buy_max_hedge_profit;
   //       }

   //       if(buy_max_hedge_profit > 0 && buy_close_hedge_profit > 0
   //             && buy_max_hedge_profit >= buy_close_hedge_profit && sum_buy_profit < buy_close_hedge_profit) {
   //          // At this point all order are closed.
   //          // Global vars will be updated thanks to UpdateVars() on next start() execution
   //          closeBuyHedgeAndFirstSellOrder();
   //       }
   //    }
   //    // close heding order faster by reverse trend
   //    if((sell_profit[sells - 1] + sell_profit[sells - 2]) > 0) {
   //       double sum_buy_profit = total_hedge_buy_profit + (sell_profit[sells - 1] + sell_profit[sells - 2]); // hedge + last order + last order -2
   //       if(sum_buy_profit > TakeProfit(Lot)) {
   //          closeBuyHedgeAndLastAndSecondLastSellOrder();
   //       }
   //    }
   // }

   // if(isHedgingSellActive()) {
   //    if(total_hedge_sell_profit > 0) {
   //       double sum_sell_profit = total_hedge_sell_profit + buy_profit[0]; // hedge - first order
   //       if(sell_max_hedge_profit == 0 && sum_sell_profit > TakeProfit(Lot)) { // fixed 10%
   //          sell_max_hedge_profit = sum_sell_profit;
   //          sell_close_hedge_profit = ProfitLock * sum_sell_profit;
   //       }

   //       if(sell_max_hedge_profit > 0 && sum_sell_profit > sell_max_hedge_profit) {
   //          sell_max_hedge_profit = sum_sell_profit;
   //          sell_close_hedge_profit = ProfitLock * sell_max_hedge_profit;
   //       }

   //       if(sell_max_hedge_profit > 0 && sell_close_hedge_profit > 0
   //             && sell_max_hedge_profit >= sell_close_hedge_profit && sum_sell_profit < sell_close_hedge_profit) {
   //          // At this point all order are closed.
   //          // Global vars will be updated thanks to UpdateVars() on next start() execution
   //          closeSellHedgeAndFirstBuyOrder();
   //       }
   //    }
   //    if((buy_profit[buys - 1] + buy_profit[buys - 2]) > 0) {
   //       double sum_sell_profit = total_hedge_sell_profit + buy_profit[buys - 1] + buy_profit[buys - 2]; // hedge + last order + last order -2
   //       if(sum_sell_profit > TakeProfit(Lot)) {
   //          closeSellHedgeAndLastAndSecondLastBuyOrder();
   //       }
   //    }
   // }
}

//+------------------------------------------------------------------+
//|  isHedgingBuyActive                                              |
//+------------------------------------------------------------------+
bool isHedgingBuyActive() {
   if(is_buy_hedging_active) return true;
   return false;
}

//+------------------------------------------------------------------+
//|  isHedgingSellActive                                             |
//+------------------------------------------------------------------+
bool isHedgingSellActive() {
   if(is_sell_hedging_active) return true;
   return false;
}

//+------------------------------------------------------------------+
//|  PartiallyClose                                                  |
//+------------------------------------------------------------------+
void PartiallyClose() {
   if(buys >= PartialClose && !isHedgingSellActive()) {
      if(buy_profit[buys - 1] > 0) {
         double buy_profit_first_and_last = buy_profit[buys - 1] + buy_profit[0];
         // if(buy_profit_first_and_last > TakeProfit(buy_lots[0])) {
         if(buy_profit_first_and_last > TakeProfit) {
            closeLastAndFirstBuyOrder();
         }
      }
   }

   if(sells >= PartialClose && !isHedgingBuyActive()) {
      if(sell_profit[sells - 1] > 0) {
         double sell_profit_first_and_last = sell_profit[sells - 1] + sell_profit[0];
         // if(sell_profit_first_and_last > TakeProfit(sell_lots[0])) {
         if(sell_profit_first_and_last > TakeProfit) {
            closeLastAndFirstSellOrder();
         }
      }
   }
}