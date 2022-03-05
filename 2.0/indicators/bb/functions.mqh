bool BBBuy() {
   double bb_lower = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, BBShift);
   double bb_upper = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, BBShift);

   if (!BBInvert) {
      if (BBOption == ASK_BID && Ask < bb_lower) return(true);
      if (BBOption == HIGH_LOW && Low[0] < bb_lower) return(true);
      return(false);
   } else {
      if (BBOption == ASK_BID && Ask > bb_upper) return(true);
      if (BBOption == HIGH_LOW && Low[0] > bb_upper) return(true);
      return(false);
   }
}

bool BBSell() {
   double bb_lower = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, BBShift);
   double bb_upper = iBands(Symbol(), BBTimeFrame, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, BBShift);
   
   if (!BBInvert) {
      if (BBOption == ASK_BID && Bid > bb_upper) return(true);
      if (BBOption == HIGH_LOW && High[0] > bb_upper) return(true);
      return(false);
   } else {
      if (BBOption == ASK_BID && Bid < bb_lower) return(true);
      if (BBOption == HIGH_LOW && High[0] < bb_lower) return(true);
      return(false);
   }
}