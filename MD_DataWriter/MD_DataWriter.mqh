//+------------------------------------------------------------------+
//|                                               MAR_DataWriter.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#define _MariaDB

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "depends/SQLite3MQL4/SQLite3Base.mqh"
#include "depends/mql4-mysql.mqh"
#include "depends/mql4-postgresql.mqh"

const int MysqlDefaultPort = 3306;

enum DataWriterFunc {
    DW_Func_None,
    DW_QueryRun,
    DW_GetCsvHandle,
    DW_QueryRetrieveRows,
    DW_QueryRetrieveOne
};

enum DataWriterType {
    DW_None,
    DW_Text,
    DW_Csv,
    DW_Sqlite,
    DW_Postgres,
    DW_Mysql
};

class DataWriter {
    private:
    CSQLite3Base *sqlite;
    int dbConnectId; // mysql, postgres
    string dbUser;
    string dbPass;
    string dbName;
    string dbHost;
    int dbPort;
    int dbSocket;
    int dbClient;
    string dbConnectString;
    string filePath; // sqlite, text
    int fileHandle; // text
    string lineComment; // text
    char csvSep;
    
    string actParamDataInput;
    
    bool isInit;

    public:
    DataWriterType dbType;
    DataWriter(DataWriterType dbTypeIn, int connectRetriesIn=5, int connectRetryDelaySecs=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    ~DataWriter();
    
    void setParams(string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    
    bool initConnection(bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    void closeConnection(bool deinitCommon = false);
    bool reconnect();
    bool attemptReconnect();
    
    bool handleErrorRetry(int errorCode, int errorLevel, string message, string funcTrace="", string params="", bool printToFile = false);

    int connectRetries;
    int connectRetryDelaySecs;
    
    bool queryRun(string dataInput);
    bool getCsvHandle(int &outFileHandle);
    
    bool queryRetrieveRows(string query, string &result[][]);
    
    template<typename T>
    bool queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/);
};

void DataWriter::DataWriter(DataWriterType dbTypeIn, int connectRetriesIn=5, int connectRetryDelaySecsIn=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    dbType = dbTypeIn;
    connectRetries = connectRetriesIn;
    connectRetryDelaySecs = connectRetryDelaySecsIn;
    isInit = false;
    
    sqlite = new CSQLite3Base();
    
    if(StringLen(param) > 0) { 
        setParams(param, param2, param3, param4, param5, param6, param7);
        initConnection(initCommon); 
    }
}

void DataWriter::setParams(string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    switch(dbType) {
        case DW_Sqlite:
            filePath = param;
            break;
            
        case DW_Mysql:
            dbHost = param; dbUser = param2; dbPass = param3; dbName = param4; 
            dbPort = param5 < 0 ? MysqlDefaultPort : param5; 
            dbSocket = param6 < 0 ? 0 : param6; 
            dbClient = param7 < 0 ? 0 : param7;
            break;
            
        case DW_Postgres:
            dbConnectString = param;
            break;
            
        case DW_Text:
            filePath = param;
            csvSep = ';';
            if(StringLen(param2) > 0) { lineComment = param2; }
            else { lineComment = "-- +--------------------------+"; } // sql
            break;
            
        case DW_Csv:
            filePath = param;
            if(StringLen(param2) == 1) { csvSep = StringGetChar(param2, 0); }
            else { csvSep = ';'; }
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
}

void DataWriter::~DataWriter() {
    closeConnection();
    if(CheckPointer(sqlite) == POINTER_DYNAMIC) { delete(sqlite); }
}



bool DataWriter::initConnection(bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    if(StringLen(param) > 0) {
        setParams(param, param2, param3, param4, param5, param6, param7);
    }
    
    bool bResult; int iResult;
    switch(dbType) {
        case DW_Sqlite: // param = file path
            iResult = sqlite.Connect(filePath);
            if(iResult != SQLITE_OK) {
                MC_Error::ThrowError(ErrorNormal, "SQLite failed init: " + iResult + " - " + sqlite.ErrorMsg(), FunctionTrace);
                return false;
            }
            isInit = true;
            return true;

        case DW_Mysql:
            bResult = init_MySQL(dbConnectId, dbHost, dbUser, dbPass, dbName, dbPort, dbSocket, dbClient);

            if(!bResult) { 
                MC_Error::ThrowError(ErrorNormal, "MySQL failed init", FunctionTrace); 
                return false; 
            } 
            else { isInit = true; return true; }

        case DW_Postgres:
            bResult = init_PSQL(dbConnectId, dbConnectString);

            if(!bResult) { 
                MC_Error::ThrowError(ErrorNormal, "PostgresSQL failed init", FunctionTrace); 
                return false; 
            }
            else { isInit = true; return true; }
        
        case DW_Text:
        case DW_Csv:
            fileHandle = FileOpen(filePath, FILE_SHARE_READ|FILE_SHARE_WRITE|(dbType == DW_Csv ? FILE_CSV : FILE_TXT)|FILE_UNICODE, csvSep);
            
            if(fileHandle == INVALID_HANDLE) {
                MC_Error::ThrowError(ErrorNormal, "Text file could not be opened: " + GetLastError(), FunctionTrace, param);
                return false;
            } else { isInit = true; return true; }
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
    }
}

void DataWriter::closeConnection(bool deinitCommon = false) {
    switch(dbType) {
        case DW_Sqlite:
            sqlite.Disconnect();
            break;
        
        case DW_Mysql:
            deinit_MySQL(dbConnectId);
            dbConnectId = 0;
            break;

        case DW_Postgres:
            deinit_PSQL(dbConnectId);
            dbConnectId = 0;
            break;

        case DW_Text:
        case DW_Csv:
            if(fileHandle != INVALID_HANDLE) { FileClose(fileHandle); }
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
    
    isInit = false;
}

bool DataWriter::reconnect() {
    closeConnection();

    bool bResult;
    bResult = initConnection();
    if(!bResult) { 
        MC_Error::ThrowError(ErrorNormal, "Reconnect failed", FunctionTrace); 
        return false; 
    }
    else { return true; }
}

bool DataWriter::attemptReconnect() {
    bool bResult;
    for(int i = 0; i < connectRetries; i++) {
        Sleep(connectRetryDelaySecs * 1000);
        MC_Error::PrintInfo(ErrorInfo, "Reconnecting attempt " + i + ", DB type: " + dbType, FunctionTrace);

        bResult = reconnect();
        if(bResult) { return true; }
    }

    MC_Error::ThrowError(ErrorNormal, "Could not reconnect to dbType: " + dbType + " after " + connectRetries + " attempts", FunctionTrace);

    return false;
}

bool DataWriter::handleErrorRetry(int errorCode, int errorLevel, string message, string funcTrace="", string params="", bool printToFile=false) {
    // todo: if the issue is connectivity, then reconnect and retry the source function
    // recall source func, using params actParamDataInput and actParamForDbType
    int sleepInterval = 0;
    switch(dbType) {
        case DW_Sqlite:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params, printToFile); 
            switch(errorCode) {
                // todo: disconnected?
                case 5: //SQLITE_BUSY
                case 6: //SQLITE_LOCKED
                case 10: //SQLITE_IOERR
                    sleepInterval = (connectRetryDelaySecs*1000)+(500*MathRand()/32767);
                    MC_Error::ThrowError(ErrorNormal, "Retrying: " + sleepInterval + " ms", FunctionTrace);
                    Sleep(sleepInterval); // add fuzz up to 500ms
                    return true;
                
                default:
                    return false;
            }
            break;

        case DW_Mysql:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params, printToFile); // MYSQL lib prints error
            break;

        case DW_Postgres:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params, printToFile); // PSQL lib prints error
            break;

        case DW_Text:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params, printToFile); 
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
    
    return false;
}

bool DataWriter::queryRun(string dataInput) {
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }

