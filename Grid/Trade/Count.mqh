//--------------------------------------------------------------------------------+
// TotalPLBuy(Magic Number)
// -------------------------------------------------------------------------------+
// Total semua Unrealized Profit/Loss BUY berdasarkan Magic Number.
//--------------------------------------------------------------------------------+
double TotalPLBuy(int magic)
{
    double count = 0;
    for(int i = 0; i < OrdersTotal(); i++) {
        double pl = 0;
        if(OrderSelect(i, SELECT_BY_POS) == true) {
            if(OrderType() == OP_BUY && OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                pl = OrderProfit();
                count += pl;
            }
        }
    }
    return count;
}

//--------------------------------------------------------------------------------+
// TotalPLSell(Magic Number)
// -------------------------------------------------------------------------------+
// Total semua Unrealized Profit/Loss SELL berdasarkan Magic Number.
//--------------------------------------------------------------------------------+
double TotalPLSell(int magic)
{
    double count = 0;
    for(int i = 0; i < OrdersTotal(); i++) {
        double pl = 0;
        if(OrderSelect(i, SELECT_BY_POS) == true) {
            if(OrderType() == OP_SELL && OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                pl = OrderProfit();
                count += pl;
            }
        }
    }
    return count;
}

//--------------------------------------------------------------------------------+
// TotalLotBuy(Magic Number)
// -------------------------------------------------------------------------------+
// Jumlah seluruh lot yang digunakan dari posisi BUY berdasarkan Magic Number.
//--------------------------------------------------------------------------------+
double TotalLotBuy(int magic)
{
    double count = 0;
    for(int i = 0; i < OrdersTotal(); i++) {
        double lot = 0;
        if(OrderSelect(i, SELECT_BY_POS) == true) {
            if(OrderType() == OP_BUY && OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                lot = OrderLots();
                count += lot;
            }
        }
    }
    return count;
}

//--------------------------------------------------------------------------------+
// TotalLotSell(Magic Number)
// -------------------------------------------------------------------------------+
// Jumlah seluruh lot yang digunakan dari posisi SELL berdasarkan Magic Number.
//--------------------------------------------------------------------------------+
double TotalLotSell(int magic) 
{
    double count = 0;
    for(int i = 0; i < OrdersTotal(); i++) {
        double lot = 0;
        if(OrderSelect(i, SELECT_BY_POS) == true) {
            if(OrderType() == OP_SELL && OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                lot = OrderLots();
                count += lot;
            }
        }
    }
    return count;
}

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