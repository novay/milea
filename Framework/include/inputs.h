input string __EA_Params__ = ">> " + ea_name + " v" + ea_version + " build " + (string)(int)__DATETIME__ + " <<";  // >>> EA31337 <<<
#ifdef __advanced__
    #ifdef __rider__
        #include "common/rider/inputs.mqh"
    #else
        #include "common/advanced/inputs.mqh"
    #endif
#else
    #include "common/lite/inputs.mqh"
#endif

#ifdef __MQL4__
    extern string __EA_Risk_Params__ = "-- EA's risk management --";  // >>> EA's RISK <<<
#else
    input group "EA's risk management"
#endif

input float EA_Risk_MarginMax = 1.2f;  // Max margin to risk (in %)

#ifdef __MQL4__
    input string __EA_Trade_Params__ = "-- EA's trade parameters --";  // >>> EA's TRADE <<<
#else
    input group "EA's trade parameters"
#endif

input double EA_LotSize = 0;        // Lot size (0 = auto)
input uint EA_MagicNumber = 31337;  // Starting EA magic number

#ifdef __MQL4__
    input string __Logging_Params__ = "-- EA's logging & messaging --";  // >>> EA's LOGS & MESSAGES <<<
#else
    input group "EA's logging & messaging"
#endif

input ENUM_LOG_LEVEL VerboseLevel = ea_log_level;   // Level of log verbosity
input bool EA_DisplayDetailsOnChart = true;         // Display EA details on chart
// input bool WriteSummaryReport = true;            // Write summary report on finish