    actParamDataInput = dataInput;
    
    int result; bool bResult; string fileContents; bool done = false; int retryCount = 0;
    int errorCode = -1; bool working = true;
    for(int attempts = 0; working && (attempts < connectRetries); attempts++) {
        working = false;
        switch(dbType) {
            case DW_Sqlite: // param = file path
                result = sqlite.Exec(dataInput); // extra "" fixes mt4 build 640 dll param corruption
                if (result != SQLITE_OK) { 
                    working = handleErrorRetry(result, ErrorNormal, "Sqlite expression failed: " + result + " - " + sqlite.ErrorMsg(), FunctionTrace, dataInput); 
                    continue;
                }
                else { return true; }
    
            case DW_Mysql:
                bResult = MySQL_Query(dbConnectId, dataInput);
                if (!bResult) { 
                    // errorCode = 
                    working = handleErrorRetry(errorCode, ErrorNormal, "MySQL query failed", FunctionTrace, dataInput); 
                    continue;
                } // MYSQL lib prints error
                else { return true; }
    
            case DW_Postgres:
                bResult = PSQL_Query(dbConnectId, dataInput);
                if (!bResult) { 
                    // errorCode = 
                    working = handleErrorRetry(errorCode, ErrorNormal, "Postgres query failed", FunctionTrace, dataInput); 
                    continue;
                } // PSQL lib prints error
                else { return true; }
    
            case DW_Text:
                dataInput = lineComment + "\n" + dataInput + "\n";
    
                if(fileHandle != INVALID_HANDLE) {
                    if(!FileSeek(fileHandle, 0, SEEK_END)) { // todo: do while loop, while(!FileIsEnding(fileHandle) && i < 10
                        working = handleErrorRetry(GetLastError(), ErrorNormal, "Could not seek file: ", FunctionTrace, filePath); 
                        continue;
                    }
                    
                    if(!FileWriteString(fileHandle, fileContents)) { 
                        working = handleErrorRetry(GetLastError(), ErrorNormal, "Could not write contents: ", FunctionTrace, filePath); 
                        continue;
                    }
                    else { return true; }
                } else { 
                    MC_Error::ThrowError(ErrorNormal, "File handle invalid", FunctionTrace, filePath); 
                    return false; 
                }
                
            case DW_Csv:
                MC_Error::PrintInfo(ErrorInfo, "Skipping CSV file for queryRun, use getCsvHandle and FileWrite", FunctionTrace);
                return false;
            
            default:
                MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
                return false;
        }
    }
    
