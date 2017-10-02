//+------------------------------------------------------------------+
//|                                                     MAR_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include <MC_Common/MC_Resource.mqh>
#include "MQ_QueryData/MD_DataWriterManager.mqh"
#include "MAR_Settings.mqh"
#include <MC_Common/Uuid.mqh>

class MainAccountRecorder {
    public:
    void MainAccountRecorder();
    void ~MainAccountRecorder();
    
    bool doFirstConnect(bool force = false);
    bool doFirstRun(bool force = false);
    void doCycle(bool force = false);
    
    private:
    DataWriterManager *dWriterMan;
    
    string uuidAccount;
    string uuidCurrency;
    
    bool schemaReady;
    bool firstRunComplete;
    bool finishedCycle;
    
    datetime lastOrderTime;
    datetime lastEquityTime;
    bool lastOrderSuccess;
    bool lastEquitySuccess;
    
    bool firstWeekendNoticeFired;
    
    bool setupConnections();
    bool setupSchema();
    bool checkSchema();
    bool setupAccountRecords();
    
    int lastOrderActiveCount;
    int lastOrderHistoryCount;
    
    bool updateOrders();
    bool recordOrder(string &orderUuidOut, bool recordElectionIfEnabled = true);
    bool recordOrderExit(string orderUuid);
    bool recordOrderSplits(string orderUuid);
    bool recordOrderElection(string orderUuid);
    
    long lastEquityAccount;
    double lastEquityValue;
    double lastBalanceValue;
    
    bool updateEquity();
    bool recordOrderEquity(string equityUuid);

    void displayFeedback(bool firstRunFailed = false, bool isWeekend = false, bool schemaFailed = false, bool accountFailed = false);
};

void MainAccountRecorder::MainAccountRecorder() {
    lastEquityValue = -0.00000001;
    lastBalanceValue = -0.00000001;
    lastEquityAccount = 0;
    lastOrderActiveCount = 0;
    lastOrderHistoryCount = 0;

    doFirstConnect();
}

void MainAccountRecorder::~MainAccountRecorder() {
    if(CheckPointer(dWriterMan) == POINTER_DYNAMIC) { delete(dWriterMan); }
}

bool MainAccountRecorder::doFirstConnect(bool force = false) {
    if(CheckPointer(dWriterMan) == POINTER_DYNAMIC) { if(force) { delete(dWriterMan); } else { return false; } }

    finishedCycle = false;

    dWriterMan = new DataWriterManager();
    setupConnections();
    dWriterMan.resetBlockingErrors(); // so first run can reconnect on first failed command
    
    finishedCycle = true;
    return true;
}

bool MainAccountRecorder::setupConnections() {
    //int loc;
    
    // todo: implement ordering, modes (0=disabled, 1=normal, 2=always)
    
    //if(EnableMysql) {
    //    dWriterMan.addDataWriter(DW_Mysql, ConnectRetries, ConnectRetryDelaySecs, 
    //        MyHost, MyUser, MyPass, MyOrderDbName, MyPort, MySocket, MyClientFlags);
    //}
    
    if(EnableOdbc) {
        dWriterMan.addDataWriter(DW_Odbc, ConnectRetries, ConnectRetryDelaySecs, OdbcConnectString, OdbcDbType);
    }
    
    if(EnableOdbc2) {
        dWriterMan.addDataWriter(DW_Odbc, ConnectRetries, ConnectRetryDelaySecs, Odbc2ConnectString, Odbc2DbType);
    }
    
    if(EnableSqlite) {
        dWriterMan.addDataWriter(DW_Sqlite, ConnectRetries, ConnectRetryDelaySecs, SlOrderDbPath);
    }
    
    return true;
}

