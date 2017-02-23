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

#include "MC_Common/MC_Error.mqh"
#include "MAR_Library/sqlite.mqh"
#include "MAR_Library/mql4-mysql.mqh"
#include "MAR_Library/mql4-postgresql.mqh"

const int MysqlDefaultPort = 3306;

enum DataWriterFunc {
    DW_Func_None,
    DW_Commit,
    DW_CommitCsv,
    DW_Retrieve
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
    DataWriterType actParamForDbType;
    DataWriterType actParamIgnoreDbType;
    
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
    
    bool commit(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1);
    bool commitCsv(string param1="", string param2="", string param3="", string param4="", string param5="", string param6="", string param7="", string param8="", string param9="", string param10="", string param11="", string param12="", string param13="", string param14="", string param15="", string param16="", string param17="", string param18="", string param19="", string param20="", string param21="", string param22="", string param23="", string param24="", string param25="", string param26="", string param27="", string param28="", string param29="", string param30="", string param31="", string param32="", string param33="", string param34="", string param35="", string param36="", string param37="", string param38="", string param39="", string param40="", string param41="", string param42="", string param43="", string param44="", string param45="", string param46="", string param47="", string param48="", string param49="", string param50="", string param51="", string param52="", string param53="", string param54="", string param55="", string param56="", string param57="", string param58="", string param59="", string param60="", string param61="", string param62="", string param63="");
    
    void handleError(DataWriterFunc source, string message, string extraInfo="", string funcTrace="", string params="");

    int connectRetries;
    int connectRetryDelaySecs;
};

void DataWriter::DataWriter(DataWriterType dbTypeIn, int connectRetriesIn=5, int connectRetryDelaySecsIn=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    dbType = dbTypeIn;
    connectRetries = connectRetriesIn;
    connectRetryDelaySecs = connectRetryDelaySecsIn;
    isInit = false;
    
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
}



bool DataWriter::initConnection(bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    if(StringLen(param) > 0) {
        setParams(param, param2, param3, param4, param5, param6, param7);
    }
    
    bool bResult;
    switch(dbType) {
        case DW_Sqlite: // param = file path
            if(initCommon) {
                if(!sqlite_init()) {
                    MC_Error::ThrowError(ErrorNormal, "SQLite failed init", FunctionTrace);
                    return false;
                }
            }

            // open file path?
            
            isInit = true;
            return true;
            break;

        case DW_Mysql:
            bResult = init_MySQL(dbConnectId, dbHost, dbUser, dbPass, dbName, dbPort, dbSocket, dbClient);

            if(!bResult) { 
                MC_Error::ThrowError(ErrorNormal, "MySQL failed init", FunctionTrace); 
                return false; 
            } 
            else { isInit = true; return true; }
            break;

        case DW_Postgres:
            bResult = init_PSQL(dbConnectId, dbConnectString);

            if(!bResult) { 
                MC_Error::ThrowError(ErrorNormal, "PostgresSQL failed init", FunctionTrace); 
                return false; 
            }
            else { isInit = true; return true; }
            break;
        
        case DW_Text:
        case DW_Csv:
            fileHandle = FileOpen(filePath, FILE_SHARE_READ|FILE_SHARE_WRITE|(dbType == DW_Csv ? FILE_CSV : FILE_TXT)|FILE_UNICODE, csvSep);
            
            if(fileHandle == INVALID_HANDLE) {
                MC_Error::ThrowError(ErrorNormal, "Text file could not be opened: " + GetLastError(), FunctionTrace, param);
                return false;
            } else { isInit = true; return true; }
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
            break;
    }
}

