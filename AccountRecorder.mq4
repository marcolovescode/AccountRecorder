#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include "MC_Common/MC_Common.mqh"
#include "MC_Common/MC_Error.mqh"

#include "MAR_Settings.mqh"

#include "MAR_DataManager.mqh"

//+------------------------------------------------------------------+
DataManager *MainDataManager;

int OnInit() {
    MainDataManager = new DataManager();
    
    
    
    return INIT_SUCCEEDED;
}



void OnDeinit(const int reason) {
    if(CheckPointer(MainDataManager) == POINTER_DYNAMIC) { delete(MainDataManager); }
}
