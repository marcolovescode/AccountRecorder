//+------------------------------------------------------------------+
//|                                                     MAR_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include "MC_Common/MC_Resource.mqh"
#include "MD_DataWriter/MD_DataWriterManager.mqh"
#include "MAR_Settings.mqh"

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
    
    bool updateOrders();
    bool recordOrder(string &orderUuidOut, bool recordElectionIfEnabled = true);
    bool recordOrderExit(string orderUuid);
    bool recordOrderSplits(string orderUuid);
    bool recordOrderElection(string orderUuid);
    
    bool updateEquity();
    bool recordOrderEquity(string equityUuid);

    void displayFeedback(bool firstRunFailed = false, bool isWeekend = false, bool schemaFailed = false, bool accountFailed = false);
};

void MainAccountRecorder::MainAccountRecorder() {
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
    
    if(EnablePostgres) {
        dWriterMan.addDataWriter(DW_Postgres, ConnectRetries, ConnectRetryDelaySecs, PgConnectOrderString);
    }
    
    if(EnableSqlite) {
        dWriterMan.addDataWriter(DW_Sqlite, ConnectRetries, ConnectRetryDelaySecs, SlOrderDbPath);
    }
    
    return true;
}

bool MainAccountRecorder::doFirstRun(bool force = false) {
    if(!finishedCycle && !force) { return false; } // todo: feedback?
    
    if(!IsConnected()) {
        MC_Error::ThrowError(ErrorNormal, "Not connected to broker, will attempt first run on cycle.", FunctionTrace);
        displayFeedback(true);
        return false;
    }
    
    MC_Error::PrintInfo(ErrorInfo, "Starting first run", FunctionTrace, NULL, ErrorForceTerminal);
    displayFeedback(); // starting first run
    
    finishedCycle = false;
    
    if(!AccountMan.setupSchema()) {
        MC_Error::ThrowError(ErrorNormal, "Aborting first run, schema failed for readiness.", FunctionTrace, NULL, false, ErrorForceTerminal);
        dWriterMan.resetBlockingErrors();
        displayFeedback(true, false, true);
        finishedCycle = true;
        return false;
    }
    if(!AccountMan.setupAccountRecords()) {
        MC_Error::ThrowError(ErrorNormal, "Aborting first run, could not create account records.", FunctionTrace, NULL, false, ErrorForceTerminal);
        dWriterMan.resetBlockingErrors();
        displayFeedback(true, false, true, true);
        finishedCycle = true;
        return false;
    }
    AccountMan.doCycle(true);
    
    MC_Error::PrintInfo(ErrorInfo, "First run complete.", FunctionTrace, NULL, ErrorForceTerminal);
    firstRunComplete = true;
    finishedCycle = true;
    displayFeedback();
    
    return true;
}

bool MainAccountRecorder::setupSchema() {
    string scriptSrc[];

    MC_Error::PrintInfo(ErrorInfo, "Setting up schema", FunctionTrace, NULL, ErrorForceTerminal);

    // todo: ordering and modes for DB types

    //if(EnableMysql && ResourceMan.getTextResource("MAR_Scripts/Schema_Orders_Mysql.sql", scriptSrc)) {
    //    dWriterMan.scriptRun(scriptSrc, DW_Mysql, -1, UseAllWriters);
    //}

    if(EnablePostgres && ResourceMan.getTextResource("MAR_Scripts/Schema_Orders_Postgres.sql", scriptSrc)) {
        dWriterMan.scriptRun(scriptSrc, DW_Postgres, -1, true);
    }

    if(EnableSqlite && ResourceMan.getTextResource("MAR_Scripts/Schema_Orders_Sqlite.sql", scriptSrc)) {
        dWriterMan.scriptRun(scriptSrc, DW_Sqlite, -1, true);
    }
    
    checkSchema();
    MC_Error::PrintInfo(ErrorInfo, "Finished setting up schema", FunctionTrace, NULL, ErrorForceTerminal);

    return schemaReady;
}

