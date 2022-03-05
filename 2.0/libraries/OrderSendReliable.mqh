// OrderReliable:
int slippage                  = 0;     // is fix; depending on chart: 2 or 20
int retry_attempts            = 10;
double sleep_time             = 4.0;   // in seconds
int sleep_maximum             = 25;    // in seconds
string OrderReliable_Fname    = "OrderReliable fname unset";
static int _OR_err            = 0;
string OrderReliableVersion   = "V1_1_1";

//=============================================================================
//                    OrderSendReliable()
//
// This is intended to be a drop-in replacement for OrderSend() which,
// one hopes, is more resistant to various forms of errors prevalent
// with MetaTrader.
//
// RETURN VALUE:
//
// Ticket number or -1 under some error conditions.  Check
// final error returned by Metatrader with OrderReliableLastErr().
// This will reset the value from GetLastError(), so in that sense it cannot
// be a total drop-in replacement due to Metatrader flaw.
//
// FEATURES:
//
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Automatic normalization of Digits
//
//     * Automatically makes sure that stop levels are more than
//       the minimum stop distance, as given by the server. If they
//       are too close, they are adjusted.
//
//     * Automatically converts stop orders to market orders
//       when the stop orders are rejected by the server for
//       being to close to market.  NOTE: This intentionally
//       applies only to OP_BUYSTOP and OP_SELLSTOP,
//       OP_BUYLIMIT and OP_SELLLIMIT are not converted to market
//       orders and so for prices which are too close to current
//       this function is likely to loop a few times and return
//       with the "invalid stops" error message.
//       Note, the commentary in previous versions erroneously said
//       that limit orders would be converted.  Note also
//       that entering a BUYSTOP or SELLSTOP new order is distinct
//       from setting a stoploss on an outstanding order; use
//       OrderModifyReliable() for that.
//
//     * Displays various error messages on the log for debugging.
//
//
// Matt Kennel, 2006-05-28 and following
//
//=============================================================================
// #001: eliminate all warnings:
//    change internal declaration of slippage to mySlippage in all OrderSendReliable stuff
//    change internal declaration of magic to myMagic
int OrderSendReliable(string symbol, int cmd, double volume, double price,
                      int mySlippage, double stoploss, double takeprofit,
                      string comment, int myMagic, datetime expiration = 0,
                      color arrow_color = CLR_NONE) {

// ------------------------------------------------
// Check basic conditions see if trade is possible.
// ------------------------------------------------
   OrderReliable_Fname = "OrderSendReliable";
   OrderReliablePrint(" attempted " + OrderReliable_CommandString(cmd) + " " + (string)volume +
                      " lots @" + (string)price + " sl:" + (string)stoploss + " tp:" + (string)takeprofit);

   if(IsStopped()) {
      OrderReliablePrint("error: IsStopped() == true");
      _OR_err = ERR_COMMON_ERROR;
      return(-1);
   }

   int cnt = 0;
   while(!IsTradeAllowed() && cnt < retry_attempts) {
      OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
      cnt++;
   }

   if(!IsTradeAllowed()) {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err = ERR_TRADE_CONTEXT_BUSY;

      return(-1);
   }

//#004 new setting: MaxSpread; trades only, if spread <= max spread:
   int spread = 0;
   cnt = 0;
// wait a bit if spread is too high
   while(cnt < retry_attempts) {
      spread = (int)MarketInfo(symbol, MODE_SPREAD);
      if(spread > MaxSpread)
         OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
      else
         cnt = retry_attempts; // spread is ok; go on trading
      cnt++;
   }
   if(spread > MaxSpread) {
      OrderReliablePrint(" no operation because spread: " + (string)spread + " > MaxSpread: " + (string)MaxSpread);
      return(-1);
   }
//#004 end

// Normalize all price / stoploss / takeprofit to the proper # of digits.
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   if(digits > 0) {
      price = NormalizeDouble(price, digits);
      stoploss = NormalizeDouble(stoploss, digits);
      takeprofit = NormalizeDouble(takeprofit, digits);
   }

   if(stoploss != 0)
      OrderReliable_EnsureValidStop(symbol, price, stoploss);

   int err = GetLastError(); // clear the global variable.
   err = 0;
   _OR_err = 0;
   bool exit_loop = false;
   bool limit_to_market = false;
   bool retVal = false;
// limit/stop order.
   int ticket = -1;

   if((cmd == OP_BUYSTOP) || (cmd == OP_SELLSTOP) || (cmd == OP_BUYLIMIT) || (cmd == OP_SELLLIMIT)) {
      cnt = 0;
      while(!exit_loop) {
         if(IsTradeAllowed()) {
            ticket = OrderSend(symbol, cmd, volume, price, mySlippage, stoploss,
                               takeprofit, comment, myMagic, expiration, arrow_color);
            err = GetLastError();
            _OR_err = err;
         } else {
            cnt++;
         }

         switch(err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         // retryable errors
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++;
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue;   // we can apparently retry immediately according to MT docs.

         case ERR_INVALID_STOPS: {
            double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
            if(cmd == OP_BUYSTOP) {
               // If we are too close to put in a limit/stop order so go to market.
               if(MathAbs(MarketInfo(symbol, MODE_ASK) - price) <= servers_min_stop)
                  limit_to_market = true;

            } else if(cmd == OP_SELLSTOP) {
               // If we are too close to put in a limit/stop order so go to market.
               if(MathAbs(MarketInfo(symbol, MODE_BID) - price) <= servers_min_stop)
                  limit_to_market = true;
            }
            exit_loop = true;
            break;
         }
         default:
            // an apparently serious error.
            exit_loop = true;
            break;

         }  // end switch

         if(cnt > retry_attempts)
            exit_loop = true;

         if(exit_loop) {
            if(err != ERR_NO_ERROR) {
               OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err));
            }
            if(cnt > retry_attempts) {
               OrderReliablePrint("retry attempts maxed at " + (string)retry_attempts);
            }
         }

         if(!exit_loop) {
            OrderReliablePrint("retryable error (" + (string)cnt + "/" + (string)retry_attempts +
                               "): " + OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
            RefreshRates();
         }
      }

      // We have now exited from loop.
      if(err == ERR_NO_ERROR) {
         OrderReliablePrint("apparently successful OP_BUYSTOP or OP_SELLSTOP order placed, details follow.");
         // #001: eliminate all warnings:
         retVal = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS!
      }
      if(!limit_to_market) {
         OrderReliablePrint("failed to execute stop or limit order after " + (string)cnt + " retries");
         OrderReliablePrint("failed trade: " + OrderReliable_CommandString(cmd) + " " + symbol +
                            "@" + (string)price + " tp@" + (string)takeprofit + " sl@" + (string)stoploss);
         OrderReliablePrint("last error: " + OrderReliableErrTxt(err));
         return(-1);
      }
   }  // end

   if(limit_to_market) {
      OrderReliablePrint("going from limit order to market order because market is too close.");
      if((cmd == OP_BUYSTOP) || (cmd == OP_BUYLIMIT)) {
         cmd = OP_BUY;
         price = MarketInfo(symbol, MODE_ASK);
      } else if((cmd == OP_SELLSTOP) || (cmd == OP_SELLLIMIT)) {
         cmd = OP_SELL;
         price = MarketInfo(symbol, MODE_BID);
      }
   }

