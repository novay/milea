sinput string Indicators_Settings;        //*****    Settings of indicators   *****
extern bool Conjunct_Idx = true;         //All selected indicators will be applied together

#include "ATR/ATR.h"
#include "BB/BB.h"
#include "RSI/RSI.h"
#include "Stochastic/Stochastic.h"

bool Indicators_Buy() {
   bool BB_ret, STO_ret, RSI_ret;
   if (Conjunct_Idx) {
      BB_ret = true;
      STO_ret = true;
      RSI_ret = true;
      if (Use_BB) BB_ret = BB_Buy();
      if (Use_Stoch) STO_ret = STO_Buy();
      if (Use_RSI) RSI_ret = RSI_Buy();
      if (BB_ret && STO_ret && RSI_ret) return (true);
      return(false);
   } else {
      if (Use_BB) BB_ret = BB_Buy();
      else BB_ret = false;
      if (Use_Stoch) STO_ret = STO_Buy();
      else STO_ret = false;
      if (Use_RSI) RSI_ret = RSI_Buy();
      else RSI_ret = false;
      if (BB_ret || STO_ret || RSI_ret) return (true);
      return(false);
   }
   return (false);
}

bool Indicators_Sell() {
   bool BB_ret, STO_ret, RSI_ret;
   if (Conjunct_Idx) {
      BB_ret = true;
      STO_ret = true;
      RSI_ret = true;
      if (Use_BB) BB_ret = BB_Sell();
      if (Use_Stoch) STO_ret = STO_Sell();
      if (Use_RSI) RSI_ret = RSI_Sell();
      if (BB_ret && STO_ret && RSI_ret) return (true);
      return(false);
   } else  {
      if (Use_BB) BB_ret = BB_Sell();
      else BB_ret = false;
      if (Use_Stoch) STO_ret = STO_Sell();
      else STO_ret = false;
      if (Use_RSI) RSI_ret = RSI_Sell();
      else RSI_ret = false;
      if (BB_ret || STO_ret || RSI_ret) return (true);
      return(false);
   }
   return (false);
}