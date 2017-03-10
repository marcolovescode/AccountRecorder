//+------------------------------------------------------------------+
//|                                              MAR_DataWriterManager.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#include "MD_DataWriter.mqh"
#include "../MC_Common/MC_Common.mqh"

class DataWriterManager {
    public:
    ~DataWriterManager();
    
    int addDataWriter(DataWriterType dbType, int connectRetries=5, int connectRetryDelaySecs=1, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    void removeDataWriter(int index);
    void removeAllDataWriters();
    
    bool queryRunByIndex(int index, string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    bool queryRun(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1, bool doAll = false);
    
    bool queryRetrieveRowsByIndex(int index, string query, string &result[][], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    bool queryRetrieveRows(string query, string &result[][], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    
    template<typename T>
    bool queryRetrieveOneByIndex(int index, string query, T &result, bool &skipped, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    template<typename T>
    bool queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);

    bool scriptRunByIndex(int index, string &scriptSrc[], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    bool scriptRun(string &scriptSrc[], DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1, bool doAll = false);
    
//    bool scriptRetrieveRowsByIndex();
//    bool scriptRetrieveRows();
//    
//    bool scriptRetrieveOneByIndex();
//    bool scriptRetrieveOne();

    template<typename T>
    bool queryRunConditional(string ifQuery, T &outParam, string thenQuery = NULL, string elseQuery = NULL, T ifParam = NULL, T thenParam = NULL, T elseParam = NULL, DataWriterType forDbType=-1, DataWriterType ignoreDbType=-1, bool doAll = false);
    template<typename T>
    bool queryRunConditional(string ifQuery, T &outParam, bool &outResult, string thenQuery = NULL, string elseQuery = NULL, T ifParam = NULL, T thenParam = NULL, T elseParam = NULL, DataWriterType forDbType=-1, DataWriterType ignoreDbType=-1, bool doAll = false);
    //bool queryRunConditional(string ifQuery, string &outParam[], string &thenQuery[], string &elseQuery[], string &ifParam[], string &thenParam[], string &elseParam[], DataWriterType forDbType=-1, DataWriterType ignoreDbType=-1);


    void resetBlockingErrorByIndex(int index, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    void resetBlockingErrors(DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);

    bool hasCsv();
    
    void freeMemoryByIndex(int index, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    void freeMemory(DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);

    private:
    DataWriter *dWriters[];
    int dwCsvIds[];
};

void DataWriterManager::~DataWriterManager() {
    removeAllDataWriters();
}

int DataWriterManager::addDataWriter(DataWriterType dbType, int connectRetries=5, int connectRetryDelaySecs=1, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    int size = ArraySize(dWriters); // assuming 1-based
    ArrayResize(dWriters, size+1);
    
    dWriters[size] = new DataWriter(dbType, connectRetries, connectRetryDelaySecs, param, param2, param3, param4, param5, param6, param7);
    
    if(dbType == DW_Csv) { Common::ArrayPush(dwCsvIds, size); }
    
    return size;
}

void DataWriterManager::removeDataWriter(int index) {
    if(CheckPointer(dWriters[index]) == POINTER_DYNAMIC) { delete(dWriters[index]); }
}

void DataWriterManager::removeAllDataWriters() {
    int dWritersLength = ArraySize(dWriters);
    for(int i = 0; i < dWritersLength; i++) {
        dWriters[i].disconnect();
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
    int failures = 0;
    
    bool finalResult = doAll;
    for(int i = 0; i < dWritersLength; i++) {
        bool result = queryRunByIndex(i, dataInput, forDbType, ignoreDbType);
        if(doAll && !result) {
            //Error::ThrowError(ErrorNormal, "Query run failed for " + EnumToString(dWriters[i].dbType), FunctionTrace);
            failures++;
        }
        if(!doAll && result) { return true; }
    }
    
    if(failures == dWritersLength) { finalResult = false; }

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
bool DataWriterManager::queryRetrieveOneByIndex(int index, string query, T &result, bool &skipped, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { skipped = true; return false; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { skipped = true; return false; }
    skipped = false;
    
    return dWriters[index].queryRetrieveOne(query, result, rowIndex);
}

template<typename T>
bool DataWriterManager::queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    int dWritersLength = ArraySize(dWriters);
    
    bool callResult; T queryResult; bool skipped;
    for(int i = 0; i < dWritersLength; i++) {
        callResult = queryRetrieveOneByIndex(i, query, queryResult, skipped, rowIndex, forDbType, ignoreDbType);
        if(callResult) { 
            result = queryResult; 
            return true; 
        }
    }

    return false;
}

bool DataWriterManager::scriptRunByIndex(int index,string &scriptSrc[],DataWriterType forDbType=-1,DataWriterType ignoreDbType=-1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { return false; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { return false; }
    
    int scriptLines = ArraySize(scriptSrc);
    string query = ""; string subclause = ""; bool finalResult = false;
    
    for(int i = 0; i < scriptLines; i++) {
        subclause = Common::StringTrim(scriptSrc[i]);
        
        if(StringLen(subclause) > 0) { query += " " + subclause; }
        if(StringFind(query, ";", StringLen(query)-1) > 0) {
            if(dWriters[index].queryRun(query)) { finalResult = true; }
            query = "";
        }
        
    }
    
    return finalResult;
}

bool DataWriterManager::scriptRun(string &scriptSrc[],DataWriterType forDbType=-1,DataWriterType ignoreDbType=-1,bool doAll=false) {
    int dWritersLength = ArraySize(dWriters);
    
    bool callResult; bool finalResult;
    for(int i = 0; i < dWritersLength; i++) {
        callResult = scriptRunByIndex(i, scriptSrc, forDbType, ignoreDbType);
        if(callResult) { finalResult = true; }
        if(!doAll && finalResult) { return true; }
    }

    return finalResult;
}

template<typename T>
bool DataWriterManager::queryRunConditional(string ifQuery, T &outParam, string thenQuery = NULL, string elseQuery = NULL, T ifParam = NULL, T thenParam = NULL, T elseParam = NULL, DataWriterType forDbType=-1, DataWriterType ignoreDbType=-1, bool doAll = false) {
    bool outResult = false;
    
    return queryRunConditional(ifQuery, outParam, outResult, thenQuery, elseQuery, ifParam, thenParam, elseParam, forDbType, ignoreDbType, doAll);
}

template<typename T>
bool DataWriterManager::queryRunConditional(string ifQuery, T &outValue, bool &outResult, string thenQuery = NULL, string elseQuery = NULL, T ifParam = NULL, T thenParam = NULL, T elseParam = NULL, DataWriterType forDbType=-1, DataWriterType ignoreDbType=-1, bool doAll = false) {
    bool returnResult = true;
    //outValue = NULL; // TODO: this probably breaks things, comment out for now
    outResult = false;
    
    int failures = 0;
    int dWriterCount = ArraySize(dWriters);
    bool halt = false; bool masterFilled = false;
    bool callResult[]; T callValue[]; bool callSkipped[];
    for(int i = 0; i < dWriterCount; i++) {
        T curCallValue = NULL; bool curCallSkipped = false;
        bool curCallResult = queryRetrieveOneByIndex(i, ifQuery, curCallValue, curCallSkipped, 0, forDbType, ignoreDbType);
        
        Common::ArrayPush(callSkipped, curCallSkipped);
        Common::ArrayPush(callResult, curCallResult);
        Common::ArrayPush(callValue, curCallValue);
        
        if(curCallResult && !masterFilled) {
            outResult = curCallResult;
            outValue = curCallValue;
            masterFilled = true;
        }
    }
    
    if(outResult && (outValue == NULL || typename(outValue) == "string" ? StringLen(outValue) <= 0 : false)) { 
        Print("BREAK"); 
    }
    
    if(outResult) {
        if(thenQuery != NULL || typename(thenQuery) == "string" ? StringLen(thenQuery) > 0 : false) {
            if(thenParam != NULL || typename(thenParam) == "string" ? StringLen(thenParam) > 0 : false) { 
                outValue = thenParam;
            }
        }
    } else {
        if(elseQuery != NULL || typename(elseQuery) == "string" ? StringLen(elseQuery) > 0 : false) {
            if(elseParam != NULL || typename(elseParam) == "string" ? StringLen(elseParam) > 0 : false) { 
                outValue = elseParam;
            }
        }
    }
    
    thenQuery = StringFormat(thenQuery, outValue); 
    elseQuery = StringFormat(elseQuery, outValue); 
    
    halt = false;
    for(int i = 0; !halt && (i < ArraySize(callResult)); i++) {
        bool curCallResult = false;
        
        if(callResult[i] && !callSkipped[i]) {
            curCallResult = queryRunByIndex(i, thenQuery, forDbType, ignoreDbType);
        } else if(!callResult[i] && !callSkipped[i]) {
            curCallResult = queryRunByIndex(i, elseQuery, forDbType, ignoreDbType);
        }
        
        if(doAll) {
            if(!curCallResult && returnResult) { 
                //Error::ThrowError(ErrorNormal, "Query failed on DB " + EnumToString(dWriters[i].dbType), FunctionTrace);
                failures++;
            }
        } else {
            if(!doAll && curCallResult) {
                returnResult = true;
                break;
            }
        }
    }
    
    if(failures == dWriterCount) { returnResult = false; }
    
    return returnResult;
}

//bool DataWriterManager::queryRunConditional(string ifQuery, string &outParam[], string &thenQuery[], string &elseQuery[], string &ifParam[], string &thenParam[], string &elseParam[], DataWriterType forDbType=-1, DataWriterType ignoreDbType=-1) {
//    return false;
//}

void DataWriterManager::resetBlockingErrorByIndex(int index,DataWriterType forDbType=-1,DataWriterType ignoreDbType=-1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { return; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { return; }
    
    dWriters[index].blockingError = false;
}

void DataWriterManager::resetBlockingErrors(DataWriterType forDbType=-1,DataWriterType ignoreDbType=-1) {
    int dWritersLength = ArraySize(dWriters);
    
    for(int i = 0; i < dWritersLength; i++) {
        resetBlockingErrorByIndex(i, forDbType, ignoreDbType);
    }
}

bool DataWriterManager::hasCsv() {
    return (ArraySize(dwCsvIds) > 0);
}

void DataWriterManager::freeMemoryByIndex(int index, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    if(forDbType > -1 && forDbType != dWriters[index].dbType) { return; }
    if(ignoreDbType > -1 && ignoreDbType == dWriters[index].dbType) { return; }
    
    dWriters[index].freeMemory();
}

void DataWriterManager::freeMemory(DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    int dWritersLength = ArraySize(dWriters);
    
    for(int i = 0; i < dWritersLength; i++) {
        freeMemoryByIndex(i, forDbType, ignoreDbType);
    }
}
