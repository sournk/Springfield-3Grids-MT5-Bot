//+------------------------------------------------------------------+
//|                                                CDKSymbolInfo.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include <Trade\SymbolInfo.mqh>

class CDKSymbolInfo : public CSymbolInfo {
public:
  int                 PriceToPoints(const double aPrice);                              // Convert aPrice to price value for current Symbol
  double              PointsToPrice(const int aPoint);                                 // Convert aPoint to points for current Symbol
  
  double              GetPriceToOpen(const ENUM_POSITION_TYPE aPositionDirection);     // Returns market price Ask or Bid to OPEN new pos with aPositionDirection dir
  double              GetPriceToClose(const ENUM_POSITION_TYPE aPositionDirection);    // Returns market price Ask or Bid to CLOSE new pos with aPositionDirection dir
  
  double              NormalizeLot(double lot);                                        // Returns normalized lots size for symbol
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

//+------------------------------------------------------------------+
//| Convert aPrice to price value for current Symbol                 |
//+------------------------------------------------------------------+
int CDKSymbolInfo::PriceToPoints(const double aPrice) {
  RefreshRates();
  
  int dig = Digits();
  int dig2 = this.Digits();
  
  return((int)(aPrice * MathPow(10, Digits())));
}

//+------------------------------------------------------------------+
//| Convert aPoint to points for current Symbol                      |
//+------------------------------------------------------------------+
double CDKSymbolInfo::PointsToPrice(const int aPoint) {
  RefreshRates();
  
  return(NormalizeDouble(aPoint * this.Point(), this.Digits()));
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Market Price Operations
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

double CDKSymbolInfo::GetPriceToOpen(const ENUM_POSITION_TYPE aPositionDirection) {
  RefreshRates();
  
  if (aPositionDirection == POSITION_TYPE_BUY)  return Ask();
  if (aPositionDirection == POSITION_TYPE_SELL) return Bid();
  return 0;   
}

double CDKSymbolInfo::GetPriceToClose(const ENUM_POSITION_TYPE aPositionDirection) {
  RefreshRates();
  
  if (aPositionDirection == POSITION_TYPE_BUY)  return Bid();
  if (aPositionDirection == POSITION_TYPE_SELL) return Ask();
  return 0;   
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Lots Size Operations
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

double CDKSymbolInfo::NormalizeLot(double lot) {
  RefreshRates();
  
  lot =  NormalizeDouble(lot, Digits());
  double lotStep = LotsStep();
  return floor(lot / lotStep) * lotStep;
}