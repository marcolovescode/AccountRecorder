//+------------------------------------------------------------------+
//|                                              mql4-postgresql.mqh |
//|                                                 Alex Stoliarchuk |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Alex Stoliarchuk"
#property link      "http://www.mql5.com"
#property strict

#define PTR32              int
#define PTR64              long

// https://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/doxyhtml/sql_8h_source.html

enum SqlResult
{
SQL_INVALID_HANDLE		= -2,
SQL_ERROR               = -1,
SQL_SUCCESS				= 0,
SQL_SUCCESS_WITH_INFO	= 1,
SQL_NO_DATA_FOUND		= 100
};

enum SqlHandle
{
SQL_NULL_HANDLE = 0,
SQL_HANDLE_ENV = 1,
SQL_HANDLE_DBC = 2,
SQL_HANDLE_DESCR = 4,
SQL_HANDLE_STMT = 3,
};

enum SqlDefines
{
SQL_FETCH_NEXT = 1,
SQL_ATTR_ODBC_VERSION = 200,
SQL_OV_ODBC3_80 = 380,
SQL_CLOSE = 0,
SQL_NULL_DATA = -1,
SQL_COPT_SS_BASE = 1200,
SQL_COPT_SS_CONNECTION_DEAD = 1244,
SQL_ATTR_CONNECTION_DEAD = 1209
};

enum SqlTypes
{
SQL_C_CHAR = 1
};
 

#import "odbc32.dll"

// Connection control

//SQLRETURN SQLAllocHandle(  
//      SQLSMALLINT   HandleType,  
//      SQLHANDLE     InputHandle,  
//      SQLHANDLE *   OutputHandlePtr);

short SQLAllocHandle(int handleType, PTR32 inputHandle, PTR32 &outputHandle);

//SQLRETURN SQLFreeHandle(  
//     SQLSMALLINT   HandleType,  
//     SQLHANDLE     Handle);

short SQLFreeHandle(int handleType, PTR32 handle);

//SQLRETURN SQLDriverConnect(  
//     SQLHDBC         ConnectionHandle,  
//     SQLHWND         WindowHandle,  
//     SQLCHAR *       InConnectionString,  
//     SQLSMALLINT     StringLength1,  
//     SQLCHAR *       OutConnectionString,  
//     SQLSMALLINT     BufferLength,  
//     SQLSMALLINT *   StringLength2Ptr,  
//     SQLUSMALLINT    DriverCompletion);

short SQLDriverConnect(
    int dbcHandle
    , int windowHandle
    , const uchar &inConnectionString[]
    , int stringLength1
    , uchar &outConnectionString[]
    , int bufferLength
    , int &stringLength2Out
    , bool driverCompletion
    );

//SQLRETURN SQLDisconnect(  
//     SQLHDBC     ConnectionHandle);

short SQLDisconnect(int dbcHandle);

//SQLRETURN SQLSetEnvAttr(  
//     SQLHENV      EnvironmentHandle,  
//     SQLINTEGER   Attribute,  
//     SQLPOINTER   ValuePtr,  
//     SQLINTEGER   StringLength);

short SQLSetEnvAttr(PTR32 envHandle, int attribute, const uchar &value[], int stringLen);
short SQLSetEnvAttr(PTR32 envHandle, int attribute, int value, int stringLen);

//SQLRETURN SQLGetConnectAttr(  
//     SQLHDBC        ConnectionHandle,  
//     SQLINTEGER     Attribute,  
//     SQLPOINTER     ValuePtr,  
//     SQLINTEGER     BufferLength,  
//     SQLINTEGER *   StringLengthPtr);

short SQLGetConnectAttr(PTR32 dbcHandle, int attribute, uchar &valueOut[], int bufferLength, int &stringLengthOut);
short SQLGetConnectAttr(PTR32 dbcHandle, int attribute, int &valueOut, int bufferLength, int &stringLengthOut);

