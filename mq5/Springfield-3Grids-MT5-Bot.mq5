//+------------------------------------------------------------------+
//|                                   Springfield-3Grids-MT5-Bot.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"

#include "Include\DKStdLib\TradingManager\CDKGridOneDirectionalStepPosition.mqh"

#property script_show_inputs

input     group                    "1. GRID A"
input     uint                     InpMaxTradesA                        = 5;                                    // MaxTrades: Max grid size
input     double                   InpLotsA                             = 0.1;                                  // Lots: Initial grid order lots size
input     double                   InpLotsExponentA                     = 1.5;                                  // LotsExponent: Next grid order volume ratio
input     uint                     InpStepA                             = 30;                                  // Step: Price distance to open next grid order, points
input     uint                     InpTakeProfitA                       = 50;                                  // Take Profit: Distance from grid Break Even, points
input     ENUM_TIMEFRAMES          InpRSITimeFrameA                     = PERIOD_M1;                            // RSI timeframe
input     ulong                    InpMaxSlippageA                      = 2;                                    // Max slippage for market operations, points
input     long                     InpMagicA                            = 2023111901;                           // Magic number of the grid
          string                   InpGridNameA                         = "A";                                  // Grid A name

input     group                    "2. GRID B"
input     bool                     InpEnabledB                          = false;                                 // Grid enabled
input     uint                     InpMaxTradesB                        = 5;                                    // MaxTrades: Max grid size
input     double                   InpLotsB                             = 0.1;                                  // Lots: Initial grid order lots size
input     double                   InpLotsExponentB                     = 1.5;                                  // LotsExponent: Next grid order volume ratio
input     uint                     InpStepB                             = 300;                                  // Step: Price distance to open next grid order, points
input     uint                     InpTakeProfitB                       = 300;                                  // Take Profit: Distance from grid Break Even, points
input     ENUM_TIMEFRAMES          InpRSITimeFrameB                     = PERIOD_H1;                            // RSI timeframe
input     ulong                    InpMaxSlippageB                      = 2;                                    // Max slippage for market operations, points
input     long                     InpMagicB                            = 2023111902;                           // Magic number of the grid
          string                   InpGridNameB                         = "B";                                  // Grid B name
          
input     group                    "3. GRID C"
input     bool                     InpEnabledC                          = false;                                 // Grid enabled
input     uint                     InpMaxTradesC                        = 5;                                    // MaxTrades: Max grid size
input     double                   InpLotsC                             = 0.1;                                  // Lots: Initial grid order lots size
input     double                   InpLotsExponentC                     = 1.5;                                  // LotsExponent: Next grid order volume ratio
input     uint                     InpStepC                             = 30;                                  // Step: Price distance to open next grid order, points
input     uint                     InpTakeProfitC                       = 50;                                  // Take Profit: Distance from grid Break Even, points
input     ENUM_TIMEFRAMES          InpRSITimeFrameC                     = PERIOD_D1;                            // RSI timeframe
input     ulong                    InpMaxSlippageC                      = 2;                                    // Max slippage for market operations, points
input     long                     InpMagicC                            = 2023111903;                           // Magic number of the grid
          string                   InpGridNameC                         = "C";                                  // Grid C name
          
input     group                    "4. MISC SETTINGS"
input     uint                     InpRSIMAPeriod                       = 14;                                   // RSI: MA period, bars
input     ENUM_APPLIED_PRICE       InpRSIAppliedPrice                   = PRICE_CLOSE;                          // RSI: Applied price
sinput    LogLevel                 InpLogLevel                          = LogLevel(INFO);                       // Log level
          
          int                      InpOpenNewGridMaxDelaySec            = 60 * 60;                              // Max delay between start new grid, sec
          int                      InpReleaseDate                       = 20231115;                             // Release date
          string                   BOT_GLOBAL_PREFIX                    = "SF";                                 // Global Prefix


DKLogger                           m_logger;

CTrade                             m_trade_a;
CTrade                             m_trade_b;
CTrade                             m_trade_c;

CDKGridOneDirectionalStepPosition  m_grid_a;
CDKGridOneDirectionalStepPosition  m_grid_b;
CDKGridOneDirectionalStepPosition  m_grid_c;