bool MainAccountRecorder::doFirstRun(bool force = false) {
    if(!finishedCycle && !force) { return false; } // todo: feedback?
    
    if(!IsConnected()) {
        Error::ThrowError(ErrorNormal, "Not connected to broker, will attempt first run on cycle.", FunctionTrace);
        displayFeedback(true);
        return false;
    }
    
    Error::PrintInfo_v02(ErrorInfo, "Starting first run", FunctionTrace, NULL, false, ErrorTerminal);
    displayFeedback(); // starting first run
    
    finishedCycle = false;
    
    if(!AccountMan.setupSchema()) {
        Error::ThrowError(ErrorNormal, "Aborting first run, schema failed for readiness.", FunctionTrace, NULL, false, ErrorTerminal);
        dWriterMan.resetBlockingErrors();
        displayFeedback(true, false, true);
        finishedCycle = true;
        return false;
    }
    if(!AccountMan.setupAccountRecords()) {
        Error::ThrowError(ErrorNormal, "Aborting first run, could not create account records.", FunctionTrace, NULL, false, ErrorTerminal);
        dWriterMan.resetBlockingErrors();
        displayFeedback(true, false, true, true);
        finishedCycle = true;
        return false;
    }
    AccountMan.doCycle(true);
    
    Error::PrintInfo_v02(ErrorInfo, "First run complete.", FunctionTrace, NULL, ErrorTerminal);
    firstRunComplete = true;
    finishedCycle = true;
    displayFeedback();
    
    return true;
}

bool MainAccountRecorder::setupSchema() {
    string scriptSrc[];

    Error::PrintInfo_v02(ErrorInfo, "Setting up schema", FunctionTrace, NULL, false, ErrorTerminal);

    // todo: ordering and modes for DB types

    string resourcePath[]; DataWriterType dbType[]; DataWriterType dbSubType[];
    
    if(EnableOdbc) {
        switch(OdbcDbType) {
            case DW_Postgres:
                Common::ArrayPush(resourcePath, "MAR_Scripts/Schema_Orders_Postgres.sql");
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(dbSubType, DW_Postgres);
                break;
                
            case DW_Sqlite:
                Common::ArrayPush(resourcePath, "MAR_Scripts/Schema_Orders_Sqlite.sql");
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(dbSubType, DW_Sqlite);
                break;
        }
    }
    
    if(EnableOdbc2) {
        switch(Odbc2DbType) {
            case DW_Postgres:
                Common::ArrayPush(resourcePath, "MAR_Scripts/Schema_Orders_Postgres.sql");
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(dbSubType, DW_Postgres);
                break;
                
            case DW_Sqlite:
                Common::ArrayPush(resourcePath, "MAR_Scripts/Schema_Orders_Sqlite.sql");
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(dbSubType, DW_Sqlite);
                break;
        }
    }
    
    if(EnableSqlite) {
        Common::ArrayPush(resourcePath, "MAR_Scripts/Schema_Orders_Sqlite.sql");
        Common::ArrayPush(dbType, DW_Sqlite);
        Common::ArrayPush(dbSubType, (DataWriterType)(-1));
    }

    for(int i = 0; i < ArraySize(resourcePath); i++) {
        if(ResourceMan.getTextResource(resourcePath[i], scriptSrc)) {
            dWriterMan.scriptRun(scriptSrc, dbType[i], -1, dbSubType[i], true);
        }
    }
    
    checkSchema();
    Error::PrintInfo_v02(ErrorInfo, "Finished setting up schema", FunctionTrace, NULL, ErrorTerminal);

    return schemaReady;
}

