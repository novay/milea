bool STOBuy() {
   double sto_value = iStochastic(Symbol(), STOTimeFrame, STOKLine, STODLine, STOSlowing, STOMethod, STOPrice, MODE_SIGNAL, STOShift);
   
   if (!STOInvert) {
      if (sto_value < STOLower) return(true);
      return(false);
   } else {
      if (sto_value > STOLower && sto_value < STOUpper ) return(true);
      return(false);
   }
}

bool STOSell() {
   double sto_value = iStochastic(Symbol(), STOTimeFrame, STOKLine, STODLine, STOSlowing, STOMethod, STOPrice, MODE_SIGNAL, STOShift);

   if (!STOInvert) {
      if (sto_value > STOUpper) return(true);
      return(false);
   } else {
      if (sto_value > STOLower && sto_value < STOUpper ) return(true);
      return(false);
   }
}