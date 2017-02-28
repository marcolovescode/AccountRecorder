//+------------------------------------------------------------------+
//|                                                     MAR_Main.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

//#define _LOCALRESOURCE

#include "MC_Common/MC_Resource.mqh"

#ifdef _LOCALRESOURCE
    #include "MAR_Scripts/MAR_Scripts.mqh"
#endif

#include "MD_DataWriter/MD_DataWriterManager.mqh"
#include "MAR_Settings.mqh"

class MainAccountRecorder {
    private:
    DataWriterManager *dWriterMan;
    bool setupConnections();
    bool checkSchema();
    bool setupSchema();
    bool setupAccountRecords();
    
    bool schemaReady;
    bool firstRunComplete;
    
    string uuidAccount;
    string uuidCurrency;
    
    datetime lastOrderTime;
    datetime lastEquityTime;
    
    bool firstWeekendNoticeFired;
    
    public:
    void MainAccountRecorder();
    void ~MainAccountRecorder();
    void doCycle(bool ignoreWeekendRules = false);
    bool recordOrder(string &orderUuidOut, bool recordElectionIfEnabled = true);
    bool recordOrderEquity(string equityUuid);
    bool recordOrderSplits(string orderUuid);
    bool recordOrderExit(string orderUuid);
    bool recordOrderElection(string orderUuid);
    void updateOrders();
    void updateEquity();
    bool doFirstRun();
};

void MainAccountRecorder::MainAccountRecorder() {
    dWriterMan = new DataWriterManager();
    setupConnections();
}

bool MainAccountRecorder::doFirstRun() {
    if(!IsConnected()) {
        MC_Error::ThrowError(ErrorNormal, "Not connected to broker, will attempt first run on cycle.", FunctionTrace);
        return false;
    }
    
    MC_Error::PrintInfo(ErrorInfo, "Starting first run", FunctionTrace, NULL, ErrorForceTerminal);
    
    if(!AccountMan.setupSchema()) {
        MC_Error::ThrowError(ErrorNormal, "Aborting first run, schema failed for readiness.", FunctionTrace, NULL, false, ErrorForceTerminal);
        return false;
    }
    AccountMan.setupAccountRecords();
    AccountMan.doCycle(true);
    
    MC_Error::PrintInfo(ErrorInfo, "First run complete", FunctionTrace, NULL, ErrorForceTerminal);
    firstRunComplete = true;
    
    return true;
}

bool MainAccountRecorder::setupConnections() {
    //int loc;
    
    if(EnableSqlite) {
        dWriterMan.addDataWriter(DW_Sqlite, ConnectRetries, ConnectRetryDelaySecs, true, SlOrderDbPath);
    }
    
    if(EnablePostgres) {
        dWriterMan.addDataWriter(DW_Postgres, ConnectRetries, ConnectRetryDelaySecs, true, PgConnectOrderString);
    }
    
    if(EnableMysql) {
        dWriterMan.addDataWriter(DW_Mysql, ConnectRetries, ConnectRetryDelaySecs, true, 
            MyHost, MyUser, MyPass, MyOrderDbName, MyPort, MySocket, MyClientFlags);
    }
    
    return true;
}

