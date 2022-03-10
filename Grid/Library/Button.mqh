//+---------------------------------------------------------------------------+
//  BUTTON methods
//+---------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| DeleteButton                                                     |
//+------------------------------------------------------------------+
void DeleteButton(string ctlName) {
   ObjectButton(ctlName, LODelete);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetButtonText(string ctlName, string Text) {
   if((ObjectFind(ChartID(), ctlName) > -1)) {
      ObjectSetString(ChartID(), ctlName, OBJPROP_TEXT, Text);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetButtonColor(string ctlName, color buttonColor = clrNONE, color textColor = clrNONE) {
   if((ObjectFind(ChartID(), ctlName) > -1)) {
      if(buttonColor != clrNONE) ObjectSetInteger(ChartID(), ctlName, OBJPROP_BGCOLOR, buttonColor);
      if(textColor != clrNONE) ObjectSetInteger(ChartID(), ctlName, OBJPROP_COLOR, textColor);
   }
}

//+------------------------------------------------------------------+
//|PressButton                                                       |
//+------------------------------------------------------------------+
void PressButton(string ctlName) {
   bool selected = ObjectGetInteger(ChartID(), ctlName, OBJPROP_STATE);
   if(selected) {
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_STATE, false);
   } else {
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_STATE, true);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawButton(string ctlName, string Text = "", int X = -1, int Y = -1, int Width = -1,
                int Height = -1, bool Selected = false,
                color BgColor = clrNONE, color TextColor = clrNONE) {
   ObjectButton(ctlName, LODraw, Text, X, Y, Width, Height, Selected, BgColor, TextColor);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectButton(string ctlName, enObjectOperation Operation, string Text = "",
                  int X = -1, int Y = -1, int Width = -1, int Height = -1, bool Selected = false,
                  color BgColor = clrNONE, color TextColor = clrNONE) {
   int DefaultX = btnLeftAxis;
   int DefaultY = btnTopAxis;
   int DefaultWidth = 90;
   int DefaultHeight = 20;
   if((ObjectFind(ChartID(), ctlName) > -1)) {
      if(Operation == LODraw) {
         if(TextColor == clrNONE) TextColor = clrWhite;
         if(BgColor == clrNONE) BgColor = clrBlueViolet;
         if(X == -1) X = DefaultX;
         if(Y == -1) Y = DefaultY;
         if(Width == -1) Width = DefaultWidth;
         if(Height == -1) Height = DefaultHeight;

         ObjectSetInteger(ChartID(), ctlName, OBJPROP_COLOR, TextColor);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_BGCOLOR, BgColor);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_XDISTANCE, X);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_YDISTANCE, Y);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_XSIZE, Width);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_YSIZE, Height);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_STATE, Selected);
         ObjectSetString(ChartID(), ctlName, OBJPROP_FONT, "Arial");
         ObjectSetString(ChartID(), ctlName, OBJPROP_TEXT, Text);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(ChartID(), ctlName, OBJPROP_SELECTABLE, 0);

      } else if(Operation == LODelete) {
         ObjectDelete(ChartID(), ctlName);
      }
   } else if(Operation == LODraw) {
      if(TextColor == clrNONE) TextColor = clrWhite;
      if(BgColor == clrNONE) BgColor = clrBlueViolet;
      if(X == -1) X = DefaultX;
      if(Y == -1) Y = DefaultY;
      if(Width == -1) Width = DefaultWidth;
      if(Height == -1) Height = DefaultHeight;

      ObjectCreate(ChartID(), ctlName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_COLOR, TextColor);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_BGCOLOR, BgColor);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_XDISTANCE, X);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_YDISTANCE, Y);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_XSIZE, Width);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_YSIZE, Height);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_STATE, Selected);
      ObjectSetString(ChartID(), ctlName, OBJPROP_FONT, "Arial");
      ObjectSetString(ChartID(), ctlName, OBJPROP_TEXT, Text);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(ChartID(), ctlName, OBJPROP_SELECTABLE, 0);
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam,
                  const string &sparam) {
   int retVal = 0;
   if(id == CHARTEVENT_OBJECT_CLICK) {
      string clickedObject = sparam;

      // #019: implement button: Stop On Next Cycle
      if(clickedObject == "btnstop_next_cycle") { //stop on Next Cycle
         if(stop_next_cycle)
            stop_next_cycle = 0;
         else {
            retVal = MessageBox("Trading as normal, until a cycle is successfully closed?", "   S T O P  N E X T  C Y C L E :", MB_YESNO);
            if(retVal == IDYES)
               stop_next_cycle = 1;
         }
      }
      // #011 #018: implement button: Stop On Next Cycle
      if(clickedObject == "btnrest_and_realize") { //stop on Next Cycle
         if(rest_and_realize)
            rest_and_realize = 0;
         else {
            retVal = MessageBox("Do not open any new position. Close cycle successfully, if possible.", "   R E S T  &  R E A L I Z E :", MB_YESNO);
            if(retVal == IDYES)
               rest_and_realize = 1;
         }
      }
      // #010: implement button: Stop & Close All
      if(clickedObject == "btnStopAll") { //stop trading and close all positions
         if(stopAll)
            stopAll = 0;
         else {
            retVal = MessageBox("Close all positons and stop trading?", "   S T O P  &  C L O S E :", MB_YESNO);
            if(retVal == IDYES)
               stopAll = 1;
         }
      }
      // #044: Add button to show or hide comment
      if(clickedObject == "btnShowComment") { //stop on Next Cycle
         if(showComment)
            showComment = 0;
         else
            showComment = 1;
      }
      // #026: implement hedge trades, if account state is not green
      if(clickedObject == "btnhedgeBuy") {
         if(true/*accountState==as_yellow || accountState==as_red*/) { // execute this button only, if account state is not green

            retVal = MessageBox("Buy " + (string)NextLotSize(OP_BUY) + " Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
            if(retVal == IDYES)
               OrderSendReliable(Symbol(), OP_BUY, NextLotSize(OP_BUY), MarketInfo(Symbol(), MODE_ASK), slippage, 0, 0, key, magic, 0, Blue);
         }
      }
      if(clickedObject == "btnhedgeSell") {
         if(true/*accountState==as_yellow || accountState==as_red*/) { // execute this button only, if account state is not green
            retVal = MessageBox("Sell " + (string)NextLotSize(OP_SELL) + " Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
            if(retVal == IDYES)
               OrderSendReliable(Symbol(), OP_SELL, NextLotSize(OP_SELL), MarketInfo(Symbol(), MODE_BID), slippage, 0, 0, key, magic, 0, Blue);
         }
      }
      // #034: implement hedge closing trades, if account state is not green
      if(clickedObject == "btnCloseLastBuy") {
         if(total_buy_lots > 0) {
            if(true/*accountState==as_yellow || accountState==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close last buy " + (string)buy_lots[buys - 1] + "Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  retVal = OrderCloseReliable(buy_tickets[buys - 1], buy_lots[buys - 1], MarketInfo(Symbol(), MODE_BID), slippage, Blue);
                  rest_and_realize = 1; // set status, that not a new position will be opened directly after closing all
               }
            }
         }
      }
      if(clickedObject == "btnCloseLastSell") {
         if(total_sell_lots > 0) {
            if(true/*accountState==as_yellow || accountState==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close last sell " + (string)sell_lots[sells - 1] + "Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  retVal = OrderCloseReliable(sell_tickets[sells - 1], sell_lots[sells - 1], MarketInfo(Symbol(), MODE_ASK), slippage, Blue);
                  rest_and_realize = 1; // set status, that not a new position will be opened directly after closing all
               }
            }
         }
      }
      // #035: implement hedge closing trades, if account state is not green
      if(clickedObject == "btnCloseAllBuys") {
         if(total_buy_lots > 0) {
            if(true/*accountState==as_yellow || accountState==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close all " + (string)total_buy_lots + "buy Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  CloseAllBuys();
                  // set status, that not a new position will be opened directly after alosing all
                  if(rest_and_realize == 0) // if not already choosen by use, set the other pause option
                     stop_next_cycle = 1;
               }
            }
         }
      }
      if(clickedObject == "btnCloseAllSells") {
         if(total_sell_lots > 0) {
            if(true/*accountState==as_yellow || accountState==as_red*/) { // execute this button only, if account state is not green
               retVal = MessageBox("Close all " + (string)total_sell_lots + "sell Lot of " + Symbol() + " ?", "   M A N U A L   O R D E R :", MB_YESNO);
               if(retVal == IDYES) {
                  CloseAllSells();
                  // set status, that not a new position will be opened directly after alosing all
                  if(rest_and_realize == 0) // if not already choosen by use, set the other pause option
                     stop_next_cycle = 1;
               }
            }
         }
      }
      WriteIniData();
   }
}