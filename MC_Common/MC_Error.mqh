//+------------------------------------------------------------------+
//|                                                     MC_Error.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#define FunctionTrace StringConcatenate(__FILE__,"(",__LINE__,") ", __FUNCTION__)

enum ErrorLevel {
    ErrorNone,
    ErrorFatal,
    ErrorNormal,
    ErrorInfo
};

class MC_Error {
    public:
    static bool PrintAllFatalErrors;
    static int FatalCounter;
    static int DebugLevel;
    
    static void PrintError(int level, string message, string code, bool fatal, bool info, string params = "");
    static void ThrowError(int level, string message, string code, string params = "", bool fatal = false);
    static void ThrowFatalError(int level, string message, string code, string params = "");
    static void PrintInfo(int level, string message, string code, string params = "");
};

//#include "MMT_Settings.mqh"

bool MC_Error::PrintAllFatalErrors = false; // because ExpertRemove() does not exit an EA right away, further error messages will print when only the first one is useful.
int MC_Error::FatalCounter = 0;
int MC_Error::DebugLevel = 2; // user configurable

void MC_Error::PrintError(int level, string message, string code, bool fatal, bool info=false, string params = "") {
    // todo: alerts
    if(fatal && FatalCounter > 0 && !PrintAllFatalErrors) { return; } // if fatal, only print an error message once. 
    
    if(DebugLevel >= level || fatal) { 
        Print(fatal ? StringConcatenate(FatalCounter, " FATAL ") : "", 
            info ? "INFO: " : "ERROR: ", 
            code, " - ", 
            message,
            StringLen(params) > 0 ? StringConcatenate(" - PARAMS: ", params) : ""
            ); 
        } 
}

void MC_Error::ThrowError(int level, string message, string code, string params = "", bool fatal = false) {
    PrintError(level, message, code, fatal, false, params);
    if(fatal) { FatalCounter++; ExpertRemove(); } // this calls OnDeinit then exits. this won't exit right away; event handler will finish processing.
}

void MC_Error::ThrowFatalError(int level, string message, string code, string params = "") {
    ThrowError(level, message, code, params, true);
}

void MC_Error::PrintInfo(int level, string message, string code, string params = "") {
    PrintError(level, message, code, false, true, params);
}