bool MainAccountRecorder::checkSchema() {
    int expectedTableCount = 16;
    int tableCount = 0;
    
    if(EnableSqlite) {
        if(!dWriterMan.queryRetrieveOne(
            "select count(type) from sqlite_master where sqlite_master.type = 'table' and sqlite_master.name in ('accounts', 'act_equity', 'currency', 'elections', 'enum_act_margin_so_mode', 'enum_act_mode', 'enum_exn_type', 'enum_spt_phase', 'enum_spt_subtype', 'enum_spt_type', 'enum_txn_type', 'splits', 'transactions', 'txn_orders', 'txn_orders_equity', 'txn_orders_exit');"
            , tableCount
            , 0
            , DW_Sqlite
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not check tables to verify schema readiness", FunctionTrace, NULL, false, ErrorForceTerminal);
        } else {
            schemaReady = (tableCount == expectedTableCount);
        }
    }
    
    if(!schemaReady) {
        MC_Error::ThrowError(ErrorNormal, "Schema error: Table count " + tableCount + " does not match expected " + expectedTableCount, FunctionTrace);
    }
    
    return schemaReady;
}

bool MainAccountRecorder::setupSchema() {
    string scriptSrc[];

    MC_Error::PrintInfo(ErrorInfo, "Setting up schema", FunctionTrace, NULL, ErrorForceTerminal);

    if(EnableSqlite && ResourceMan.getTextResource("MAR_Scripts/Schema_Orders_Sqlite.sql", scriptSrc)) {
        dWriterMan.scriptRun(scriptSrc, DW_Sqlite, -1, UseAllWriters);
    }

    if(EnablePostgres && ResourceMan.getTextResource("MAR_Scripts/Schema_Orders_Postgres.sql", scriptSrc)) {
        dWriterMan.scriptRun(scriptSrc, DW_Postgres, -1, UseAllWriters);
    }

    if(EnableMysql && ResourceMan.getTextResource("MAR_Scripts/Schema_Orders_Mysql.sql", scriptSrc)) {
        dWriterMan.scriptRun(scriptSrc, DW_Mysql, -1, UseAllWriters);
    }
    
    checkSchema();
    MC_Error::PrintInfo(ErrorInfo, "Finished setting up schema", FunctionTrace, NULL, ErrorForceTerminal);

    return schemaReady;
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
    
    if(!dWriterMan.queryRetrieveOne(
        StringFormat("select uuid from currency where name='%s';", curName)
        , uuidCurrency)
        ) {
        uuidCurrency = MC_Common::GetUuid();
        
        if(!dWriterMan.queryRun(
            StringFormat("INSERT INTO currency (uuid, name) SELECT '%s', '%s' WHERE NOT EXISTS (select name from currency where name='%s');"
                , uuidCurrency
                , curName
                , curName
                )
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not create identifying currency record", FunctionTrace);
        }
    }
    
    if(!dWriterMan.queryRetrieveOne(
        StringFormat("select uuid from accounts where num='%i';", actNum)
        , uuidAccount)
        ) {
        uuidAccount = MC_Common::GetUuid();
        
        if(!dWriterMan.queryRun(
            StringFormat("INSERT INTO accounts (uuid, cny_uuid, num, mode, name, server, company) SELECT '%s', '%s', '%i', '%i', '%s', '%s', '%s' WHERE NOT EXISTS (select num from accounts where num='%i');"
                , uuidAccount
                , uuidCurrency
                , actNum
                , actMode
                , actName
                , actServer
                , actCompany
                , actNum
                )
            )
        ) {
            MC_Error::ThrowError(ErrorNormal, "Could not create identifying account record", FunctionTrace);
        }
    }
    
    return true;
}

void MainAccountRecorder::~MainAccountRecorder() {
    if(CheckPointer(dWriterMan) == POINTER_DYNAMIC) { delete(dWriterMan); }
}

void MainAccountRecorder::doCycle(bool force = false) {
    if(!IsConnected()) {
        MC_Error::ThrowError(ErrorNormal, "Not connected to broker, cannot do cycle.", FunctionTrace);
        return;
    }

    datetime currentTimerTime = TimeLocal();
    
    if(SkipWeekends) {
        if(MC_Common::IsDatetimeInRange(currentTimerTime, EndWeekday, EndWeekdayHour, StartWeekday, StartWeekdayHour)) {
            if(!firstWeekendNoticeFired) {
                MC_Error::PrintInfo(ErrorInfo, "Currently a weekend, running cycle once before trading week starts again.", FunctionTrace, NULL, ErrorForceTerminal);
                firstWeekendNoticeFired = true;
            } else if(!force) { return; }
        } else {
            firstWeekendNoticeFired = false;
        }
    }
    
    if(!checkSchema()) {
        if(!setupSchema()) {
            MC_Error::ThrowError(ErrorNormal, "Could not verify schema readiness, aborting cycle.", FunctionTrace, NULL, false, ErrorForceTerminal);
            return;
        }
    }
    
    if(EnableOrderRecording && (force || (currentTimerTime - lastOrderTime >= OrderRefreshSeconds))) {
        MC_Error::PrintInfo(ErrorInfo, "Updating order records...", FunctionTrace, NULL, ErrorForceTerminal);
        updateOrders();
        lastOrderTime = currentTimerTime;
    }
    
    if(EnableEquityRecording && (force || (currentTimerTime - lastEquityTime >= EquityRefreshSeconds))) {
        MC_Error::PrintInfo(ErrorInfo, "Updating equity records...", FunctionTrace, NULL, ErrorForceTerminal);
        updateEquity();
        lastEquityTime = currentTimerTime;
    }
    
    MC_Error::PrintInfo(ErrorInfo, "Cycle completed.", FunctionTrace, NULL, ErrorForceTerminal);
}

bool MainAccountRecorder::recordOrderSplits(string orderUuid) {
    if(OrderType() > OP_SELL) { 
        MC_Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
        return false;
    }
    
    bool finalResult = true; string query = ""; string splitUuid = "";
    
    // record splits
    // todo: these need to be updated periodically. e.g. swap is 0 one day and 3.00 the next
    // todo: HOW TO KNOW WHETHER TO IGNORE A SPLIT OR UPDATE IT???
    if(OrderCommission() != 0) {
        if(!dWriterMan.queryRetrieveOne(
            StringFormat("select uuid from splits where txn_uuid='%s' and type='%i' and subtype='%i';", orderUuid, 2, 1)
            , splitUuid)
        ) {
            query = StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%s', '%s', '%s', '%i', '%i', '%i', '%f');"
                , MC_Common::GetUuid()
                , orderUuid
                , uuidCurrency
                , -1
                , 2 // fee
                , 1 // commission
                , OrderCommission()
                );
            if(!dWriterMan.queryRun(query)) {
                MC_Error::ThrowError(ErrorNormal, "Could not create order commission split", FunctionTrace, OrderTicket());
                finalResult = false;
            }
        } else {
            if(!dWriterMan.queryRetrieveOne(
                StringFormat("select uuid from splits where uuid='%s' and amount='%f';", splitUuid, OrderCommission())
                , splitUuid)
            ) {
                query = StringFormat("UPDATE splits SET amount='%f' WHERE uuid='%s'"
                    , OrderCommission()
                    , splitUuid
                    );
                if(!dWriterMan.queryRun(query)) {
                    MC_Error::ThrowError(ErrorNormal, "Could not update order commission split", FunctionTrace, OrderTicket());
                    finalResult = false;
                }
            }
        }
        
        if(OrderSwap() != 0) {
            if(!dWriterMan.queryRetrieveOne(
                StringFormat("select uuid from splits where txn_uuid='%s' and type='%i' and subtype='%i';", orderUuid, 2, 2)
                , splitUuid)
            ) {
                query = StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%s', '%s', '%s', '%i', '%i', '%i', '%f');"
                    , MC_Common::GetUuid()
                    , orderUuid
                    , uuidCurrency
                    , -1
                    , 2 // fee
                    , 2 // swap
                    , OrderSwap()
                    );
                if(!dWriterMan.queryRun(query)) {
                    MC_Error::ThrowError(ErrorNormal, "Could not create order swap split", FunctionTrace, OrderTicket());
                    finalResult = false;
                }
            } else {
                if(!dWriterMan.queryRetrieveOne(
                    StringFormat("select uuid from splits where uuid='%s' and amount='%f';", splitUuid, OrderSwap())
                    , splitUuid)
                ) {
                    query = StringFormat("UPDATE splits SET amount='%f' WHERE uuid='%s'"
                        , OrderSwap()
                        , splitUuid
                        );
                    if(!dWriterMan.queryRun(query)) {
                        MC_Error::ThrowError(ErrorNormal, "Could not update order swap split", FunctionTrace, OrderTicket());
                        finalResult = false;
                    }
                }
            }
        }
    }
    
    if(!dWriterMan.queryRetrieveOne(
        StringFormat("select uuid from splits where txn_uuid='%s' and type='%i' and subtype='%i';", orderUuid, 1, -1)
        , splitUuid)
    ) {
        query = StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%s', '%s', '%s', '%i', '%i', '%i', '%f');"
            , MC_Common::GetUuid()
            , orderUuid
            , uuidCurrency
            , -1
            , 1 // gross
            , -1 // does not apply
            , OrderProfit() // does not include fee or swap (or taxes -- NOTE: MQL4 DOES NOT EXPOSE TAX EXPENSE)
            );
        if(!dWriterMan.queryRun(query)) {
            MC_Error::ThrowError(ErrorNormal, "Could not create order withdrawal split", FunctionTrace, OrderTicket());
            finalResult = false;
        }
    } else {
        if(!dWriterMan.queryRetrieveOne(
            StringFormat("select uuid from splits where uuid='%s' and amount='%f';", splitUuid, OrderProfit())
            , splitUuid)
        ) {
            query = StringFormat("UPDATE splits SET amount='%f' WHERE uuid='%s'"
                , OrderProfit()
                , splitUuid
                );
            if(!dWriterMan.queryRun(query)) {
                MC_Error::ThrowError(ErrorNormal, "Could not update order withdrawal split", FunctionTrace, OrderTicket());
                finalResult = false;
            }
        }
    }
    
    return finalResult;
}