    return false;
}

bool DataWriter::getCsvHandle(int &outFileHandle) {
    // This is needed because CSV is written by FileWrite, which takes a variable number of params
    // that is determined at code level
    
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    bool working = true;
    for(int attempts = 0; working && (attempts < connectRetries); attempts++) {
        working = false;
        switch(dbType) {
            case DW_Csv:
                if(fileHandle != INVALID_HANDLE) {
                    if(!FileSeek(fileHandle, 0, SEEK_END)) { // todo: do while loop, while(!FileIsEnding(fileHandle) && i < 10);
                        working = handleErrorRetry(GetLastError(), ErrorNormal, "Could not seek file: ", FunctionTrace, filePath); 
                        continue;
                    }
            
                    outFileHandle = fileHandle;
    
                    return true;
                } else {
                    MC_Error::ThrowError(ErrorNormal, "File handle invalid", FunctionTrace, filePath); 
                    false;
                }    
                
            default:
                MC_Error::ThrowError(ErrorNormal, "dbType is not CSV", FunctionTrace, dbType);
                return false;
        }
    }
    
    return false;
}

bool DataWriter::queryRetrieveRows(string query, string &result[][]) {
    // NOTE: Multidim array size needs to be hardcoded to the expected number of cols. Else, this fails.
    
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    int callResult; int i = 0; int j = 0; int errorCode = -1;
    bool working = true;
    ArrayFree(result);
    
    for(int attempts = 0; working && (attempts < connectRetries); attempts++) {
        working = false;
        switch(dbType) {
            case DW_Sqlite: {
                CSQLite3Table tbl;
                callResult = sqlite.Query(tbl, query);
                if(callResult != SQLITE_DONE) {
                    working = handleErrorRetry(callResult, ErrorNormal, "Query error: " + callResult + " " + sqlite.ErrorMsg(), FunctionTrace, query);
                    continue;
                }
                
                int rowCount = ArraySize(tbl.m_data);
                int colCount = 0;
                ArrayResize(result, 0, rowCount);
                for (i = 0; i < rowCount; i++) {
                    CSQLite3Row *row = tbl.Row(i);
                    if(!CheckPointer(row)) {
                        MC_Error::ThrowError(ErrorNormal, "Query error: row pointer invalid", FunctionTrace, query);
                        continue;
                    }
    
                    ArrayResize(result, i+1);
                    colCount = ArraySize(row.m_data);
                    for (j = 0; j < colCount; j++) {
                        result[i][j] = row.m_data[j].GetString();
                    }
                    if(CheckPointer(row) == POINTER_DYNAMIC) { delete(row); }
                }
    
                if(i > 0 && j > 0) { return true; }
                else {
                    MC_Error::PrintInfo(ErrorTrivial, "Query: " + i + " rows, " + j + " columns returned: " + i, FunctionTrace, query, ErrorForceFile);
                    return false;
                }
            }
            
            case DW_Mysql:
                callResult = MySQL_FetchArray(dbConnectId, query, result);
                if(callResult < 1) { 
                    // errorCode = 
                    working = handleErrorRetry(errorCode, ErrorNormal, "Query error: ", FunctionTrace, query);
                    continue;
                }
                else { return true; }
                
            case DW_Postgres:
                callResult = PSQL_FetchArray(dbConnectId, query, result);
                if(callResult < 1) { 
                    // errorCode = 
                    working = handleErrorRetry(errorCode, ErrorNormal, "Query error: ", FunctionTrace, query);
                    continue;
                }
                else { return true; }
                
            case DW_Text:
            case DW_Csv: // todo: use a library like pandas to select CSV rows/cols
                MC_Error::ThrowError(ErrorNormal, "Text and CSV not supported for retrieval", FunctionTrace, dbType);
                return false;           
        
            default:
                MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
                return false;
        }
    }
    
    return false;
}

