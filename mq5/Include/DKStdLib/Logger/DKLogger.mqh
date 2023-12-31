//+------------------------------------------------------------------+
//|                                                     DKLogger.mqh |
//|                                                  Denis Kislitsyn |
//|                                               http:/kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "http:/kislitsyn.me"

enum LogLevel  // перечисление именованных констант
{
  DEBUG=10,
  INFO=20,
  WARN=30,
  ERROR=40,
  CRITICAL=50,
};
   
class DKLogger
{
  public:
    string Name;
    LogLevel Level;

    DKLogger(void) {Level = LogLevel(INFO);};
    DKLogger(string LoggerName, LogLevel MessageLevel = LogLevel(INFO)) 
    {
      Name = LoggerName;
      Level = LogLevel(INFO);
    }
    
    void Log(string MessageTest, LogLevel MessageLevel = LogLevel(INFO))
    {
      if (MessageLevel >= Level) 
        Print("[", TimeLocal(), "]:", Name, ":[", EnumToString(MessageLevel), "] ", MessageTest);
    }; 
  
    void Debug(string MessageTest)
    {
      Log(MessageTest, LogLevel(DEBUG));
    };           

    void Info(string MessageTest)
    {
      Log(MessageTest, LogLevel(INFO));
    }; 
    
    void Warn(string MessageTest)
    {
      Log(MessageTest, LogLevel(WARN));
    };         
    
    void Error(string MessageTest)
    {
      Log(MessageTest, LogLevel(ERROR));
    };         
    
    void Critical(string MessageTest)
    {
      Log(MessageTest, LogLevel(CRITICAL));
    };  
    
    void Assert(const bool aCondition, const string aTestName) 
    {
      if (aCondition) Info(StringFormat("%s passed", aTestName));
      else Error(StringFormat("%s failed", aTestName));
    }               
};