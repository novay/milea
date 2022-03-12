extern string   Code            	= "Novay"; // Real Account Code
extern string   EAName          	= "Grid Edition"; // MilEA Edition
extern double   Lot             	= 0.01; // Initial Lot Size
extern double   TargetEquity    	= 100000000.0; // Target Equity (USD) 
extern double   DailyTarget     	= 0; // Daily Target (USD). 0 to Ignore
extern double   Spread          	= 10.0; // Max Spread
extern double   MaxSlippage 	  	= 2.0; // Slippage

extern string   Engine1         	= "==== MAIN STRATEGY ===="; // >>> MAIN ATTACK
enum ENUM_SEQUENCE {
	FIX, // FIXED LOT 
	DA, // D´ALEMBERT
	MARTI, // MARTINGALE
	FIBO, // FIBONACCI
	MILEA // MARTI-EXTRA
};
extern ENUM_SEQUENCE Sequence    	= FIBO; // Progression (Sequence)
extern double   Multiplier       	= 1.4; // Multiplier (Martingale Only)
extern double   Distance         	= 40; // Grid Distance
extern double   TakeProfitPips   	= 17; // Take Profit (Pips)
extern double   TakeProfit       	= 5; // Take Profit (USD)
extern double   MaxLot1          	= 1.44; // Maximum Lot Size. 0 to Ignore
extern int 		MaxOrders      		= 6; // Max Position (Layers). 0 to Ignore
extern int      Magic1           	= 555571; // Magic Number (Engine 1)

extern string   Engine2          	= "==== PYRAMID (REVERSE MARTI) ===="; // >>> DEFENCE 1
extern bool     EnablePyramid    	= false; // Enable Anti Marti
extern int      HedgeLevel       	= 11; // Start Hedge Level
extern int      TrailSL          	= 35; // Trailing SL (Pips)
extern int      StopLoss         	= 40; // Stop Loss (Pips)
extern double   MaxLot2          	= 1.44; // Maximum Lot Size
extern int      Magic2           	= 555572; // Magic Number (Engine 2)

extern string   Engine3          	= "==== GAMBLING (FULL MARGIN) ===="; // >>> DEFENCE 2
extern bool     Reload           	= true; // Reload Hedge
extern bool     FullLots         	= true; // Full Lots

#ifdef __time__
	extern string   TimeSettings  	= ""; // ==== TIME SETTINGS ====
	extern bool     TimeFilter    	= false; // Time Filter
	extern int      StartHour     	= 24; // Start Hour (Market Watch)
	extern int      EndHour       	= 8; // End Hour (Market Watch)
#endif

#ifdef __news__
	extern string   NewsFilters     = ""; // ==== NEWS FILTER ====
	extern bool     nAvoidNews      = false; // Avoid News (High Impact)
	extern int      nMinsBeforeNews = 60; // Close Before News (Min)
	extern int      nMinsAfterNews  = 60; // Open After News (Min)
	extern int      nTimeZone       = 8; // Time Zone, GMT (for news)
	extern string   nPairs          = "USD,EUR"; // Affected Pairs (empty for current pairs) 
#endif

#ifdef __protection__
	extern string   ProtectSettings = ""; // ==== PROTECTION SETTINGS ====
	extern bool     TotalLoss       = false; // Use Total Loss
	extern double   AccountLock     = 100000000.0; // Maximal Loss Allowed (USD)
	extern double   PairsLoss     	= 0; // Cutloss Per Pairs (%)
	extern double   LevelRisk     	= 0; // BEP Trigger (Layers). Close on +1$
	
	extern int     	PartialClose 	= 0; // Close Partials (Last & First)
	extern bool 	HiddenTP     	= false; // Hidden Take Profit
#endif

extern string   MILEASettings  		= ""; // ==== MILEA (ONLY) SETTINGS ====
extern string   MilTrade       		= "4,4"; // Number of trades in each block (separated by a comma)
extern string   MilSpace       		= "25,50,100"; // Specifies number of pips away to issue limit order (separated by a comma)
extern string   MilTP       		= "50,100,200"; // Take profit for each block (separated by a comma)