template<typename T>
bool DataWriter::queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/) {
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    int colIndex = 0; // since multidim array size is hardcoded, we can only retrieve one column
    int callResult; int cols[1]; int i = 0; int j = 0; 
    string allRows[][1];
    bool queryResult; bool returnResult = false; string dbResult; int errorCode = -1;
    bool working = true;
    
    for(int attempts = 0; working && (attempts < connectRetries); attempts++) {
        working = false;
        switch(dbType) {
            case DW_Sqlite: {
                CSQLite3Table tbl;
                callResult = sqlite.Query(tbl, query);
                if(callResult != SQLITE_DONE) {
                    working = handleErrorRetry(callResult, ErrorNormal, "Query error: " + sqlite.ErrorMsg(), FunctionTrace, query);
                    continue;
                }
                
                int rowCount = ArraySize(tbl.m_data);
                int colCount = 0;
                for (i = 0; i < rowCount; i++) {
                    if(i == rowIndex) {
                        CSQLite3Row *row = tbl.Row(i);
                        if(!CheckPointer(row)) {
                            MC_Error::ThrowError(ErrorNormal, "Query error: row pointer invalid", FunctionTrace, query);
                            break;
                        }
    
                        colCount = ArraySize(row.m_data);
                        for (j = 0; j < colCount; j++) {
                            if(j == colIndex) { 
                                dbResult = row.m_data[j].GetString();
                                returnResult = true;
                                break;
                            }
                        }
                        if(CheckPointer(row) == POINTER_DYNAMIC) { delete(row); }
                        break;
                    }
                }
            } 
            break;
            
            case DW_Mysql:
            case DW_Postgres:
                // todo: would be nice to copy these methods from the helper libraries directly
                // so we can refer to data directly by row and col
                queryResult = queryRetrieveRows(query, allRows);
                if(!queryResult) { 
                    // errorCode = 
                    working = handleErrorRetry(errorCode, ErrorNormal, "Query error: ", FunctionTrace, query);
                    continue;
                }
                else {
                    int dim1Size = ArrayRange(allRows, 1);
                    int dim0Size = ArraySize(allRows) / dim1Size;
                    
                    if(dim0Size < rowIndex+1/* || dim1Size < colIndex+1*/) { 
                        // we can't determine colSize valid because we already size the col dimension to the requested index
                        MC_Error::PrintInfo(ErrorTrivial, "Query did not return enough rows: ", FunctionTrace, query, ErrorForceFile);
                        return false;
                    } else {
                        dbResult = allRows[rowIndex][colIndex];
                        returnResult = true;
                        break;
                    }
                }
                
            case DW_Text:
            case DW_Csv: // todo: use a library like pandas to select CSV rows/cols
                MC_Error::ThrowError(ErrorNormal, "Text and CSV not supported for retrieval", FunctionTrace, dbType);
                return false;           
        
            default:
                MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
                return false;
        }
        
        if(returnResult) {
            string type = typename(T);
            if(type == "int") { result = StringToInteger(dbResult); }
            else if(type =="double") { result = StringToDouble(dbResult); }
            else if(type == "bool") { result = MC_Common::StrToBool(dbResult); }
            else { result = dbResult; }
            
            return true;
        } else {
            MC_Error::PrintInfo(ErrorTrivial, "Query did not return data: ", FunctionTrace, query, ErrorForceFile);
            return false; 
        }
    }
    
    return false;
}
