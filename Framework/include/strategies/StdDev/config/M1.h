/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_StdDev_Params_M1 : IndiStdDevParams {
  Indi_StdDev_Params_M1() : IndiStdDevParams(indi_stddev_defaults, PERIOD_M1) {
    applied_price = (ENUM_APPLIED_PRICE)0;
    ma_method = (ENUM_MA_METHOD)0;
    ma_period = 14;
    shift = 0;
  }
} indi_stddev_m1;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_StdDev_Params_M1 : StgParams {
  // Struct constructor.
  Stg_StdDev_Params_M1() : StgParams(stg_stddev_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0.0;
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
} stg_stddev_m1;
