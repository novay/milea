// **************************************************
// Logic Robot
// **************************************************
void Robot() 
{
    int ticket = -1;

    double local_total_buy_profit = total_buy_profit;
    double local_total_sell_profit = total_sell_profit;

    if(hedge_buys > 0) {
        local_total_sell_profit = total_sell_profit + total_hedge_buy_profit;
    }

    if(hedge_sells > 0) {
        local_total_buy_profit = total_buy_profit + total_hedge_sell_profit;
    }

    InitFunction();
    
    double buy_tp = 0, sell_tp = 0;

    if(run && ((TimeFilter && TradeTime()) || TimeFilter == false) && (market_spread/10 <= Spread)) 
    {
        if(!HiddenTP) {
            buy_tp = market_price_buy+TakeProfitPips*market_point;
            sell_tp = market_price_sell+(TakeProfitPips*market_point);
        }

        //**************************************************
        // BUYS == 0 - First Buy
        //**************************************************
        if(buys == 0) {
            if(!stop_next_cycle && !rest_and_realize) {
                NewGridOrder(OP_BUY, Magic1, 0, buy_tp);
            }
        } else {
            if(HiddenTP) {
                if((total_buy_profit+total_hedge_sell_profit >= TakeProfit || (total_buy_profit+total_hedge_sell_profit)/(total_buy_lots+total_hedge_sell_lots)*market_point >= TakeProfitPips*market_point)) {
                    CloseAllBuys();
                }
            }
        }

        // **************************************************
        // BUYS == 1
        // **************************************************
        if(buys == 1) {
            if(!stop_next_cycle && !rest_and_realize && MaxOrders > 0) {
                if(Ask <= buy_price[buys-1]-Distance*market_point) {
                    NewGridOrder(OP_BUY, Magic1);
                }
            }
        }

        // **************************************************
        // BUYS > 1
        // **************************************************
        if(buys > 1) {
            if(!stop_next_cycle && !rest_and_realize) {
                if(buys < MaxOrders) {
                    if(Ask <= buy_price[buys-1]-Distance*market_point) {
                        NewGridOrder(OP_BUY, Magic1);
                        if(buys == HedgeLevel) {    
                            is_sell_hedging_active = true;
                            NewGridOrder(OP_SELL, Magic2, market_price_buy-StopLoss*market_point, 0, buy_lots[buys-1]);
                        } else if(buys > HedgeLevel) {
                            if(!Reload) {
                                NewGridOrder(OP_SELL, Magic2, market_price_buy-StopLoss*market_point, 0, total_buy_lots);
                            } else {
                                NewGridOrder(OP_SELL, Magic2, market_price_buy-StopLoss*market_point, 0, buy_lots[buys-1]);
                            }
                        }
                    }
                }
            }
        }

        //**************************************************
        // SELLS == 0 - First Sell
        //**************************************************
        if(sells == 0) {
            if(!stop_next_cycle && !rest_and_realize) {
                NewGridOrder(OP_SELL, Magic1, 0, sell_tp);
            }
        } else {
            if(HiddenTP) {
                if((total_sell_profit+total_hedge_buy_profit >= TakeProfit || (total_sell_profit+total_hedge_buy_profit)/(total_sell_lots+total_hedge_buy_lots)*market_point >= TakeProfitPips*market_point)) {
                    CloseAllSells();
                }
            }
        }

        // **************************************************
        // SELLS == 1
        // **************************************************
        if(sells == 1) {
            if(!stop_next_cycle && !rest_and_realize && MaxOrders > 0) {
                if(Bid >= sell_price[sells-1]-Distance*market_point) {
                    NewGridOrder(OP_SELL, Magic1);
                }
            }
        }

        // **************************************************
        // SELLS > 1
        // **************************************************
        if(sells > 1) {
            if(!stop_next_cycle && !rest_and_realize) {
                if(sells < MaxOrders) {
                    if(Bid >= sell_price[sells-1]-Distance*market_point) {
                        NewGridOrder(OP_SELL, Magic1);
                        if(sells == HedgeLevel) {
                            is_buy_hedging_active = true;
                            NewGridOrder(OP_BUY, Magic2, market_price_sell+StopLoss*market_point, 0, sell_lots[sells-1]);
                        } else if(sells > HedgeLevel) {
                            if(!Reload) {
                                NewGridOrder(OP_BUY, Magic2, market_price_sell+StopLoss*market_point, 0, total_sell_lots);
                            } else {
                                NewGridOrder(OP_BUY, Magic2, market_price_sell+StopLoss*market_point, 0, sell_lots[sells-1]);
                            }
                        }
                    }
                }
            }
        }

        if(total_buy_profit >= TakeProfit) CloseAllBuys();
        if(total_sell_profit >= TakeProfit) CloseAllSells();

        if(LevelRisk > 0) {
            if(buys == LevelRisk || sells == LevelRisk) {
                if(total_buy_profit >= 1) 
                    CloseAllBuys();
                
                if(total_sell_profit >= 1) 
                    CloseAllSells();
            }
        }

        if(PairsLoss > 0) {
            if(PairsLoss-(2*PairsLoss) >= total_buy_profit) {
                CloseAllBuys();
            }

            if(PairsLoss-(2*PairsLoss) >= total_sell_profit) {
                CloseAllSells();
            }
        }

        // if(hedge_buys > 0) {
        //     for(int i=0;i<OrdersTotal();i++) {
        //         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
        //             if(OrderType()==0 && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic2) {
        //                 if(OrderStopLoss()<Bid-TrailSL*market_point && Bid-OrderOpenPrice()>=TrailSL*market_point) {
        //                     bool mb=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailSL*market_point,OrderTakeProfit(),0,clrNONE);
        //                     // if(mb) {
        //                     //     hedge_buy_sl=Bid-TrailSL*market_point;
        //                     // }
        //                 }
        //             }
        //         }
        //     }
        // }

        // if(hedge_sells > 0) {
        //     for(int j=0;j<OrdersTotal();j++) {
        //         if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES)) {
        //             if(OrderType()==1 && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic2) {
        //                 if((OrderStopLoss()>Ask+TrailSL*market_point || OrderStopLoss()==0) && (OrderOpenPrice()-Ask>=TrailSL*market_point)) {
        //                     bool sb=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailSL*market_point,OrderTakeProfit(),0,clrNONE);
        //                     // if(sb) {
        //                     //     hedge_sell_sl=Ask+TrailSL*market_point;
        //                     // }
        //                 }
        //             }
        //         }
        //     }
        // }
    }
}

// **************************************************
// Inisiasi Fungsi
// **************************************************
void InitFunction() 
{
    //**************************************************
    // Close all if "Daily Target (USD)" reached
    //**************************************************
    if(DailyTarget > 0 && ProfitToday(-1)+total_sell_profit+total_hedge_sell_profit+total_buy_profit+total_hedge_sell_profit >= DailyTarget) {
        run = false;
        CloseAll();

        if(!IsTesting()) Alert("Capai Target Harian! Istirahat Dulu!");
        return;
    } else {
        run = true;
    }

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
    if(AccountProfit() <= -AccountLock && TotalLoss && AccountLock > 0) {
        run = false;
        ExpertRemove();

        return;
    }
}
