// **************************************************
// Logic Robot
// **************************************************
void Robot() 
{
    int ticket = - 1;

    double local_total_buy_profit = total_buy_profit;
    double local_total_sell_profit = total_sell_profit;

    if(hedge_buys > 0) 
        local_total_sell_profit = total_sell_profit + total_hedge_buy_profit;

    if(hedge_sells > 0) 
        local_total_buy_profit = total_buy_profit + total_hedge_sell_profit;

    InitFunction();
    OrderLogic(ticket);
}

// **************************************************
// Inisiasi Fungsi
// **************************************************
void InitFunction() 
{
    //**************************************************
    // Close all if "Daily Target (USD)" reached
    //**************************************************
    // if(DailyTarget > 0 && ProfitToday(-1) + TotalPLSell(Magic1)+TotalPLSell(Magic2) + TotalPLBuy(Magic1)+TotalPLBuy(Magic2) >= DailyTarget) {
    //     run = false;
    //     CloseAll();

    //     if(!IsTesting()) Alert("Capai Target Harian! Istirahat Dulu!");
    //     return;
    // } else {
    //     run = true;
    // }

    //**************************************************
    // Close all if "Target Equity (USD)" reached
    //**************************************************
    if(TargetEquity > 0 && AccountEquity() >= TargetEquity) {
        run = false;
        CloseAll();

        if(!IsTesting()) Alert("Capai Target! WD, jangan lupa sedekah!");
        return;
    } else {
        run = true;
    }

    // **************************************************
    // Close all posisi bila sesuai "Time Settings"
    // **************************************************
    if(!TradeTime()) {
        run = false;
        CloseAll();

        if(!IsTesting()) Print("Sudah waktunya istirahat, jangan GREEDY!");
        return;
    } else {
        run = true;
    }
    
    // **************************************************
    // Batasi floating, jika menyentuh tutup semua posisi
    // **************************************************
    if(AccountProfit() <= -AccountLock) {
        run = false;
        ExpertRemove();

        return;
    }
}

