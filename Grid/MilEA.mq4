//+------------------------------------------------------------------+
//|                                                 MilEA-Marti.mq4  |
//|                           Copyright 2022, Borneo Teknomedia, CV. |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#include "Include/Define.h"     // Define EA
#include "Include/Presets.h"    // Properties
#include "Include/Global.h"     // Global Variable

string Comment = ea_name + " v" + ea_version;
bool run = true;
double point;

double hedge_buy_sl, hedge_sell_sl;
double buy_lot, sell_lot;
double hedge_buy_lot, hedge_sell_lot;

bool shb = false;
bool shs = false;

// Global Flags:
bool booting = true; // to do some things only one time after program start
int stop_all = 0; // close all and stop trading or continue with trading

//+------------------------------------------------------------------+
// Library                                                           |
//+------------------------------------------------------------------+
#include "Library/NewsFilter.mqh"
#include "Library/Display.mqh"

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if(Digits == 5 || Digits == 3) {
        point = Point*10;
    } else {
        point = Point;
    }

    DisplayOnInit();
    NewsOnInit();

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
{
    #ifdef DEMO
        if(!IsDemo()) {
            stop_all = 0;
            MessageBox("Pakai Akun DEMO dulu bos!", "PERINGATAN!", MB_OK);
            stop_all = 1 / stop_all;
            return(0);
        }
    #endif

    // Do this only one time after starting the program
    if(booting) {
        if(AccountCurrency() == "EUR") ter_currencySymbol = "€";
        if(MarketInfo(Symbol(), MODE_DIGITS) == 4 || MarketInfo(Symbol(), MODE_DIGITS) == 2) {
            slippage = MaxSlippage;
            ter_chartMultiplier = 1;
        } else if(MarketInfo(Symbol(), MODE_DIGITS) == 5 || MarketInfo(Symbol(), MODE_DIGITS) == 3) {
            ter_chartMultiplier = 10;
            slippage = ter_chartMultiplier * MaxSlippage;
        }
        
        // Do we have any data from previous session?
        ReadIniData();

        debugCommentStat += "\nNew program start at " + TimeToStr(TimeCurrent());
        booting = false;
    }

    if(!IsTradeAllowed()) {
        Comment(versionBMI + "\n\nTrade not allowed.");
        return;
    }




    ChartDisplay();
    NewsOnTick();

    // ------------------------------------------------------------------+
    // Tutup semua bila "Daily Target (USD)" tercapai
    // ------------------------------------------------------------------+
    if(DailyTarget > 0 && ProfitToday(-1) + TotalPLSell(Magic1)+TotalPLSell(Magic2) + TotalPLBuy(Magic1)+TotalPLBuy(Magic2) >= DailyTarget) {
        run = false;
        CloseAllOrders();

        if(!IsTesting()) Alert("Capai Target Harian! Istirahat Dulu!");
        return;
    } else {
        run = true;
    }

    // ------------------------------------------------------------------+
    // Tutup semua posisi bila "Target Equity (USD)" tercapai
    // ------------------------------------------------------------------+
    if(TargetEquity > 0 && AccountEquity() >= TargetEquity) {
        run = false;
        CloseAllOrders();

        if(!IsTesting()) Alert("Capai Target! WD, jangan lupa sedekah!");
        return;
    }

    // ------------------------------------------------------------------+
    // Tutup semua posisi bila sesuai properti "Time Settings"
    // ------------------------------------------------------------------+
    if(!TradeTime()) {
        run = false;
        CloseAllOrders();

        if(!IsTesting()) {
            Print("Sudah waktunya istirahat, jangan GREEDY!");
        }
        return;
    } else {
        run = true;
    }
    
    // string skip = TimeToStr(TimeCurrent(),TIME_DATE);
    // if(skip == "2021.12.01") return;
    // if(skip == "2020.07.22") return;
    // if(skip == "2020.07.28") return;

    // TODO:
    // Kalau ada perlebaran spread yang abnormal, stop open posisi marti, pastikan open posisi saat ini tidak lebih dari 4.
    // Kalau lebih dari 4, perlebar Distance Gridnya.
    
    // Proteksi atau batasi floating loss, jika menyentuh titik batas tutup semua posisi
    if(AccountProfit() <= -AccountLock) {
        run = false;
        ExpertRemove();
        return;
    }

    if(((TimeFilter && TradeTime()) || TimeFilter == false) && (MarketInfo(Symbol(), MODE_SPREAD)/10 <= Spread)) {

        // 
        if(CountBuy(Magic1) == 0) {
            buy_lot = Lot;
            hedge_sell_lot = 0;
            hedge_sell_sl = 0;
            shs = false;
        }

        // 
        if(CountSell(Magic1) == 0) {
            sell_lot = Lot;
            hedge_buy_sl = 0;
            hedge_buy_lot = 0;
            shb = false;
        }

        // Kalau belum ada open posisi -> Open Hedge
        if(CountBuy(Magic1) == 0 && CountSell(Magic1) == 0) {
            OpenBuy(Lot, Magic1, 0);
            OpenSell(Lot, Magic1, 0);
        }

        // if(CountBuy(Magic1) == 0 && CountSell(Magic1) > 0) {
        //     OpenBuy(Lot, Magic1, 0);
        // }

        // if(CountBuy(Magic1) > 0 && CountSell(Magic1) == 0) {
        //     OpenSell(Lot, Magic1, 0);
        // }

        // if(CountBuy(Magic1) == 0 && CountSell(Magic1) == 0) {
        //     OpenBuy(Lot, Magic1, 0);
        //     OpenSell(Lot, Magic1, 0);
        // }

        // Kalau sudah ada posisi BUY dan 
        if(CountBuy(Magic1) > 0 && Ask <= FirstOrderBuy(Magic1)-Distance*point) {
            buy_lot = buy_lot*Multiplier;
            OpenBuy(buy_lot, Magic1, 0);
            
            if(CountBuy(Magic1) == HedgeLevel) {
                hedge_sell_lot = FirstLotBuy(Magic1);
                OpenSell(hedge_sell_lot, Magic2, StopLoss);


            } else if(CountBuy(Magic1) > HedgeLevel) {
                hedge_sell_lot+=FirstLotBuy(Magic1);

                if(Reload)
                    OpenSell(hedge_sell_lot-TotalLotSell(Magic2), Magic2, StopLoss);
                else
                    OpenSell(buy_lot, Magic2, StopLoss);
            }
         
            if(CountSell(Magic1) == 0) {
                OpenSell(Lot, Magic1, 0);
            }
        }

        // Kalau sudah ada posisi SELL dan ...
        if(CountSell(Magic1)>0 && Bid >= FirstOrderSell(Magic1)+Distance*point) {
            sell_lot = sell_lot * Multiplier;
            OpenSell(sell_lot, Magic1, 0);
            
            if(CountSell(Magic1)==HedgeLevel) {
                hedge_buy_lot=FirstLotSell(Magic1);
                OpenBuy(hedge_buy_lot,Magic2,StopLoss);
            

            } else if(CountSell(Magic1)>HedgeLevel) {
                hedge_buy_lot+=FirstLotSell(Magic1);

                if(Reload) {
                    OpenBuy(hedge_buy_lot-TotalLotBuy(Magic2),Magic2,StopLoss);
                } else {
                    OpenBuy(sell_lot,Magic2,StopLoss);
                }
            }

            if(CountBuy(Magic1)==0) {
                OpenBuy(Lot,Magic1,0);
            }
        }
    }
      
    if(CountSell(Magic1)>0 && (TotalPLSell(Magic1)+TotalPLBuy(Magic2)>=TakeProfit || 
      ((TotalPLSell(Magic1)+TotalPLBuy(Magic2))/(TotalLotSell(Magic1)+TotalLotBuy(Magic2)))*Point>=TakeProfitPips*point)) { 
        CloseSell(Magic1);
        
        if(CountBuy(Magic2)>0) {
            CloseBuy(Magic2);
        }
    }

    if(CountBuy(Magic1)>0 && (TotalPLBuy(Magic1)+TotalPLSell(Magic2)>=TakeProfit || ((TotalPLBuy(Magic1)+TotalPLSell(Magic2))/(TotalLotBuy(Magic1)+TotalLotSell(Magic2)))*Point>=TakeProfitPips*point)) {
        CloseBuy(Magic1);
        
        if(CountSell(Magic2)>0) {
            CloseSell(Magic2);
        }
    }

    

    if(CountBuy(Magic2)>0) {
        for(int i=0;i<OrdersTotal();i++) {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
                if(OrderType()==0 && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic2) {
                    if(OrderStopLoss()<Bid-TrailSL*point && Bid-OrderOpenPrice()>=TrailSL*point) {
                        bool mb=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailSL*point,OrderTakeProfit(),0,clrNONE);
                        if(mb) {
                            hedge_buy_sl=Bid-TrailSL*point;
                        }
                    }
                }
            }
        }
    }
    
    if(CountSell(Magic2)>0) {
        for(int j=0;j<OrdersTotal();j++) {
            if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES)) {
                if(OrderType()==1 && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic2) {
                    if((OrderStopLoss()>Ask+TrailSL*point || OrderStopLoss()==0) && (OrderOpenPrice()-Ask>=TrailSL*point)) {
                        bool sb=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailSL*point,OrderTakeProfit(),0,clrNONE);
                        if(sb) {
                            hedge_sell_sl=Ask+TrailSL*point;
                        }
                    }
                }
            }
        }
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