//SQLRETURN SQLGetDiagField(  
//     SQLSMALLINT     HandleType,  
//     SQLHANDLE       Handle,  
//     SQLSMALLINT     RecNumber,  
//     SQLSMALLINT     DiagIdentifier,  
//     SQLPOINTER      DiagInfoPtr,  
//     SQLSMALLINT     BufferLength,  
//     SQLSMALLINT *   StringLengthPtr);

short SQLGetDiagField(
    int handleType
    , PTR32 handle
    , int recNumber
    , int diagIdentifier
    , uchar &diagInfoPtr[] // use for text or POINTER
    , int bufferLength
    , int &stringLengthOut
    );
    
short SQLGetDiagField(
    int handleType
    , PTR32 handle
    , int recNumber
    , int diagIdentifier
    , int &diagInfoOut // use for INTEGER, UINTEGER, SMALLINT, or USMALLINT
    , int bufferLength
    , int &stringLengthOut
    );

//SQLRETURN SQLGetDiagRec(  
//     SQLSMALLINT     HandleType,  
//     SQLHANDLE       Handle,  
//     SQLSMALLINT     RecNumber,  
//     SQLCHAR *       SQLState,  
//     SQLINTEGER *    NativeErrorPtr,  
//     SQLCHAR *       MessageText,  
//     SQLSMALLINT     BufferLength,  
//     SQLSMALLINT *   TextLengthPtr);

short SQLGetDiagRec(
    int handleType
    , PTR32 handle
    , int recNumber
    , uchar &sqlState[]
    , int &nativeErrorOut
    , uchar &messageText[]
    , int bufferLength
    , int &textLengthOut
    );

//+------------------------------------------------------------------+

// Command execution

//SQLRETURN SQLExecDirect(  
//     SQLHSTMT     StatementHandle,  
//     SQLCHAR *    StatementText,  
//     SQLINTEGER   TextLength);

short SQLExecDirect(PTR32 statementHandle, const uchar &statementText[], int textLength);

//SQLRETURN SQLFreeStmt(  
//     SQLHSTMT       StatementHandle,  
//     SQLUSMALLINT   Option);

short SQLFreeStmt(PTR32 statementHandle, int option);

//SQLRETURN SQLNumResultCols(  
//     SQLHSTMT        StatementHandle,  
//     SQLSMALLINT *   ColumnCountPtr);

short SQLNumResultCols(PTR32 statementHandle,int &columnCountOut);

//SQLRETURN SQLFetch(  
//     SQLHSTMT     StatementHandle);

short SQLFetch(PTR32 statementHandle);

//SQLRETURN SQLGetData(  
//      SQLHSTMT       StatementHandle,  
//      SQLUSMALLINT   Col_or_Param_Num,  
//      SQLSMALLINT    TargetType,  
//      SQLPOINTER     TargetValuePtr,  
//      SQLLEN         BufferLength,  
//      SQLLEN *       StrLen_or_IndPtr);

short SQLGetData(PTR32 statementHandle, int colOrParamNum, int targetType, uchar &targetValueOut[], int bufferLength, int &stringLenOrIndPtrOut);
short SQLGetData(PTR32 statementHandle, int colOrParamNum, int targetType, int &targetValueOut, int bufferLength, int &stringLenOrIndPtrOut);

//SQLRETURN SQLRowCount(  
//      SQLHSTMT   StatementHandle,  
//      SQLLEN *   RowCountPtr);

short SQLRowCount(PTR32 statementHandle, int &rowCountOut);

#import

string ODBC_LastErrorMessage = "";
string ODBC_LastErrorCode = "";
int ODBC_LastErrorNativeCode = 0;
string ODBC_LastErrorString = "";
bool ODBC_PrintErrors = false;
bool ODBC_PrintResults = false;

//+------------------------------------------------------------------+

bool ODBC_Init(PTR32 &envHandle, PTR32 &dbcHandle, PTR32 &stmtHandle, string connString, bool prompt = false) {
    if(!ODBC_Try(0, 0, SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, envHandle))) { return false; }
    
    if(!ODBC_Try(envHandle, SQL_HANDLE_ENV
        , SQLSetEnvAttr(envHandle, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3_80, 0)
        )
    ) { return false; }
    
    return ODBC_Connect(envHandle, dbcHandle, stmtHandle, connString, prompt);
}

