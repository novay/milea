int color_light      = clrGray;
int color_white      = clrWhite;
int color_success    = clrGreen;
int color_warning    = clrGold;
int color_danger     = clrRed;
int color_primary    = clrBlue;

int forecast_panel = color_light;
int forecast_text = color_light;

void ShowForecast() 
{
   if(total_buy_profit + total_sell_profit > 0) {
      forecast_text = color_success;
   } else {
      forecast_text = color_danger;
   }

   // XAUUSD
   // Spread: 6.3
   // Balance: 
   // Equity: 

   // P/L Buy  0.00 $
   // P/L Sell    0.00 $
   // P/L Sym     0.00 $

   // P/L 0.00 $

   Write("FORECAST_SYMBOL", ChartSymbol(0), 5, 22, "Arial", 14, forecast_text);
   
   if(market_spread > Spread) {
      Write("FORECAST_SPREAD", "Spread: " + DoubleToString(market_spread / 10, 1), 5, 42, "Arial", 10, color_danger);
   } else {
      Write("FORECAST_SPREAD", "Spread: " + DoubleToString(market_spread / 10, 1), 5, 42, "Arial", 10, forecast_panel);
   }

   Write("FORECAST_BALANCE", "Balance: " + DoubleToString(AccountBalance(), 2) + " " + market_symbol, 5, 74, "Arial", 10, forecast_panel);
   Write("FORECAST_EQUITY", "Equity: " + DoubleToString(AccountEquity(), 2) + " " + market_symbol, 5, 90, "Arial", 10, forecast_panel);

   Write("FORECAST_PL_SYM", "P/L Sym. " + DoubleToString(total_buy_profit + total_sell_profit, 2) + " " + market_symbol, 5, 122, "Arial", 14, forecast_text);

   if(total_buy_profit < 0) {
      Write("FORECAST_PL_BUY", "P/L Buy: " + DoubleToStr(total_buy_profit, 2) + " " + market_symbol, 5, 144, "Arial", 10, color_danger);
   } else {
      Write("FORECAST_PL_BUY", "P/L Buy: " + DoubleToStr(total_buy_profit, 2) + " " + market_symbol, 5, 144, "Arial", 10, color_success);
   }

   if(total_sell_profit < 0) {
      Write("FORECAST_PL_SELL", "P/L sell: " + DoubleToStr(total_sell_profit, 2) + " " + market_symbol, 5, 160, "Arial", 10, color_danger);
   } else {
      Write("FORECAST_PL_SELL", "P/L sell: " + DoubleToStr(total_sell_profit, 2) + " " + market_symbol, 5, 160, "Arial", 10, color_success);
   }

   double accountPL = AccountProfit();
   if(accountPL < 0) {
      Write("FORECAST_PL", "Unrealize P/L " + DoubleToString(accountPL, 2) + " " + market_symbol, 5, 176, "Arial", 10, color_danger);
   } else {
      Write("FORECAST_PL", "Unrealize P/L " + DoubleToString(accountPL, 2) + " " + market_symbol, 5, 176, "Arial", 10, color_success);
   }
}

void Write(string name, string s, int x, int y, string font, int size, color c) {
   if(ObjectFind(name) == -1) {
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, 1);
   }
   ObjectSetText(name, s, size, font, c);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
}