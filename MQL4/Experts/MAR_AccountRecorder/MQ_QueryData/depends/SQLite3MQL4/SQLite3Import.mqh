//+------------------------------------------------------------------+
//|                                                       SQLite3API |
//|                      Copyright 2006-2014, FINEXWARE Technologies |
//|                                         http://www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property strict
#include "depends/memcpy.mqh"
#include "depends/strlen.mqh"
#include "depends/strcpy.mqh"

#define PTR32              int
#define sqlite3_stmt_p32   PTR32
#define sqlite3_p32        PTR32
#define PTRPTR32           PTR32

#define PTR64              long
#define sqlite3_stmt_p64   PTR64
#define sqlite3_p64        PTR64
#define PTRPTR64           PTR64

#define SQLITE_STATIC      0

// data types
#define SQLITE_INTEGER  1
#define SQLITE_FLOAT    2
#define SQLITE_TEXT     3
#define SQLITE_BLOB     4
#define SQLITE_NULL     5

#ifdef _X64
#else
#import "MD_DataWriter/sqlite3.dll"
int sqlite3_open(const uchar &filename[],sqlite3_p32 &paDb);
int sqlite3_open_v2(const uchar &filename[],sqlite3_p32 &paDb,int flags,const uchar &zVfs[]);
int sqlite3_close(sqlite3_p32 aDb);
int sqlite3_prepare(sqlite3_p32 aDb,const char &sql[],int nByte,sqlite3_stmt_p32 &pStmt,PTRPTR32 pzTail);
int sqlite3_prepare_v2(sqlite3_p32 aDb,const char &sql[],int nByte,sqlite3_stmt_p32 &pStmt,PTRPTR32 pzTail);
int sqlite3_exec(sqlite3_p32 aDb,const char &sql[],PTR32 acallback,PTR32 apvoid,PTRPTR32 errmsg);
int sqlite3_step(sqlite3_stmt_p32 apstmt);
int sqlite3_finalize(sqlite3_stmt_p32 apstmt);
int sqlite3_errcode(sqlite3_p32 db);
int sqlite3_extended_errcode(sqlite3_p32 db);
const PTR32 sqlite3_errmsg(sqlite3_p32 db);

int sqlite3_bind_null(sqlite3_stmt_p32 apstmt,int icol);
int sqlite3_bind_int(sqlite3_stmt_p32 apstmt,int icol,int a);
int sqlite3_bind_int64(sqlite3_stmt_p32 apstmt,int icol,long a);
int sqlite3_bind_double(sqlite3_stmt_p32 apstmt,int icol,double a);
int sqlite3_bind_text(sqlite3_stmt_p32 apstmt,int icol,char &a[],int len,PTRPTR32 destr);
int sqlite3_bind_blob(sqlite3_stmt_p32 apstmt,int icol,uchar &a[],int len,PTRPTR32 destr);

const PTR32 sqlite3_column_name(sqlite3_stmt_p32 apstmt,int icol);

int sqlite3_column_count(sqlite3_stmt_p32 apstmt);
int sqlite3_column_type(sqlite3_stmt_p32 apstmt,int acol);
int sqlite3_column_bytes(sqlite3_stmt_p32 apstmt,int acol);
int sqlite3_column_int(sqlite3_stmt_p32 apstmt,int acol);
long sqlite3_column_int64(sqlite3_stmt_p32 apstmt,int acol);
double sqlite3_column_double(sqlite3_stmt_p32 apstmt,int acol);
const PTR32 sqlite3_column_text(sqlite3_stmt_p32 apstmt,int acol);
const PTR32 sqlite3_column_blob(sqlite3_stmt_p32 apstmt,int acol);

int sqlite3_db_release_memory(sqlite3_p32 db);
#import
#endif

int sqlite3_open(const uchar &filename[],sqlite3_p64 &ppDb) { sqlite3_p32 pdb=NULL; int r=sqlite3::sqlite3_open(filename,pdb); ppDb=pdb; return(r); }
int sqlite3_open_v2(const uchar &filename[],sqlite3_p64 &ppDb, int flags, const uchar &zVfs[]) { sqlite3_p32 pdb=NULL; int r=sqlite3::sqlite3_open_v2(filename,pdb,flags,zVfs); ppDb=pdb; return(r); }
int sqlite3_close(PTR64 pDb) { return(sqlite3::sqlite3_close((PTR32)pDb)); };
int sqlite3_exec(sqlite3_p64 aDb,const char &sql[],PTR64 acallback,PTR64 avoid,PTRPTR64 errmsg) { return(sqlite3::sqlite3_exec((sqlite3_p32)aDb,sql,(PTR32)acallback,(PTR32)avoid,(PTRPTR32)errmsg)); }
int sqlite3_prepare(sqlite3_p64 aDb,const char &sql[],int nByte,sqlite3_stmt_p64 &pStmt,PTRPTR64 pzTail) { sqlite3_stmt_p32 pstmt=NULL; int r=sqlite3::sqlite3_prepare(aDb,sql,nByte,pstmt,pzTail); pStmt=pstmt; return(r); }
int sqlite3_prepare_v2(sqlite3_p64 aDb,const char &sql[],int nByte,sqlite3_stmt_p64 &pStmt,PTRPTR64 pzTail) { sqlite3_stmt_p32 pstmt=NULL; int r=sqlite3::sqlite3_prepare_v2(aDb,sql,nByte,pstmt,pzTail); pStmt=pstmt; return(r); }
int sqlite3_step(sqlite3_stmt_p64 apstmt) { return(sqlite3::sqlite3_step((sqlite3_stmt_p32)apstmt)); }
int sqlite3_finalize(sqlite3_stmt_p64 apstmt) { return(sqlite3::sqlite3_finalize((sqlite3_stmt_p32)apstmt)); }

