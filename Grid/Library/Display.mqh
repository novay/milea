int SubWindow = 0;
int Corner = 2;
int Move_X = 0;
int Move_Y = 0;

int Button_Width = 70;
string Font_Type = "Arial Bold";
color Font_Color = clrWhite;
int Font_Size = 8;

void DisplayOnInit()
{
	CreateButtons();
    ToolTips_Text("xALL_btn");
    ToolTips_Text("xBUY_btn");
    ToolTips_Text("xSELL_btn");
}

//+------------------------------------------------------------------+
// Button                                                            |
//+------------------------------------------------------------------+
void CreateButtons()
{
  int Button_Height = (int)(Font_Size*2.8);

  if (!ButtonCreate(0, "xALL_btn", 0, 005 + 000 + Move_X, 045 + 005 + Move_Y, Button_Width*2+3, Button_Height, Corner, "Close All", Font_Type, Font_Size, Font_Color, clrTeal, clrYellow)) return;
  if (!ButtonCreate(0, "xBUY_btn", 0, 005 + 000 + Move_X, 020 + 005 + Move_Y, Button_Width + 000, Button_Height, Corner, "Close Buy", Font_Type, Font_Size, Font_Color, clrBlue, clrYellow)) return;
  if (!ButtonCreate(0, "xSELL_btn", 0, 005 + 073 + Move_X, 020 + 005 + Move_Y, Button_Width + 000, Button_Height, Corner, "Close Sell", Font_Type, Font_Size, Font_Color, clrCrimson, clrYellow)) return;
  ChartRedraw();
}

void ButtonPressed(const long chartID, const string action)
{
    ObjectSetInteger(chartID, action, OBJPROP_BORDER_COLOR, clrBlack); // Pressed
    if(action == "xALL_btn") xAll_Button(action);
    if(action == "xBUY_btn") xBuy_Button(action);
    if(action == "xSELL_btn") xSell_Button(action);

    Sleep(1000);
    ObjectSetInteger(chartID, action, OBJPROP_BORDER_COLOR, clrYellow); // Unpressed
    ObjectSetInteger(chartID, action, OBJPROP_STATE, false); // Unpressed
    ChartRedraw();
}

void RemoveButtons()
{
    RemoveObject(0, "xALL_btn");
    RemoveObject(0, "xBUY_btn");
    RemoveObject(0, "xSELL_btn");
}

void ToolTips_Text(const string action)
{
    if(action == "xALL_btn") { ObjectSetString(0, action, OBJPROP_TOOLTIP, "Close All Order(s) for **Current Chart** ONLY"); }
    if(action == "xBUY_btn") { ObjectSetString(0, action, OBJPROP_TOOLTIP, "Close Buy Order(s) for **Current Chart** ONLY"); }
    if(action == "xSELL_btn") { ObjectSetString(0, action, OBJPROP_TOOLTIP, "Close Sell Order(s) for **Current Chart** ONLY"); }
}

int xAll_Button(const string action)
{
    CloseAll();
    return(0);
}

int xBuy_Button(const string action)
{
    CloseAllBuys();
    return(0);
}

int xSell_Button(const string action)
{
    CloseAllSells();
    return(0);
}

bool ButtonCreate(const long chart_ID = 0, 
        const string name = "Button", 
        const int sub_window = 0, 
        const int x = 0, 
        const int y = 0, 
        const int width = 500,
        const int height = 18, int corner = 0, 
        const string text = "button", 
        const string font = "Arial Bold",
        const int font_size = 10, 
        const color clr = clrBlack, 
        const color back_clr = C'170,170,170', 
        const color border_clr = clrNONE,
        const bool state = false, 
        const bool back = false, 
        const bool selection = false, 
        const bool hidden = true, 
        const long z_order = 0)
{
    ResetLastError();
    if (!ObjectCreate (chart_ID, name, OBJ_BUTTON, SubWindow, 0, 0)) {
        Print (__FUNCTION__, " : failed to create the button! Error code : ", GetLastError());
        return(false);
    }

    ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(chart_ID, name, OBJPROP_CORNER, corner);
    ObjectSetInteger(chart_ID, name, OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, back_clr);
    ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, border_clr);
    ObjectSetInteger(chart_ID, name, OBJPROP_BACK, back);
    ObjectSetInteger(chart_ID, name, OBJPROP_STATE, state);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, selection);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, selection);
    ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN, hidden);
    ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER,z_order);
    ObjectSetString(chart_ID, name, OBJPROP_TEXT, text);
    ObjectSetString(chart_ID, name, OBJPROP_FONT, font);

    return(true);
}
  
