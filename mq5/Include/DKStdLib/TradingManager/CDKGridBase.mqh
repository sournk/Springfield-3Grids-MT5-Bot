//+------------------------------------------------------------------+
//|                                                     CDKGrids.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "..\Common\DKStdLib.mqh"
#include "..\Logger\DKLogger.mqh"

#include <Arrays\ArrayLong.mqh>
#include <Trade\Trade.mqh>

#include "CDKPositionInfo.mqh"

//+------------------------------------------------------------------+
//| Grid State Struct
//+------------------------------------------------------------------+
struct DKGridState {
  uint                Size;                                             // Grid open position count
  double              Volume;                                           // Grid volume
  double              Sum;                                              // Grid sum
  double              SumFull;                                          // Grid sum with swap and commision
  double              Profit;                                           // Grid profit
  double              Commission;                                       // Grid commision
  double              Swap;                                             // Grid swap
  double              PriceAverage;                                     // Grid price average
  double              PriceBreakEven;                                   // Grid break-even price of a grid
};

//+------------------------------------------------------------------+
//| Base Grid Class uses:
//| 1. Grid size contol by CheckEntry method
//| 2. Load open pos by Magic and Symbol
//| 3. Add pos by Ticket
//| 4. Get cumulative state
//| 5. OpenNext pos
//| 6. Set SL/TP for all grid pos
//| 7. Set SL/TP from avgerage or breakeven price
//| 8. Get any pos of grid
//+------------------------------------------------------------------+
class CDKGridBase : public CObject {
 protected:
  CDKSymbolInfo            m_symbol;
  CTrade                   m_trade;

  uint                     m_max_pos_count;
    
  string                   m_comment_prefix;
  string                   m_id;  
  
  CArrayLong               m_positions;
  
  DKLogger*                m_logger;
  void                     Log(string aMessageTest, LogLevel aMessageLevel = LogLevel(INFO));
 public:;
  void                Init(const string aSymbol,                                       // Constructor pseudo 
                           const uint aMaxPositionCount,
                           const string aCommentPrefix,
                           CTrade& Trade);                                             // Preconfigurated CTrade  
  
  void                SetLogger(DKLogger* aLogger);                                    // Set logger                           
  
  bool                Get(const uint aIndex, CDKPositionInfo& aPosition);              // Return grid position by index
  bool                GetLast(CDKPositionInfo& aPosition);                             // Return last position
  uint                Size();                                                          // Return position count of the grid

  uint                Add(const ulong aTicket);                                        // Add position to the grid by ticket
  uint                Load(const long aMagic);                                         // Load all open positions by Magic
  uint                Delete(const uint aIndex);                                       // Add position to the grid. Return new size of grid
  void                Clear();                                                         // Clear all grid's positions

  DKGridState         GetState();                                                      // Returns current state of grid

  bool                CheckEntry();                                                    // Checks is it possible to open next grid position (max grid size check)
  ulong               OpenNext(const string aSymbol,                                   // New pos symbol
                               const ENUM_POSITION_TYPE aDirection,                    // New pos direction
                               const double aLots,                                     // New pos lots
                               const double aPrice,                                    // Open price
                               const double aSL,                                       // New pos SL
                               const double aTP,                                       // New pos TP
                               const string aComment);                                 // New pos comment
  bool                SetSLTP(double aSL, double aTP);                     // Update take profit and stop loss for all orders of the gird                               
  
  bool                SetTPFromAveragePrice(const double aDistancePoint);              // Set take profit for all orders of the gird to AP+aDistance
  bool                SetTPFromAveragePricePoint(const int aDistancePoint);            // Set take profit for all orders of the gird to AP+aDistance in point

  bool                SetTPFromBreakEven(const double aDistancePoint);                 // Set take profit for all orders of the gird to BE+aDistance
  bool                SetTPFromBreakEvenPoint(const int aDistancePoint);               // Set take profit for all orders of the gird to BE+aDistance in point
  
  string              GetPosComment(const string aPrefix, const uint aNumber);         // Returns pos comment
  string              GetIDFromComment(const string aComment);                         // Parse aComment and return grid id  
  
  string              GetID();                                                         // Returns grid ID
  string              GetDescription();                                                // Get description string
};

//+------------------------------------------------------------------+
//| Log operations
//+------------------------------------------------------------------+
void CDKGridBase::Log(string aMessageTest, LogLevel aMessageLevel = LogLevel(INFO)) {
  if (m_logger != NULL) m_logger.Log(aMessageTest, aMessageLevel);
}

//+------------------------------------------------------------------+
//| Init
//+------------------------------------------------------------------+
void CDKGridBase::Init(const string aSymbol,
                       const uint aMaxPositionCount,
                       const string aCommentPrefix,
                       CTrade& aTrade){
  m_max_pos_count = aMaxPositionCount;
  
  m_symbol.Name(aSymbol);
  m_trade = aTrade;
  
  m_comment_prefix = aCommentPrefix;
  m_id = GetUniqueInstanceName("");   // ID with no prefix
}

