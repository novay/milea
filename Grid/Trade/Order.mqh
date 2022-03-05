void OpenPosition(int orderType, int magic, bool isHedge) {
   int ticket;
   double next_lot = Lot;

   if(rest_and_realize && !isHedge) return;
   if(orderType == OP_BUY) {
      if(Sequence == 0) next_lot = Lot;
      if(Sequence == 1) next_lot = buy_lots[buys - 1] + buy_lots[0];
      if(Sequence == 2) next_lot = 2 * buy_lots[buys - 1];
      if(Sequence == 3) next_lot = FiboSequence(buys + 1) * Lot;

      ticket = OrderSendReliable(Symbol(), OP_BUY, next_lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)buys, magic, 0, Blue);
   } else {
      if(Sequence == 0) next_lot = Lot;
      if(Sequence == 1) next_lot = sell_lots[sells - 1] + sell_lots[0];
      if(Sequence == 2) next_lot = 2 * sell_lots[sells - 1];
      if(Sequence == 3) next_lot = FiboSequence(sells + 1) * Lot;

      ticket = OrderSendReliable(Symbol(), OP_SELL, next_lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key + "-" + (string)sells, magic, 0, Red);
   }
}



//+------------------------------------------------------------------+
// CloseAllOrders()
// ------------------------------------------------------------------+
// Tutup semua posisi yang terbuka
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   CloseAllBuyOrders();
   CloseAllSellOrders();
}

//+------------------------------------------------------------------+
// CloseAllBuyOrders()
// ------------------------------------------------------------------+
// Tutup semua open posisi BUY
//+------------------------------------------------------------------+
void CloseAllBuyOrders()
{
   for(int order = OrdersTotal(); order >= 0; order--) {
      if(OrderSelect(order, SELECT_BY_POS)) {
         if(OrderType() == OP_BUY && OrderSymbol() == Symbol()) {
            RefreshRates();
            bool success = OrderClose(OrderTicket(), OrderLots(), Bid, 0, Blue);
         }
      }
   }
}


//+------------------------------------------------------------------+
// CloseAllSellOrders()
// ------------------------------------------------------------------+
// Tutup semua open posisi SELL
//+------------------------------------------------------------------+
void CloseAllSellOrders()
{
   for(int order = OrdersTotal(); order >= 0; order--) {
      if(OrderSelect(order,SELECT_BY_POS)) {
         if(OrderType() == OP_SELL && OrderSymbol() == Symbol()) {
            RefreshRates();
            bool success = OrderClose(OrderTicket(), OrderLots(), Ask, 0, Red);
         }
      }
   }
}

//--------------------------------------------------------------------------------+
// CountBuy(Magic)
// -------------------------------------------------------------------------------+
// Jumlah Open Posisi BUY
//--------------------------------------------------------------------------------+
int CountBuy(int magic)
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++) {
        int buy = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            count++;
        }
    }

    return count;
}

//--------------------------------------------------------------------------------+
// CountSell(Magic)
// -------------------------------------------------------------------------------+
// Jumlah Open Posisi SELL
//--------------------------------------------------------------------------------+
int CountSell(int magic)
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++) {
        int sell = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            count++;
        }
    }

    return count;
}

//--------------------------------------------------------------------------------+
// FirstOrderBuy(Magic)
// -------------------------------------------------------------------------------+
// First Order Price BUY
//--------------------------------------------------------------------------------+
double FirstOrderBuy(int magic) 
{
    double p = 0;
    double op = 0;

    for(int i = OrdersTotal(); i >= 0; i--) {
        int a = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            p = OrderOpenPrice();
        }
        if(p < op || op == 0) op = p;
    }

    return op;
}

//--------------------------------------------------------------------------------+
// FirstOrderSell(Magic)
// -------------------------------------------------------------------------------+
// First Order Price SELL
//--------------------------------------------------------------------------------+
double FirstOrderSell(int magic)
{
    double p = 0;
    double op = 0;
    
    for(int i = OrdersTotal(); i >= 0; i--) {
        int a = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            p = OrderOpenPrice();
        }
        if(p > op || op == 0) op = p;
    }

    return op;
}

