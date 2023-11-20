//+------------------------------------------------------------------+
//|                                                CDKSymbolInfo.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include <Trade\PositionInfo.mqh>
#include "CDKSymbolInfo.mqh"

class CDKPositionInfo : public CPositionInfo {
private:
  CDKSymbolInfo                      m_symbol;
public:
  double                             GetPriceDeltaCurrentAndOpenToOpen();                   // Returns delta between pos current price and pos open price to OPEN new pos with same dir
  int                                GetPriceDeltaCurrentAndOpenToOpenPoint();              // Returns delta in point between pos current price and pos open price to OPEN new pos with same dir
  
  double                             GetPriceDeltaCurrentAndOpenToClose();                  // Returns delta between pos current price and pos open price to CLOSE new pos with same dir
  int                                GetPriceDeltaCurrentAndOpenClosePoint();               // Returns delta in points between pos current price and pos open price to CLOSE new pos with same dir
  
  double                             GetImprovedtPriceDelta();                              // Rerurns positive number of price delta if it's improved after the pos opening
  int                                GetImprovedtPriceDeltaPoint();                         // Rerurns positive number of price delta in points if it's improved after the pos opening
  
  double                             GetWorsenedtPriceDelta();                              // Rerurns positive number of price delta if it's worsened after the pos opening
  int                                GetWorsenedtPriceDeltaPoint();                         // Rerurns positive number of price delta in points if it's improved after the pos opening  
};

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Price Operations
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

double CDKPositionInfo::GetPriceDeltaCurrentAndOpenToOpen() {
  m_symbol.Name(Symbol());
  return m_symbol.GetPriceToOpen(PositionType()) - PriceOpen();
}

int CDKPositionInfo::GetPriceDeltaCurrentAndOpenToOpenPoint() {
  m_symbol.Name(Symbol());
  return m_symbol.PriceToPoints(GetPriceDeltaCurrentAndOpenToOpen());
}

double CDKPositionInfo::GetPriceDeltaCurrentAndOpenToClose(){
  m_symbol.Name(Symbol());
  return m_symbol.GetPriceToClose(PositionType()) - PriceOpen();
}

int CDKPositionInfo::GetPriceDeltaCurrentAndOpenClosePoint() {
  m_symbol.Name(Symbol());
  return m_symbol.PriceToPoints(GetPriceDeltaCurrentAndOpenToClose());
}

double CDKPositionInfo::GetImprovedtPriceDelta() {
  double delta = GetPriceDeltaCurrentAndOpenToOpen();
  if(PositionType() == POSITION_TYPE_BUY)  return (delta > 0) ? delta : 0;
  if(PositionType() == POSITION_TYPE_SELL) return (delta > 0) ? 0 : -1 * delta;
  
  return 0;
}

int CDKPositionInfo::GetImprovedtPriceDeltaPoint() {
  m_symbol.Name(Symbol());
  return m_symbol.PriceToPoints(GetImprovedtPriceDelta());
}

double CDKPositionInfo::GetWorsenedtPriceDelta() {
  double delta = GetPriceDeltaCurrentAndOpenToOpen();
  if(PositionType() == POSITION_TYPE_BUY)  return (delta > 0) ? 0 : -1 * delta;
  if(PositionType() == POSITION_TYPE_SELL) return (delta > 0) ? delta : 0;
  
  return 0;
}

int CDKPositionInfo::GetWorsenedtPriceDeltaPoint() {
  return m_symbol.PriceToPoints(GetWorsenedtPriceDelta());
}