bool MainAccountRecorder::checkSchema() {
    int expectedTableCount = 16;
    int tableCount = 0;
    
    // todo: handle schema readiness separately for pgsql and sqlite
    
    string postgresQuery = "select count(*) from information_schema.tables where table_schema = 'public' and table_name in ('accounts', 'act_equity', 'currency', 'elections', 'enum_act_margin_so_mode', 'enum_act_mode', 'enum_exn_type', 'enum_spt_phase', 'enum_spt_subtype', 'enum_spt_type', 'enum_txn_type', 'splits', 'transactions', 'txn_orders', 'txn_orders_equity', 'txn_orders_exit');";
    string sqliteQuery = "select count(type) from sqlite_master where sqlite_master.type = 'table' and sqlite_master.name in ('accounts', 'act_equity', 'currency', 'elections', 'enum_act_margin_so_mode', 'enum_act_mode', 'enum_exn_type', 'enum_spt_phase', 'enum_spt_subtype', 'enum_spt_type', 'enum_txn_type', 'splits', 'transactions', 'txn_orders', 'txn_orders_equity', 'txn_orders_exit');";
    
    string query[]; DataWriterType dbType[]; DataWriterType subDbType[];
    if(EnableOdbc) {
        switch(OdbcDbType) {
            case DW_Postgres:
                Common::ArrayPush(query, postgresQuery);
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(subDbType, DW_Postgres);
                break;
                
            case DW_Sqlite:
                Common::ArrayPush(query, sqliteQuery);
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(subDbType, DW_Sqlite);
                break;
        }
    }
    
    if(EnableOdbc2) {
        switch(Odbc2DbType) {
            case DW_Postgres:
                Common::ArrayPush(query, postgresQuery);
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(subDbType, DW_Postgres);
                break;
                
            case DW_Sqlite:
                Common::ArrayPush(query, sqliteQuery);
                Common::ArrayPush(dbType, DW_Odbc);
                Common::ArrayPush(subDbType, DW_Sqlite);
                break;
        }
    }
    
    if(EnableSqlite) {
        Common::ArrayPush(query, sqliteQuery);
        Common::ArrayPush(dbType, DW_Sqlite);
        Common::ArrayPush(subDbType, (DataWriterType)(-1));
    }
    
    for(int i = 0; i < ArraySize(query); i++) {
        if(!dWriterMan.queryRetrieveOne(
            query[i]
            , tableCount
            , 0
            , dbType[i]
            , -1
            , subDbType[i]
            )
        ) {
            Error::ThrowError(ErrorNormal, EnumToString(dbType[i]) + (subDbType[i] > -1 ? EnumToString(subDbType[i]) : "") + ": Could not check tables to verify schema readiness", FunctionTrace, NULL, false, ErrorTerminal);
        } else {
            schemaReady = (tableCount == expectedTableCount);
            
            if(!schemaReady) {
                Error::ThrowError(ErrorNormal, EnumToString(dbType[i]) + (subDbType[i] > -1 ? EnumToString(subDbType[i]) : "") + " Schema error: Table count " + tableCount + " does not match expected " + expectedTableCount, FunctionTrace);
                return false;
            }
        }
    }
    
    return true;
}

bool MainAccountRecorder::setupAccountRecords() {
    if(!IsConnected()) {
        Error::ThrowError(ErrorNormal, "Not connected to server", FunctionTrace, NULL, false, ErrorTerminal);
        return false;
    }
    
    int actNum = AccountInfoInteger(ACCOUNT_LOGIN);
    int actMode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
    string actName = AccountInfoString(ACCOUNT_NAME);
    string curName = AccountInfoString(ACCOUNT_CURRENCY);
    string actServer = AccountInfoString(ACCOUNT_SERVER);
    string actCompany = AccountInfoString(ACCOUNT_COMPANY);
    
    if(actNum <= 0 || StringLen(curName) < 1) {
        Error::ThrowError(ErrorNormal, "Cannot get account number or currency name", FunctionTrace, actNum +"|" + curName);
        return false;
    }
    
    if(!dWriterMan.queryRunConditional(
        StringFormat("select uuid from currency where name='%s';", curName)
        , uuidCurrency
        , ""
        , StringFormat("INSERT INTO currency (uuid, name) SELECT '%%s', '%s' WHERE NOT EXISTS (select name from currency where name='%s');"
            , curName
            , curName
            )
        , ""
        , ""
        , GetUuid()
        , -1
        , -1
        , true
        )
    ) {
        Error::ThrowError(ErrorNormal, "Could not create identifying currency record", FunctionTrace);
    }
    
    if(!dWriterMan.queryRunConditional(
        StringFormat("select uuid from accounts where num='%i';", actNum)
        , uuidAccount
        , ""
        , StringFormat("INSERT INTO accounts (uuid, cny_uuid, num, mode, name, server, company) SELECT '%%s', '%s', '%i', '%i', '%s', '%s', '%s' WHERE NOT EXISTS (select num from accounts where num='%i');"
            , uuidCurrency
            , actNum
            , actMode
            , actName
            , actServer
            , actCompany
            , actNum
            )
        , ""
        , ""
        , GetUuid()
        , -1
        , -1
        , true
        )
    ) {
        Error::ThrowError(ErrorNormal, "Could not create identifying account record", FunctionTrace);
    }
    
    return true;
}

