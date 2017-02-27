#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

// _LOCALRESOURCE uses SQL scripts stored in MAR_SCRIPTS/MAR_SCRIPTS.mqh
// instead of loading them by actual files.
// Note that not all SQL statements are stored in scripts -- just the long ones.
//
// Enable this for production (no need for external SQL scripts)
// Disable this (comment out) for development and testing.
//
// For production, you need to update MAR_Scripts.mqh to latest scripts.
//
// IMPORTANT NOTE: If you load by actual files, you need to
// create a hard link (aka directory junction) in MQL4/Files
// to MQL4/Experts/M_AccountRecorder/MAR_Scripts
// to bypass the FileOpen sandbox imposed by MT4

//#define _LOCALRESOURCE

#include "MC_Common/MC_Common.mqh"
#include "MC_Common/MC_Error.mqh"
#include "MAR_Settings.mqh"
#include "MAR_Main.mqh"

bool FirstTimerRun = true;

//+------------------------------------------------------------------+
//MainAccountRecorder *AccountMan;

int OnInit() {
    MC_Error::DebugLevel = DebugLevel;
    ResourceMan = new ResourceStore();
    
#ifdef _LOCALRESOURCE

#else
    ResourceMan.loadTextResource("MAR_Scripts/Schema_Orders_Sqlite.sql");
    ResourceMan.loadTextResource("MAR_Scripts/Schema_Orders_Postgres.sql");
    ResourceMan.loadTextResource("MAR_Scripts/Schema_Orders_Mysql.sql");
#endif
    
    AccountMan = new MainAccountRecorder();
    
    if(DelayedEntrySeconds > 0) { EventSetTimer(DelayedEntrySeconds); }
    else { EventSetMillisecondTimer(255); }
    
    return INIT_SUCCEEDED;
}

void OnTimer() {
    if(FirstTimerRun) {
        EventKillTimer();
        AccountMan.doFirstRun();
        FirstTimerRun = false;
        EventSetTimer(MC_Common::GetGcd(OrderRefreshSeconds, EquityRefreshSeconds));
    } else {
        AccountMan.doCycle();
    }
}

void OnDeinit(const int reason) {
    if(CheckPointer(ResourceMan) == POINTER_DYNAMIC) { delete(ResourceMan); }
    if(CheckPointer(AccountMan) == POINTER_DYNAMIC) { delete(AccountMan); }
}
