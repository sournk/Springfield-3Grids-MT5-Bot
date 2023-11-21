//+------------------------------------------------------------------+
//|                                   Springfield-3Grids-MT5-Bot.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Don't touch anything bellow
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"

#include "Include\DKStdLib\TradingManager\CDKGridOneDirStepPos.mqh"
#include "Include\DKStdLib\License\DKLicense.mqh"

#property script_show_inputs

input     group                    "0. LICENSE"
          string                   InpLicenseSalt  = "Springfield-3Grids-MT5-Bot.v1.mq5";                       // Salt
input     string                   InpLicenseKey;                                                               // Put here you license key with no sapces and line breaks

input     group                    "1. GRID A"
input     uint                     InpMaxTradesA                        = 5;                                    // MaxTrades: Max grid size
input     double                   InpLotsA                             = 0.1;                                  // Lots: Initial grid order lots size
input     double                   InpLotsExponentA                     = 1.5;                                  // LotsExponent: Next grid order volume ratio
input     uint                     InpStepA                             = 300;                                  // Step: Price distance to open next grid order, points
input     uint                     InpTakeProfitA                       = 300;                                  // Take Profit: Distance from grid Break Even, points
input     ENUM_TIMEFRAMES          InpRSITimeFrameA                     = PERIOD_M1;                            // RSI timeframe
input     ulong                    InpMaxSlippageA                      = 2;                                    // Max slippage for market operations, points
input     long                     InpMagicA                            = 2023111901;                           // Magic number of the grid
          string                   InpGridNameA                         = "A";                                  // Grid A name

input     group                    "2. GRID B"
input     bool                     InpEnabledB                          = true;                                 // Grid enabled
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
input     bool                     InpEnabledC                          = true;                                 // Grid enabled
input     uint                     InpMaxTradesC                        = 5;                                    // MaxTrades: Max grid size
input     double                   InpLotsC                             = 0.1;                                  // Lots: Initial grid order lots size
input     double                   InpLotsExponentC                     = 1.5;                                  // LotsExponent: Next grid order volume ratio
input     uint                     InpStepC                             = 300;                                  // Step: Price distance to open next grid order, points
input     uint                     InpTakeProfitC                       = 300;                                  // Take Profit: Distance from grid Break Even, points
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


DKLogger                           m_logger_a;
DKLogger                           m_logger_b;
DKLogger                           m_logger_c;

CTrade                             m_trade_a;
CTrade                             m_trade_b;
CTrade                             m_trade_c;

CDKGridOneDirStepPos               m_grid_a;
CDKGridOneDirStepPos               m_grid_b;
CDKGridOneDirStepPos               m_grid_c;

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
                             "GRID %s (%s):\n"+
                             "=======\n"+
                             "%s\n\n"+                             
                             "GRID %s (%s):\n"+
                             "=======\n"+
                             "%s\n\n"+                             
                             "GRID %s (%s):\n"+
                             "=======\n"+
                             "%s\n\n",                                                    
                             
                             InpGridNameA,
                             m_grid_a.GetID(),
                             StringFormat("Dir: %s\n", EnumToString(m_grid_a.GetDirection())) + m_grid_a.GetDescription(),
                             
                             InpGridNameB,
                             m_grid_b.GetID(),
                             StringFormat("Dir: %s\n", EnumToString(m_grid_b.GetDirection())) + m_grid_b.GetDescription() + StringFormat("Seed: %.1f\n", m_grid_b_sleep_till / 60),
                             
                             InpGridNameC,
                             m_grid_c.GetID(),
                             StringFormat("Dir: %s\n", EnumToString(m_grid_c.GetDirection())) + m_grid_c.GetDescription() + StringFormat("Seed: %.1f\n", m_grid_c_sleep_till / 60));

  Comment(text);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Check exp. date
   string expar = (string)InpReleaseDate;
   if (TimeCurrent() > StringToTime(expar) + 31 * 24 * 60 * 60) {
     MessageBox("Developer version is expired", "Error", MB_OK | MB_ICONERROR);
     return(INIT_FAILED);
   }  

   // Check license
   CAccountInfo account;
   if (!IsLicenseValid(InpLicenseKey, account.Login(), InpLicenseSalt)) {
     MessageBox("Your license key is invalid", "Error", MB_OK | MB_ICONERROR);
     return(INIT_FAILED);
   }    

   MathSrand(GetTickCount());
   
   EventSetTimer(1);
   
   m_logger_a.Name = BOT_GLOBAL_PREFIX + ":" + InpGridNameA;
   m_logger_a.Level = InpLogLevel;
   if(MQL5InfoInteger(MQL5_DEBUGGING)) m_logger_a.Level = LogLevel(DEBUG);  

   m_logger_b.Name = BOT_GLOBAL_PREFIX + ":" + InpGridNameB;
   m_logger_b.Level = m_logger_a.Level;

   m_logger_c.Name = BOT_GLOBAL_PREFIX + ":" + InpGridNameC;
   m_logger_c.Level = m_logger_a.Level;
   
    if (InpMagicA == InpMagicB || InpMagicA == InpMagicC || InpMagicB == InpMagicC) {
     MessageBox("Put different Magic for all grids", "Error", MB_OK && MB_ICONERROR);
     return(INIT_FAILED);   
   }
   
   InitGrid(m_trade_a, InpMagicA, InpMaxSlippageA);
   InitGrid(m_trade_b, InpMagicB, InpMaxSlippageB);
   InitGrid(m_trade_c, InpMagicC, InpMaxSlippageC);
   
   m_grid_a.SetLogger(GetPointer(m_logger_a));
   m_grid_b.SetLogger(GetPointer(m_logger_b));
   m_grid_c.SetLogger(GetPointer(m_logger_c));

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
  ShowComment();
  
  if (m_grid_a.Size() <= 0) 
    m_grid_a.SetDirection(GetRSI(InpRSITimeFrameA));
  
  m_grid_a.OpenNext();
  m_grid_a.SetTPFromAverage();

  CDKPositionInfo pos;
  if (m_grid_a.Get(0, pos)) {
    if (InpEnabledB && TimeCurrent() >= pos.Time() + m_grid_b_sleep_till) {
       if (m_grid_b.Size() <= 0)
         m_grid_b.SetDirection(GetRSI(InpRSITimeFrameB));
      m_grid_b.OpenNext();
      
    }
    
    if (InpEnabledC && TimeCurrent() >= pos.Time() + m_grid_c_sleep_till) {
       if (m_grid_c.Size() <= 0)
         m_grid_c.SetDirection(GetRSI(InpRSITimeFrameC));
      m_grid_c.OpenNext();
    }    
  }  
  
  if (InpEnabledB) m_grid_b.SetTPFromAverage();
  if (InpEnabledC) m_grid_c.SetTPFromAverage();  
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
  
}

void OnTrade() {
  if (m_grid_a.OpenPosCount(InpMagicA) != m_grid_a.Size()) {
     m_grid_a.Clear();              
     m_grid_a.Load(InpMagicA);
   }
   
  if (m_grid_b.OpenPosCount(InpMagicB) != m_grid_b.Size()) {
     m_grid_b.Clear();              
     m_grid_b.Load(InpMagicB);
   }
   
  if (m_grid_c.OpenPosCount(InpMagicC) != m_grid_c.Size()) {
     m_grid_c.Clear();              
     m_grid_c.Load(InpMagicC);
   }
}