// we now have a market order.
   err = GetLastError(); // so we clear the global variable.
   err = 0;
   _OR_err = 0;
   ticket = -1;

   if((cmd == OP_BUY) || (cmd == OP_SELL)) {
      cnt = 0;
      while(!exit_loop) {
         if(IsTradeAllowed()) {
            ticket = OrderSend(symbol, cmd, volume, price, mySlippage,
                               stoploss, takeprofit, comment, myMagic,
                               expiration, arrow_color);
            err = GetLastError();
            _OR_err = err;
         } else {
            cnt++;
         }
         switch(err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue; // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;

         }  // end switch

         if(cnt > retry_attempts)
            exit_loop = true;

         if(!exit_loop) {
            OrderReliablePrint("retryable error (" + (string)cnt + "/" +
                               (string)retry_attempts + "): " + OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
            RefreshRates();
         }

         if(exit_loop) {
            if(err != ERR_NO_ERROR) {
               OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err));
            }
            if(cnt > retry_attempts) {
               OrderReliablePrint("retry attempts maxed at " + (string)retry_attempts);
            }
         }
      }

      // we have now exited from loop.
      if(err == ERR_NO_ERROR) {
         //#004 new setting: MaxSpread; add spread info for this position
         OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed(spread: " + (string)spread + "), details follow.");
         // #001: eliminate all warnings:
         retVal = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS!
      }
      OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after " + (string)cnt + " retries");
      OrderReliablePrint("failed trade: " + OrderReliable_CommandString(cmd) + " " + symbol +
                         "@" + (string)price + " tp@" + (string)takeprofit + " sl@" + (string)stoploss);
      OrderReliablePrint("last error: " + OrderReliableErrTxt(err));
      return(-1);
   }
// #001: eliminate all warnings:
   return(-1);
}

