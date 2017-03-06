//+------------------------------------------------------------------+
//|                                                 MAR_Settings.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
input int DebugLevel = 2; // DebugLevel: 0=None, 1=Fatal, 2=Normal, 3=Info, 4=Trivial
input bool LogAllErrorsToTerminal = true; // LogAllErrorsToTerminal
input bool LogAllErrorsToFile = false; // LogAllErrorsToFile
input string ErrorLogFileName = ""; // ErrorLogFileName: default Log_[datetime].txt in MQL4\Files
input string TimingOptions = "-------------------- Timing --------------------";
input int DelayedEntrySeconds = 10;
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
//input bool UseAllWriters = false; // UseAllWriters true, or only use first successful writer
bool UseAllWriters = true; // The way fallback mode works, if the primary DB fails, then the sub DB's record the complete recordset, making UseAllWriters redundant.
input int ConnectRetries = 5;
input int ConnectRetryDelaySecs = 1;

//input bool EnableMysql = false;
//input string MyHost = "";
//input string MyUser = "";
//input string MyPass = "";
//input string MyOrderDbName = "";
//input int MyPort = 3306;
//input int MySocket = 0;
//input int MyClientFlags = 0;

bool EnableMysql = false;
string MyHost = "";
string MyUser = "";
string MyPass = "";
string MyOrderDbName = "";
int MyPort = 3306;
int MySocket = 0;
int MyClientFlags = 0;

input bool EnablePostgres = true;
input string PgConnectOrderString = "hostaddr=127.0.0.1 port=9122 dbname=forextest user=mt4 password=U?G~.e?Mc25xZgsJ7b$/`P|it9h4CwwW connect_timeout=5";

input bool EnableSqlite = false;
input string SlOrderDbPath = "D:\\Desktop\\marTest.sqlite"; // DbPath: Use a separate file for every EA instance

//input bool EnableSqlText = false;
//input string TxOrderDbPath = "";

bool EnableSqlText = false;
string TxOrderDbPath = "";