int                                m_grid_b_sleep_till;
int                                m_grid_c_sleep_till;

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| BOT'S LOGIC
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void InitGrid(CTrade& aTrade, const long aMagic, const ulong aSlippage) {
   aTrade.SetExpertMagicNumber(aMagic);
   aTrade.SetMarginMode();
   aTrade.SetTypeFillingBySymbol(_Symbol);
   aTrade.SetDeviationInPoints(aSlippage);  
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetRSI(int aRSIHandle, int aBuffer, int aIndex)
 {
  double RSIArr[];
  if(CopyBuffer(aRSIHandle, aBuffer, aIndex, 1, RSIArr) >= 0)
    return RSIArr[0];

  return -1;
 }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE GetRSI(const ENUM_TIMEFRAMES aPeriod) {
  int RSIHandle = iRSI(_Symbol, aPeriod, InpRSIMAPeriod, InpRSIAppliedPrice);

  double RSIMainLine = GetRSI(RSIHandle, MAIN_LINE, 1);
  double RSISignalLine = GetRSI(RSIHandle, SIGNAL_LINE, 1);

  return (RSIMainLine <= 50) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
}

void ShowComment() {
  string text = StringFormat("\n"+
                             "GRID %s:\n"+
                             "=======\n"+
                             "%s\n\n"+                             
                             "GRID %s:\n"+
                             "=======\n"+
                             "%s\n\n"+                             
                             "GRID %s:\n"+
                             "=======\n"+
                             "%s\n\n",                                                    
                             
                             InpGridNameA,
                             m_grid_a.GetDescription(),
                             
                             InpGridNameB,
                             m_grid_b.GetDescription(),
                             
                             InpGridNameC,
                             m_grid_c.GetDescription());

  Comment(text);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   MathSrand(GetTickCount());
   
   EventSetTimer(1);
   
   m_logger.Name = BOT_GLOBAL_PREFIX;
   m_logger.Level = InpLogLevel;
   if(MQL5InfoInteger(MQL5_DEBUGGING)) m_logger.Level = LogLevel(DEBUG);  
   
   string expar = (string)InpReleaseDate;
   if (TimeCurrent() > StringToTime(expar) + 31 * 24 * 60 * 60) {
     MessageBox("Developer version is expired", "Error", MB_OK && MB_ICONERROR);
     return(INIT_FAILED);
   }   
   
   if (InpMagicA == InpMagicB || InpMagicA == InpMagicC || InpMagicB == InpMagicC) {
     MessageBox("Put different Magic for all grids", "Error", MB_OK && MB_ICONERROR);
     return(INIT_FAILED);   
   }
   
   InitGrid(m_trade_a, InpMagicA, InpMaxSlippageA);
   InitGrid(m_trade_b, InpMagicB, InpMaxSlippageB);
   InitGrid(m_trade_c, InpMagicC, InpMaxSlippageC);
   
   m_grid_a.Init(_Symbol, GetRSI(InpRSITimeFrameA), InpMaxTradesA, InpLotsA, InpStepA, InpLotsExponentA, InpTakeProfitA, InpGridNameA, m_trade_a);
   m_grid_b.Init(_Symbol, GetRSI(InpRSITimeFrameB), InpMaxTradesB, InpLotsB, InpStepB, InpLotsExponentB, InpTakeProfitB, InpGridNameB, m_trade_b);
   m_grid_c.Init(_Symbol, GetRSI(InpRSITimeFrameC), InpMaxTradesC, InpLotsC, InpStepC, InpLotsExponentC, InpTakeProfitC, InpGridNameC, m_trade_c);
   
   OnTrade(); // Load open positions   
   
   m_grid_b_sleep_till = (int)(InpOpenNewGridMaxDelaySec * MathRand() / 32768); 
   m_grid_c_sleep_till = (int)(InpOpenNewGridMaxDelaySec * MathRand() / 32768); 
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {   
  EventKillTimer(); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
  ShowComment();
  
  if (m_grid_a.Size() <= 0) 
    m_grid_a.SetDirection(GetRSI(InpRSITimeFrameA));

  m_grid_a.OpenNext();
  m_grid_a.SetTPFromAverage();

  CDKPositionInfo pos;
  if (m_grid_a.Get(0, pos)) {
    if (InpEnabledB && TimeCurrent() >= pos.Time() + m_grid_b_sleep_till) {
       if (m_grid_b.Size() <= 0)
         m_grid_a.SetDirection(GetRSI(InpRSITimeFrameB));
     
      m_grid_b.OpenNext();
      m_grid_b.SetTPFromAverage();
    }
    
    if (InpEnabledC && TimeCurrent() >= pos.Time() + m_grid_c_sleep_till) {
       if (m_grid_c.Size() <= 0)
         m_grid_a.SetDirection(GetRSI(InpRSITimeFrameC));
     
      m_grid_c.OpenNext();
      m_grid_c.SetTPFromAverage();
    }    
  }
}

void OnTrade() {
   m_grid_a.Clear();              
   m_grid_a.AddOpenPositions(InpMagicA);
   Print(m_grid_a.Size());
   
   m_grid_b.Clear();              
   m_grid_b.AddOpenPositions(InpMagicB);
   Print(m_grid_b.Size());
   
   m_grid_c.Clear();              
   m_grid_c.AddOpenPositions(InpMagicC);
   Print(m_grid_c.Size());
}
