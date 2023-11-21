//+------------------------------------------------------------------+
//|                                         CDKGridOneDirStepPos.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include <Arrays\ArrayObj.mqh>
#include <Generic\HashMap.mqh>

#include "CDKPositionInfo.mqh"
#include "CDKGridBase.mqh"

//+------------------------------------------------------------------+
//| Class for One Directoion Grid with the step opening positions 
//| 1. You can set deafult step between pos or set specific
//|    step for every next pos by idx. For example, you can
//|    specify step to open 6th order in grid using
//|    SetStep(5, points), where 5 is current grid size before opening.
//| 2. Use same approach to take profits distance. It can be different 
//|    for direfferent grid sizes.
//| 3. All the same for volume ratio to open next order.
//| 4. CDKGridOneDirStepPos uses volume of last order in the grid as
//|    as base volume to multiply to ratio. You can override 
//|    GetBaseVolumeForNextPosition() to change volume base for your grid.
//+------------------------------------------------------------------+
class CDKGridOneDirStepPos : public CDKGridBase {
private:
  ENUM_POSITION_TYPE       m_dir;
  double                   m_init_lots;
  int                      m_step_default;
  CHashMap <uint, int>     m_step;  
  
  double                   m_ratio_default;
  CHashMap <uint, double>  m_ratio;  
  
  int                      m_tp_default;
  CHashMap <uint, int>     m_tp;    
public:
  void              Init(const string aSymbol,
                         const ENUM_POSITION_TYPE aDirection,
                         const uint aMaxPositionCount,
                         const double aInitialLotsSize, 
                         const int aDefaultStepPoint,
                         const double aDefaultRatio,
                         const int aDefaultTakeProfit,
                         const string aCommentPrefix,
                         CTrade& Trade);                                     // Preconfigurated CTrade
                         
  uint              Load(const long aMagic);                                 // Load all open positions by Magic                         
  
  void              SetDirection(const ENUM_POSITION_TYPE aDirection);       // Set grid direction. WARNING: Change sirection of non empty grid is dangerous
  ENUM_POSITION_TYPE GetDirection();                                         // Get current direction
                           
  void              SetDefaultStep(const int aStepPoint);                    // Set default step in point to next position
  void              SetStep(const uint aGridSize, const int aStepPoint);     // Set step in point to every position. Step set for next order when grid size = aGridSize
  int               GetStep(const uint aIdx);                                // Returns step in point to pos with aIdx
  int               GetStepLast();                                           // Returns step in point to last pos

  void              SetDefaultRatio(const double aRatio);                    // Set default lots ratio to next position
  void              SetRatio(const uint aGridSize, const double aRatio);     // Set ration to every position. Ratio set for next order when grid size = aGridSize
  double            GetRatio(const uint aIdx);                               // Returns ration to pos with aIdx
  double            GetRatioLast();                                          // Returns ratio to last pos
  
  
  void              SetDefaultTakeProfit(const int aTakeProfitPoint);                    // Set default TP from grid BE in point to next position
  void              SetTakeProfit(const uint aGridSize, const int aTakeProfitPoint);     // Set TP from grid BE in point to every position. Step set for next order when grid size = aGridSize
  int               GetTakeProfit(const uint aIdx);                                      // Returns step in point to pos with aIdx
  int               GetTakeProfitLast();                                                 // Returns step in point to last pos

  double            GetBaseVolumeForNextPosition();                           // Returns base of volume to calc lots of next pos

  bool              CheckEntry();                                             // Check is entry for next grid position allowed
  ulong             OpenNext(const bool aIgnoreEntryCheck = false);           // Opens next position check entry before. To ignore check use aIgnoreEntryCheck=true
  
  bool              SetTPFromAverage();                                       // Set TP from Average grid price + TP distance
  bool              SetTPFromBreakEven();                                     // Set TP from Breakeven + TP distance
  
  string            GetDescription();                                         // Get description string
};

