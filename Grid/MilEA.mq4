//+------------------------------------------------------------------+
//|                                                       MilEA.mq4  |
//|                           Copyright 2022, Borneo Teknomedia, CV. |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#define __protection__  // Enable protection settings.
#define __time__        // Enable time settings.
#define __news__        // Enable news filter settings.

#include "Include/Define.h"

#property copyright     ea_copy
#property version       ea_version
#property description   ea_name + " v" + ea_version + "\nMy Personal Expert Advisor\n\nWARNING:\nMy Strategy is VERY AGGRESSIVE, DO WITH YOUR OWN RISK!"
#property link          ea_link
#property strict

//+------------------------------------------------------------------+
// Library                                                           |
//+------------------------------------------------------------------+
#ifdef __news__
    #include "Library/NewsFilter.mqh"
#endif
#include "Library/Display.mqh"
#include "Library/OrderReliable.mqh"

#include "Trade/Init.mqh"

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if(Digits == 5 || Digits == 3) {
        pips = Point*10;
    } else {
        pips = Point;
    }

    DisplayOnInit();
    #ifdef __news__
      if(nAvoidNews == true) {
         NewsOnInit();
      }
    #endif

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
{
    if(!IsDemo()) {
        stop_all = 0;
        MessageBox("Pakai Akun DEMO dulu bos!", "PERINGATAN!", MB_OK);
        stop_all = 1 / stop_all;
        return;
    }

    IsBooting(booting);
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

    if(Slippage > MaxSlippage) market_point = market_point * 10;

    market_time = TimeCurrent();
    market_ticks_grid = - CalculateTicksByPrice(Lot, StopLoss(Lot, 1)) - market_spread * market_tick_size;

    ChartDisplay();
    #ifdef __news__
        if(nAvoidNews == true) {
            NewsOnTick();
        }
    #endif

    // Updating current status:
    InitVars();
    UpdateVars();
    SortByLots();

    if(stop_all) {
        closeAllBuys();
        closeAllSells();
    } else {
        Robot();

        if(PartialClose > 0) {
            ThinOutTheGrid();
        }
    }
}

#include "Trade/Order.mqh"
#include "Trade/Lot.mqh"
#include "Trade/Count.mqh"

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // RemoveButtons();
    // ObjectsDeleteAll(0, OBJ_VLINE);
    ObjectsDeleteAll();
}

//+------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &action)
{
    ResetLastError();
    if (id == CHARTEVENT_OBJECT_CLICK) {
        if (ObjectType (action) == OBJ_BUTTON) {
            ButtonPressed(0, action);
        }
    }
}

#include "Robot.mqh"