//+------------------------------------------------------------------+
//| Set logger
//+------------------------------------------------------------------+
void CDKGridBase::SetLogger(DKLogger* aLogger){
  m_logger = aLogger;
}

//+------------------------------------------------------------------+
//| Get pos by index
//+------------------------------------------------------------------+
bool CDKGridBase::Get(const uint aIndex, CDKPositionInfo& aPosition) {
  long ticket = m_positions.At(aIndex);
  if(ticket == LONG_MAX) return false;
  
  return aPosition.SelectByTicket(ticket);
}

//+------------------------------------------------------------------+
//| Get last pos
//+------------------------------------------------------------------+
bool CDKGridBase::GetLast(CDKPositionInfo& aPosition) {
  return Get(Size() - 1, aPosition);
}

//+------------------------------------------------------------------+
//| Get grid size
//+------------------------------------------------------------------+
uint CDKGridBase::Size() {
  return m_positions.Total();
}

//+------------------------------------------------------------------+
//| Add pos in grid by Ticket
//+------------------------------------------------------------------+
uint CDKGridBase::Add(const ulong aTicket) {
  CDKPositionInfo pos;
  if (m_positions.Search(aTicket) >= 0) return Size(); // aTicket is already in list
  
  if (pos.SelectByTicket(aTicket)) {
    m_positions.Add(aTicket);
    Log(StringFormat("Position added to grid: GRID=%s | TICKET=%I64u | SIZE=%d", 
                     m_id, aTicket, Size()), INFO);
  }

  return Size();
}

//+------------------------------------------------------------------+
//| Load pos by Magic and Symbol
//+------------------------------------------------------------------+
uint CDKGridBase::Load(const long aMagic) {
  CDKPositionInfo pos;
  for(int i = 0; i < PositionsTotal(); i++) {
    if(!pos.SelectByIndex(i)) continue; // Pos not found
    if(pos.Symbol() != m_symbol.Name()) continue; // Wrong Symbol
    if (aMagic != 0 && pos.Magic() != aMagic) continue; // Wrong Magic
    
     Add(pos.Ticket());   
     m_id = GetIDFromComment(pos.Comment());
     m_id = (m_id == "") ? GetUniqueInstanceName("") : m_id;  
  }  
 
  return Size();
}

//+------------------------------------------------------------------+
//| Delete pos from grif by index
//+------------------------------------------------------------------+
uint CDKGridBase::Delete(const uint aIndex) {
  m_positions.Delete(aIndex);
  return Size();
}

//+------------------------------------------------------------------+
//| Clear grid pos
//+------------------------------------------------------------------+
void CDKGridBase::Clear() {
  m_positions.Clear();
}

//+------------------------------------------------------------------+
//| Returns cumulative state
//+------------------------------------------------------------------+
DKGridState CDKGridBase::GetState() {
  DKGridState state;

  state.Size          = Size();
  state.Volume        = 0;
  state.Sum           = 0;
  state.SumFull       = 0;
  state.Profit        = 0;
  state.Commission    = 0;
  state.Swap          = 0;
  for (uint i = 0; i < Size(); i++) {
    CDKPositionInfo pos;
    if (!Get(i, pos)) continue;
    
    state.Volume          += pos.Volume();
    state.Sum             += pos.Volume() * pos.PriceOpen();
    state.Profit          += pos.Profit();
    state.Commission      += pos.Commission();
    state.Swap            += pos.Swap();
  }

  state.SumFull        = state.Sum - state.Swap - state.Commission; // #todo sign mistake
  state.PriceAverage   = (state.Volume != 0) ? state.Sum / state.Volume : 0;
  state.PriceBreakEven = (state.Volume != 0) ? state.SumFull / state.Volume : 0;

  return state;
}

bool CDKGridBase::CheckEntry() {
  bool res = (m_max_pos_count < 0 || Size() < m_max_pos_count);
  Log(StringFormat("CDKGridBase::CheckEntry(): RES=%d | GRID=%s | SIZE=%d < MAX=%d", 
                   res, m_id, Size(), m_max_pos_count), DEBUG);  
  return res;
}

