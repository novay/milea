//**************************************************
// Reset all variables before update with new one
//**************************************************
void ResetVars() {
    buys = 0;
    sells = 0;
    hedge_buys = buys;
    hedge_buys = sells;

    is_buy_hedging_active = false;
    is_sell_hedging_active = false;

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
}

void UpdateVars() 
{
    double max_lot = 0;
    int aux_buys = 0, aux_sells = 0;
    int aux_hedge_buys = 0, aux_hedge_sells = 0;
    double aux_total_buy_profit = 0, aux_total_sell_profit = 0;
    double aux_hedge_total_buy_profit = 0, aux_hedge_total_sell_profit = 0;
    double aux_total_buy_swap = 0, aux_total_sell_swap = 0, aux_hedge_total_buy_swap = 0, aux_hedge_total_sell_swap = 0;
    double aux_total_buy_commission = 0, aux_total_sell_commission = 0, aux_hedge_total_buy_commission = 0, aux_hedge_total_sell_commission = 0;
    double aux_total_buy_lots = 0, aux_total_sell_lots = 0;
    double aux_hedge_total_buy_lots = 0, aux_hedge_total_sell_lots = 0;
    double aux_total_swap = 0, aux_total_commission = 0;

    if(Sequence == 0) max_lot = Lot;
    if(Sequence == 1) max_lot = MaxOrders * Lot;
    if(Sequence == 2) max_lot = 2 * MaxOrders * Lot;
    if(Sequence == 3) max_lot = Fibonacci(MaxOrders) * Lot;

    // We are going to introduce data from opened orders in arrays
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true) {
            if(OrderSymbol() == Symbol()) {
                if(OrderMagicNumber() == Magic1 && OrderType() == OP_BUY) {
                    buy_tickets[aux_buys] = OrderTicket();
                    buy_lots[aux_buys] = OrderLots();

                    buy_profit[aux_buys] = OrderProfit() + OrderCommission() + OrderSwap();
                    buy_price[aux_buys] = OrderOpenPrice();
                    aux_total_buy_profit = aux_total_buy_profit + buy_profit[aux_buys];
                    aux_total_buy_lots = aux_total_buy_lots + buy_lots[aux_buys];
                    aux_total_buy_swap += OrderSwap();
                    aux_total_buy_commission += OrderCommission();

                    aux_total_swap += aux_total_buy_swap;
                    aux_total_commission += aux_total_buy_commission;
                    aux_buys++;
                }

                // hedge opened buy orders - this is used for corrections
                if(OrderMagicNumber() == Magic2 && OrderType() == OP_BUY) {
                    hedge_buy_tickets[aux_hedge_buys] = OrderTicket();
                    hedge_buy_lots[aux_hedge_buys] = OrderLots();
                    hedge_buy_profit[aux_hedge_buys] = OrderProfit() + OrderCommission() + OrderSwap();
                    hedge_buy_price[aux_hedge_buys] = OrderOpenPrice();
                    aux_hedge_total_buy_profit = aux_hedge_total_buy_profit + hedge_buy_profit[aux_hedge_buys];
                    aux_hedge_total_buy_lots = aux_hedge_total_buy_lots + hedge_buy_lots[aux_hedge_buys];
                    aux_hedge_total_buy_swap += OrderSwap();
                    aux_hedge_total_buy_commission += OrderCommission();

                    aux_total_swap += aux_hedge_total_buy_swap;
                    aux_total_commission += aux_hedge_total_buy_commission;
                    aux_hedge_buys++;
                }

                if(OrderMagicNumber() == Magic1 && OrderType() == OP_SELL) {
                    sell_tickets[aux_sells] = OrderTicket();
                    sell_lots[aux_sells] = OrderLots();

                    sell_profit[aux_sells] = OrderProfit() + OrderCommission() + OrderSwap();
                    sell_price[aux_sells] = OrderOpenPrice();
                    aux_total_sell_profit = aux_total_sell_profit + sell_profit[aux_sells];
                    aux_total_sell_lots = aux_total_sell_lots + sell_lots[aux_sells];
                    aux_total_sell_swap += OrderSwap();
                    aux_total_sell_commission += OrderCommission();

                    aux_total_swap += aux_total_sell_swap;
                    aux_total_commission += aux_total_sell_commission;
                    aux_sells++;
                }

                // manual opened sell orders - this is used for corrections
                if(OrderMagicNumber() == Magic2 && OrderType() == OP_SELL) {
                    hedge_sell_tickets[aux_hedge_sells] = OrderTicket();
                    hedge_sell_lots[aux_hedge_sells] = OrderLots();
                    hedge_sell_profit[aux_hedge_sells] = OrderProfit() + OrderCommission() + OrderSwap();
                    hedge_sell_price[aux_hedge_sells] = OrderOpenPrice();
                    aux_hedge_total_sell_profit = aux_hedge_total_sell_profit + hedge_sell_profit[aux_hedge_sells];
                    aux_hedge_total_sell_lots = aux_hedge_total_sell_lots + hedge_sell_lots[aux_hedge_sells];
                    aux_hedge_total_sell_swap += OrderSwap();
                    aux_hedge_total_sell_commission += OrderCommission();

                    aux_total_swap += aux_hedge_total_sell_swap;
                    aux_total_commission += aux_hedge_total_sell_commission;
                    aux_hedge_sells++;
                }
            }
        }
    }

    buys                        = aux_buys;
    sells                       = aux_sells;
    hedge_buys                  = aux_hedge_buys;
    hedge_sells                 = aux_hedge_sells;
    total_buy_profit            = aux_total_buy_profit;
    total_sell_profit           = aux_total_sell_profit;
    total_hedge_buy_profit      = aux_hedge_total_buy_profit;
    total_hedge_sell_profit     = aux_hedge_total_sell_profit;
    total_buy_lots              = aux_total_buy_lots;
    total_sell_lots             = aux_total_sell_lots;
    total_hedge_buy_lots        = aux_hedge_total_buy_lots;
    total_hedge_sell_lots       = aux_hedge_total_sell_lots;

    if(total_hedge_buy_lots > 0) 
        is_buy_hedging_active = true;
    
    if(total_hedge_sell_lots > 0) 
        is_sell_hedging_active = true;

    total_buy_swap              = aux_total_buy_swap;
    total_sell_swap             = aux_total_sell_swap;
    total_hedge_buy_swap        = aux_hedge_total_buy_swap;
    total_hedge_sell_swap       = aux_hedge_total_sell_swap;

    total_buy_commission              = aux_total_buy_commission;
    total_sell_commission             = aux_total_sell_commission;
    total_hedge_buy_commission        = aux_hedge_total_buy_commission;
    total_hedge_sell_commission       = aux_hedge_total_sell_commission;
    
    total_swap                  = aux_total_swap;
    total_commission            = aux_total_commission;
}

//**************************************************
// Sorting by Lots
//**************************************************
void SortByLots() {
    int aux_tickets;
    double aux_lots, aux_profit, aux_price;

    // BUY ORDERS
    for(int i = 0; i < buys - 1; i++) {
        for(int j = i + 1; j < buys; j++) {
            if(buy_lots[i] > 0 && buy_lots[j] > 0) {
                // at least 2 orders
                if(buy_lots[j] < buy_lots[i]) {
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
                    // ...and open price...
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
                    // ...and open price...
                    aux_price = sell_price[i];
                    sell_price[i] = sell_price[j];
                    sell_price[j] = aux_price;
                }
            }
        }
    }
}