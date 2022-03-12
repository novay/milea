//**************************************************
// Indicators settings presets
//**************************************************
sinput string  Indicators_Settings;             // >>> Settings of indicators <<<
extern bool    ApplyIndicators         = true;  // Apply All Indicators

//**************************************************
// Including each indicators functions
//**************************************************
#include "ATR/ATR.h"
#include "BB/BB.h"
#include "RSI/RSI.h"
#include "Stochastic/Stochastic.h"

#include "ZigZag/ZigZag.h"

//**************************************************
// Order buy using confirmed  indicators
//**************************************************
bool BuyUsingIndicators() {
   bool bb_return, sto_return, rsi_return;
   if (ApplyIndicators) {
      bb_return = true;
      sto_return = true;
      rsi_return = true;
      if (UseBB) bb_return = BBBuy();
      if (UseSTO) sto_return = STOBuy();
      if (UseRSI) rsi_return = RSIBuy();
      if (bb_return && sto_return && rsi_return) return (true);

      return(false);
   } else {
      if (UseBB) bb_return = BBBuy();
      else bb_return = false;

      if (UseSTO) sto_return = STOBuy();
      else sto_return = false;

      if (UseRSI) rsi_return = RSIBuy();
      else rsi_return = false;

      if (bb_return || sto_return || rsi_return) return (true);
      return(false);
   }
   return (false);
}

//**************************************************
// Order sell using confirmed  indicators
//**************************************************
bool SellUsingIndicators() {
   bool bb_return, sto_return, rsi_return;
   
   if (ApplyIndicators) {
      bb_return = true;
      sto_return = true;
      rsi_return = true;
      if (UseBB) bb_return = BBSell();
      if (UseSTO) sto_return = STOSell();
      if (UseRSI) rsi_return = RSISell();
      if (bb_return && sto_return && rsi_return) return (true);

      return(false);
   } else  {
      if (UseBB) bb_return = BBSell();
      else bb_return = false;

      if (UseSTO) sto_return = STOSell();
      else sto_return = false;
      
      if (UseRSI) rsi_return = RSISell();
      else rsi_return = false;
      
      if (bb_return || sto_return || rsi_return) return (true);
      return(false);
   }
   return (false);
}