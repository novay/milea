//+------------------------------------------------------------------+
//|                                                       MilEAv3.00 |
//|                                Copyright 2020, Noviyanto Rahmadi |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#property link      "https://milea.btekno.id"
#property version   "3.00"
#property strict

#property script_show_inputs
#property description "Sample script posting a user message "
#property description "on the wall on mql5.com"

input string InpLogin      = "novay@btekno.id";    // MilEA Email (Username)
input string InpPassword   = "password";           // MilEA Password
input string InpAccount    = "52082362";           // MT4 Account ID
//+------------------------------------------------------------------+

#include <JSON.mqh>
#include <Request.mqh>

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // =============================================
   // If its running on real account
   // =============================================
   if(!IsDemo()) {
      // =============================================
      // Check the credentials
      // =============================================
      string cookie = NULL, headers;
      char post[], result[];
      int res;

      string str = "email="+InpLogin+"&password="+InpPassword+"&account_id="+InpAccount;
      ArrayResize(post, StringToCharArray(str, post, 0, WHOLE_ARRAY, CP_UTF8)-1);
      
      int timeout = 5000;
      res = WebRequest("POST","https://milea.btekno.id/api/login", cookie, NULL, timeout, post, 0, result, headers); 

      CJAVal data;
      data.Deserialize(result);
      
      if(data["status"].ToStr() == "error") {
         MessageBox(data["message"].ToStr());
         return false;
      } else {
         // Run this bot!!!
         MessageBox(data["message"].Serialize());
      }
    }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   
}
//+------------------------------------------------------------------+