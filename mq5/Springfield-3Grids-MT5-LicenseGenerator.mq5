//+------------------------------------------------------------------+
//|                                                     Research.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"
#property version   "1.0.1"
#property description "License Key Generator Tool For Springfield-3Grids-MT5-Bot.v1*"

#property script_show_inputs

          string                   InpLicenseSalt  = "Springfield-3Grids-MT5-Bot.v1.mq5";  // Salt
          
input     group                    "CREATE NEW LICENSE KEY"
input     long                     InpAccount;                                             // License for account number 
input     datetime                 InpExpiryDate;                                          // Licence expiry date (inlcluded). Time is ignored.
//input     string                   InpLicenseToCheck;
          
#include <Trade\AccountInfo.mqh>
#include "Include\DKStdLib\License\DKLicense.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
  //CAccountInfo account;
  //Print(IsLicenseValid(InpLicenseToCheck, account.Login(), InpLicenseSalt));

  if (InpAccount <= 0) {
    Print("Wrong account number to create license key");
    return;
  }
  
  if (InpExpiryDate < TimeCurrent()) {
    Print("Expiry date is the past. Cannot create license key");
    return;
  }
  
  Print(StringFormat("Licence key for %I64u account with %s expiry date is in the next line:", 
                     InpAccount, TimeToString(InpExpiryDate, TIME_DATE)));
  Print(LicenseToString(InpAccount, InpExpiryDate, InpLicenseSalt)); 
}
  
