// Ticket
bool buy_chased = false, sell_chased = false;
int buy_tickets[max_open_positions];
int sell_tickets[max_open_positions];

// Lots
double buy_lots[max_open_positions];
double sell_lots[max_open_positions];

// Current Profit
double buy_profit[max_open_positions];
double sell_profit[max_open_positions];

// Open Price
double buy_price[max_open_positions];
double sell_price[max_open_positions];

// Hedge correction orders
int hedge_buy_tickets[max_open_positions];
int hedge_sell_tickets[max_open_positions];

double hedge_buy_lots[max_open_positions];
double hedge_sell_lots[max_open_positions];

double hedge_buy_profit[max_open_positions];
double hedge_sell_profit[max_open_positions];

double hedge_buy_price[max_open_positions];
double hedge_sell_price[max_open_positions];

// Hedging indicators
int hedge_magic = 11236;
bool is_sell_hedging_active = false, is_buy_hedging_active = false;
bool is_sell_hedging_order_active = false, is_buy_hedging_order_active = false;

// Number of orders
int buys = 0, sells = 0, hedge_buys = 0, hedge_sells = 0;

// #020: show line, where the next line_buy /line_sell would be, if it would be opened
// value of lines:
double line_buy = 0, line_sell = 0, line_buy_tmp = 0, line_sell_tmp = 0, line_buy_next = 0;
double line_sell_next = 0, line_buy_ts = 0, line_sell_ts = 0, line_margincall = 0;

// profits:
double total_buy_profit = 0, total_sell_profit = 0, total_buy_swap = 0, total_sell_swap = 0;
double total_hedge_buy_profit = 0, total_hedge_sell_profit = 0, total_hedge_buy_swap = 0, total_hedge_sell_swap = 0;
double buy_max_profit = 0, buy_close_profit = 0;
double buy_max_hedge_profit = 0, buy_close_hedge_profit = 0;
double sell_max_profit = 0, sell_close_profit = 0;
double sell_max_hedge_profit = 0, sell_close_hedge_profit = 0;
double total_buy_lots = 0, total_sell_lots = 0;
double total_hedge_buy_lots = 0, total_hedge_sell_lots = 0;
double relativeVolume = 0;
double buy_close_profit_trail_orders = 0, sell_close_profit_trail_orders = 0;
bool buy_max_order_lot_open = false, sell_max_order_lot_open = false;

// Colors:
//color c=Black;
int colInPlus  = clrGreen;
int colInMinus = clrRed;
int colNeutral = clrGray;
int colBlue    = clrBlue;

int colFontLight  = clrWhite;
int colFontDark   = clrGray;
int colFontWhite  = clrWhite;

int colCodeGreen  = clrGreen;
int colCodeYellow = clrGold;
int colCodeRed    = clrRed;
int colPauseButtonPassive = clrBlue;

int panelCol = colNeutral;         // fore color of neutral panel text
int instrumentCol = colNeutral;    // panel color that changes depending on its value

// #023: implement account state by 3 colored button
enum ACCOUNT_STATE {as_green, as_yellow, as_red};
int account_state = as_green;
// #025: use equity percentage instead of unpayable position
double max_equity = 0;             // maximum of equity ever reached, saved in global vars
double max_float = 0;              // minimum of equity ever reached, saved in global vars

// global flags:
int stop_next_cycle = 0;          // flag, if trading will be terminated after next successful cycle, trades normally until cyle is closed
int rest_and_realize = 0;         // flag, if trading will be terminated after next successful cycle, does not open new positions
int stop_all = 0;                // flag, if stopAll must close all and stop trading or continue with trading

// #044: Add button to hide comment
int show_comment = 0;            // flag for comment at left side
bool is_first_loop = true;   // flag, to do some things only one time after program start

// screen coordinates:
// #054: make size of buttons flexible
int btn_width = 70;            // width of smallest buttons
int btn_height = 30;           // height of all buttons
int btn_gap = 10;              // gap, between buttons
int btn_left_axis = 200;        // distance of button from left screen border
int btn_top_axis = 17;          // distance of button from top screen border
int btn_next_left = btn_width + btn_gap;      // distance to next button
int btn_next_top = btn_height + btn_gap;      // distance to next button

// debugging:
string debug_comment_dyn = "\n";        // will be added to regular Comment txt and updated each program loop
string debug_comment_stat = "";         // will be added only - no updates
string debug_comment_close_buys = "";    // show condition, when cycle will be closed
string debug_comment_close_sells = "";
string code_red_message = "";               // tell user, why account state is yellow or red
string code_yellow_message = "";
double market_channel = 0;         // line_buy - line_sell
string global_id = Symbol() + "_" + (string)magic + "_"; //ID to specify the global vars from other charts

// values read from terminal:
int market_digits = 0;
double market_price_buy = 0;
double market_price_sell = 0;
double market_point = 0;
double market_tick_value = 0;
double market_tick_size = 0;
double market_spread = 0;
datetime market_time = 0;             // date and time while actual loop

// calculate by values from terminal:
double market_ticks_per_grid = 0;          // ticks of 1 min_lot per 1 grid size
int market_chart_multiplier = 1;          // if digits = 3 or 5: chart multiplier = 10
string market_symbol = "$";      // € if account is in Euro, $ for all other

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double market_mode_hedged = MarketInfo(Symbol(), MODE_MARGINHEDGED);
double market_mode_init = MarketInfo(Symbol(), MODE_MARGININIT);
double market_mode_maintenance = MarketInfo(Symbol(), MODE_MARGINMAINTENANCE);
double market_mode_required = MarketInfo(Symbol(), MODE_MARGINREQUIRED);