bool MainAccountRecorder::checkSchema() {
    int expectedTableCount = 16;
    int tableCount = 0;
    
    // todo: handle schema readiness separately for pgsql and sqlite
    
    if(EnablePostgres) {
        if(!dWriterMan.queryRetrieveOne(
            "select count(*) from information_schema.tables where table_schema = 'public' and table_name in ('accounts', 'act_equity', 'currency', 'elections', 'enum_act_margin_so_mode', 'enum_act_mode', 'enum_exn_type', 'enum_spt_phase', 'enum_spt_subtype', 'enum_spt_type', 'enum_txn_type', 'splits', 'transactions', 'txn_orders', 'txn_orders_equity', 'txn_orders_exit');"
            , tableCount
            , 0
            , DW_Postgres
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "PgSQL: Could not check tables to verify schema readiness", FunctionTrace, NULL, false, ErrorForceTerminal);
        } else {
            schemaReady = (tableCount == expectedTableCount);
            
            if(!schemaReady) {
                MC_Error::ThrowError(ErrorNormal, "PgSQL Schema error: Table count " + tableCount + " does not match expected " + expectedTableCount, FunctionTrace);
                return false;
            }
        }
    }
    
    if(EnableSqlite) {
        if(!dWriterMan.queryRetrieveOne(
            "select count(type) from sqlite_master where sqlite_master.type = 'table' and sqlite_master.name in ('accounts', 'act_equity', 'currency', 'elections', 'enum_act_margin_so_mode', 'enum_act_mode', 'enum_exn_type', 'enum_spt_phase', 'enum_spt_subtype', 'enum_spt_type', 'enum_txn_type', 'splits', 'transactions', 'txn_orders', 'txn_orders_equity', 'txn_orders_exit');"
            , tableCount
            , 0
            , DW_Sqlite
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "SQLite: Could not check tables to verify schema readiness", FunctionTrace, NULL, false, ErrorForceTerminal);
        } else {
            schemaReady = (tableCount == expectedTableCount);
            
            if(!schemaReady) {
                MC_Error::ThrowError(ErrorNormal, "SQLite Schema error: Table count " + tableCount + " does not match expected " + expectedTableCount, FunctionTrace);
                return false;
            }
        }
    }
    
    return true;
}

bool MainAccountRecorder::setupAccountRecords() {
    if(!IsConnected()) {
        MC_Error::ThrowError(ErrorNormal, "Not connected to server", FunctionTrace, NULL, false, ErrorForceTerminal);
        return false;
    }
    
    int actNum = AccountInfoInteger(ACCOUNT_LOGIN);
    int actMode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
    string actName = AccountInfoString(ACCOUNT_NAME);
    string curName = AccountInfoString(ACCOUNT_CURRENCY);
    string actServer = AccountInfoString(ACCOUNT_SERVER);
    string actCompany = AccountInfoString(ACCOUNT_COMPANY);
    
    if(actNum <= 0 || StringLen(curName) < 1) {
        MC_Error::ThrowError(ErrorNormal, "Cannot get account number or currency name", FunctionTrace, actNum +"|" + curName);
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
        , MC_Common::GetUuid()
        , -1
        , -1
        , true
        )
    ) {
        MC_Error::ThrowError(ErrorNormal, "Could not create identifying currency record", FunctionTrace);
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
        , MC_Common::GetUuid()
        , -1
        , -1
        , true
        )
    ) {
        MC_Error::ThrowError(ErrorNormal, "Could not create identifying account record", FunctionTrace);
    }
    
    return true;
}