//--------------------------------------------------------------------------------+
// OpenSell(Lot, Magic, StopLoss)
// -------------------------------------------------------------------------------+
// Open Posisi SELL
//--------------------------------------------------------------------------------+
void OpenSell(double lots, int magic, double stoploss)
{
    if(stoploss > 0) {
        stoploss = Bid+stoploss*pips;
        if(shs) {
            hedge_sell_sl = stoploss;
        }
    }

    if(lots > MaxLot1 && run && magic == Magic1)
        lots = MaxLot1;
    
    else if(lots > MaxLot2 && run && magic == Magic2)
        lots = MaxLot2;

    int sell = OrderSend(Symbol(), OP_SELL, lots, Bid, 0, stoploss, 0, Key, magic, 0, clrNONE);
    
    if(sell < 0) {
        Print("Sell failed with error #", GetLastError());
    } else {
        Print("Sell placed successfully ", magic);
    }
}

//--------------------------------------------------------------------------------+
// OpenBuy(Lot, Magic, StopLoss)
// -------------------------------------------------------------------------------+
// Open Posisi BUY
//--------------------------------------------------------------------------------+
void OpenBuy(double lots, int magic, double stoploss)
{
    if(stoploss > 0) {
        stoploss = Ask-stoploss*pips;
        if(shb) {
            hedge_buy_sl = stoploss;
        }
    }

    if(lots > MaxLot1 && run && magic == Magic1)
        lots = MaxLot1;

    else if(lots > MaxLot2 && run && magic == Magic2)
        lots = MaxLot2;

    int buy = OrderSend(Symbol(), OP_BUY, lots, Ask, 0, stoploss, 0, Key, magic, clrNONE);

    if(buy < 0) {
        Print("Buy failed with error #", GetLastError());
    } else {
        Print("Buy placed successfully ", magic);
    }
}

//--------------------------------------------------------------------------------+
// CloseBuy(Magic Number)
// -------------------------------------------------------------------------------+
// Tutup semua posisi BUY berdasarkan Magic Number.
//--------------------------------------------------------------------------------+
void CloseBuy(int magic)
{
    for(int i = 0; i < OrdersTotal(); i++) {
        int a = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        {
            if(OrderType() == OP_BUY && OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                int u = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 100, clrNONE);
            }
        }
    }

    if(CountBuy(magic) > 0) CloseBuy(magic);
}

//--------------------------------------------------------------------------------+
// CloseSell(Magic Number)
// -------------------------------------------------------------------------------+
// Tutup semua posisi SELL berdasarkan Magic Number.
//--------------------------------------------------------------------------------+
void CloseSell(int magic)
{
    for(int i = 0; i < OrdersTotal(); i++) {
        int a = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        {
            if(OrderType() == OP_SELL && OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                int u = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 100, clrNONE);
            }
        }
    }

    if(CountSell(magic) > 0) CloseSell(magic);
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
         bool retVal = OrderCloseReliable(sell_tickets[i], sell_lots[i], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
      }
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
         bool retVal = OrderCloseReliable(buy_tickets[i], buy_lots[i], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
      }
   }
}