void MainAccountRecorder::doCycle(bool force = false) {
    if(!finishedCycle && !force) { return; } // todo: feedback?
    
    if(!IsConnected()) {
        Error::ThrowError(ErrorNormal, "Not connected to broker, cannot do cycle.", FunctionTrace);
        dWriterMan.resetBlockingErrors();
        displayFeedback(); // IsConnected() checked in feedback
        return;
    }

    datetime currentTimerTime = TimeLocal();
    
    if(SkipWeekends) {
        if(Common::IsDatetimeInRange(currentTimerTime, EndWeekday, EndWeekdayHour, StartWeekday, StartWeekdayHour)) {
            if(!firstWeekendNoticeFired) {
                Error::PrintInfo_v02(ErrorInfo, "Currently a weekend, running cycle once before trading week starts again.", FunctionTrace, NULL, false, ErrorTerminal);
                firstWeekendNoticeFired = true;
            } else if(!force) { 
                dWriterMan.resetBlockingErrors(); 
                displayFeedback(false, true);
                return; 
            }
        } else {
            firstWeekendNoticeFired = false;
        }
    }
    
    finishedCycle = false;
    displayFeedback();
    Error::PrintInfo("Doing cycle...");
    
    if(!checkSchema()) {
        if(!setupSchema()) {
            Error::ThrowError(ErrorNormal, "Could not verify schema readiness, aborting cycle.", FunctionTrace, NULL, false, ErrorTerminal);
            dWriterMan.resetBlockingErrors();
            finishedCycle = true;
            displayFeedback(false, false, true);
            return;
        }
    }
    
    if(EnableOrderRecording && (force || (currentTimerTime - lastOrderTime >= OrderRefreshSeconds))) {
        Error::PrintInfo_v02(ErrorInfo, "Updating order records...", FunctionTrace, NULL, ErrorTerminal);
        lastOrderSuccess = updateOrders();
        lastOrderTime = currentTimerTime;
    }
    
    if(EnableEquityRecording && (force || (currentTimerTime - lastEquityTime >= EquityRefreshSeconds))) {
        Error::PrintInfo_v02(ErrorInfo, "Updating equity records...", FunctionTrace, NULL, ErrorTerminal);
        lastEquitySuccess = updateEquity();
        lastEquityTime = currentTimerTime;
    }
    
    if(EnableSqlite && SlForceFreeMem) {
        dWriterMan.freeMemory(DW_Sqlite);
    }
    
    Error::PrintInfo_v02(ErrorInfo, "Cycle completed.", FunctionTrace, NULL, ErrorTerminal);
    dWriterMan.resetBlockingErrors();
    finishedCycle = true;
    if(firstRunComplete) { displayFeedback(); }
}

bool MainAccountRecorder::updateOrders() {
    string orderUuid;
    
    int orderCount = OrdersTotal();
    // todo: more robust active trade detection
    // compare a list of order IDs
    // possibly compare specific order values? comment, value, etc.?
    //if(CollapseOrderUpdates && lastOrderActiveCount == orderCount) {
    //    Error::PrintInfo("No new active orders.");
    //} else {
        for(int i = 0; i < orderCount; i++) {
            if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }
            
            recordOrder(orderUuid);
        }
        lastOrderActiveCount = orderCount;
    //}
    
    orderCount = OrdersHistoryTotal();
    if(CollapseOrderUpdates && lastOrderHistoryCount == orderCount) {
        Error::PrintInfo("No new closed orders.");
    } else {
        for(int i = 0; i < orderCount; i++) {
            if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) { continue; }
            
            recordOrder(orderUuid);
        }
        lastOrderHistoryCount = orderCount;
    }
    
    return true;
}

