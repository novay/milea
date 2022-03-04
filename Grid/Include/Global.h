bool buy_chased = false, sell_chased = false;

// Ticket
int buy_tickets[max_open_positions];
int sell_tickets[max_open_positions];
int hedge_buy_tickets[max_open_positions];
int hedge_sell_tickets[max_open_positions];

// Lots
double buy_lots[max_open_positions];
double sell_lots[max_open_positions];
double hedge_buy_lots[max_open_positions];
double hedge_sell_lots[max_open_positions];

// Current Profit
double buy_profit[max_open_positions];
double sell_profit[max_open_positions];
double hedge_buy_profit[max_open_positions];
double hedge_sell_profit[max_open_positions];

// Open Price
double buy_price[max_open_positions];
double sell_price[max_open_positions];
double hedge_buy_price[max_open_positions];
double hedge_sell_price[max_open_positions];

// Hedging indicators
int hedge_magic = 11236;
bool is_sell_hedging_active = false, is_buy_hedging_active = false;
bool is_sell_hedging_order_active = false, is_buy_hedging_order_active = false;

// Number of orders
int buys = 0, sells = 0, hedge_buys = 0, hedge_sells = 0;





