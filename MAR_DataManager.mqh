//+------------------------------------------------------------------+
//|                                              MAR_DataManager.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "MAR_DataWriter.mqh"
#include "MC_Common/MC_Common.mqh"

class DataManager {
    private:
    DataWriter *dWriters[];
    int dwCsvIds[];
    
    public:
    ~DataManager();
    
    int addDataWriter(DataWriterType dbType, int connectRetries=5, int connectRetryDelaySecs=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    
    bool hasCsv();
    
    void removeDataWriter(int index);
    void removeAllDataWriters();
    
    bool queryRun(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1, bool doAll = false);
    bool queryRunByIndex(int index, string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
};

void DataManager::~DataManager() {
    removeAllDataWriters();
}

bool DataManager::hasCsv() {
    return (ArraySize(dwCsvIds) > 0);
}

int DataManager::addDataWriter(DataWriterType dbType, int connectRetries=5, int connectRetryDelaySecs=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    int size = ArraySize(dWriters); // assuming 1-based
    ArrayResize(dWriters, size+1);
    
    dWriters[size] = new DataWriter(dbType, connectRetries, connectRetryDelaySecs, initCommon, param, param2, param3, param4, param5, param6, param7);
    
    if(dbType == DW_Csv) { MC_Common::ArrayPush(dwCsvIds, size); }
    
    return size;
}

void DataManager::removeDataWriter(int index) {
    if(CheckPointer(dWriters[index]) == POINTER_DYNAMIC) { delete(dWriters[index]); }
}

void DataManager::removeAllDataWriters() {
    int dWritersLength = ArraySize(dWriters);
    for(int i = 0; i < dWritersLength; i++) {
        removeDataWriter(i);
    }
    
    ArrayFree(dWriters);
}

bool DataManager::queryRunByIndex(int index, string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    return dWriters[index].queryRun(dataInput, forDbType, ignoreDbType);
}

bool DataManager::queryRun(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1, bool doAll = false) {
    int dWritersLength = ArraySize(dWriters);
    
    bool finalResult = false;
    for(int i = 0; i < dWritersLength; i++) {
        bool result = queryRunByIndex(i, dataInput, forDbType, ignoreDbType);
        if(result) { finalResult = true; }
        if(doAll && result) { return true; }
    }

    return finalResult;
}
