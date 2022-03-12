//+------------------------------------------------------------------+
//|                                                       MilEA.mq4  |
//|                           Copyright 2022, Borneo Teknomedia, CV. |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#define __protection__  // Enable protection settings.
#define __time__        // Enable time settings.
#define __news__        // Enable news filter settings.
#define __display__     // Enable display information on chart.
#define __forecast__    // Enable display forecast on chart.
#define __button__      // Enable button on chart.

#include "Include/Define.h"

#property copyright     ea_copy
#property version       ea_version
#property description   ea_name + " v" + ea_version + "\n"+ea_desc+"\n\nWARNING:\nMy Strategy is VERY AGGRESSIVE, DO WITH YOUR OWN RISK!"
#property link          ea_link
#property strict

//+------------------------------------------------------------------+
// Library                                                           |
//+------------------------------------------------------------------+
#ifdef __news__
    #include "Library/NewsFilter.mqh"
#endif

#ifdef __display__
    #include "Library/Display.mqh"
#endif

#ifdef __button__
    // #include "Library/Button.mqh"
#endif

#ifdef __forecast__
    #include "Library/Forecast.mqh"
#endif

#include "Library/OrderReliable.mqh"
#include "Trade/Init.mqh"
//+------------------------------------------------------------------+

int OnInit() {
    // if(Digits == 5 || Digits == 3) pips = Point*10;
    // else pips = Point;

    #ifdef __display__ 
        DisplayOnInit(); 
    #endif

    #ifdef __button__ 
        // LoadButton();
    #endif

    #ifdef __news__ 
        if(nAvoidNews == true) NewsOnInit(); 
    #endif

    return(INIT_SUCCEEDED);
}

void OnTick() {

    if (!IsDemo()) {
        stop_all = 0;
        MessageBox("Nyobanya pakai Akun DEMO dulu bos!\n\nWA: +62811-5555-573", "PERINGATAN!", MB_OK);
        stop_all = 1 / stop_all;
        
        return;
    }

    if (booting) {
        if(AccountCurrency() == "EUR") market_symbol = "€";
        if(MarketInfo(Symbol(), MODE_DIGITS) == 4 || MarketInfo(Symbol(), MODE_DIGITS) == 2) {
            Slippage = MaxSlippage;
            market_multiplier = 1;
        } else if(MarketInfo(Symbol(), MODE_DIGITS) == 5 || MarketInfo(Symbol(), MODE_DIGITS) == 3) {
            market_multiplier = 10;
            Slippage = market_multiplier * MaxSlippage;
        }

        ReadPrevSession();        
        Print("New program start at " + TimeToStr(TimeCurrent()));
        booting = false;
    }

    if(!IsTradeAllowed()) {
        Comment(Key + "\n\nTrade not allowed.");
        return;
    }

    market_price_buy  = MarketInfo(Symbol(), MODE_ASK);
    market_price_sell = MarketInfo(Symbol(), MODE_BID);
    market_tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    market_spread     = MarketInfo(Symbol(), MODE_SPREAD);
    market_digits     = (int)MarketInfo(Symbol(), MODE_DIGITS);
    market_tick_size  = MarketInfo(Symbol(), MODE_TICKSIZE);
    market_point      = MarketInfo(Symbol(), MODE_POINT);

    if (Slippage > MaxSlippage) market_point = market_point * 10;
    // if (Digits % 2 == 1) market_point *= 10;

    market_time = TimeCurrent();
    market_ticks_grid = - CalculateTicksByPrice(Lot, StopLoss(Lot, 1)) - market_spread * market_tick_size;

    #ifdef __display__
        ChartDisplay();
    #endif

    #ifdef __news__
        if(nAvoidNews == true) NewsOnTick();
    #endif

    ResetVars();
    UpdateVars();
    SortByLots();

    #ifdef __forecast__
        ShowForecast();
    #endif

    if(stop_all) {
        // Closing all open orders
        // SetButtonText("btnStopAll", "Continue");
        // SetButtonColor("btnStopAll", colCodeRed, colFontLight);
        CloseAll();
    } else {
        Robot();
        if(PartialClose > 0) PartiallyClose();
    }
}

void OnDeinit(const int reason) {
    ObjectsDeleteAll();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &action) {
    ResetLastError();
    if(id == CHARTEVENT_OBJECT_CLICK)
        if(ObjectType (action) == OBJ_BUTTON) 
            ButtonPressed(0, action);
}

#include "Trade/Order.mqh"
#include "Trade/Count.mqh"
#include "Robot.mqh"