//+------------------------------------------------------------------+
// closeAllhedgeSells
//+------------------------------------------------------------------+
void closeAllhedgeSells() {
   if(hedge_sells > 0) {
      for(int i = 0; i <= hedge_sells - 1; i++) {
         bool retVal = OrderCloseReliable(hedge_sell_tickets[i], hedge_sell_lots[i], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
      }
   }
}

//+------------------------------------------------------------------+
// closeAllhedgeBuys
//+------------------------------------------------------------------+
void closeAllhedgeBuys() {
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
   buy_max_hedge_profit = 0;
   buy_close_hedge_profit = 0;

   bool retVal = OrderCloseReliable(sell_tickets[0], sell_lots[0], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
   closeAllhedgeBuys();
}

//+------------------------------------------------------------------+
// closeBuyHedgeAndFirstSellOrder
//+------------------------------------------------------------------+
void closeBuyHedgeAndLastAndSecondLastSellOrder() {

   closeAllhedgeBuys();
   bool retVal = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
   bool retVal2 = OrderCloseReliable(sell_tickets[sells - 2], sell_lots[sells - 2], MarketInfo(Symbol(), MODE_ASK), Slippage, Red);
}

//+------------------------------------------------------------------+
// closeSellHedgeAndFirstBuyOrder
//+------------------------------------------------------------------+
void closeSellHedgeAndFirstBuyOrder() {
   sell_max_hedge_profit = 0;
   sell_close_hedge_profit = 0;

   bool retVal = OrderCloseReliable(buy_tickets[0], buy_lots[0], MarketInfo(Symbol(), MODE_BID), Slippage, Blue);
   closeAllhedgeSells();
}

//+------------------------------------------------------------------+
// closeBuyHedgeAndLastAndSecondLastBuyOrder
//+------------------------------------------------------------------+
void closeSellHedgeAndLastAndSecondLastBuyOrder() {

   closeAllhedgeSells();
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
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_BUY, Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)hedge_buys, Magic1, 0, Blue);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_BUY, MaxOrders * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)hedge_buys, Magic1, 0, Blue);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_BUY, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)hedge_buys, Magic1, 0, Blue);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_BUY, FiboSequence(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)hedge_buys, Magic1, 0, Blue);
   } else {
      // new hedging sell order
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_SELL, buy_lots[0], MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key + "-" + (string)hedge_sells, Magic1, 0, Red);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_SELL, MaxOrders * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key + "-" + (string)hedge_sells, Magic1, 0, Red);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_SELL, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key + "-" + (string)hedge_sells, Magic1, 0, Red);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_SELL, FiboSequence(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key + "-" + (string)hedge_sells, Magic1, 0, Red);
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
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_BUY, FiboSequence(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_buys, Magic2, 0, Blue);
   } else {
      
      // new hedging sell order
      if(Sequence == 0) ticket = OrderSendReliable(Symbol(), OP_SELL, Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
      if(Sequence == 1) ticket = OrderSendReliable(Symbol(), OP_SELL, MaxOrders * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
      if(Sequence == 2) ticket = OrderSendReliable(Symbol(), OP_SELL, (2 * MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
      if(Sequence == 3) ticket = OrderSendReliable(Symbol(), OP_SELL, FiboSequence(MaxOrders) * Lot, MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, KeyHedging + "-" + (string)hedge_sells, Magic2, 0, Red);
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
   //       closeAllSells();
   //    }

   //    if((CycleEquityRisk * AccountBalance()) * -1 > local_total_buy_profit) {
   //       closeAllBuys();
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
   // check if MaxOrders is reached:
   // if(buys >= GridPartiallyClose && !isHedgingSellActive()) {
   //    // calculate profit of the first and last buy order
   //    // trail the profit of the last and first buy order
   //    // close the first and the last buy order at trailed profit

   //    if(buy_profit[buys - 1] > 0) {
   //       double buy_profit_first_and_last = buy_profit[buys - 1] + buy_profit[0];
   //       if(buy_profit_first_and_last > TakeProfit(buy_lots[0])) {
   //          closeLastAndFirstBuyOrder();
   //       }
   //    }
   // }

   // if(sells >= GridPartiallyClose && !isHedgingBuyActive()) {
   //    // calculate profit of the first and last sell order
   //    // trail the profit of the last and first sell order
   //    // close the first and the last sell order at trailed profit

   //    if(sell_profit[sells - 1] > 0) {
   //       double sell_profit_first_and_last = sell_profit[sells - 1] + sell_profit[0];
   //       if(sell_profit_first_and_last > TakeProfit(sell_lots[0])) {
   //          closeLastAndFirstSellOrder();
   //       }
   //    }
   // }
}