int sqlite3_errcode(sqlite3_p64 db) { return(sqlite3::sqlite3_errcode((sqlite3_stmt_p32)db)); }
int sqlite3_extended_errcode(sqlite3_p64 db) { return(sqlite3::sqlite3_extended_errcode((sqlite3_stmt_p32)db)); }
const PTR64 sqlite3_errmsg(sqlite3_p64 db) { return(sqlite3::sqlite3_errmsg((sqlite3_stmt_p32)db)); }

int sqlite3_bind_null(sqlite3_stmt_p64 apstmt,int icol) { return(sqlite3::sqlite3_bind_null((sqlite3_stmt_p32)apstmt,icol)); }
int sqlite3_bind_int(sqlite3_stmt_p64 apstmt,int icol,int a) { return(sqlite3::sqlite3_bind_int((sqlite3_stmt_p32)apstmt,icol,a)); }
int sqlite3_bind_int64(sqlite3_stmt_p64 apstmt,int icol,long a) { return(sqlite3::sqlite3_bind_int64((sqlite3_stmt_p32)apstmt,icol,a)); }
int sqlite3_bind_double(sqlite3_stmt_p64 apstmt,int icol,double a) { return(sqlite3::sqlite3_bind_double((sqlite3_stmt_p32)apstmt,icol,a)); }
int sqlite3_bind_text(sqlite3_stmt_p64 apstmt,int icol,char &a[],int len,PTRPTR64 destr) { return(sqlite3::sqlite3_bind_text((sqlite3_stmt_p32)apstmt,icol,a,len,(PTRPTR32)destr)); }
int sqlite3_bind_blob(sqlite3_stmt_p64 apstmt,int icol,uchar &a[],int len,PTRPTR64 destr) { return(sqlite3::sqlite3_bind_blob((sqlite3_stmt_p32)apstmt,icol,a,len,(PTRPTR32)destr)); }

const PTR64 sqlite3_column_name(sqlite3_stmt_p64 apstmt,int icol) { return(sqlite3::sqlite3_column_name((sqlite3_stmt_p32)apstmt,icol)); }
int sqlite3_column_count(sqlite3_stmt_p64 apstmt) { sqlite3_stmt_p32 pstmt=(sqlite3_stmt_p32)apstmt; int r=sqlite3::sqlite3_column_count(pstmt); apstmt=pstmt; return(r); } 
int sqlite3_column_type(sqlite3_stmt_p64 apstmt,int acol) { return(sqlite3::sqlite3_column_type((sqlite3_stmt_p32)apstmt,acol)); }
int sqlite3_column_bytes(sqlite3_stmt_p64 apstmt,int acol) { return(sqlite3::sqlite3_column_bytes((sqlite3_stmt_p32)apstmt,acol)); }
int sqlite3_column_int(sqlite3_stmt_p64 apstmt,int acol) { return(sqlite3::sqlite3_column_int((sqlite3_stmt_p32)apstmt,acol)); }
long sqlite3_column_int64(sqlite3_stmt_p64 apstmt,int acol) { return(sqlite3::sqlite3_column_int64((sqlite3_stmt_p32)apstmt,acol)); }
double sqlite3_column_double(sqlite3_stmt_p64 apstmt,int acol) { return(sqlite3::sqlite3_column_double((sqlite3_stmt_p32)apstmt,acol)); }
const PTR64 sqlite3_column_text(sqlite3_stmt_p64 apstmt, int acol) { return(sqlite3::sqlite3_column_text((sqlite3_stmt_p32)apstmt, acol)); }
const PTR64 sqlite3_column_blob(sqlite3_stmt_p64 apstmt, int acol) { return(sqlite3::sqlite3_column_blob((sqlite3_stmt_p32)apstmt, acol)); }

int sqlite3_db_release_memory(PTR64 pDb) { return sqlite3::sqlite3_db_release_memory((PTR32)pDb); }

/* file open flags */
#define SQLITE_OPEN_READONLY         1  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_READWRITE        2  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_CREATE           4  /* Ok for sqlite3_open_v2() */.
#define SQLITE_OPEN_URI              64  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_MEMORY           128  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_NOMUTEX          32768  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_FULLMUTEX        65536  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_SHAREDCACHE      131072  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_PRIVATECACHE     262144  /* Ok for sqlite3_open_v2() */

#define SQLITE_OK           0   /* Successful result */
/* beginning-of-error-codes */
#define SQLITE_ERROR        1   /* SQL error or missing database */
#define SQLITE_ROW        100   /* sqlite3_step() has another row ready */
#define SQLITE_DONE       101   /* sqlite3_step() has finished executing */
//+------------------------------------------------------------------+
