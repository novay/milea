double ProfitLoss(int type) 
{
    double response = 0;
    for(int cnt = OrdersTotal() - 1; cnt >= 0; cnt--) {
        if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
            if(Symbol()==OrderSymbol() && (OrderType() == type || type == -1))
                response += OrderProfit()+OrderSwap()+OrderCommission();
    }
    return(response);
}

double ProfitToday(int type) 
{
    double response = 0;
    datetime midnight = TimeCurrent()-(TimeCurrent()%(PERIOD_D1*60));

    for(int cnt = OrdersHistoryTotal()-1; cnt >= 0; cnt--) {
        if(OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY) && OrderCloseTime() >= midnight)
            response += OrderProfit()+OrderSwap()+OrderCommission();
    }

    return response;
}