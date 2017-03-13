#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#ifdef __MQL5__
#include "MC_Common/Mql4Shim.mqh"
//#define _X64 // define if building x64
//#define _X64 IsX64()
#else
#ifdef __MQL4__
//#define _X64 false
#endif
#endif

#define _LOCALRESOURCE // for MAR_Scripts.
    // If defined, this loads scripts from "MAR_Scripts/MAR_Scripts.mqh" into the text resource store.
    // MAR_Scripts.mqh can be generated using "MAR_Scripts/CompileScripts.ahk" run by AutoHotkey.
    //
    // If not defined, will load files directly in "MAR_Scripts/" folder. IMPORTANT NOTE:
    // you must create a hard link (aka directory junction) in MQL4/Files
    // to MQL4/Experts/[current folder if any]/MAR_Scripts
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
    Error::DebugLevel = ::DebugLevel;
    Error::LogAllErrorsToFile = ::LogAllErrorsToFile;
    Error::LogAllErrorsToTerminal = ::LogAllErrorsToTerminal;
    Error::FilePath = ::ErrorLogFileName;
    
    MAR_LoadScripts();
    
    Error::PrintInfo(ErrorInfo, "AccountRecorder");
    Error::PrintInfo(ErrorInfo, "Connecting to databases...");
    Comment("AccountRecorder\r\n"
        , "\r\n"
        , "Connecting to databases..."
        );
    
    AccountMan = new MainAccountRecorder();
    
    SetTimer(true);
    
    Error::PrintInfo(ErrorInfo, "Waiting for first run...");
    Comment("AccountRecorder\r\n"
        , "\r\n"
        , "Starting first run " + (DelayedEntrySeconds > 0 ? "in " + DelayedEntrySeconds + " seconds..." : "") + "\r\n"
        );
    
    return INIT_SUCCEEDED;
}

bool SetTimer(bool firstRun = false) {
    bool result = false;
    
    if(firstRun) {
        if(DelayedEntrySeconds > 0) { result = Common::EventSetTimerReliable(DelayedEntrySeconds); }
        else { result = Common::EventSetMillisecondTimerReliable(255); }
    } else {
        result = Common::EventSetTimerReliable(Common::GetGcd(OrderRefreshSeconds, EquityRefreshSeconds));
    }
    
    if(!result) {
        Error::ThrowFatalError(ErrorFatal, "Could not set run timer; try to reload the EA.", FunctionTrace);
    }
    
    return result;
}

void OnTimer() {
    EventKillTimer();
    
    if(FirstTimerRun) {
        if(AccountMan.doFirstRun()) { // this will fail if not connected or schema not verified
            FirstTimerRun = false;
            SetTimer(false);
        } else {
            SetTimer(true);
        }
    } else {
        AccountMan.doCycle();
        SetTimer(false);
    }
}

void OnDeinit(const int reason) {
    if(CheckPointer(AccountMan) == POINTER_DYNAMIC) { delete(AccountMan); }
}
