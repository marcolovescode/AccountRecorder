CREATE TABLE IF NOT EXISTS enum_exn_type (id INTEGER NOT NULL UNIQUE PRIMARY KEY, name TEXT);
INSERT OR IGNORE INTO enum_exn_type VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_exn_type VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_exn_type VALUES (1, 'USA § 988(a)(1)(B)');

CREATE TABLE IF NOT EXISTS enum_spt_phase (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_spt_phase VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_spt_phase VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_spt_phase VALUES (1, 'Entry');
INSERT OR IGNORE INTO enum_spt_phase VALUES (2, 'Exit');

CREATE TABLE IF NOT EXISTS enum_spt_subtype (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_spt_subtype VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (1, 'Commission');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (2, 'Swap');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (3, 'Tax');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (4, 'Deposit');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (5, 'Withdrawal');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (6, 'Expense');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (7, 'Rebate');

CREATE TABLE IF NOT EXISTS enum_spt_type (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_spt_type VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_spt_type VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_spt_type VALUES (1, 'Gross');
INSERT OR IGNORE INTO enum_spt_type VALUES (2, 'Fee');
INSERT OR IGNORE INTO enum_spt_type VALUES (3, 'Adjustment');

CREATE TABLE IF NOT EXISTS enum_txn_type (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_txn_type VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_txn_type VALUES (0, 'Long');
INSERT OR IGNORE INTO enum_txn_type VALUES (1, 'Short');
INSERT OR IGNORE INTO enum_txn_type VALUES (2, 'Buy Limit');
INSERT OR IGNORE INTO enum_txn_type VALUES (3, 'Buy Stop');
INSERT OR IGNORE INTO enum_txn_type VALUES (4, 'Sell Limit');
INSERT OR IGNORE INTO enum_txn_type VALUES (5, 'Sell Stop');
INSERT OR IGNORE INTO enum_txn_type VALUES (6, 'Balance');

CREATE TABLE IF NOT EXISTS enum_act_mode (id INT PRIMARY KEY UNIQUE NOT NULL, name TEXT);
INSERT OR IGNORE INTO enum_act_mode VALUES(-1, 'Unspecified');
INSERT OR IGNORE INTO enum_act_mode VALUES(0, 'Demo');
INSERT OR IGNORE INTO enum_act_mode VALUES(1, 'Contest');
INSERT OR IGNORE INTO enum_act_mode VALUES(2, 'Real');

CREATE TABLE IF NOT EXISTS enum_act_margin_so_mode (id INT PRIMARY KEY UNIQUE NOT NULL, name TEXT);
INSERT OR IGNORE INTO enum_act_margin_so_mode VALUES(-1, 'Unspecified');
INSERT OR IGNORE INTO enum_act_margin_so_mode VALUES(0, 'Percent');
INSERT OR IGNORE INTO enum_act_margin_so_mode VALUES(1, 'Money');

CREATE TABLE IF NOT EXISTS currency (uuid TEXT PRIMARY KEY UNIQUE NOT NULL, name TEXT NOT NULL, fraction DOUBLE NOT NULL DEFAULT (1));

CREATE TABLE IF NOT EXISTS accounts (uuid TEXT PRIMARY KEY UNIQUE NOT NULL, cny_uuid TEXT NOT NULL, num INT NOT NULL, mode INT, name TEXT, server TEXT, company TEXT);

CREATE TABLE IF NOT EXISTS elections (uuid TEXT PRIMARY KEY UNIQUE NOT NULL, txn_uuid TEXT NOT NULL, type INTEGER NOT NULL DEFAULT (- 1), active BOOLEAN NOT NULL DEFAULT (0), made_datetime DATETIME NOT NULL, recorded_datetime DATETIME NOT NULL);

CREATE TABLE IF NOT EXISTS splits (uuid TEXT PRIMARY KEY UNIQUE NOT NULL, txn_uuid TEXT NOT NULL, cny_uuid TEXT NOT NULL, phase INTEGER NOT NULL DEFAULT (- 1), type INTEGER NOT NULL DEFAULT (- 1), subtype INTEGER NOT NULL DEFAULT (- 1), amount DOUBLE NOT NULL, comment TEXT);

CREATE TABLE IF NOT EXISTS transactions (uuid TEXT PRIMARY KEY UNIQUE NOT NULL, act_uuid TEXT NOT NULL, type INTEGER NOT NULL DEFAULT (- 1), num INT NOT NULL, comment TEXT, magic INTEGER DEFAULT (- 1) NOT NULL, entry_datetime DATETIME NOT NULL);

CREATE TABLE IF NOT EXISTS txn_orders (txn_uuid TEXT PRIMARY KEY UNIQUE NOT NULL, symbol TEXT NOT NULL, lots DOUBLE NOT NULL, entry_price DOUBLE NOT NULL, entry_stoploss DOUBLE NOT NULL DEFAULT (0), entry_takeprofit DOUBLE NOT NULL DEFAULT (0));

CREATE TABLE IF NOT EXISTS txn_orders_exit (txn_uuid TEXT PRIMARY KEY UNIQUE NOT NULL, exit_datetime DATETIME NOT NULL, exit_price DOUBLE NOT NULL, exit_stoploss DOUBLE NOT NULL DEFAULT (0), exit_takeprofit DOUBLE NOT NULL DEFAULT (0), exit_comment TEXT);

CREATE TABLE IF NOT EXISTS act_equity (uuid TEXT PRIMARY KEY UNIQUE NOT NULL, act_uuid TEXT NOT NULL, record_datetime DATETIME NOT NULL, leverage INTEGER, margin_so_mode INTEGER, margin_so_call DOUBLE, margin_so_so DOUBLE, balance DOUBLE, equity DOUBLE, credit DOUBLE, margin DOUBLE);

CREATE TABLE IF NOT EXISTS txn_orders_equity (txn_uuid TEXT NOT NULL, eqt_uuid TEXT NOT NULL, price DOUBLE, stoploss DOUBLE, takeprofit DOUBLE, gross DOUBLE, comment TEXT, primary key (txn_uuid, eqt_uuid));