bool MainAccountRecorder::recordOrder(string &orderUuidOut, bool recordElectionIfEnabled = true) {
    // Assumes OrderSelect was already called
    string orderUuid = ""; string orderSpecificUuid = ""; string balanceUuid = ""; string query="";
    int orderTypeId = OrderType();
    int orderNum = OrderTicket();
    string orderCom = OrderComment();
    
    if(!dWriterMan.queryRunConditional(
        StringFormat("select uuid from transactions where num='%i';", orderNum)
        , orderUuid
        , ""
        , StringFormat("INSERT INTO transactions (uuid, act_uuid, type, num, comment, magic, entry_datetime) SELECT '%%s', '%s', '%i', '%i', '%s', '%i', '%s' WHERE NOT EXISTS (select num from transactions where num='%i');"
            , uuidAccount
            , orderTypeId
            , orderNum
            , orderCom
            , OrderMagicNumber()
            , Common::GetSqlDatetime(OrderOpenTime(), true, BrokerTimeZone)
            , orderNum
            )
        , ""
        , ""
        , GetUuid()
        , -1
        , -1
        , UseAllWriters
        )
    ) {
        Error::ThrowError(ErrorNormal, "Could not create identifying order record", FunctionTrace, orderNum);
        orderUuidOut = "";
        return false;
    }
        
    // todo: handle partial lot closes?
    // is the original order modified, or new orders created?
    if(orderTypeId < 6) { // OP_BUY, OP_SELL, OP_BUYSTOP, OP_SELLSTOP, OP_BUYLIMIT, OP_SELLLIMIT (6 = Balance)
        // record txn_orders
        // lots can change, but should not be updated here.
        // todo: pendings - change OrderType when a pending order changes type to a OP_BUY/OP_SELL?
        if(!dWriterMan.queryRunConditional(
            StringFormat("select txn_uuid from txn_orders where txn_uuid='%s';", orderUuid)
            , orderSpecificUuid
            , ""
            , StringFormat("INSERT INTO txn_orders (txn_uuid, symbol, lots, entry_price, entry_stoploss, entry_takeprofit) VALUES ('%%s', '%s', '%f', '%f', '%f', '%f');"
                , OrderSymbol()
                , OrderLots()
                , OrderOpenPrice()
                , OrderStopLoss()
                , OrderTakeProfit()
                )
            , ""
            , ""
            , orderUuid // GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            Error::ThrowError(ErrorNormal, "Could not create order-specific record", FunctionTrace, orderNum);
        }
        
        recordOrderExit(orderUuid);
        
        recordOrderSplits(orderUuid);
        
        if(recordElectionIfEnabled) { recordOrderElection(orderUuid); }
    } else if(orderTypeId >= 6) { // balance transaction, undocumented https://www.mql5.com/en/forum/134197
        if(!dWriterMan.queryRunConditional(
            StringFormat("select uuid from splits where txn_uuid='%s';", orderUuid)
            , balanceUuid
            , ""
            , StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%%s', '%s', '%s', '%i', '%i', '%i', '%f');"
                , orderUuid
                , uuidCurrency
                , -1
                , 3 // adjustment
                , orderCom == "Deposit" ? 4 : orderCom == "Withdrawal" ? 5 : -1
                , OrderProfit() // is adjustment amount in this case
                )
            , ""
            , ""
            , GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            Error::ThrowError(ErrorNormal, "Could not create balance split", FunctionTrace, orderNum);
        }
    }
    
    orderUuidOut = orderUuid;
    return true;
}

bool MainAccountRecorder::recordOrderExit(string orderUuid) {
    if(OrderType() > OP_SELL) { 
        Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
        return false;
    }
    
    string query = "";
    string exitSpecificUuid = "";

    // record txn_orders_exit
    if(OrderCloseTime() > 0) {
        // todo: pendings - add OrderType() to exit
        if(!dWriterMan.queryRunConditional(
            StringFormat("select txn_uuid from txn_orders_exit where txn_uuid='%s';", orderUuid)
            , exitSpecificUuid
            , ""
            , StringFormat("INSERT INTO txn_orders_exit (txn_uuid, exit_datetime, exit_lots, exit_price, exit_stoploss, exit_takeprofit, exit_comment) VALUES ('%%s', '%s', '%f', '%f', '%f', '%f', '%s');"
                , Common::GetSqlDatetime(OrderCloseTime(), true, BrokerTimeZone)
                , OrderLots()
                , OrderClosePrice()
                , OrderStopLoss()
                , OrderTakeProfit()
                , OrderComment() // sometimes comment will be overwritten by stopout notes
                )
            , ""
            , ""
            , orderUuid // GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            Error::ThrowError(ErrorNormal, "Could not create order-specific exit record", FunctionTrace, OrderTicket());
            return false;
        }
    }
    
    return true;
}

bool MainAccountRecorder::recordOrderSplits(string orderUuid) {
    if(OrderType() > OP_SELL) { // todo: pendings - record splits for pendings?
        Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
        return false;
    }
    
    bool returnResult = true; string query = ""; string splitUuid = ""; bool callResult = false; 
    
    if(OrderCommission() != 0) {
        if(dWriterMan.queryRunConditional(
            StringFormat("select uuid from splits where txn_uuid='%s' and type='%i' and subtype='%i';", orderUuid, 2, 1)
            , splitUuid
            , callResult
            , ""
            , StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%%s', '%s', '%s', '%i', '%i', '%i', '%f');"
                , orderUuid
                , uuidCurrency
                , -1
                , 2 // fee
                , 1 // commission
                , OrderCommission()
                )
            , ""
            , ""
            , GetUuid()
            , -1 
            , -1
            , UseAllWriters
            )
        ) {
            if(callResult && !dWriterMan.queryRunConditional(
                StringFormat("select uuid from splits where uuid='%s' and amount='%f';", splitUuid, OrderCommission())
                , splitUuid
                , callResult
                , ""
                , StringFormat("UPDATE splits SET amount='%f' WHERE uuid='%s'"
                    , OrderCommission()
                    , splitUuid
                    )
                , "", "", "", -1, -1
                , UseAllWriters
                )
            ) {
                Error::ThrowError(ErrorNormal, "Could not update order commission split", FunctionTrace, OrderTicket());
                returnResult = false;
            }
        } else {
            Error::ThrowError(ErrorNormal, "Could not create order commission split", FunctionTrace, OrderTicket());
            returnResult = false;
        }
    }
        
    if(OrderSwap() != 0) {
        if(dWriterMan.queryRunConditional(
            StringFormat("select uuid from splits where txn_uuid='%s' and type='%i' and subtype='%i';", orderUuid, 2, 2)
            , splitUuid
            , callResult
            , ""
            , StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%%s', '%s', '%s', '%i', '%i', '%i', '%f');"
                , orderUuid
                , uuidCurrency
                , -1
                , 2 // fee
                , 2 // swap
                , OrderSwap()
                )
            , ""
            , ""
            , GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            if(callResult && !dWriterMan.queryRunConditional(
                StringFormat("select uuid from splits where uuid='%s' and amount='%f';", splitUuid, OrderSwap())
                , splitUuid
                , callResult
                , ""
                , StringFormat("UPDATE splits SET amount='%f' WHERE uuid='%s'"
                    , OrderSwap()
                    , splitUuid
                    )
                , "", "", "", -1, -1
                , UseAllWriters    
                )
            ) {
                Error::ThrowError(ErrorNormal, "Could not update order swap split", FunctionTrace, OrderTicket());
                returnResult = false;
            }
        } else {
            Error::ThrowError(ErrorNormal, "Could not create order swap split", FunctionTrace, OrderTicket());
            returnResult = false;
        }
    }
    
    if(dWriterMan.queryRunConditional(
        StringFormat("select uuid from splits where txn_uuid='%s' and type='%i' and subtype='%i';", orderUuid, 1, -1)
        , splitUuid
        , callResult
        , ""
        , StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%%s', '%s', '%s', '%i', '%i', '%i', '%f');"
            , orderUuid
            , uuidCurrency
            , -1
            , 1 // gross
            , -1 // does not apply
            , OrderProfit() // does not include fee or swap (or taxes -- NOTE: MQL4 DOES NOT EXPOSE TAX EXPENSE)
            )
        , ""
        , ""
        , GetUuid()
        , -1
        , -1
        , UseAllWriters
        )
    ) {
        if(callResult && !dWriterMan.queryRunConditional(
            StringFormat("select uuid from splits where uuid='%s' and amount='%f';", splitUuid, OrderProfit())
            , splitUuid
            , callResult
            , ""
            , StringFormat("UPDATE splits SET amount='%f' WHERE uuid='%s'"
                , OrderProfit()
                , splitUuid
                )
            , "", "", "", -1, -1
            , UseAllWriters
            )
        ) {
            Error::ThrowError(ErrorNormal, "Could not update order withdrawal split", FunctionTrace, OrderTicket());
            returnResult = false;
        }
    } else {
        Error::ThrowError(ErrorNormal, "Could not create order withdrawal split", FunctionTrace, OrderTicket());
        returnResult = false;
    }
    
    return returnResult;
}