bool ODBC_Connect(PTR32 &envHandle, PTR32 &dbcHandle, PTR32 &stmtHandle, string connString, bool prompt = false) {
    if(!envHandle) { return false; }
    
    if(!ODBC_Try(envHandle, SQL_HANDLE_ENV
        , SQLAllocHandle(SQL_HANDLE_DBC, envHandle, dbcHandle)
        )
    ) { return false; }
    
    uchar inConnString[]; uchar outConnString[1024]; int outConnStringLen;
    if(StringLen(connString) > 0) { StringToCharArray(connString, inConnString); }
    
    if(!ODBC_Try(dbcHandle, SQL_HANDLE_DBC
        , SQLDriverConnect(
            dbcHandle
            , NULL
            , inConnString
            , ArraySize(inConnString)
            , outConnString
            , 1024
            , outConnStringLen
            , prompt
            )
        )
    ) { return false; }
    
    if(!ODBC_Try(dbcHandle, SQL_HANDLE_DBC
        , SQLAllocHandle(SQL_HANDLE_STMT, dbcHandle, stmtHandle)
        )
    ) { return false; }
    else { return true; }
}

bool ODBC_Disconnect(PTR32 &dbcHandle, PTR32 &stmtHandle, bool stmtOnly = false) {
    if(stmtHandle) {
        if(ODBC_Try(stmtHandle, SQL_HANDLE_STMT, SQLFreeHandle(SQL_HANDLE_STMT, stmtHandle))) {
            stmtHandle = 0;
        }
        if(stmtOnly) { return stmtHandle == 0; }
    }

    if(dbcHandle) {
        if(ODBC_Try(dbcHandle, SQL_HANDLE_DBC, SQLDisconnect(dbcHandle))) {
            dbcHandle = 0;
            return true;
        } else { return false; }
    } else { return true; }
}

void ODBC_Deinit(PTR32 &envHandle, PTR32 &dbcHandle, PTR32 &stmtHandle)
{
    if(dbcHandle) { ODBC_Disconnect(dbcHandle, stmtHandle); }
    if(envHandle) { SQLFreeHandle(SQL_HANDLE_ENV, envHandle); envHandle = 0; }
}

bool ODBC_IsConnected(PTR32 &dbcHandle) {
    // SQL_ATTR_CONNECTION_DEAD checks state of conn from last attempt
    // SQL_COPT_SS_CONNECTION_DEAD checks current state of conn by querying, but support is inconsistent
        // SQL Server 2000 defines as 1244
        // Other sources define as 1209, same as SQL_ATTR_CONNECTION_DEAD
        
    int result = 0; int resultLength = 0;
    
    if(ODBC_Try(dbcHandle, SQL_HANDLE_DBC
        , SQLGetConnectAttr(dbcHandle, SQL_ATTR_CONNECTION_DEAD, result, 1, resultLength)
        )
    ) {
        return !result;
    } else { return false; }
}

bool ODBC_Query(PTR32 &dbcHandle, PTR32 &stmtHandle, string query)
{
    string dataZeroArray[1][1];
    return (ODBC_FetchArray(dbcHandle, stmtHandle, query, dataZeroArray) > -1);
}

