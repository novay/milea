/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_OsMA_Params_H1 : IndiOsMAParams {
  Indi_OsMA_Params_H1() : IndiOsMAParams(indi_osma_defaults, PERIOD_H1) {
    applied_price = (ENUM_APPLIED_PRICE)1;
    ema_fast_period = 10;
    ema_slow_period = 30;
    signal_period = 12;
    shift = 0;
  }
} indi_osma_h1;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OsMA_Params_H1 : StgParams {
  // Struct constructor.
  Stg_OsMA_Params_H1() : StgParams(stg_osma_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_osma_h1;
