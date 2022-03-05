double ATRGridSize() {
   int digits, scale = 10000;
   digits = (int)MarketInfo(Symbol(), MODE_DIGITS);

   if (digits == 3 || digits == 2) scale = 100;
   if (ATREnable) {
      return ((int)round(ATRMultiplier * scale * iATR(Symbol(), ATRTimeFrame, ATRPeriod, ATRShift)));
   } else {
      return Distance;
   }
}