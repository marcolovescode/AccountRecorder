//+------------------------------------------------------------------+
//|                                              MAR_DataWriterManager.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "MAR_DataWriter.mqh"
#include "MC_Common/MC_Common.mqh"

class DataWriterManager {
    private:
    DataWriter *dWriters[];
    int dwCsvIds[];
    
    public:
    ~DataWriterManager();
    
    int addDataWriter(DataWriterType dbType, int connectRetries=5, int connectRetryDelaySecs=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    
    bool hasCsv();
    
    void removeDataWriter(int index);
    void removeAllDataWriters();
    
    bool queryRunByIndex(int index, string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    bool queryRun(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1, bool doAll = false);
    
    bool queryRetrieveRowsByIndex(int index, string query, string &result[][], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    bool queryRetrieveRows(string query, string &result[][], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    
    template<typename T>
    bool queryRetrieveOneByIndex(int index, string query, T &result, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);

    template<typename T>
    bool queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
};

void DataWriterManager::~DataWriterManager() {
    removeAllDataWriters();
}

bool DataWriterManager::hasCsv() {
    return (ArraySize(dwCsvIds) > 0);
}

int DataWriterManager::addDataWriter(DataWriterType dbType, int connectRetries=5, int connectRetryDelaySecs=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    int size = ArraySize(dWriters); // assuming 1-based
    ArrayResize(dWriters, size+1);
    
    dWriters[size] = new DataWriter(dbType, connectRetries, connectRetryDelaySecs, initCommon, param, param2, param3, param4, param5, param6, param7);
    
    if(dbType == DW_Csv) { MC_Common::ArrayPush(dwCsvIds, size); }
    
    return size;
}

void DataWriterManager::removeDataWriter(int index) {
    if(CheckPointer(dWriters[index]) == POINTER_DYNAMIC) { delete(dWriters[index]); }
}

void DataWriterManager::removeAllDataWriters() {
    int dWritersLength = ArraySize(dWriters);
    for(int i = 0; i < dWritersLength; i++) {
        removeDataWriter(i);
    }
    
    ArrayFree(dWriters);
}

bool DataWriterManager::queryRunByIndex(int index, string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { return false; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { return false; }
    
    return dWriters[index].queryRun(dataInput);
}

bool DataWriterManager::queryRun(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1, bool doAll = false) {
    int dWritersLength = ArraySize(dWriters);
    
    bool finalResult = false;
    for(int i = 0; i < dWritersLength; i++) {
        bool result = queryRunByIndex(i, dataInput, forDbType, ignoreDbType);
        if(result) { finalResult = true; }
        if(!doAll && result) { return true; }
    }

    return finalResult;
}

bool DataWriterManager::queryRetrieveRowsByIndex(int index, string query, string &result[][], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { return false; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { return false; }
    
    return dWriters[index].queryRetrieveRows(query, result);
}

bool DataWriterManager::queryRetrieveRows(string query, string &result[][], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    // todo: if doAll, then return a resultArray with all returned rows
    
    int dWritersLength = ArraySize(dWriters);
    
    bool callResult;
    for(int i = 0; i < dWritersLength; i++) {
        callResult = queryRetrieveRowsByIndex(i, query, result, forDbType, ignoreDbType);
        if(callResult) { return true; }
    }

    return false;
}

template<typename T>
bool DataWriterManager::queryRetrieveOneByIndex(int index, string query, T &result, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { return false; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { return false; }
    
    return dWriters[index].queryRetrieveOne(query, result, rowIndex);
}

template<typename T>
bool DataWriterManager::queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    int dWritersLength = ArraySize(dWriters);
    
    bool callResult;
    for(int i = 0; i < dWritersLength; i++) {
        callResult = queryRetrieveOneByIndex(i, query, result, rowIndex, forDbType, ignoreDbType);
        if(callResult) { return true; }
    }

    return false;
}