//=============================================================================
//                    OrderCloseReliable()
//
// This is intended to be a drop-in replacement for OrderClose() which,
// one hopes, is more resistant to various forms of errors prevalent
// with MetaTrader.
//
// RETURN VALUE:
//
//    TRUE if successful, FALSE otherwise
//
//
// FEATURES:
//
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//
// Derk Wehler, ashwoods155@yahoo.com     2006-07-19
//
//=============================================================================
bool OrderCloseReliable(int ticket, double lots, double price,
                        int mySlippage, color arrow_color = CLR_NONE) {
   int nOrderType;
   string strSymbol;
   OrderReliable_Fname = "OrderCloseReliable";

   OrderReliablePrint(" attempted close of #" + (string)ticket + " price:" + (string)price +
                      " lots:" + (string)lots + " slippage:" + (string)mySlippage);

// collect details of order so that we can use GetMarketInfo later if needed
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) {
      _OR_err = GetLastError();
      OrderReliablePrint("error: " + ErrorDescription(_OR_err));
      return(false);
   } else {
      nOrderType = OrderType();
      strSymbol = OrderSymbol();
   }

   if(nOrderType != OP_BUY && nOrderType != OP_SELL) {
      _OR_err = ERR_INVALID_TICKET;
      OrderReliablePrint("error: trying to close ticket #" + (string)ticket + ", which is " + OrderReliable_CommandString(nOrderType) + ", not OP_BUY or OP_SELL");
      return(false);
   }

   if(IsStopped()) {
      OrderReliablePrint("error: IsStopped() == true");
      return(false);
   }

   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   _OR_err = 0;
   bool exit_loop = false;
   cnt = 0;
   bool result = false;

   while(!exit_loop) {
      if(IsTradeAllowed()) {
         result = OrderClose(ticket, lots, price, mySlippage, arrow_color);
         err = GetLastError();
         _OR_err = err;
      } else {
         cnt++;
      }

      if(result == true) exit_loop = true;

      switch(err) {
      case ERR_NO_ERROR:
         exit_loop = true;
         break;

      case ERR_SERVER_BUSY:
      case ERR_NO_CONNECTION:
      case ERR_INVALID_PRICE:
      case ERR_OFF_QUOTES:
      case ERR_BROKER_BUSY:
      case ERR_TRADE_CONTEXT_BUSY:
      case ERR_TRADE_TIMEOUT:      // for modify this is a retryable error, I hope.
         cnt++;    // a retryable error
         break;

      case ERR_PRICE_CHANGED:
      case ERR_REQUOTE:
         continue;    // we can apparently retry immediately according to MT docs.

      default:
         // an apparently serious, unretryable error.
         exit_loop = true;
         break;

      }  // end switch

      if(cnt > retry_attempts) exit_loop = true;

      if(!exit_loop) {
         OrderReliablePrint("retryable error (" + (string)cnt + "/" + (string)retry_attempts +
                            "): " + OrderReliableErrTxt(err));
         OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
         // Added by Paul Hampton-Smith to ensure that price is updated for each retry
         if(nOrderType == OP_BUY)  price = NormalizeDouble(MarketInfo(strSymbol, MODE_BID), (int)MarketInfo(strSymbol, MODE_DIGITS));
         if(nOrderType == OP_SELL) price = NormalizeDouble(MarketInfo(strSymbol, MODE_ASK), (int)MarketInfo(strSymbol, MODE_DIGITS));
      }

      if(exit_loop) {
         if((err != ERR_NO_ERROR) && (err != ERR_NO_RESULT))
            OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err));

         if(cnt > retry_attempts)
            OrderReliablePrint("retry attempts maxed at " + (string)retry_attempts);
      }
   }

// we have now exited from loop.
   if((result == true) || (err == ERR_NO_ERROR)) {
      OrderReliablePrint("apparently successful close order, updated trade details follow.");
      // #001: eliminate all warnings:
      bool retVal = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
      OrderPrint();
      return(true); // SUCCESS!
   }

   OrderReliablePrint("failed to execute close after " + (string)cnt + " retries");
   OrderReliablePrint("failed close: Ticket #" + (string)ticket + ", Price: " +
                      (string)price + ", Slippage: " + (string)mySlippage);
   OrderReliablePrint("last error: " + OrderReliableErrTxt(err));

   return(false);
}