bool RemoveObject(const long chart_ID = 0, const string name = "Button")
{
    ResetLastError();
    if(!ObjectDelete (chart_ID, name)) {
        Print(__FUNCTION__, ": Failed to delete the button! Error code = ", GetLastError());
        return(false);
    }

    return(true);
}
//+------------------------------------------------------------------+
// End of Button                                                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Chart Display                                                     |
//+------------------------------------------------------------------+
void ChartDisplay()
{
   RectLabelCreate3("INFO_BG", 10, 20, 230, 280, Black);
   
   PutLabel("INFO_LOGO",       15, 25,  ea_name + " v" + ea_version + " (Grid Edition)", 11, "Arial Bold");
   PutLabel("INFO_EDITION",    13, 44,  " by " + ea_author, 7);
   
   PutLabel("INFO_LINE1",      15, 42,  "___________________________");
   PutLabel_("INFO_ACCOUNT",   15, 60,  "Account Information", 11, "Arial Bold");
   PutLabel("INFO_LINE2",      15, 65,  "___________________________");
   
   PutLabel("INFO_NAME",       15, 85,  "Account ID:");
   PutLabel("INFO_SPREAD",     15, 103, "Spread:");
   PutLabel("INFO_BALANCE",    15, 121, "Balance:");
   PutLabel("INFO_EQUITY",     15, 139, "Equity:");
   PutLabel("INFO_LINE3",      15, 147, "___________________________");
   PutLabel_("INFO_txt6",      15, 165, "Trade Settings", 11, "Arial Bold");
   PutLabel("INFO_LINE4",      15, 170, "___________________________");
   PutLabel("INFO_TARGET",     15, 188, "Target Equity:");
   PutLabel("INFO_LOCK",       15, 206, "Lock Equity:");
   PutLabel("INFO_TIME",       15, 224, "Time Settings:");
   PutLabel("INFO_NEWS",       15, 242, "News Filter:");
   PutLabel("INFO_TODAY",      15, 260, "Today Profit:");
   PutLabel("INFO_PL",         15, 278, "Profit/Loss:");
   
   PutLabel_("INFO_IN01",    130, 85,  (string)AccountNumber());
   PutLabel_("INFO_IN02",    130, 103, (string)MarketInfo(Symbol(), MODE_SPREAD));
   PutLabel_("INFO_IN03",    130, 121, (string)NormalizeDouble(AccountBalance(), 2));
   PutLabel_("INFO_IN04",    130, 139, (string)NormalizeDouble(AccountEquity(), 2));
   PutLabel_("INFO_IN05",    130, 188, (string)TargetEquity);
   PutLabel_("INFO_IN06",    130, 206, (string)AccountLock);
   PutLabel_("INFO_IN07",    130, 224, (string)TimeFilter);
   PutLabel_("INFO_IN08",    130, 242, nNewsString);
   PutLabel_("INFO_IN09",    130, 260, (string)NormalizeDouble(ProfitToday(-1), 2));
   PutLabel_("INFO_IN10",    130, 278, (string)NormalizeDouble(ProfitLoss(-1), 2));
}

void PutLabel(string name, 
    int x, 
    int y, 
    string text, 
    int size = 11, 
    string font = "Arial")
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, font);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetInteger(0, name, OBJPROP_COLOR, White);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

void PutLabel_(string name,
    int x,
    int y,
    string text, 
    int size = 11, 
    string font = "Arial")
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, font);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  size);
    ObjectSetInteger(0, name, OBJPROP_COLOR, DodgerBlue);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

bool RectLabelCreate3(string name, 
    int x,
    int y, 
    int width, 
    int height, 
    color back_clr)
{
    ResetLastError(); 
    if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
        return(false);
    } 
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); 
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y); 
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width); 
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height); 
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, back_clr); 
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_SUNKEN); 
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); 
    ObjectSetInteger(0, name, OBJPROP_COLOR, Blue); 
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1); 
    ObjectSetInteger(0, name, OBJPROP_BACK, false); 
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); 
    
    return(true);
}