bool MainAccountRecorder::recordOrderElection(string orderUuid) {
    if(OrderType() > OP_SELL) { // todo: pendings - record for pendings? most likely not
        Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
        return false;
    }
    
    string electionUuid = ""; string query = "";
    
    if(RecordOrderElection) {
        if(!dWriterMan.queryRunConditional(
            StringFormat("select uuid from elections where txn_uuid='%s';", orderUuid)
            , electionUuid
            , ""
            , StringFormat("INSERT INTO elections (uuid, txn_uuid, type, active, made_datetime, recorded_datetime) VALUES ('%%s', '%s', '%i', '%i', '%s', '%s');"
                , orderUuid
                , ElectionId
                , 1 // true
                , Common::GetSqlDatetime(TimeLocal(), true)
                , Common::GetSqlDatetime(TimeLocal(), true) // todo: sql trigger instead?
                )
            , ""
            , ""
            , GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            Error::ThrowError(ErrorNormal, "Could not create order election entry", FunctionTrace, OrderTicket());
            return false;
        }
        return true;
    } 
    else { return false; }
}

bool MainAccountRecorder::updateEquity() {
    string equityUuid = GetUuid(); string query = "";
    
    if(CollapseEquityUpdates
        && lastEquityValue == AccountInfoDouble(ACCOUNT_EQUITY)
        && lastBalanceValue == AccountInfoDouble(ACCOUNT_BALANCE)
        && lastEquityAccount == AccountInfoInteger(ACCOUNT_LOGIN) 
    ) {
        Error::PrintInfo("No new equity activity");
        return true;
    }
    
    query = StringFormat("INSERT INTO act_equity (uuid, act_uuid, record_datetime, leverage, margin_so_mode, margin_so_call, margin_so_so, balance, equity, credit, margin) VALUES ('%s', '%s', '%s', '%i', '%i', '%f', '%f', '%f', '%f', '%f', '%f');"
        , equityUuid
        , uuidAccount
        , Common::GetSqlDatetime(TimeLocal(), true)
        , AccountInfoInteger(ACCOUNT_LEVERAGE)
        , AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE)
        , AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)
        , AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)
        , AccountInfoDouble(ACCOUNT_BALANCE)
        , AccountInfoDouble(ACCOUNT_EQUITY)
        , AccountInfoDouble(ACCOUNT_CREDIT)
        , AccountInfoDouble(ACCOUNT_MARGIN)
        );
    if(!dWriterMan.queryRun(query, -1, -1, UseAllWriters)) {
        Error::ThrowError(ErrorNormal, "Could not record account equity", FunctionTrace, equityUuid);
    }
    
    int orderCount = OrdersTotal();
    for(int i = 0; i < orderCount; i++) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }
        
        recordOrderEquity(equityUuid);
    }
    
    lastEquityValue = AccountInfoDouble(ACCOUNT_EQUITY);
    lastBalanceValue = AccountInfoDouble(ACCOUNT_BALANCE);
    lastEquityAccount = AccountInfoInteger(ACCOUNT_LOGIN);
    
    return true;
}


