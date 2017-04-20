//+------------------------------------------------------------------+
//|                                                 MAR_Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#include "MC_Common/MC_Error.mqh"

//+------------------------------------------------------------------+
input ErrorLevelConfig ErrorTerminalLevel=ErrorConfigFatalNormal;
input ErrorLevelConfig ErrorFileLevel=ErrorConfigNone;
input ErrorLevelConfig ErrorAlertLevel=ErrorConfigFatal;
input string ErrorLogFileName=""; // ErrorLogFileName: Leave blank to generate a filename
input string TimingOptions = "-------------------- Timing --------------------";
input int DelayedEntrySeconds = 5;
input int OrderRefreshSeconds = 60;
input int EquityRefreshSeconds = 300;
//input bool SkipIfDisconnected = true;
input bool SkipWeekends = true;
input int StartWeekday = 0; // Start weekday from Sunday = 0, Monday = 1 .. Saturday = 6
input int StartWeekdayHour = 17;
input int EndWeekday = 5; // End weekday from Sunday = 0, Monday = 1 .. Saturday = 6
input int EndWeekdayHour = 16;
input string BrokerTimeZone = "+02:00";

input string TaxElectionOptions = "----------------- Tax Elections ----------------";
input string TaxElectionTypes = "1 - USA Sec. 988(a)(1)(B)"; // Tax elections: Fill ElectionId with one of these values
input bool RecordOrderElection = true; // Record tax election
input int ElectionId = 1;

input string DatabaseOptions = "---------------- Database Targets --------------";
input bool EnableOrderRecording = true;
input bool EnableEquityRecording = true;
bool UseAllWriters = true; // The way fallback mode works, if the primary DB fails, then the sub DB's record the complete recordset, making UseAllWriters redundant.
input int ConnectRetries = 5;
input int ConnectRetryDelaySecs = 1;

input bool EnableOdbc = true; // EnableOdbc: Primary database connection
input string OdbcConnectString = "DSN=PostgreSQL30";
input int OdbcDbType = 4; // OdbcDbType: 3=Sqlite, 4=Postgres, 5=Mysql

input bool EnableOdbc2 = true; // EnableOdbc2: Backup database connection
input string Odbc2ConnectString = "DSN=SqliteOdbcTest"; 
input int Odbc2DbType = 3; // Odbc2DbType: 3=Sqlite, 4=Postgres, 5=Mysql

input bool EnableSqlite = false; // EnableSqlite: Use internal SQLite DLL instead of ODBC. Is less stable; ODBC is recommended. Needs sqlite3.dll in MQL4/Libraries/MD_DataWriter
bool SlForceFreeMem = true; // appears to be necessary -- sqlite fails and reports out of memory if MT4's garbage collection frees too much mem.
input string SlOrderDbPath = "D:\\Desktop\\marTest.sqlite"; // DbPath: Use a separate file for every EA instance