void DataWriter::closeConnection(bool deinitCommon = false) {
    switch(dbType) {
        case DW_Sqlite:
            if(deinitCommon) { sqlite_finalize(); }
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

void DataWriter::handleError(DataWriterFunc source, string message, string extraInfo="", string funcTrace="", string params="") {
    // todo: if the issue is connectivity, then reconnect and retry the source function
    // recall source func, using params actParamDataInput and actParamForDbType
    
    switch(dbType) {
        case DW_Sqlite:
            MC_Error::ThrowError(ErrorNormal, message + extraInfo, funcTrace, params); 
            break;

        case DW_Mysql:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params); // MYSQL lib prints error
            break;

        case DW_Postgres:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params); // PSQL lib prints error
            break;

        case DW_Text:
            MC_Error::ThrowError(ErrorNormal, message + extraInfo, funcTrace, params); 
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
}

bool DataWriter::commit(string dataInput, DataWriterType forDbType = -1, DataWriterType ignoreDbType = -1) {
    if(forDbType > -1 && forDbType != dbType) { return false; }
    if(ignoreDbType > -1 && ignoreDbType == dbType) { return false; }
    
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    actParamDataInput = dataInput;
    actParamForDbType = forDbType;
    actParamIgnoreDbType = ignoreDbType;
    
    int result; bool bResult; string fileContents; int dataInputArrLen;
    switch(dbType) {
        case DW_Sqlite: // param = file path
            result = sqlite_exec(filePath, dataInput + ""); // extra "" fixes mt4 build 640 dll param corruption
            if (result != 0) { 
                handleError(DW_Commit, "Sqlite expression failed: ", result, FunctionTrace, dataInput); 
                return false; 
            }
            else { return true; }
            break;

        case DW_Mysql:
            bResult = MySQL_Query(dbConnectId, dataInput);
            if (!bResult) { 
                handleError(DW_Commit, "MySQL query failed", "", FunctionTrace, dataInput); 
                return false; 
            } // MYSQL lib prints error
            else { return true; }
            break;

        case DW_Postgres:
            bResult = PSQL_Query(dbConnectId, dataInput);
            if (!bResult) { 
                handleError(DW_Commit, "Postgres query failed", "", FunctionTrace, dataInput); 
                return false; 
            } // PSQL lib prints error
            else { return true; }
            break;

        case DW_Text:
            dataInput = lineComment + "\n" + dataInput + "\n";

            if(fileHandle != INVALID_HANDLE) {
                if(!FileSeek(fileHandle, 0, SEEK_END)) { // todo: do while loop, while(!FileIsEnding(fileHandle) && i < 10
                    handleError(DW_Commit, "Could not seek file: ", GetLastError(), FunctionTrace, filePath); 
                    return false;
                }
                
                if(!FileWriteString(fileHandle, fileContents)) { 
                    handleError(DW_Commit, "Could not write contents: ", GetLastError(), FunctionTrace, filePath); 
                    return false; 
                }
                else { return true; }
            } else { 
                MC_Error::ThrowError(ErrorNormal, "File handle invalid", FunctionTrace, filePath); 
                return false; 
            }
            break;
            
        case DW_Csv:
            MC_Error::PrintInfo(ErrorInfo, "Skipping CSV file for commit, use commitCsv", FunctionTrace);
            return false;
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
            break;
    }
    
    return true;
}

bool DataWriter::commitCsv(string param1="", string param2="", string param3="", string param4="", string param5="", string param6="", string param7="", string param8="", string param9="", string param10="", string param11="", string param12="", string param13="", string param14="", string param15="", string param16="", string param17="", string param18="", string param19="", string param20="", string param21="", string param22="", string param23="", string param24="", string param25="", string param26="", string param27="", string param28="", string param29="", string param30="", string param31="", string param32="", string param33="", string param34="", string param35="", string param36="", string param37="", string param38="", string param39="", string param40="", string param41="", string param42="", string param43="", string param44="", string param45="", string param46="", string param47="", string param48="", string param49="", string param50="", string param51="", string param52="", string param53="", string param54="", string param55="", string param56="", string param57="", string param58="", string param59="", string param60="", string param61="", string param62="", string param63="") {
    switch(dbType) {
        case DW_Csv:
            if(fileHandle != INVALID_HANDLE) {
                if(!FileSeek(fileHandle, 0, SEEK_END)) { // todo: do while loop, while(!FileIsEnding(fileHandle) && i < 10);
                    handleError(DW_Commit, "Could not seek file: ", GetLastError(), FunctionTrace, filePath); 
                    return false;
                }
        
                if(!FileWrite(fileHandle, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20, param21, param22, param23, param24, param25, param26, param27, param28, param29, param30, param31, param32, param33, param34, param35, param36, param37, param38, param39, param40, param41, param42, param43, param44, param45, param46, param47, param48, param49, param50, param51, param52, param53, param54, param55, param56, param57, param58, param59, param60, param61, param62, param63)) {
                    handleError(DW_CommitCsv, "Could not write file: ", GetLastError(), FunctionTrace, filePath); 
                    return false;
                } 
                else { return true; }
            } else {
                MC_Error::ThrowError(ErrorNormal, "File handle invalid", FunctionTrace, filePath); 
                return false; 
            }    
            break;
            
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType is not CSV", FunctionTrace, dbType);
            return false;
            break;
    }
    
    return true;
}
