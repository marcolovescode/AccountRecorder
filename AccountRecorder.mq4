#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#define _LOCALRESOURCE // for MAR_Scripts. Comment out to force reading SQL scripts from directory instead of internally
    // If defined, this loads scripts from "MAR_Scripts/MAR_Scripts.mqh" into the text resource store. See "MAR_Main.mqh"
    // MAR_Scripts.mqh can be generated using "MAR_Scripts/CompileScripts.ahk" run by AutoHotkey.
    //
    // IMPORTANT NOTE: If you load by actual files, you need to
    // create a hard link (aka directory junction) in MQL4/Files
    // to MQL4/Experts/M_AccountRecorder/MAR_Scripts
    // to bypass the FileOpen sandbox imposed by MT4

#include "MC_Common/MC_Common.mqh"
#include "MC_Common/MC_Error.mqh"

#include "MC_Common/MC_Resource.mqh"
#ifdef _LOCALRESOURCE
    #include "MAR_Scripts/MAR_Scripts.mqh"
#else
    void function MAR_LoadScripts() { }
#endif

#include "MAR_Settings.mqh"
#include "MAR_Main.mqh"

bool FirstTimerRun = true;

//+------------------------------------------------------------------+
//MainAccountRecorder *AccountMan;

int OnInit() {
    MC_Error::DebugLevel = DebugLevel;
    MC_Error::LogAllErrorsToFile = LogAllErrorsToFile;
    MC_Error::FilePath = ErrorLogFileName;
    
    MAR_LoadScripts();
    
    AccountMan = new MainAccountRecorder();
    
    if(DelayedEntrySeconds > 0) { MC_Common::EventSetTimerReliable(DelayedEntrySeconds); }
    else { MC_Common::EventSetMillisecondTimerReliable(255); }
    
    return INIT_SUCCEEDED;
}

void OnTimer() {
    if(FirstTimerRun) {
        if(AccountMan.doFirstRun()) { // this will fail if not connected or schema not verified
            EventKillTimer();
            FirstTimerRun = false;
            MC_Common::EventSetTimerReliable(MC_Common::GetGcd(OrderRefreshSeconds, EquityRefreshSeconds));
        }    
    } else {
        AccountMan.doCycle();
    }
}

void OnDeinit(const int reason) {
    if(CheckPointer(AccountMan) == POINTER_DYNAMIC) { delete(AccountMan); }
}