bool MainAccountRecorder::recordOrderEquity(string equityUuid) {
    // Assumes OrderSelect was already called
    string orderUuid = "";
    int orderNum = OrderTicket();
    string query = "";
    
    if(!recordOrder(orderUuid)) {
        Error::ThrowError(ErrorNormal, "Could not create identifying order record", FunctionTrace);
    }
    
    // todo: should lots be recorded in equity? how about comments?
    // partial closes: are lots modified, or are new tickets created?
    // comments -- record only if there is a change? record always? not at all?
    // recordd spread? probably not
    
    // order current price: https://www.mql5.com/en/forum/102462
    // buy orders will be closed at Bid, so Bid-OrderOpenPrice() 
    // sell orders at Ask, so OrderOpenPrice()-Ask
    // alt: what is mode_tickvalue?  OrderProfit() - OrderCommision() ) / OrderLots() / MarketInfo( OrderSymbol(), MODE_TICKVALUE
    
    // todo: pendings - select Ask/Bid for pending orders, also record OrderType()
    query = StringFormat("INSERT INTO txn_orders_equity (txn_uuid, eqt_uuid, price, stoploss, takeprofit, commission, swap, gross) VALUES ('%s', '%s', '%f', '%f', '%f', '%f', '%f', '%f');"
        , orderUuid
        , equityUuid
        , OrderType() == OP_SELL ? MarketInfo(OrderSymbol(), MODE_ASK) : MarketInfo(OrderSymbol(), MODE_BID)
        , OrderStopLoss()
        , OrderTakeProfit()
        , OrderCommission()
        , OrderSwap()
        , OrderProfit()
//        , OrderComment()
        );
    if(!dWriterMan.queryRun(query, -1, -1, UseAllWriters)) {
        Error::ThrowError(ErrorNormal, "Could not create order equity entry", FunctionTrace, orderNum);
    }
    
    return true;
}