//=============================================================================
//                    OrderSendReliableMKT()
//
// This is intended to be an alternative for OrderSendReliable() which
// will update market-orders in the retry loop with the current Bid or Ask.
// Hence with market orders there is a greater likelihood that the trade will
// be executed versus OrderSendReliable(), and a greater likelihood it will
// be executed at a price worse than the entry price due to price movement.
//
// RETURN VALUE:
//
// Ticket number or -1 under some error conditions.  Check
// final error returned by Metatrader with OrderReliableLastErr().
// This will reset the value from GetLastError(), so in that sense it cannot
// be a total drop-in replacement due to Metatrader flaw.
//
// FEATURES:
//
//     * Most features of OrderSendReliable() but for market orders only.
//       Command must be OP_BUY or OP_SELL, and specify Bid or Ask at
//       the time of the call.
//
//     * If price moves in an unfavorable direction during the loop,
//       e.g. from requotes, then the slippage variable it uses in
//       the real attempt to the server will be decremented from the passed
//       value by that amount, down to a minimum of zero.   If the current
//       price is too far from the entry value minus slippage then it
//       will not attempt an order, and it will signal, hedgely,
//       an ERR_INVALID_PRICE (displayed to log as usual) and will continue
//       to loop the usual number of times.
//
//     * Displays various error messages on the log for debugging.
//
//
// Matt Kennel, 2006-08-16
//
//=============================================================================
int OrderSendReliableMKT(string symbol, int cmd, double volume, double price,
                         int mySlippage, double stoploss, double takeprofit,
                         string comment, int myMagic, datetime expiration = 0,
                         color arrow_color = CLR_NONE) {

// ------------------------------------------------
// Check basic conditions see if trade is possible.
// ------------------------------------------------
   OrderReliable_Fname = "OrderSendReliableMKT";
   OrderReliablePrint(" attempted " + OrderReliable_CommandString(cmd) + " " + (string)volume +
                      " lots @" + (string)price + " sl:" + (string)stoploss + " tp:" + (string)takeprofit);

   if((cmd != OP_BUY) && (cmd != OP_SELL)) {
      OrderReliablePrint("Improper non market-order command passed.  Nothing done.");
      _OR_err = ERR_MALFUNCTIONAL_TRADE;
      return(-1);
   }

//if (!IsConnected())
//{
// OrderReliablePrint("error: IsConnected() == false");
// _OR_err = ERR_NO_CONNECTION;
// return(-1);
//}

   if(IsStopped()) {
      OrderReliablePrint("error: IsStopped() == true");
      _OR_err = ERR_COMMON_ERROR;
      return(-1);
   }

   int cnt = 0;
   while(!IsTradeAllowed() && cnt < retry_attempts) {
      OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
      cnt++;
   }

   if(!IsTradeAllowed()) {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err = ERR_TRADE_CONTEXT_BUSY;

      return(-1);
   }

// Normalize all price / stoploss / takeprofit to the proper # of digits.
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   if(digits > 0) {
      price = NormalizeDouble(price, digits);
      stoploss = NormalizeDouble(stoploss, digits);
      takeprofit = NormalizeDouble(takeprofit, digits);
   }

   if(stoploss != 0)
      OrderReliable_EnsureValidStop(symbol, price, stoploss);

   int err = GetLastError(); // clear the global variable.
   err = 0;
   _OR_err = 0;
   bool exit_loop = false;

// limit/stop order.
   int ticket = -1;

// we now have a market order.
   err = GetLastError(); // so we clear the global variable.
   err = 0;
   _OR_err = 0;
   ticket = -1;

   if((cmd == OP_BUY) || (cmd == OP_SELL)) {
      cnt = 0;
      while(!exit_loop) {
         if(IsTradeAllowed()) {
            double pnow = price;
            int slippagenow = mySlippage;
            if(cmd == OP_BUY) {
               // modification by Paul Hampton-Smith to replace RefreshRates()
               pnow = NormalizeDouble(MarketInfo(symbol, MODE_ASK), (int)MarketInfo(symbol, MODE_DIGITS)); // we are buying at Ask
               if(pnow > price) {
                  slippagenow = mySlippage - (int)((pnow - price) / MarketInfo(symbol, MODE_POINT));
               }
            } else if(cmd == OP_SELL) {
               // modification by Paul Hampton-Smith to replace RefreshRates()
               pnow = NormalizeDouble(MarketInfo(symbol, MODE_BID), (int)MarketInfo(symbol, MODE_DIGITS)); // we are buying at Ask
               if(pnow < price) {
                  // moved in an unfavorable direction
                  slippagenow = mySlippage - (int)((price - pnow) / MarketInfo(symbol, MODE_POINT));
               }
            }
            if(slippagenow > mySlippage) slippagenow = mySlippage;
            if(slippagenow >= 0) {

               ticket = OrderSend(symbol, cmd, volume, pnow, slippagenow,
                                  stoploss, takeprofit, comment, myMagic,
                                  expiration, arrow_color);
               err = GetLastError();
               _OR_err = err;
            } else {
               // too far away, hedgely signal ERR_INVALID_PRICE, which
               // will result in a sleep and a retry.
               err = ERR_INVALID_PRICE;
               _OR_err = err;
            }
         } else {
            cnt++;
         }
         switch(err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            // Paul Hampton-Smith removed RefreshRates() here and used MarketInfo() above instead
            continue; // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;

         }  // end switch

         if(cnt > retry_attempts)
            exit_loop = true;

         if(!exit_loop) {
            OrderReliablePrint("retryable error (" + (string)cnt + "/" +
                               (string)retry_attempts + "): " + OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
         }

         if(exit_loop) {
            if(err != ERR_NO_ERROR) {
               OrderReliablePrint("non-retryable error: " + OrderReliableErrTxt(err));
            }
            if(cnt > retry_attempts) {
               OrderReliablePrint("retry attempts maxed at " + (string)retry_attempts);
            }
         }
      }

      // we have now exited from loop.
      if(err == ERR_NO_ERROR) {
         OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed, details follow.");
         // #001: eliminate all warnings:
         bool retVal = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS!
      }
      OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after " + (string)cnt + " retries");
      OrderReliablePrint("failed trade: " + OrderReliable_CommandString(cmd) + " " + symbol +
                         "@" + (string)price + " tp@" + (string)takeprofit + " sl@" + (string)stoploss);
      OrderReliablePrint("last error: " + OrderReliableErrTxt(err));
      return(-1);
   }
// #001: eliminate all warnings:
   return(-1);
}

//+------------------------------------------------------------------+
//| OrderReliable_CommandString                                      |
//+------------------------------------------------------------------+
string OrderReliable_CommandString(int cmd) {
   if(cmd == OP_BUY)
      return("OP_BUY");

   if(cmd == OP_SELL)
      return("OP_SELL");

   if(cmd == OP_BUYSTOP)
      return("OP_BUYSTOP");

   if(cmd == OP_SELLSTOP)
      return("OP_SELLSTOP");

   if(cmd == OP_BUYLIMIT)
      return("OP_BUYLIMIT");

   if(cmd == OP_SELLLIMIT)
      return("OP_SELLLIMIT");

   return("(CMD==" + (string)cmd + ")");
}

//=============================================================================
//
//                 OrderReliable_SleepRandomTime()
//
// This sleeps a random amount of time defined by an exponential
// probability distribution. The mean time, in Seconds is given
// in 'mean_time'.
//
// This is the back-off strategy used by Ethernet.  This will
// quantize in tenths of seconds, so don't call this with a too
// small a number.  This returns immediately if we are backtesting
// and does not sleep.
//
// Matt Kennel mbkennelfx@gmail.com.
//
//=============================================================================
void OrderReliable_SleepRandomTime(double mean_time, int max_time) {
   if(IsTesting())
      return;    // return immediately if backtesting.

   double tenths = MathCeil(mean_time / 0.1);
   if(tenths <= 0)
      return;

   int maxtenths = max_time * 10;
   double p = 1.0 - 1.0 / tenths;

   Sleep(100);    // one tenth of a second PREVIOUS VERSIONS WERE STUPID HERE.

   for(int i = 0; i < maxtenths; i++) {
      if(MathRand() > p * 32768)
         break;

      // MathRand() returns in 0..32767
      Sleep(100);
   }
}

//=============================================================================
//
//                 OrderReliable_EnsureValidStop()
//
//    Adjust stop loss so that it is legal.
//
//
//=============================================================================
void OrderReliable_EnsureValidStop(string symbol, double price, double &sl) {
// Return if no S/L
   if(sl == 0) return;

   double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
   if(MathAbs(price - sl) <= servers_min_stop) {
      // we have to adjust the stop.
      if(price > sl)
         sl = price - servers_min_stop; // we are long

      else if(price < sl)
         sl = price + servers_min_stop; // we are short

      else
         OrderReliablePrint("EnsureValidStop: error, passed in price == sl, cannot adjust");

      sl = NormalizeDouble(sl, (int)MarketInfo(symbol, MODE_DIGITS));
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderReliableLastErr() {
   return (_OR_err);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string OrderReliableErrTxt(int err) {
   return ("" + (string)err + ":" + ErrorDescription(err));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderReliablePrint(string s) {
// Print to log prepended with stuff;
   if(!(IsTesting() || IsOptimization())) Print(OrderReliable_Fname + " " + OrderReliableVersion + ":" + s);
}
//+------------------------------------------------------------------+
