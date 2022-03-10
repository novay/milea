string 	KeyHedging 			= "Reverse";
string 	Key 				= ea_name + " v" + ea_version;
int 	Slippage 			= MaxSlippage;

// Global Variable =====
bool 	run 				= true;
bool 	booting 			= true;
int 	stop_all 			= 0;
int 	stop_next_cycle 	= 0;
int 	rest_and_realize 	= 0;

// Number of Orders =====
int 	buys = 0, sells = 0; 
int 	hedge_buys = 0, hedge_sells = 0;

// Ticket =====
int 	buy_tickets[max_open_positions], sell_tickets[max_open_positions];
int 	hedge_buy_tickets[max_open_positions], hedge_sell_tickets[max_open_positions];

// Lots =====
double 	buy_lots[max_open_positions], sell_lots[max_open_positions];
double 	hedge_buy_lots[max_open_positions], hedge_sell_lots[max_open_positions];
double 	total_buy_lots = 0, total_sell_lots = 0;
double 	total_hedge_buy_lots = 0, total_hedge_sell_lots = 0;

// Current Profit =====
double 	buy_profit[max_open_positions], sell_profit[max_open_positions];
double 	hedge_buy_profit[max_open_positions], hedge_sell_profit[max_open_positions];

// Open Price =====
double 	buy_price[max_open_positions], sell_price[max_open_positions];
double 	hedge_buy_price[max_open_positions], hedge_sell_price[max_open_positions];

// Hedging Indicators =====
bool 	is_sell_hedging_active = false, is_buy_hedging_active = false;
bool 	is_sell_hedging_order_active = false, is_buy_hedging_order_active = false;

// Profit/Loss Information =====
double 	total_buy_profit = 0, total_sell_profit = 0;
double 	total_buy_swap = 0, total_sell_swap = 0;
double 	total_buy_commission = 0, total_sell_commission = 0;
double 	total_hedge_buy_profit = 0, total_hedge_sell_profit = 0;
double 	total_hedge_buy_swap = 0, total_hedge_sell_swap = 0;
double 	total_hedge_buy_commission = 0, total_hedge_sell_commission = 0;
double 	total_swap = 0, total_commission = 0;

// Protection Settings =====
bool 	buy_max_order_lot_open = false, sell_max_order_lot_open = false;

// Market Information =====
int 		market_digits 		= 0;
double 		market_price_buy 	= 0;
double 		market_price_sell	= 0;
double 		market_point 		= 0;
double 		market_tick_value 	= 0;
double 		market_tick_size 	= 0;
double 		market_spread 		= 0;
datetime 	market_time 		= 0;
double 		market_ticks_grid 	= 0;
int 		market_multiplier 	= 1;
string 		market_symbol 		= "$";

double market_mode_hedged 		= MarketInfo(Symbol(), MODE_MARGINHEDGED);
double market_mode_init 		= MarketInfo(Symbol(), MODE_MARGININIT);
double market_mode_maintenance 	= MarketInfo(Symbol(), MODE_MARGINMAINTENANCE);
double market_mode_required 	= MarketInfo(Symbol(), MODE_MARGINREQUIRED);

#ifdef __news__
	string nNewsString = (string)nAvoidNews;
#endif