// **************************************************
// Order Logic "BUY & SELL"
// **************************************************
void OrderLogic(int ticket) 
{
    double buy_tp = 0, sell_tp = 0;

    if(run && ((TimeFilter && TradeTime()) || TimeFilter == false) && (market_spread/10 <= Spread)) 
    {    
        //**************************************************
        // BUYS == 0 - First Buy
        //**************************************************
        if(buys == 0) {
            if(!stop_next_cycle && !rest_and_realize) {
                if(!HiddenTP) {
                    buy_tp = market_price_buy+(TakeProfitPips*market_point);
                }
                
                ticket = OrderSendReliable(Symbol(), OP_BUY, InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, buy_tp, Key, Magic1, 0, Blue);
            }
        }

        // **************************************************
        // BUYS == 1
        // **************************************************
        if(buys == 1) {
            if(!stop_next_cycle && !rest_and_realize && MaxOrders > 0) {
                if(Ask <= buy_price[buys-1]-Distance*market_point) {
                    NewOrder(OP_BUY, Magic1, false);
                }
            }
        }

        // **************************************************
        // BUYS > 1
        // **************************************************
        if(buys > 1) {
            if(!stop_next_cycle && !rest_and_realize) {
                if(Ask <= buy_price[buys-1]-Distance*market_point) {
                    if(buys < max_auto_open_positions) {
                        if(buys < MaxOrders && !buy_max_order_lot_open) {
                            NewOrder(OP_BUY, Magic1, false);
                        }
                    }
                }
            }
        }

        if(HiddenTP) {
            if((total_buy_profit+sell_close_hedge_profit >= TakeProfit || (total_buy_profit+sell_close_hedge_profit)/(total_buy_lots+total_hedge_sell_lots)*market_point >= TakeProfitPips*market_point)) {
                CloseAllBuys();
            }
        }

        // **************************************************
        // SELLS == 0 - First Sell
        // **************************************************
        // if(sells == 0) {
        //     if(!stop_next_cycle && !rest_and_realize) {
        //         if(!HiddenTP)
        //             sell_tp = market_price_sell-(TakeProfitPips*market_point);

        //         ticket = OrderSendReliable(Symbol(), OP_SELL, InitLot(), MarketInfo(Symbol(), MODE_BID), Slippage, 0, sell_tp, Key, Magic1, 0, Red);
        //     }
        // } else {
        //     if(HiddenTP) {
        //         if((total_sell_profit+buy_close_hedge_profit >= TakeProfit || (total_sell_profit+buy_close_hedge_profit)/(total_sell_lots+total_hedge_buy_lots)*market_point >= TakeProfitPips*market_point))
        //             CloseAllSells();
        //     }
        // }

        //**************************************************
        // SELLS == 1
        //**************************************************
        // if(sells == 1) {
        //     if(!stop_next_cycle && !rest_and_realize && MaxOrders > 0)
        //         if(Bid >= sell_price[sells-1]+Distance*market_point)
        //             NewOrder(OP_SELL, Magic1, false);
        // }

        //**************************************************
        // BUYS > 1
        //**************************************************
        // if(buys > 1) {
        //     // CASE 1 >>> Kalau arah loss (Stop Loss)
        //     if(!stop_next_cycle && !rest_and_realize && MaxOrders > 1) {
        //         if(buy_profit[buys - 1] <= DistanceGrid(buy_lots[buys - 1], buys)) {
        //             NewOrder(OP_BUY, Magic1, false);
        //             if(EnablePyramid) {
        //                 if(buys == HedgeLevel) {
        //                     is_sell_hedging_order_active = true;
        //                     NewOrder(OP_SELL, Magic2, StopLoss);
        //                 } else if(buys > HedgeLevel) {
        //                     hedge_sell_lot += FirstLotBuy(Magic1);
        //                     if(Reload)
        //                         OpenSell(hedge_sell_lot-TotalLotSell(Magic2), Magic2, StopLoss);
        //                     else
        //                         OpenSell(buy_lot, Magic2, StopLoss);
        //                 }
        //             }
        //         }
        //     }

        //     // CASE 2 >>> Kalau arah profit (Take Profit)
        //     if(!stop_next_cycle && !rest_and_realize) {
        //         if(local_total_buy_profit+total_hedge_sell_profit >= TakeProfit || (local_total_buy_profit+total_hedge_sell_profit)/(total_buy_lots+total_sell_lots)*Point >= TakeProfitPips*pips) {
        //             CloseBuy
        //             if()
        //         }

        //     }

        //     if(CountBuy(Magic1)>0 && (TotalPLBuy(Magic1)+TotalPLSell(Magic2)>=TakeProfit || 
        //         ((TotalPLBuy(Magic1)+TotalPLSell(Magic2))/(TotalLotBuy(Magic1)+TotalLotSell(Magic2)))*Point>=TakeProfitPips*pips)) {
        //         CloseBuy(Magic1);
                
        //         if(CountSell(Magic2)>0) {
        //             CloseSell(Magic2);
        //         }
        //     }
        // }


        




        
        // **************************************************
        // SELLS > 1
        // **************************************************
        // if(sells > 0 && Bid >= sell_price[sells-1]+Distance*pips) {
            
        //     NewOrder(OP_SELL, Magic1, false);
            
        //     if(EnablePyramid == true) {

        //         if(CountSell(Magic1)==HedgeLevel) {

        //             is_sell_hedging_order_active = true;
                    
        //             hedge_buy_lot=FirstLotSell(Magic1);
        //             OpenBuy(hedge_buy_lot,Magic2,StopLoss);
        //         } else if(CountSell(Magic1)>HedgeLevel) {
        //             hedge_buy_lot+=FirstLotSell(Magic1);
        //             if(Reload) {
        //                 OpenBuy(hedge_buy_lot-TotalLotBuy(Magic2),Magic2,StopLoss);
        //             } else {
        //                 OpenBuy(sell_lot,Magic2,StopLoss);
        //             }
        //         }
        //     }
        // }
    }



    

    // Modify Stoploss Pyramyd Buy
    // if(hedge_buys > 0) {
    //     for(int i=0;i<OrdersTotal();i++) {
    //         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
    //             if(OrderType()==0 && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic2) {
    //                 if(OrderStopLoss()<Bid-TrailSL*pips && Bid-OrderOpenPrice()>=TrailSL*pips) {
    //                     bool mb=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailSL*pips,OrderTakeProfit(),0,clrNONE);
    //                     if(mb) {
    //                         hedge_buy_sl=Bid-TrailSL*pips;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }
    
    // Modify Stoploss Pyramyd Sell
    // if(hedge_sells > 0) {
    //     for(int j=0;j<OrdersTotal();j++) {
    //         if(OrderSelect(j,SELECT_BY_POS, MODE_TRADES)) {
    //             if(OrderType()==1 && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic2) {
    //                 if((OrderStopLoss()>Ask+TrailSL*pips || OrderStopLoss()==0) && (OrderOpenPrice()-Ask>=TrailSL*pips)) {
    //                     bool sb=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailSL*pips,OrderTakeProfit(),0,clrNONE);
    //                     if(sb) {
    //                         hedge_sell_sl=Ask+TrailSL*pips;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }
}