//+------------------------------------------------------------------+
//| Init
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::Init(const string aSymbol,
                                             const ENUM_POSITION_TYPE aDirection,
                                             const uint aMaxPositionCount,
                                             const double aInitialLotsSize, 
                                             const int aDefaultStepPoint,
                                             const double aDefaultRatio,
                                             const int aDefaultTakeProfit,
                                             const string aCommentPrefix,
                                             CTrade& aTrade){
  CDKGridBase::Init(aSymbol, aMaxPositionCount, aCommentPrefix, aTrade);
  
  m_dir = aDirection;
  m_init_lots = aInitialLotsSize;
  SetDefaultStep(aDefaultStepPoint);
  SetDefaultRatio(aDefaultRatio);
  SetDefaultTakeProfit(aDefaultTakeProfit);
}

//+------------------------------------------------------------------+
//| Load: Add all open post to grid by Magic and Symbol
//+------------------------------------------------------------------+
uint CDKGridOneDirStepPos::Load(const long aMagic) {
  uint sizeBefore = Size();
  
  // Put Direction to last add pos direction
  if (CDKGridBase::Load(aMagic) > 0) {
    CDKPositionInfo pos;
    if (GetLast(pos)  && m_dir != pos.PositionType()) {
      m_dir = pos.PositionType();
      Log(StringFormat("Grid direction changed by loaded position: GRID=%s | DIR=%s", m_id, EnumToString(m_dir)), WARN);
    }
  }
  
  return Size();
}

//+------------------------------------------------------------------+
//| SetDirection
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetDirection(const ENUM_POSITION_TYPE aDirection){
  m_dir = aDirection;
} 

//+------------------------------------------------------------------+
//| GetDirection
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE CDKGridOneDirStepPos::GetDirection(){
  return m_dir;
} 

//+------------------------------------------------------------------+
//| SetDefaultStep
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetDefaultStep(const int aStepPoint) {
  m_step_default = aStepPoint;
}

//+------------------------------------------------------------------+
//| SetStep for specific pos in grid by idx
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetStep(const uint aGridSize, const int aStepPoint) {
  m_step.Add(aGridSize, aStepPoint);
}

//+------------------------------------------------------------------+
//| GetStep
//+------------------------------------------------------------------+
int CDKGridOneDirStepPos::GetStep(const uint aIdx) {
  int value = 0;
  if (m_step.TryGetValue(aIdx, value))
    return value;
   
  return m_step_default;
}

//+------------------------------------------------------------------+
//| GetStep for last grid order
//+------------------------------------------------------------------+
int CDKGridOneDirStepPos::GetStepLast(){
  return GetStep(Size() - 1);
}

//+------------------------------------------------------------------+
//| GetSetDefaultRatio
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetDefaultRatio(const double aRatio) {
  m_ratio_default = aRatio;
}

//+------------------------------------------------------------------+
//| SetRatio
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetRatio(const uint aGridSize, const double aRatio) {
  m_ratio.Add(aGridSize, aRatio);
}

//+------------------------------------------------------------------+
//| GetRatio
//+------------------------------------------------------------------+
double CDKGridOneDirStepPos::GetRatio(const uint aIdx) {
  double value = 0;
  if (m_ratio.TryGetValue(aIdx, value))
    return value;
   
  return m_ratio_default;
}

//+------------------------------------------------------------------+
//| GetRatio for last grid order
//+------------------------------------------------------------------+
double CDKGridOneDirStepPos::GetRatioLast(){
  return GetRatio(Size() - 1);
}

//+------------------------------------------------------------------+
//| SetDefaultTakeProfit
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetDefaultTakeProfit(const int aTakeProfitPoint) {
  m_tp_default = aTakeProfitPoint;
}

//+------------------------------------------------------------------+
//| SetTakeProfit
//+------------------------------------------------------------------+
void CDKGridOneDirStepPos::SetTakeProfit(const uint aGridSize, const int aTakeProfitPoint) {
  m_tp.Add(aGridSize, aTakeProfitPoint);
}

