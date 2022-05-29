//+------------------------------------------------------------------+
//|                                                       MilEAv3.00 |
//|                                Copyright 2022, Noviyanto Rahmadi |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#define __protection__  // Enable protection settings.
#define __time__        // Enable time filter settings.
#define __news__        // Enable news filter settings.
#define __display__     // Enable display information on chart.

#include <MilEA/Define.h>
#include <MilEA/Preset.h>

#property copyright     ea_copy
#property version       ea_version
#property description   ea_name + " v" + ea_version + "\n"+ea_desc+"\n\nWARNING:\nMy Strategy is VERY AGGRESSIVE, DO WITH YOUR OWN RISK!"
#property link          ea_link
#property strict
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

      string str = "email="+MilEAEmail+"&password="+MilEAPassword+"&account_id="+MilEAAccount;
      ArrayResize(post, StringToCharArray(str, post, 0, WHOLE_ARRAY, CP_UTF8)-1);
      
      int timeout = 5000;
      res = WebRequest("POST","https://milea.btekno.id/api/login", cookie, NULL, timeout, post, 0, result, headers); 

      CJAVal data;
      data.Deserialize(result);
      
      if(data["status"].ToStr() == "error") {
         MessageBox(data["message"].ToStr());
         return false;
      } else {
         // Run the BOT!
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
//--- destroy timer
   EventKillTimer();
   
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