//+------------------------------------------------------------------+
//| Main auto trading method 		                                 |
//+------------------------------------------------------------------+
void Robot() 
{
    int ticket = -1;
    bool closed = false;

    double local_total_buy_profit = total_buy_profit;
    double local_total_sell_profit = total_sell_profit;

	// **************************************************
    // BUYS==0
    // **************************************************
    if(buys == 0 && TradeTime()) {
        if(!stop_next_cycle && !rest_and_realize) {
            ticket = OrderSendReliable(Symbol(), OP_BUY, InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)buys, Magic1, 0, Blue);
        }
    }

    // **************************************************
    // BUYS == 1
    // **************************************************
    if(buys == 1) {
        // CASE 1 >>> We reach Stop Loss (grid size)
        if(!stop_next_cycle && !rest_and_realize && MaxOrders > 1) {
            if(buy_profit[buys - 1] <= StopLoss(buy_lots[buys - 1], 1)) {
                OpenPosition(OP_BUY, Magic1, false);
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
        if(buy_max_profit > 0 && buy_close_profit > 0 && buy_max_profit >= buy_close_profit && local_total_buy_profit < buy_close_profit) {
            // At this point all order are closed.
            // Global vars will be updated thanks to UpdateVars() on next start() execution
            closeAllBuys();
        }
    }

    // **************************************************
    // BUYS > 1
    // **************************************************
    if(buys > 1) {
        // CASE 1 >>> We reach Stop Loss (grid size)
        if(buy_profit[buys - 1] <= StopLoss(buy_lots[buys - 1], buys)) {
            // We are going to open a new order if we have less than 90 orders opened.
            // Volume depends on chosen Sequence.
            if(buys < max_auto_open_positions) {
                if(buys < MaxOrders && !buy_max_order_lot_open) {
                    OpenPosition(OP_BUY, Magic1, false);
                }
            }
        }

        // CASE 2.1 >>> We reach Take Profit so we activate profit lock
        if(buy_max_profit == 0 && Sequence == 0 && local_total_buy_profit > TakeProfit(buy_lots[0])) {
            buy_max_profit = local_total_buy_profit;
            buy_close_profit = ProfitLock * buy_max_profit;
            if (!buy_chased && ProfitChasing > 0) {
                if (buys < max_auto_open_positions && buys < MaxOrders) {
                    ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)buys, Magic1, 0, Blue);
                }
                buy_chased = true;
            }
        }
        if(buy_max_profit == 0 && Sequence == 1 && local_total_buy_profit > buys * TakeProfit(buy_lots[0])) {
            buy_max_profit = local_total_buy_profit;
            buy_close_profit = ProfitLock * buy_max_profit;
            if(!buy_chased && ProfitChasing > 0) {
                if (buys < max_auto_open_positions && buys < MaxOrders)
                ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)buys, Magic1, 0, Blue);
                buy_chased = true;
            }
        }
        if(buy_max_profit == 0 && Sequence == 2 && local_total_buy_profit > TakeProfit(buy_lots[buys - 1])) {
            buy_max_profit = local_total_buy_profit;
            buy_close_profit = ProfitLock * buy_max_profit;
            if(!buy_chased && ProfitChasing > 0) {
                if (buys < max_auto_open_positions && buys < MaxOrders) {
                    ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)buys, Magic1, 0, Blue);
                }
                buy_chased = true;
            }
        }
        if(buy_max_profit == 0 && Sequence == 3 && local_total_buy_profit > TakeProfit(buy_lots[buys - 1])) {
            buy_max_profit = local_total_buy_profit;
            buy_close_profit = ProfitLock * buy_max_profit;
            if(!buy_chased && ProfitChasing > 0) {
                if (buys < max_auto_open_positions && buys < MaxOrders) {
                    ticket = OrderSendReliable(Symbol(), OP_BUY, ProfitChasing * InitLot(), MarketInfo(Symbol(), MODE_ASK), Slippage, 0, 0, Key + "-" + (string)buys, Magic1, 0, Blue);
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
        if(buy_max_profit > 0 && buy_close_profit > 0 && buy_max_profit >= buy_close_profit && local_total_buy_profit < buy_close_profit) {
            closeAllBuys();
        }
    }

    // **************************************************
    // SELLS==0
    // **************************************************
    if(sells == 0 && TradeTime()) {
        if(!stop_next_cycle && !rest_and_realize) {
            ticket = OrderSendReliable(Symbol(), OP_SELL, InitLot(), MarketInfo(Symbol(), MODE_BID), Slippage, 0, 0, Key + "-" + (string)sells, Magic1, 0, Red);
        }
    }

    // **************************************************
    // SELLS == 1
    // **************************************************
    if(sells == 1) {}

    // **************************************************
    // SELLS>1
    // **************************************************
    if(sells > 1) {}









    // ------------------------------------------------------------------+
    // Tutup semua bila "Daily Target (USD)" tercapai
    // ------------------------------------------------------------------+
    // if(DailyTarget > 0 && ProfitToday(-1) + TotalPLSell(Magic1)+TotalPLSell(Magic2) + TotalPLBuy(Magic1)+TotalPLBuy(Magic2) >= DailyTarget) {
    //     run = false;
    //     CloseAllOrders();

    //     if(!IsTesting()) Alert("Capai Target Harian! Istirahat Dulu!");
    //     return;
    // } else {
    //     run = true;
    // }

    // ------------------------------------------------------------------+
    // Tutup semua posisi bila "Target Equity (USD)" tercapai
    // ------------------------------------------------------------------+
    // if(TargetEquity > 0 && AccountEquity() >= TargetEquity) {
    //     run = false;
    //     CloseAllOrders();

    //     if(!IsTesting()) Alert("Capai Target! WD, jangan lupa sedekah!");
    //     return;
    // }

    // ------------------------------------------------------------------+
    // Tutup semua posisi bila sesuai properti "Time Settings"
    // ------------------------------------------------------------------+
    // if(!TradeTime()) {
    //     run = false;
    //     CloseAllOrders();

    //     if(!IsTesting()) {
    //         Print("Sudah waktunya istirahat, jangan GREEDY!");
    //     }
    //     return;
    // } else {
    //     run = true;
    // }
    
    // Proteksi atau batasi floating loss, jika menyentuh titik batas tutup semua posisi
    // if(AccountProfit() <= -AccountLock) {
    //     run = false;
    //     ExpertRemove();
    //     return;
    // }

    // if(((TimeFilter && TradeTime()) || TimeFilter == false) && (MarketInfo(Symbol(), MODE_SPREAD)/10 <= Spread)) {

    //     // 
    //     if(CountBuy(Magic1) == 0) {
    //         buy_lot = Lot;
    //         hedge_sell_lot = 0;
    //         hedge_sell_sl = 0;
    //         shs = false;
    //     }

    //     // 
    //     if(CountSell(Magic1) == 0) {
    //         sell_lot = Lot;
    //         hedge_buy_sl = 0;
    //         hedge_buy_lot = 0;
    //         shb = false;
    //     }

    //     // Kalau belum ada open posisi -> Open Hedge
    //     if(CountBuy(Magic1) == 0 && CountSell(Magic1) > 0) {
    //         OpenBuy(Lot, Magic1, 0);
    //     }

    //     if(CountBuy(Magic1) > 0 && CountSell(Magic1) == 0) {
    //         OpenSell(Lot, Magic1, 0);
    //     }

    //     if(CountBuy(Magic1) == 0 && CountSell(Magic1) == 0) {
    //         OpenBuy(Lot, Magic1, 0);
    //         OpenSell(Lot, Magic1, 0);
    //     }

    //     // Kalau sudah ada posisi BUY dan 
    //     if(CountBuy(Magic1) > 0 && Ask <= FirstOrderBuy(Magic1)-Distance*pips) {
    //         buy_lot = buy_lot*Multiplier;
    //         OpenBuy(buy_lot, Magic1, 0);
            
    //         if(CountBuy(Magic1) == HedgeLevel) {
    //             hedge_sell_lot = FirstLotBuy(Magic1);
    //             OpenSell(hedge_sell_lot, Magic2, StopLoss);


    //         } else if(CountBuy(Magic1) > HedgeLevel) {
    //             hedge_sell_lot+=FirstLotBuy(Magic1);

    //             if(Reload)
    //                 OpenSell(hedge_sell_lot-TotalLotSell(Magic2), Magic2, StopLoss);
    //             else
    //                 OpenSell(buy_lot, Magic2, StopLoss);
    //         }
         
    //         if(CountSell(Magic1) == 0) {
    //             OpenSell(Lot, Magic1, 0);
    //         }
    //     }

    //     // Kalau sudah ada posisi SELL dan ...
    //     if(CountSell(Magic1)>0 && Bid >= FirstOrderSell(Magic1)+Distance*pips) {
    //         sell_lot = sell_lot * Multiplier;
    //         OpenSell(sell_lot, Magic1, 0);
            
    //         if(CountSell(Magic1)==HedgeLevel) {
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

    //         if(CountBuy(Magic1)==0) {
    //             OpenBuy(Lot,Magic1,0);
    //         }
    //     }
    // }
      
    // if(CountSell(Magic1)>0 && (TotalPLSell(Magic1)+TotalPLBuy(Magic2)>=TakeProfit || 
    //   ((TotalPLSell(Magic1)+TotalPLBuy(Magic2))/(TotalLotSell(Magic1)+TotalLotBuy(Magic2)))*Point>=TakeProfitPips*pips)) { 
    //     CloseSell(Magic1);
        
    //     if(CountBuy(Magic2)>0) {
    //         CloseBuy(Magic2);
    //     }
    // }

    // if(CountBuy(Magic1)>0 && (TotalPLBuy(Magic1)+TotalPLSell(Magic2)>=TakeProfit || ((TotalPLBuy(Magic1)+TotalPLSell(Magic2))/(TotalLotBuy(Magic1)+TotalLotSell(Magic2)))*Point>=TakeProfitPips*pips)) {
    //     CloseBuy(Magic1);
        
    //     if(CountSell(Magic2)>0) {
    //         CloseSell(Magic2);
    //     }
    // }

    // if(CountBuy(Magic2)>0) {
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
    
    // if(CountSell(Magic2)>0) {
    //     for(int j=0;j<OrdersTotal();j++) {
    //         if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES)) {
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