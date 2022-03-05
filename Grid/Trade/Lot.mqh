//--------------------------------------------------------------------------------+
// FirstLotBuy(Magic)
// -------------------------------------------------------------------------------+
// First Lot BUY
//--------------------------------------------------------------------------------+
double FirstLotBuy(int magic) {
    double l = 0;
    double ol = 0;
    for(int i = OrdersTotal(); i >= 0; i--) {
        int a = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            l = OrderLots();
        }
        if(l >= ol || ol == 0) ol = l;
    }

    return ol;
}

//--------------------------------------------------------------------------------+
// FirstLotSell(Magic)
// -------------------------------------------------------------------------------+
// First Lot SELL
//--------------------------------------------------------------------------------+
double FirstLotSell(int magic)
{
    double l = 0;
    double ol = 0;
    for(int i = OrdersTotal(); i >= 0; i--) {
        int a = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            l = OrderLots();
        }
        if(l >= ol || ol == 0) ol = l;
    }

    return ol;
}