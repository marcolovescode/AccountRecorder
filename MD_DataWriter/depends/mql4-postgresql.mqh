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

#import "msvcrt.dll"
  int strcpy(uchar &dst[],int src);
  long strcpy(uchar &dst[],long src);
  int strlen(int src);
  int strlen(long src);
#import

enum ConnStatusType
{
        CONNECTION_OK,
        CONNECTION_BAD,
        /* Non-blocking mode only below here */

        /*
         * The existence of these should never be relied upon - they should only
         * be used for user feedback or similar purposes.
         */
        CONNECTION_STARTED,                     /* Waiting for connection to be made.  */
        CONNECTION_MADE,                        /* Connection OK; waiting to send.     */
        CONNECTION_AWAITING_RESPONSE,           /* Waiting for a response from the
                                                                                 * postmaster.        */
        CONNECTION_AUTH_OK,                     /* Received authentication; waiting for
                                                                 * backend startup. */
        CONNECTION_SETENV,                      /* Negotiating environment. */
        CONNECTION_SSL_STARTUP,         /* Negotiating SSL. */
        CONNECTION_NEEDED                       /* Internal state: connect() needed */
};

enum ExecStatusType
{
        PGRES_EMPTY_QUERY = 0,          /* empty query string was executed */
        PGRES_COMMAND_OK,                       /* a query command that doesn't return
                                                                 * anything was executed properly by the
                                                                 * backend */
        PGRES_TUPLES_OK,                        /* a query command that returns tuples was
                                                                 * executed properly by the backend, PGresult
                                                                 * contains the result tuples */
        PGRES_COPY_OUT,                         /* Copy Out data transfer in progress */
        PGRES_COPY_IN,                          /* Copy In data transfer in progress */
        PGRES_BAD_RESPONSE,                     /* an unexpected response was recv'd from the
                                                                 * backend */
        PGRES_NONFATAL_ERROR,           /* notice or warning message */
        PGRES_FATAL_ERROR,                      /* query failed */
        PGRES_COPY_BOTH,                        /* Copy In/Out data transfer in progress */
        PGRES_SINGLE_TUPLE                      /* single tuple from larger resultset */
};
 

#import "MD_DataWriter/libpq.dll"

// Connection control

//extern PGconn *PQconnectdb(const char *conninfo);
PTR32 PQconnectdb(const uchar &conninfo[]);
//extern void PQfinish(PGconn *conn);
void PQfinish(PTR32 conn);
//extern ConnStatusType PQstatus(const PGconn *conn);
ConnStatusType PQstatus(const PTR32 conn);
//extern char *PQerrorMessage(const PGconn *conn);
PTR32 PQerrorMessage(const PTR32 conn);

//+------------------------------------------------------------------+

// Command execution

//extern PGresult *PQexec(PGconn *conn, const char *query);
PTR32 PQexec(PTR32 conn, const uchar &query[]);
//extern void PQclear(PGresult *res);
void PQclear(PTR32 res);
//extern ExecStatusType PQresultStatus(const PGresult *res);
ExecStatusType PQresultStatus(const PTR32 res);
//char *PQresultErrorMessage(const PGresult *res);
PTR32 PQresultErrorMessage(const PTR32 res);

//int PQntuples(const PGresult *res);
int PQntuples(const PTR32 res);
//int PQnfields(const PGresult *res);
int PQnfields(const PTR32 res);

//int PQgetlength(const PGresult *res, int row_number, int column_number);
int PQgetlength(const PTR32 res, int row_number, int column_number);
// int PQfformat(const PGresult *res, int column_number);
int PQfformat(const PTR32 res, int column_number);
// int PQgetisnull(const PGresult *res, int row_number, int column_number);
int PQgetisnull(const PTR32 res, int row_number, int column_number);

//extern char *PQgetvalue(const PGresult *res, int tup_num, int field_num);
PTR32 PQgetvalue(const PTR32 res, int tup_num, int field_num);

#import

// todo: retrieve and store by handle id
string PSQL_LastErrorMessage = "";

//+------------------------------------------------------------------+

