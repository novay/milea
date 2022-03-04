// Sets EA mode (Lite, Advanced or Rider).
#include "common/mode.h"

// Includes common files.
#include "common/code-conf.h"
#include "common/define.h"
#include "common/enum.h"

// Includes class files.
#include "classes/Action.struct.h"
#include "classes/Chart.mqh"
#include "classes/Condition.mqh"
#include "classes/Condition.struct.h"
#include "classes/EA.mqh"
#include "classes/Msg.mqh"
#include "classes/Terminal.mqh"
#include "classes/Trade.mqh"

// Includes common EA's functions.
#ifdef __advanced__
	// Includes common EA actions.
	#include "common/funcs-adv.h"
#endif

// Includes indicator classes.
#include "classes/Indicators/Bitwise/indicators.h"
#include "classes/Indicators/Price/indicators.h"
#include "classes/Indicators/Special/indicators.h"
#include "classes/Indicators/indicators.h"

// EA structs.
#include "common/struct.h"

// Strategy enums.
#include "strategies/enum.h"

// Main user inputs.
#include "inputs.h"

// Strategy includes.
INPUT_GROUP("Strategy parameters");  // >>> STRATEGIES <<<
#include "strategies/strategies.h"