bool MainAccountRecorder::recordOrderElection(string orderUuid) {
    if(OrderType() > OP_SELL) { 
        MC_Error::ThrowError(ErrorNormal, "Order is not a buy or sell.", FunctionTrace);
        return false;
    }
    
    string electionUuid = ""; string query = "";
    
    if(RecordOrderElection) {
        if(!dWriterMan.queryRetrieveOne(
            StringFormat("select uuid from elections where txn_uuid='%s';", orderUuid)
            , electionUuid)
        ) {
            query = StringFormat("INSERT INTO elections (uuid, txn_uuid, type, active, made_datetime, recorded_datetime) VALUES ('%s', '%s', '%i', '%i', '%s', '%s');"
                , MC_Common::GetUuid()
                , orderUuid
                , ElectionId
                , 1 // true
                , MC_Common::GetSqlDatetime(TimeLocal(), true)
                , MC_Common::GetSqlDatetime(TimeLocal(), true) // todo: sql trigger instead?
                );
            if(!dWriterMan.queryRun(query)) {
                MC_Error::ThrowError(ErrorNormal, "Could not create order election entry", FunctionTrace, OrderTicket());
                return false;
            }
        }
        
        return true;
    } 
    else { return false; }
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
        if(!dWriterMan.queryRetrieveOne(
            StringFormat("select txn_uuid from txn_orders_exit where txn_uuid='%s';", orderUuid)
            , exitSpecificUuid)
        ) {
            query = StringFormat("INSERT INTO txn_orders_exit (txn_uuid, exit_datetime, exit_lots, exit_price, exit_stoploss, exit_takeprofit, exit_comment) VALUES ('%s', '%s', '%f', '%f', '%f', '%f', '%s');"
                , orderUuid
                , MC_Common::GetSqlDatetime(OrderCloseTime(), true, BrokerTimeZone)
                , OrderLots()
                , OrderClosePrice()
                , OrderStopLoss()
                , OrderTakeProfit()
                , OrderComment() // sometimes comment will be overwritten by stopout notes
                );
            if(!dWriterMan.queryRun(query)) {
                MC_Error::ThrowError(ErrorNormal, "Could not create order-specific exit record", FunctionTrace, OrderTicket());
                return false;
            }
        }
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
    
    if(!dWriterMan.queryRetrieveOne(
        StringFormat("select uuid from transactions where num='%i';", orderNum)
        , orderUuid)
    ) {
        orderUuid = MC_Common::GetUuid();
        
        query = StringFormat("INSERT INTO transactions (uuid, act_uuid, type, num, comment, magic, entry_datetime) SELECT '%s', '%s', '%i', '%i', '%s', '%i', '%s' WHERE NOT EXISTS (select num from transactions where num='%i');"
            , orderUuid
            , uuidAccount
            , orderTypeId
            , orderNum
            , orderCom
            , OrderMagicNumber()
            , MC_Common::GetSqlDatetime(OrderOpenTime(), true, BrokerTimeZone)
            , orderNum
            );
        if(!dWriterMan.queryRun(query)) {
            MC_Error::ThrowError(ErrorNormal, "Could not create identifying order record", FunctionTrace, orderNum);
            orderUuidOut = "";
            return false;
        }
    }
        
    // todo: handle partial lot closes?
    // is the original order modified, or new orders created?
    if(orderTypeId <= OP_SELL) {
        // record txn_orders
        // lots can change, but should not be updated here.
        if(!dWriterMan.queryRetrieveOne(
            StringFormat("select txn_uuid from txn_orders where txn_uuid='%s';", orderUuid)
            , orderSpecificUuid)
        ) {
            query = StringFormat("INSERT INTO txn_orders (txn_uuid, symbol, lots, entry_price, entry_stoploss, entry_takeprofit) VALUES ('%s', '%s', '%f', '%f', '%f', '%f');"
                , orderUuid
                , OrderSymbol()
                , OrderLots()
                , OrderOpenPrice()
                , OrderStopLoss()
                , OrderTakeProfit()
                );
            if(!dWriterMan.queryRun(query)) {
                MC_Error::ThrowError(ErrorNormal, "Could not create order-specific record", FunctionTrace, orderNum);
            }
        } 
        
        recordOrderExit(orderUuid);
        
        recordOrderSplits(orderUuid);
        
        if(recordElectionIfEnabled) { recordOrderElection(orderUuid); }
    } else if(orderTypeId >= 6) { // balance transaction, undocumented https://www.mql5.com/en/forum/134197
        if(!dWriterMan.queryRetrieveOne(
            StringFormat("select uuid from splits where txn_uuid='%s';", orderUuid)
            , balanceUuid)
        ) {
            query = StringFormat("INSERT INTO splits (uuid, txn_uuid, cny_uuid, phase, type, subtype, amount) VALUES ('%s', '%s', '%s', '%i', '%i', '%i', '%f');"
                , MC_Common::GetUuid()
                , orderUuid
                , uuidCurrency
                , -1
                , 3 // adjustment
                , orderCom == "Deposit" ? 4 : orderCom == "Withdrawal" ? 5 : -1
                , OrderProfit() // is adjustment amount in this case
                );
            if(!dWriterMan.queryRun(query)) {
                MC_Error::ThrowError(ErrorNormal, "Could not create balance split", FunctionTrace, orderNum);
            }
        }
    }
    
    orderUuidOut = orderUuid;
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
    
    query = StringFormat("INSERT INTO txn_orders_equity (txn_uuid, eqt_uuid, lots, price, stoploss, takeprofit, commission, swap, gross) VALUES ('%s', '%s', '%f', '%f', '%f', '%f', '%f', '%f', '%f');"
        , orderUuid
        , equityUuid
        , OrderLots()
        , OrderType() == OP_SELL ? MarketInfo(OrderSymbol(), MODE_ASK) : MarketInfo(OrderSymbol(), MODE_BID)
        , OrderStopLoss()
        , OrderTakeProfit()
        , OrderCommission()
        , OrderSwap()
        , OrderProfit()
//        , OrderComment()
        );
    if(!dWriterMan.queryRun(query)) {
        MC_Error::ThrowError(ErrorNormal, "Could not create order equity entry", FunctionTrace, orderNum);
    }
    
    return true;
}

void MainAccountRecorder::updateOrders() {
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
}

void MainAccountRecorder::updateEquity() {
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
    if(!dWriterMan.queryRun(query)) {
        MC_Error::ThrowError(ErrorNormal, "Could not record account equity", FunctionTrace, equityUuid);
    }
    
    int orderCount = OrdersTotal();
    for(int i = 0; i < orderCount; i++) {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }
        if(OrderType() > OP_SELL) { continue; } // is a pending order, then continue
        
        recordOrderEquity(equityUuid);
    }
}

MainAccountRecorder *AccountMan;
