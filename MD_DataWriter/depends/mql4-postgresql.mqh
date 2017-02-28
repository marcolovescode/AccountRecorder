//+------------------------------------------------------------------+
//|                                              mql4-postgresql.mqh |
//|                                                 Alex Stoliarchuk |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Alex Stoliarchuk"
#property link      "http://www.mql5.com"
#property strict

#import "kernel32.dll"
   int lstrlenA(int);
   void RtlMoveMemory(uchar & arr[], int, int);
   int LocalFree(int); // May need to be changed depending on how the DLL allocates memory
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
//extern PGconn *PQconnectdb(const char *conninfo);
int PQconnectdb(uchar & conninfo[]);
//extern void PQfinish(PGconn *conn);
void PQfinish(int conn);
//extern PGresult *PQexec(PGconn *conn, const char *query);
int PQexec(int conn, uchar & query[]);
//extern ConnStatusType PQstatus(const PGconn *conn);
ConnStatusType PQstatus(int conn);
//extern char *PQerrorMessage(const PGconn *conn);
int PQerrorMessage(int conn);
/* Delete a PGresult */
//extern void PQclear(PGresult *res);
void PQclear(int res);
//extern ExecStatusType PQresultStatus(const PGresult *res);
ExecStatusType PQresultStatus(int res);
//int PQntuples(const PGresult *res);
int PQntuples(int res);
//int PQnfields(const PGresult *res);
int PQnfields(int res);
//extern char *PQgetvalue(const PGresult *res, int tup_num, int field_num);
int PQgetvalue(int res, int tup_num, int field_num);

#import

bool init_PSQL(int & dbConnectId, string conninfo)
  {
    uchar conninfoChar[];
    StringToCharArray(conninfo, conninfoChar);
    dbConnectId=PQconnectdb(conninfoChar);
    if (PQstatus(dbConnectId) != CONNECTION_OK) {
      Print("Connection to database failed: ",mql4_ansi2unicode(PQerrorMessage(dbConnectId)));
      return(false);
    } else {
      return(true);
    }
  }

void deinit_PSQL(int dbConnectId)
  {
    PQfinish(dbConnectId);
  }

//+----------------------------------------------------------------------------+
//| Simply run a query, perfect for actions like INSERTs, UPDATEs, DELETEs     |
//+----------------------------------------------------------------------------+
bool PSQL_Query(int dbConnectId, string query)
  {
    uchar queryChar[];
    StringToCharArray(query, queryChar);
    
    int res=PQexec(dbConnectId,queryChar);
    if ( PQresultStatus(res) != PGRES_COMMAND_OK ) {
      Print("Query failed: ",mql4_ansi2unicode(PQerrorMessage(dbConnectId)));
      PQclear(res);
      return (false);
    } else {
      PQclear(res);
      return (true);
    }
  }

//+----------------------------------------------------------------------------+
//| Fetch row(s) in a 2-dimansional array                                      |
//|                                                                            |
//| return (-1): error; (0): 0 rows selected; (1+): some rows selected;         |
//+----------------------------------------------------------------------------+
int PSQL_FetchArray(int dbConnectId, string query, string & data[][])
  {
    uchar queryChar[];
    StringToCharArray(query, queryChar);
    
    int res=PQexec(dbConnectId,queryChar);
    switch(PQresultStatus(res)) {
      case PGRES_EMPTY_QUERY:
      case PGRES_COMMAND_OK:
        ArrayFree(data);
        PQclear(res);
        return(0);
      case PGRES_TUPLES_OK:{
        int num_rows   = PQntuples(res);
        int num_fields = PQnfields(res);
        ArrayResize(data, num_rows);
        for ( int i = 0; i < num_rows; i++ ) {
          for ( int j = 0; j < num_fields; j++ ) {
            data[i][j]=mql4_ansi2unicode(PQgetvalue(res, i, j));
          }
        }
        PQclear(res);
        return(num_rows);
      }
    }
    Print("Query failed: ",mql4_ansi2unicode(PQerrorMessage(dbConnectId)));
    PQclear(res);
    return(-1);
  }

//+----------------------------------------------------------------------------+
//| Lovely function that helps us to get ANSI strings from DLLs to our UNICODE |
//| format                                                                     |
//| http://forum.mql4.com/60708                                                |
//+----------------------------------------------------------------------------+
string mql4_ansi2unicode(int ptrStringMemory)
  {
    int szString = lstrlenA(ptrStringMemory);
    uchar ucValue[];
    ArrayResize(ucValue, szString + 1);
    RtlMoveMemory(ucValue, ptrStringMemory, szString + 1);
    string str = CharArrayToString(ucValue);
    LocalFree(ptrStringMemory);
    return str;
  }
