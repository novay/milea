string 	KeyHedging 			= "Reverse";
string 	Key 				= ea_name + " v" + ea_version;
int 	UserSlippage 		= 2;
int 	Slippage 			= 0;

bool 	run 				= true;
bool 	booting 			= true; 	// to do some things only one time after program start
int 	stop_all 			= 0; 		// close all and stop trading or continue with trading
int 	stop_next_cycle 	= 0;
int 	rest_and_realize 	= 0;
string nNewsString;

bool 	buy_chased = false, sell_chased = false;

// Number of Orders =====
int 	buys = 0, sells = 0; 
int 	hedge_buys = 0, hedge_sells = 0;

// Ticket =====
int 	buy_tickets[max_open_positions], sell_tickets[max_open_positions];
int 	hedge_buy_tickets[max_open_positions], hedge_sell_tickets[max_open_positions];

// Lots =====
double 	buy_lots[max_open_positions], sell_lots[max_open_positions];
double 	hedge_buy_lots[max_open_positions], hedge_sell_lots[max_open_positions];

// Current Profit =====
double 	buy_profit[max_open_positions], sell_profit[max_open_positions];
double 	hedge_buy_profit[max_open_positions], hedge_sell_profit[max_open_positions];

// Open Price =====
double 	buy_price[max_open_positions], sell_price[max_open_positions];
double 	hedge_buy_price[max_open_positions], hedge_sell_price[max_open_positions];

// Hedging Indicators =====
int 	hedge_magic = 11236;
bool 	is_sell_hedging_active = false, is_buy_hedging_active = false;
bool 	is_sell_hedging_order_active = false, is_buy_hedging_order_active = false;

// Profit/Loss Information =====
double 	total_buy_profit = 0, total_sell_profit = 0, total_buy_swap = 0, total_sell_swap = 0;
double 	total_hedge_buy_profit = 0, total_hedge_sell_profit = 0, total_hedge_buy_swap = 0, total_hedge_sell_swap = 0;
double 	buy_max_profit = 0, buy_close_profit = 0;
double 	buy_max_hedge_profit = 0, buy_close_hedge_profit = 0;
double 	sell_max_profit = 0, sell_close_profit = 0;
double 	sell_max_hedge_profit = 0, sell_close_hedge_profit = 0;
double 	total_buy_lots = 0, total_sell_lots = 0;
double 	total_hedge_buy_lots = 0, total_hedge_sell_lots = 0;
double 	relative_volume = 0;
double 	buy_close_profit_trail_orders = 0, sell_close_profit_trail_orders = 0;
bool 	buy_max_order_lot_open = false, sell_max_order_lot_open = false;

int 		market_digits 		= 0;
double 		market_price_buy 	= 0;
double 		market_price_sell	= 0;
double 		market_point 		= 0;
double 		market_tick_value 	= 0;
double 		market_tick_size 	= 0;
double 		market_spread 		= 0;
datetime 	market_time 		= 0;
double 		market_ticks_grid 	= 0; 	// Ticks of 1 Initial Lot per 1 Distance
int 		market_multiplier 	= 1; 	// If digits = 3 or 5: chart multiplier = 10
string 		market_symbol 		= "$";

double market_mode_hedged 		= MarketInfo(Symbol(), MODE_MARGINHEDGED);
double market_mode_init 		= MarketInfo(Symbol(), MODE_MARGININIT);
double market_mode_maintenance 	= MarketInfo(Symbol(), MODE_MARGINMAINTENANCE);
double market_mode_required 	= MarketInfo(Symbol(), MODE_MARGINREQUIRED);





double pips;

double hedge_buy_sl, hedge_sell_sl;
double buy_lot, sell_lot;
double hedge_buy_lot, hedge_sell_lot;

bool shb = false;
bool shs = false;