bool init_PSQL(PTR32 &dbConnectId, string conninfo)
  {
    uchar conninfoChar[];
    StringToCharArray(conninfo, conninfoChar);
    dbConnectId=PQconnectdb(conninfoChar);
    if (PQstatus(dbConnectId) != CONNECTION_OK) {
      PSQL_LastErrorMessage = PointerToString(PQerrorMessage(dbConnectId));
      return(false);
    } else {
      return(true);
    }
  }

void deinit_PSQL(PTR32 &dbConnectId)
  {
    PQfinish(dbConnectId);
    dbConnectId = 0;
  }
  
string PSQL_LastError(PTR32 dbConnectId) {
    //if(StringLen(PSQL_LastErrorMessage) < 1) { PSQL_LastErrorMessage = PointerToString(PQerrorMessage(dbConnectId)); }
    return PSQL_LastErrorMessage;
}

//+----------------------------------------------------------------------------+
//| Simply run a query, perfect for actions like INSERTs, UPDATEs, DELETEs     |
//+----------------------------------------------------------------------------+
bool PSQL_Query(PTR32 dbConnectId, string query)
  {
    uchar queryChar[];
    StringToCharArray(query, queryChar);
    bool returnResult = false;
    PTR32 res = PQexec(dbConnectId,queryChar);
    
    if(res <= 0) {
      PSQL_LastErrorMessage = PointerToString(PQresultErrorMessage(res));
      returnResult = false;
    } else {
      switch(PQresultStatus(res)) {
        case PGRES_BAD_RESPONSE:
        case PGRES_NONFATAL_ERROR:
        case PGRES_FATAL_ERROR:
          PSQL_LastErrorMessage = PointerToString(PQresultErrorMessage(res));
          returnResult = false;
          break;
          
        case PGRES_EMPTY_QUERY:
        case PGRES_COMMAND_OK:
        case PGRES_TUPLES_OK:
        default:
          returnResult = true;   
          break;
      }
    }
    
    PQclear(res);
    return returnResult;
  }

//+----------------------------------------------------------------------------+
//| Fetch row(s) in a 2-dimansional array                                      |
//|                                                                            |
//| return (-1): error; (0): 0 rows selected; (1+): some rows selected;         |
//+----------------------------------------------------------------------------+
int PSQL_FetchArray(PTR32 dbConnectId, string query, string &data[][])
  {
    uchar queryChar[];
    StringToCharArray(query, queryChar);
    int returnResult = -1;
    
    ArrayFree(data);
    
    int res=PQexec(dbConnectId,queryChar);
    
    if(res <= 0) {
      PSQL_LastErrorMessage = PointerToString(PQresultErrorMessage(res));
      returnResult = -1;
    } else {
      switch(PQresultStatus(res)) {
        case PGRES_BAD_RESPONSE:
        case PGRES_NONFATAL_ERROR:
        case PGRES_FATAL_ERROR:
          PSQL_LastErrorMessage = PointerToString(PQresultErrorMessage(res));
          returnResult = -1;
          break;
          
        case PGRES_EMPTY_QUERY:
        case PGRES_COMMAND_OK:
          returnResult = 0;
          break;
          
        case PGRES_TUPLES_OK:{
          int num_rows   = PQntuples(res);
          int num_fields = PQnfields(res);
          ArrayResize(data, num_rows);
          for (int i = 0; i < num_rows; i++ ) {
            for (int j = 0; j < num_fields; j++ ) {
              if(!PQgetisnull(res, i, j) && PQfformat(res, j) == 0 /* text */) {
                data[i][j]=PointerToString(PQgetvalue(res, i, j), PQgetlength(res, i, j));
              } // todo: represent binary?
            }
          }
          returnResult = num_rows;
          break;
        }
      }
    }
    
    PQclear(res);
    return returnResult;
  }

//+----------------------------------------------------------------------------+
//| Lovely function that helps us to get ANSI strings from DLLs to our UNICODE |
//| format                                                                     |
//| http://forum.mql4.com/60708                                                |
//+----------------------------------------------------------------------------+
string PointerToString(PTR32 ptrStringMemory, int szString = -1)
{
    if(szString < 0) { szString = msvcrt::strlen(ptrStringMemory); }
    if(szString <= 0) { return ""; }
    
    uchar ucValue[];
    ArrayResize(ucValue, szString + 1);
    
    msvcrt::strcpy(ucValue,ptrStringMemory);
    
    string str = CharArrayToString(ucValue);
    return str;
}