void MainAccountRecorder::displayFeedback(bool firstRunFailed = false, bool isWeekend = false, bool schemaFailed = false, bool accountFailed = false) {
    int orderRefreshMins = MathFloor(OrderRefreshSeconds / 60);
    int orderRefreshSecs = OrderRefreshSeconds - (orderRefreshMins*60);
    int equityRefreshMins = MathFloor(EquityRefreshSeconds/60);
    int equityRefreshSecs = EquityRefreshSeconds - (equityRefreshMins*60);
    
    Comment(
        "AccountRecorder\r\n"
        , (int)lastOrderTime > 0 ? 
            "Last Order Cycle: " + TimeToString(lastOrderTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS)
                + (!lastOrderSuccess ? " (Failed!)" : "")
                + "\r\n"
            : ""
        , (int)lastEquityTime > 0 ? 
            "Last Equity Cycle: " + TimeToString(lastEquityTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS)
                + (!lastEquitySuccess ? " (Failed!)" : "")
                + "\r\n"
            : ""
            
        , "\r\n"
        , firstRunComplete && IsConnected() && !isWeekend ? 
            (EnableOrderRecording ? "Order Cycle:" 
                + (orderRefreshMins > 0 ? " " + orderRefreshMins + " min" : "")
                + (orderRefreshSecs > 0 ? " " + orderRefreshSecs + " secs" : "")
                : "" 
                )
            + (EnableEquityRecording && EnableOrderRecording ? ", " : " ")
            + (EnableEquityRecording ? "Equity Cycle:" 
                + (equityRefreshMins > 0 ? " " + equityRefreshMins + " min" : "")
                + (equityRefreshSecs > 0 ? " " + equityRefreshSecs + " secs" : "")
                : "" 
                )
            + "\r\n"
            : ""
            
        , "\r\n"
        , !firstRunComplete && !firstRunFailed ? "Doing first run...\r\n" : ""
        , schemaFailed ? "Could not verify schema readiness, trying again next cycle.\r\n" : ""
        , accountFailed ? "Could not verify master account records, trying again next cycle.\r\n" : "" 
        , !firstRunComplete && firstRunFailed ? "First run failed, trying again " 
            + (DelayedEntrySeconds > 0 ? "in " + DelayedEntrySeconds + " seconds." : "") 
            + "\r\n"
            : ""
            
        , firstRunComplete && !finishedCycle ? "Doing cycle...\r\n" : ""
        , isWeekend ? "Currently a weekend, sleeping until "
            + (StartWeekday == 0 ? "Sunday "
                : StartWeekday == 1 ? "Monday "
                : StartWeekday == 2 ? "Tuesday "
                : StartWeekday == 3 ? "Wednesday "
                : StartWeekday == 4 ? "Thursday "
                : StartWeekday == 5 ? "Friday "
                : StartWeekday == 6 ? "Saturday "
                : ""
                )
            + StartWeekdayHour + ":00.\r\n"
            : ""
        , !IsConnected() ? "Not connected to broker, trying again next cycle.\r\n" : ""
        );
}

MainAccountRecorder *AccountMan;