void MainAccountRecorder::doCycle(bool force = false) {
    if(!finishedCycle && !force) { return; } // todo: feedback?
    
    if(!IsConnected()) {
        MC_Error::ThrowError(ErrorNormal, "Not connected to broker, cannot do cycle.", FunctionTrace);
        dWriterMan.resetBlockingErrors();
        displayFeedback(); // IsConnected() checked in feedback
        return;
    }

    datetime currentTimerTime = TimeLocal();
    
    if(SkipWeekends) {
        if(MC_Common::IsDatetimeInRange(currentTimerTime, EndWeekday, EndWeekdayHour, StartWeekday, StartWeekdayHour)) {
            if(!firstWeekendNoticeFired) {
                MC_Error::PrintInfo(ErrorInfo, "Currently a weekend, running cycle once before trading week starts again.", FunctionTrace, NULL, ErrorForceTerminal);
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
    MC_Error::PrintInfo(ErrorInfo, "Doing cycle...", FunctionTrace, NULL, ErrorForceTerminal);
    
    if(!checkSchema()) {
        if(!setupSchema()) {
            MC_Error::ThrowError(ErrorNormal, "Could not verify schema readiness, aborting cycle.", FunctionTrace, NULL, false, ErrorForceTerminal);
            dWriterMan.resetBlockingErrors();
            finishedCycle = true;
            displayFeedback(false, false, true);
            return;
        }
    }
    
    if(EnableOrderRecording && (force || (currentTimerTime - lastOrderTime >= OrderRefreshSeconds))) {
        MC_Error::PrintInfo(ErrorInfo, "Updating order records...", FunctionTrace, NULL, ErrorForceTerminal);
        lastOrderSuccess = updateOrders();
        lastOrderTime = currentTimerTime;
    }
    
    if(EnableEquityRecording && (force || (currentTimerTime - lastEquityTime >= EquityRefreshSeconds))) {
        MC_Error::PrintInfo(ErrorInfo, "Updating equity records...", FunctionTrace, NULL, ErrorForceTerminal);
        lastEquitySuccess = updateEquity();
        lastEquityTime = currentTimerTime;
    }
    
    MC_Error::PrintInfo(ErrorInfo, "Cycle completed.", FunctionTrace, NULL, ErrorForceTerminal);
    dWriterMan.resetBlockingErrors();
    finishedCycle = true;
    if(firstRunComplete) { displayFeedback(); }
}

bool MainAccountRecorder::updateOrders() {
    string orderUuid;
    
    int orderCount = OrdersTotal();
    for(int i = 0; i < orderCount; i++) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }
        if(OrderType() > OP_SELL) { continue; } // is a pending order, then continue
        
        recordOrder(orderUuid);
    }
    
    orderCount = OrdersHistoryTotal();
    for(int i = 0; i < orderCount; i++) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) { continue; }
        if(OrderType() > OP_SELL && OrderType() < 6) { continue; } // is a pending order, then continue // 6 is a balance transaction, let it through
        
        recordOrder(orderUuid);
    }
    
    return true;
}

bool MainAccountRecorder::recordOrder(string &orderUuidOut, bool recordElectionIfEnabled = true) {
    // Assumes OrderSelect was already called
    string orderUuid = ""; string orderSpecificUuid = ""; string balanceUuid = ""; string query="";
    int orderTypeId = OrderType();
    int orderNum = OrderTicket();
    string orderCom = OrderComment();
    
    if(orderTypeId > OP_SELL && orderTypeId < 6) { return false; } // ignore buy/sell stops and limits. todo: how to handle?
    
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
            , MC_Common::GetSqlDatetime(OrderOpenTime(), true, BrokerTimeZone)
            , orderNum
            )
        , ""
        , ""
        , MC_Common::GetUuid()
        , -1
        , -1
        , UseAllWriters
        )
    ) {
        MC_Error::ThrowError(ErrorNormal, "Could not create identifying order record", FunctionTrace, orderNum);
        orderUuidOut = "";
        return false;
    }
        
    // todo: handle partial lot closes?
    // is the original order modified, or new orders created?
    if(orderTypeId <= OP_SELL) {
        // record txn_orders
        // lots can change, but should not be updated here.
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
            , orderUuid // MC_Common::GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not create order-specific record", FunctionTrace, orderNum);
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
            , MC_Common::GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not create balance split", FunctionTrace, orderNum);
        }
    }
    
    orderUuidOut = orderUuid;
    return true;
}

