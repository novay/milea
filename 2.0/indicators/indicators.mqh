sinput string __indicators_settings__;    // ***** Settings of indicators *****
extern bool ApplyIndicators = false;      // Apply All Indicators

// #include "bb/presets.mqh"
// #include "stochastic/presets.mqh"
// #include "rsi/presets.mqh"
// #include "atr/presets.mqh"

bool IndicatorsBuy() {
   bool bb_execute, sto_execute, rsi_execute;
   if(ApplyIndicators) {
      bb_execute = true;
      sto_execute = true;
      rsi_execute = true;
      if(BBEnable) bb_execute = BBBuy();
      if(STOEnable) sto_execute = STOBuy();
      if(RSIEnable) rsi_execute = RSIBuy();
      if(bb_execute && sto_execute && rsi_execute) return (true);

      return(false);
   } else {
      if(BBEnable) bb_execute = BBBuy();
      else bb_execute = false;
      
      if(STOEnable) sto_execute = STOBuy();
      else sto_execute = false;
      
      if(RSIEnable) rsi_execute = RSIBuy();
      else rsi_execute = false;
      
      if(bb_execute || sto_execute || rsi_execute) return (true);
      
      return(false);
   }
   return (false);
}

bool IndicatorsSell() {
   bool bb_execute, sto_execute, rsi_execute;
   if(ApplyIndicators) {
      bb_execute = true;
      sto_execute = true;
      rsi_execute = true;
      if(BBEnable) bb_execute = BBSell();
      if(STOEnable) sto_execute = STOSell();
      if(RSIEnable) rsi_execute = RSISell();
      if(bb_execute && sto_execute && rsi_execute) return (true);
      
      return(false);
   } else  {
      if(BBEnable) bb_execute = BBSell();
      else bb_execute = false;
      
      if(STOEnable) sto_execute = STOSell();
      else sto_execute = false;
      
      if(RSIEnable) rsi_execute = RSISell();
      else rsi_execute = false;
      
      if(bb_execute || sto_execute || rsi_execute) return (true);
      
      return(false);
   }
   return (false);
}