//+------------------------------------------------------------------+
//|                                                 DKGrids_Test.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"
#property version   "1.0.0"

#include <Trade\Trade.mqh>

#include <DKStdLib\Logger\DKLogger.mqh>;
#include <DKStdLib\Common\DKStdLib.mqh>;
#include "CDKPositionInfo.mqh";
#include "CDKGridBase.mqh";
#include "CDKGridOneDirectionalStepPosition.mqh";

DKLogger m_logger;

void Test_CheckGridSize10_WithNoMaxLimit0() {
  CDKGridBase base_grid;
    
  for (int i=1; i <= 10; i++) {
    CDKPositionInfo* pos = new CDKPositionInfo;
    base_grid.Add(pos);
  }
  
  m_logger.Assert(base_grid.Size() == 10, __FUNCTION__);
}

void Test_CheckGridSize10_WithLimit10() {
  CDKGridBase base_grid;
    
  for (int i=1; i <= 10; i++) {
    CDKPositionInfo* pos = new CDKPositionInfo;
    base_grid.Add(pos);
  }
  
  m_logger.Assert(base_grid.Size() == 10, __FUNCTION__);
}

void Test_CheckGridSize10_AfterAdding20Pos_WithLimit10() {
  CDKGridBase base_grid;
  
  base_grid.SetMaxPositionCount(10);
  for (int i=1; i <= 20; i++) {
    CDKPositionInfo* pos = new CDKPositionInfo;
    base_grid.Add(pos);
  }
  
  m_logger.Assert(base_grid.Size() == 10, __FUNCTION__);
}

void Test_CheckGridSize3_AddOpenPositionFroimMarket_Lim2() {
  CTrade trade;
  trade.SetExpertMagicNumber(123456);
  for (int i=1; i <= 3; i++) {
    // #todo Open 3 market pos with 123456 magic   
    trade.Buy(0.01);
  }
  
  CDKGridBase base_grid;  
  base_grid.SetMaxPositionCount(2);

  base_grid.AddOpenPositions(123456, "");  
  
  m_logger.Assert(base_grid.Size() == 3, __FUNCTION__);
}

void Test_CheckGetState_3MarketPos() {
  CTrade trade;
  trade.SetExpertMagicNumber(1234567);
  for (int i=1; i <= 3; i++) {
    // #todo Open 3 market pos with 123456 magic   
    trade.Buy(0.01);
  }
  
  CDKGridBase base_grid;  
  base_grid.SetMaxPositionCount(2);

  base_grid.AddOpenPositions(1234567, "");  
  
  DKGridState grid_state = base_grid.GetState();
  
  m_logger.Assert((grid_state.Size == 3 && 
                   grid_state.Volume == 0.03), __FUNCTION__);
}




//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
  m_logger.Name = __FILE__;
  m_logger.Level = LogLevel(DEBUG);
   
  Test_CheckGridSize10_WithNoMaxLimit0();
  Test_CheckGridSize10_WithLimit10();
  Test_CheckGridSize10_AfterAdding20Pos_WithLimit10();  
  
  Test_CheckGridSize3_AddOpenPositionFroimMarket_Lim2();
  Test_CheckGetState_3MarketPos();
  }
//+------------------------------------------------------------------+