//+------------------------------------------------------------------+
//| Opens next pos 
//+------------------------------------------------------------------+
ulong CDKGridBase::OpenNext(const string aSymbol,                 // New pos symbol
                            const ENUM_POSITION_TYPE aDirection,  // New pos direction
                            const double aLots,                   // New pos lots
                            const double aPrice,                  // Open price
                            const double aSL,                     // New pos SL
                            const double aTP,                     // New pos TP
                            const string aComment) {              // New pos comment
  bool openRes;
  if(aDirection == POSITION_TYPE_BUY)  openRes = m_trade.Buy(aLots, aSymbol, aPrice, aSL, aTP, aComment);
  if(aDirection == POSITION_TYPE_SELL) openRes = m_trade.Sell(aLots, aSymbol, aPrice, aSL, aTP, aComment);
 
  if(openRes) {
    ulong openDeal = m_trade.ResultDeal();
    if (openDeal != 0) {
      Add(openDeal);
      Log(StringFormat("Position open: GRID=%s | TICKET=%I64u | SIZE=%d", m_id, openDeal, Size()), INFO);
    }
    else    
      Log(StringFormat("Position open error: ResultDeal()=0 | GRID=%s | SIZE=%d", m_id, Size()), ERROR);
  }
  else
    Log(StringFormat("Position open error: RETCODE=%d | GRID=%s | SIZE=%d", m_trade.ResultRetcode(), m_id, Size()), ERROR);
  
  return Size();
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos
//+------------------------------------------------------------------+
bool CDKGridBase::SetSLTP(double aSL, double aTP) {
  aSL = m_symbol.NormalizePrice(aSL);
  aTP = m_symbol.NormalizePrice(aTP);
  
  bool resHasError = false;
  for (uint i = 0; i < Size(); i++) {
    CDKPositionInfo pos;
    if (!Get(i, pos)) continue;
    
    // If SL and TP are the same then skip pos update
    double oldTP = pos.TakeProfit();
    double oldSL = pos.StopLoss();
    if (CompareDouble(oldTP, aTP) && CompareDouble(oldSL, aSL)) continue;
    
    if(m_trade.PositionModify(pos.Ticket(), aSL, aTP)) 
      if(TRADE_RETCODE_DONE == m_trade.ResultRetcode()) {
        Log(StringFormat("Position modified: GRID=%s | TICKET=%I64u | SIZE=%d | SL=%f | TP=%f", m_id, pos.Ticket(), Size(), aSL, aTP), INFO);
        continue;        
      }
    
    resHasError = true;
    Log(StringFormat("Position modify error: RETCODE=%d | GRID=%s | TICKET=%I64u | SIZE=%d | SL=%f | TP=%f", 
                     m_trade.ResultRetcode(), m_id, pos.Ticket(), Size(), aSL, aTP), ERROR);    
  }
    
  return resHasError;
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from avg price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromAveragePrice(const double aDistance) {
  DKGridState state = GetState();  
  Log(StringFormat("CDKGridBase::SetTPFromAveragePrice: GRID=%s| SIZE=%d | DISTANCE=%f | PRICE_AVG=%f", m_id, Size(), aDistance, state.PriceAverage), DEBUG);
  return SetSLTP(0, state.PriceAverage + aDistance);
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from avg price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromAveragePricePoint(const int aDistancePoint) {
  return SetTPFromAveragePrice(m_symbol.PointsToPrice(aDistancePoint));
}

//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from breakeven price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromBreakEven(const double aDistance) {
  DKGridState state = GetState();  
  Log(StringFormat("CDKGridBase::SetTPFromBreakEven: GRID=%s| SIZE=%d |DISTANCE=%f | BREAKEVEN=%f", m_id, Size(), aDistance, state.PriceBreakEven), DEBUG);
  return SetSLTP(0, state.PriceBreakEven + aDistance);
}
//+------------------------------------------------------------------+
//| Set SL/TP to all grid pos from avg price
//+------------------------------------------------------------------+
bool CDKGridBase::SetTPFromBreakEvenPoint(const int aDistancePoint) {
  return SetTPFromBreakEven(m_symbol.PointsToPrice(aDistancePoint));
}

//+------------------------------------------------------------------+
//| Return comment for frid pos by number
//+------------------------------------------------------------------+
string CDKGridBase::GetPosComment(const string aPrefix, const uint aNumber) {
  return StringFormat("%s|%s|%d", 
                      aPrefix, 
                      m_id, 
                      aNumber);
}

//+------------------------------------------------------------------+
//| Gets grid ID from pos comment
//+------------------------------------------------------------------+
string CDKGridBase::GetIDFromComment(const string aComment) {
  string arr[];
  if (StringSplit(aComment, StringGetCharacter("|", 0), arr) >= 2)
    return arr[1];
    
  return "";   
}

//+------------------------------------------------------------------+
//| Returns grid id
//+------------------------------------------------------------------+
string CDKGridBase::GetID() {
  return m_id;
}

//+------------------------------------------------------------------+
//| Returns grid summary text
//+------------------------------------------------------------------+
string CDKGridBase::GetDescription() {
  DKGridState state = GetState();
  return StringFormat("Size: %d\n"+
                      "Volume: %.2f\n"+  
                      "Sum: %.2f\n"+  
                      "Sum (incl. commision&swap): %.2f\n"+  
                      "Profit: %.2f\n"+  
                      "Commission: %.2f\n"+                                                                                                                      
                      "Swap: %.2f\n"+     
                      "Price average: %.5f\n"+     
                      "Price breakeven: %.5f\n",                                                                                          
                      
                      state.Size,
                      state.Volume,
                      state.Sum,
                      state.SumFull,
                      state.Profit,
                      state.Commission,
                      state.Swap,
                      state.PriceAverage,
                      state.PriceBreakEven);  
}