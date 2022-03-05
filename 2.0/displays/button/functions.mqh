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
enum enObjectOperation {
   LODraw = 0,
   LODelete = 1
};

void ObjectButton(string ctlName, enObjectOperation Operation, string Text = "",
                  int X = -1, int Y = -1, int Width = -1, int Height = -1, bool Selected = false,
                  color BgColor = clrNONE, color TextColor = clrNONE) {
   int DefaultX = btn_left_axis;
   int DefaultY = btn_top_axis;
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