//+------------------------------------------------------------------+
//|                                                     MAR_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "MAR_DataWriterManager.mqh"
#include "MAR_Settings.mqh"

class MainAccountRecorder {
    private:
    DataWriterManager *dWriterMan;
    
    public:
    void MainAccountRecorder();
    void ~MainAccountRecorder();
};

void MainAccountRecorder::MainAccountRecorder() {
    dWriterMan = new DataWriterManager();
}

void MainAccountRecorder::~MainAccountRecorder() {
    if(CheckPointer(dWriterMan) == POINTER_DYNAMIC) { delete(dWriterMan); }
}