//--------------------------------------------------------------------------------
// TradeTime()
// -------------------------------------------------------------------------------
// Return true jika waktu trading sesuai kondisi 
//--------------------------------------------------------------------------------
bool TradeTime()
{
    if(TimeFilter == true) {
        int jam = TimeHour(TimeCurrent());
        if(StartHour > jam && jam < EndHour) {
            return true;
        } else {
            return false;
        }
    }

    return true;
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

//--------------------------------------------------------------------------------+
// OpenSell(Lots, Magic, StopLoss)
// -------------------------------------------------------------------------------+
// Open Posisi SELL
//--------------------------------------------------------------------------------+
void OpenSell(double lots, int magic, double stoploss)
{
    if(stoploss > 0) {
        stoploss = Bid+stoploss*point;
        if(shs) {
            hedge_sell_sl = stoploss;
        }
    }

    if(lots > MaxLot1 && run && magic == Magic1)
        lots = MaxLot1;
    
    else if(lots > MaxLot2 && run && magic == Magic2)
        lots = MaxLot2;

    int sell = OrderSend(Symbol(), OP_SELL, lots, Bid, 0, stoploss, 0, Comment, magic, 0, clrNONE);
    
    if(sell < 0) {
        Print("Sell failed with error #", GetLastError());
    } else {
        Print("Sell placed successfully ", magic);
    }
}

//--------------------------------------------------------------------------------+
// OpenBuy(Lots, Magic, StopLoss)
// -------------------------------------------------------------------------------+
// Open Posisi BUY
//--------------------------------------------------------------------------------+
void OpenBuy(double lots, int magic, double stoploss)
{
    if(stoploss > 0) {
        stoploss = Ask-stoploss*point;
        if(shb) {
            hedge_buy_sl = stoploss;
        }
    }

    if(lots > MaxLot1 && run && magic == Magic1)
        lots = MaxLot1;

    else if(lots > MaxLot2 && run && magic == Magic2)
        lots = MaxLot2;

    int buy = OrderSend(Symbol(), OP_BUY, lots, Ask, 0, stoploss, 0, Comment, magic, clrNONE);

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

    return DoubleToString(response, 2);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    RemoveButtons();
    ObjectsDeleteAll(0, OBJ_VLINE);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &action)
{
    ResetLastError();
    if (id == CHARTEVENT_OBJECT_CLICK) {
        if (ObjectType (action) == OBJ_BUTTON) {
            ButtonPressed(0, action);
        }
    }
}