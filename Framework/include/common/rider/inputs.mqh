//+------------------------------------------------------------------+
//|                                                         inputs.h |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Includes.
#include "..\enum.h"

//+------------------------------------------------------------------+
//| Inputs.
//+------------------------------------------------------------------+

// Includes strategies.
#ifdef __MQL4__
    input static string __Strategies_Active__ = "-- Active strategies --";  // >>> ACTIVE STRATEGIES <<<
#else
    input group "Active strategy"
#endif

input ENUM_STRATEGY Strategy_M1 = STRAT_NONE;      // Strategy on M1
input ENUM_STRATEGY Strategy_M5 = STRAT_NONE;      // Strategy on M5
input ENUM_STRATEGY Strategy_M15 = STRAT_NONE;     // Strategy on M15
input ENUM_STRATEGY Strategy_M30 = STRAT_PATTERN;  // Strategy on M30
input ENUM_STRATEGY Strategy_H1 = STRAT_CHAIKIN;   // Strategy on H1
input ENUM_STRATEGY Strategy_H2 = STRAT_FORCE;     // Strategy on H2
input ENUM_STRATEGY Strategy_H3 = STRAT_DEMARKER;  // Strategy on H3
input ENUM_STRATEGY Strategy_H4 = STRAT_ASI;       // Strategy on H4
input ENUM_STRATEGY Strategy_H6 = STRAT_PIVOT;     // Strategy on H6
input ENUM_STRATEGY Strategy_H8 = STRAT_OBV;       // Strategy on H8

#ifdef __MQL4__
input static string __Strategies_Stops__ = "-- Strategies' stops --";  // >>> STRATEGIES' STOPS <<<
#else
input group "Strategies' stops"
#endif
input ENUM_STRATEGY EA_Stops_Strat = STRAT_ENVELOPES;  // Stop loss strategy
input ENUM_TIMEFRAMES EA_Stops_Tf = PERIOD_H12;        // Stop loss timeframe

#ifdef __MQL4__
input string __EA_Tasks__ = "-- EA's tasks --";  // >>> EA's TASKS <<<
#else
input group "EA's tasks"
#endif
input ENUM_EA_ADV_COND EA_Task1_If = EA_ADV_COND_TRADE_EQUITY_GT_05PC;             // 1: Task's condition
input ENUM_EA_ADV_ACTION EA_Task1_Then = EA_ADV_ACTION_ORDERS_CLOSE_IN_TREND;      // 1: Task's action
input ENUM_EA_ADV_COND EA_Task2_If = EA_ADV_COND_TRADE_EQUITY_GT_05PC;             // 2: Task's condition
input ENUM_EA_ADV_ACTION EA_Task2_Then = EA_ADV_ACTION_ORDERS_CLOSE_SIDE_IN_LOSS;  // 2: Task's action
input ENUM_EA_ADV_COND EA_Task3_If = EA_ADV_COND_TRADE_EQUITY_LT_05PC;             // 3: Task's condition
input ENUM_EA_ADV_ACTION EA_Task3_Then = EA_ADV_ACTION_ORDERS_CLOSE_IN_PROFIT;     // 3: Task's action

// input static string __EA_Order_Params__ = "-- EA's order params --";  // >>> EA's ORDERS <<<

#ifdef __MQL4__
input string __Signal_Filters__ = "-- Signal filters --";  // >>> SIGNAL FILTERS <<<
#else
input group "Signal filters"
#endif
input int EA_SignalOpenFilterMethod = 46;   // Open (1=!BarO,2=Trend,4=PP,8=OppO,16=Peak,32=BetterO,64=!Eq<1%)
input int EA_SignalCloseFilterMethod = 40;  // Close (1=!BarO,2=!Trend,4=!PP,8=O>H,16=Peak,32=BetterO,64=Eq>1%)
input int EA_SignalOpenFilterTime = 3;      // Time (1=CHGO,2=FR,4=HK,8=LON,16=NY,32=SY,64=TYJ,128=WGN)
int EA_SignalOpenStrategyFilter = 0;        // Strategy (0-EachSignal,1=FirstOnly,2=HourlyConfirmed)
input int EA_TickFilterMethod = 32;  // Tick (1=PerMin,2=Peaks,4=PeaksMins,8=Unique,16=MiddleBar,32=Open,64=10thBar)