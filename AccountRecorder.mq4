#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include "MC_Common/MC_Common.mqh"
#include "MC_Common/MC_Error.mqh"

#include "MAR_Main.mqh"
#include "MC_Common/MC_Resource.mqh"

//+------------------------------------------------------------------+
MainAccountRecorder *AccountMan;
ResourceStore *ResourceMan;

int OnInit() {
    ResourceMan = new ResourceStore();
    AccountMan = new MainAccountRecorder();
    
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if(CheckPointer(ResourceMan) == POINTER_DYNAMIC) { delete(ResourceMan); }
    if(CheckPointer(AccountMan) == POINTER_DYNAMIC) { delete(AccountMan); }
}