//+------------------------------------------------------------------+
//| GetTakeProfit
//+------------------------------------------------------------------+
int CDKGridOneDirStepPos::GetTakeProfit(const uint aIdx) {
  int value = 0;
  if (m_tp.TryGetValue(aIdx, value))
    return value;
   
  return m_tp_default;
}

//+------------------------------------------------------------------+
//| GetTakeProfitLast
//+------------------------------------------------------------------+
int CDKGridOneDirStepPos::GetTakeProfitLast(){
  return GetTakeProfit(Size() - 1);
}

//+------------------------------------------------------------------+
//| CheckEntry. Return true if size < Max and price passed step
//+------------------------------------------------------------------+
bool CDKGridOneDirStepPos::CheckEntry() {
  // Grid size less max
  if (!CDKGridBase::CheckEntry()) return false;
  
  // Grid is not empty. So check step to next order
  if (Size() > 0) {
    CDKPositionInfo lastPos;
    if (!GetLast(lastPos)) return false;
    
    int delta = lastPos.GetWorsenedtPriceDeltaPoint();
    int step = GetStepLast();
    
    Log(StringFormat("CDKGridOneDirStepPos::CheckEntry(): RES=%d | GRID=%s | SIZE=%d | CURR_DELTA=%d >= STEP=%d", 
                     delta > step, m_id, Size(), delta, step), (delta > step) ? INFO : DEBUG);  
    if (delta < step)
      return false;
  }
  
  return true;
}

//+------------------------------------------------------------------+
//| GetBaseVolumeForNextPosition returns a base to calc next pos volume
//+------------------------------------------------------------------+
double CDKGridOneDirStepPos::GetBaseVolumeForNextPosition() {
  if (Size() > 0) {
    CDKPositionInfo pos;
    if (!GetLast(pos)) return 0;
    return pos.Volume();
  }  
  
  return 0;
}

//+------------------------------------------------------------------+
//| Opens next pos
//+------------------------------------------------------------------+
ulong CDKGridOneDirStepPos::OpenNext(const bool aIgnoreEntryCheck = false) {
  if (!aIgnoreEntryCheck && !CheckEntry())
    return 0;
    
  double lotSize = m_init_lots;
  if (Size() > 0) lotSize =  GetBaseVolumeForNextPosition() * GetRatioLast();
  
  lotSize = m_symbol.NormalizeLot(lotSize);
  
  if (Size() == 0) m_id = GetUniqueInstanceName(""); // Create new grid ID for 1st pos
  return CDKGridBase::OpenNext(m_symbol.Name(),
                               m_dir,
                               lotSize,
                               0, // Open by current price
                               0, // No SL
                               0, // No TP
                               CDKGridBase::GetPosComment(m_comment_prefix, Size() + 1));
}

//+------------------------------------------------------------------+
//| Set TP to all grid orders from Average price
//+------------------------------------------------------------------+
bool CDKGridOneDirStepPos::SetTPFromAverage() {
  int distance = GetTakeProfitLast() * ((m_dir == POSITION_TYPE_BUY) ? +1 : -1);
  return CDKGridBase::SetTPFromAveragePricePoint(distance);
}

//+------------------------------------------------------------------+
//| Set TP to all grid orders from Breakeven price
//+------------------------------------------------------------------+
bool CDKGridOneDirStepPos::SetTPFromBreakEven() {
  int distance = GetTakeProfitLast() * ((m_dir == POSITION_TYPE_BUY) ? +1 : -1);
  return CDKGridBase::SetTPFromBreakEvenPoint(distance);
}

//+------------------------------------------------------------------+
//| Returns grid summary text
//+------------------------------------------------------------------+
string CDKGridOneDirStepPos::GetDescription() {
  string res = CDKGridBase::GetDescription();
  
  int dist = 0;
  CDKPositionInfo pos;
  if (GetLast(pos)) dist = pos.GetPriceDeltaCurrentAndOpenToOpenPoint();
  
  return res + StringFormat("Distance from last order: %d\n", dist);
}