int ODBC_FetchArray(PTR32 &dbcHandle, PTR32 &stmtHandle, string query, string &data[][])
{
    if(StringLen(query) <= 0) { return false; }
    if(!stmtHandle) { return false; }
    
    int finalResult = -1;
    
    int dataDim0Size = ArraySize(data);
    int dataDim1Size = ArrayRange(data, 1);
    bool dataIsFixed = !ArrayIsDynamic(data);
    
    uchar inStmtText[];
    StringToCharArray(query, inStmtText);
    short callResult = SQLExecDirect(stmtHandle, inStmtText, StringLen(query));
    
    switch(callResult) {
        case SQL_SUCCESS_WITH_INFO:
            ODBC_GetError(stmtHandle, SQL_HANDLE_STMT, callResult, ODBC_PrintErrors);
            
        case SQL_SUCCESS: {
            int colCount = 0;
            int rowCount = 0;
            
            ODBC_Try(stmtHandle, SQL_HANDLE_STMT
                , SQLNumResultCols(stmtHandle, colCount)
                );
                
            ODBC_Try(stmtHandle, SQL_HANDLE_STMT
                    , SQLRowCount(stmtHandle, rowCount)
                    );
            
            if(colCount > 0) {
                if(!dataIsFixed) { ArrayResize(data, dataDim0Size, rowCount); }
                
                for(
                    int i = 1
                    ; ODBC_Try(stmtHandle, SQL_HANDLE_STMT, SQLFetch(stmtHandle)) 
                        && (dataIsFixed ? i <= dataDim0Size : true)
                    ; i++
                ) {
                    if(!dataIsFixed) { ArrayResize(data, i); }
                    for(
                        int j = 1
                        ; j <= colCount && (dataIsFixed ? j <= dataDim1Size : true)
                        ; j++
                    ) {
                        int strLen = 0; uchar buf[512]; string bufStr;
                        if(ODBC_Try(stmtHandle, SQL_HANDLE_STMT, SQLGetData(stmtHandle, j, SQL_C_CHAR, buf, 512, strLen))) {
                            if(strLen == SQL_NULL_DATA) { if(ODBC_PrintResults) { Print(i + "-" + j+": NULL"); } }
                            else { 
                                bufStr = CharArrayToString(buf);
                                data[i-1][j-1] = bufStr;
                                if(ODBC_PrintResults) { Print(i+"-"+j+": " + bufStr); }
                            }
                        }
                    }
                }
            } else {
                if(ODBC_PrintResults) { Print(rowCount + " rows affected"); }
            }
            
            finalResult = rowCount;
            break;
        }
        
        case SQL_NO_DATA_FOUND: // not an error, but no rows returned
            finalResult = 0;
            break;
            
        case SQL_ERROR:
            ODBC_GetError(stmtHandle, SQL_HANDLE_STMT, callResult, ODBC_PrintErrors);
            finalResult = -1;
            break;
            
        default:
            if(ODBC_PrintErrors) { Print("Unexpected return code " + callResult); }
            finalResult = -1;
            break;
    }
    
    ODBC_Try(stmtHandle, SQL_HANDLE_STMT, SQLFreeStmt(stmtHandle, SQL_CLOSE));
    
    return finalResult;
}

bool ODBC_Try(int handle, int handleType, short callResult) {
    if(((callResult)&(~1)) == 0) { return true; } // SQL_SUCCEEDED
    else {
        ODBC_GetError(handle, handleType, callResult, ODBC_PrintErrors); // could be info, not an actual error
    
        if(callResult <= SQL_ERROR || callResult == SQL_NO_DATA_FOUND) { return false; }
    }
    
    return true; // some results succeed with weird numbers like 65535
}

void ODBC_GetError(int handle, int handleType, short callResult, bool print = false) {
    if(callResult == SQL_INVALID_HANDLE) {
        ODBC_LastErrorCode = -1;
        ODBC_LastErrorMessage = "Invalid handle";
        ODBC_LastErrorString = ODBC_LastErrorCode + " - " + ODBC_LastErrorMessage;
        
        if(print) { Print(ODBC_LastErrorString); }
        
        return;
    }
    
    int iRec = 0; uchar sqlState[6]; int nativeErrorCode = 0; uchar messageText[1024]; int textLength = 0;
    while(SQLGetDiagRec(handleType, handle, ++iRec, sqlState, nativeErrorCode, messageText, 1024, textLength) == SQL_SUCCESS) {
        ODBC_LastErrorCode = CharArrayToString(sqlState);
        ODBC_LastErrorNativeCode = nativeErrorCode;
        if(textLength > 0) { ODBC_LastErrorMessage = CharArrayToString(messageText); }
        else { ODBC_LastErrorMessage = ODBC_LastErrorCode; }
        
        ODBC_LastErrorString = ODBC_LastErrorCode + " - " + ODBC_LastErrorMessage;
        
        if(print) { Print(ODBC_LastErrorString); }
    }
}