bool MainAccountRecorder::recordOrderExit(string orderUuid) {
    if(OrderType() > OP_SELL) { 
        MC_Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
        return false;
    }
    
    string query = "";
    string exitSpecificUuid = "";

    // record txn_orders_exit
    if(OrderCloseTime() > 0) {
        if(!dWriterMan.queryRunConditional(
            StringFormat("select txn_uuid from txn_orders_exit where txn_uuid='%s';", orderUuid)
            , exitSpecificUuid
            , ""
            , StringFormat("INSERT INTO txn_orders_exit (txn_uuid, exit_datetime, exit_lots, exit_price, exit_stoploss, exit_takeprofit, exit_comment) VALUES ('%%s', '%s', '%f', '%f', '%f', '%f', '%s');"
                , MC_Common::GetSqlDatetime(OrderCloseTime(), true, BrokerTimeZone)
                , OrderLots()
                , OrderClosePrice()
                , OrderStopLoss()
                , OrderTakeProfit()
                , OrderComment() // sometimes comment will be overwritten by stopout notes
                )
            , ""
            , ""
            , orderUuid // MC_Common::GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not create order-specific exit record", FunctionTrace, OrderTicket());
            return false;
        }
    }
    
    return true;
}

bool MainAccountRecorder::recordOrderSplits(string orderUuid) {
    if(OrderType() > OP_SELL) { 
        MC_Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
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
            , MC_Common::GetUuid()
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
                MC_Error::ThrowError(ErrorNormal, "Could not update order commission split", FunctionTrace, OrderTicket());
                returnResult = false;
            }
        } else {
            MC_Error::ThrowError(ErrorNormal, "Could not create order commission split", FunctionTrace, OrderTicket());
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
            , MC_Common::GetUuid()
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
                MC_Error::ThrowError(ErrorNormal, "Could not update order swap split", FunctionTrace, OrderTicket());
                returnResult = false;
            }
        } else {
            MC_Error::ThrowError(ErrorNormal, "Could not create order swap split", FunctionTrace, OrderTicket());
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
        , MC_Common::GetUuid()
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
            MC_Error::ThrowError(ErrorNormal, "Could not update order withdrawal split", FunctionTrace, OrderTicket());
            returnResult = false;
        }
    } else {
        MC_Error::ThrowError(ErrorNormal, "Could not create order withdrawal split", FunctionTrace, OrderTicket());
        returnResult = false;
    }
    
    return returnResult;
}

bool MainAccountRecorder::recordOrderElection(string orderUuid) {
    if(OrderType() > OP_SELL) { 
        MC_Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
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
                , MC_Common::GetSqlDatetime(TimeLocal(), true)
                , MC_Common::GetSqlDatetime(TimeLocal(), true) // todo: sql trigger instead?
                )
            , ""
            , ""
            , MC_Common::GetUuid()
            , -1
            , -1
            , UseAllWriters
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not create order election entry", FunctionTrace, OrderTicket());
            return false;
        }
        return true;
    } 
    else { return false; }
}

bool MainAccountRecorder::updateEquity() {
    string equityUuid = MC_Common::GetUuid(); string query = "";
    
    query = StringFormat("INSERT INTO act_equity (uuid, act_uuid, record_datetime, leverage, margin_so_mode, margin_so_call, margin_so_so, balance, equity, credit, margin) VALUES ('%s', '%s', '%s', '%i', '%i', '%f', '%f', '%f', '%f', '%f', '%f');"
        , equityUuid
        , uuidAccount
        , MC_Common::GetSqlDatetime(TimeLocal(), true)
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
        MC_Error::ThrowError(ErrorNormal, "Could not record account equity", FunctionTrace, equityUuid);
    }
    
    int orderCount = OrdersTotal();
    for(int i = 0; i < orderCount; i++) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }
        if(OrderType() > OP_SELL) { continue; } // is a pending order, then continue
        
        recordOrderEquity(equityUuid);
    }
    
    return true;
}


bool MainAccountRecorder::recordOrderEquity(string equityUuid) {
    // Assumes OrderSelect was already called
    string orderUuid = "";
    int orderNum = OrderTicket();
    string query = "";
    
    if(!recordOrder(orderUuid)) {
        MC_Error::ThrowError(ErrorNormal, "Could not create identifying order record", FunctionTrace);
    }
    
    // todo: should lots be recorded in equity? how about comments?
    // partial closes: are lots modified, or are new tickets created?
    // comments -- record only if there is a change? record always? not at all?
    // recordd spread? probably not
    
    // order current price: https://www.mql5.com/en/forum/102462
    // buy orders will be closed at Bid, so Bid-OrderOpenPrice() 
    // sell orders at Ask, so OrderOpenPrice()-Ask
    // alt: what is mode_tickvalue?  OrderProfit() - OrderCommision() ) / OrderLots() / MarketInfo( OrderSymbol(), MODE_TICKVALUE
    
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
        MC_Error::ThrowError(ErrorNormal, "Could not create order equity entry", FunctionTrace, orderNum);
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
            "Last Order Cycle: " + TimeToStr(lastOrderTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS)
                + (!lastOrderSuccess ? " (Failed!)" : "")
                + "\r\n"
            : ""
        , (int)lastEquityTime > 0 ? 
            "Last Equity Cycle: " + TimeToStr(lastEquityTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS)
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
