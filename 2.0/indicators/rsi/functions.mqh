bool RSIBuy() {
   double rsi_value = iRSI(Symbol(), RSITimeFrame, RSIPeriod, PRICE_CLOSE, RSIShift);
   if (!RSIInvert) {
      if (rsi_value < RSILower) return(true);
      return(false);
   } else {
      if (rsi_value > RSILower && rsi_value < RSIUpper) return(true);
      return(false);
   }
}

bool RSISell() {
   double rsi_value = iRSI(Symbol(), RSITimeFrame, RSIPeriod, PRICE_CLOSE, RSIShift);
   if (!RSIInvert) {
      if (rsi_value > RSIUpper) return(true);
      return(false);
   } else {
      if (rsi_value > RSILower && rsi_value < RSIUpper) return(true);
      return(false);
   }
}