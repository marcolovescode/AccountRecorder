CREATE TABLE IF NOT EXISTS enum_exn_type (id INTEGER NOT NULL UNIQUE PRIMARY KEY, name VARCHAR(64));
INSERT IGNORE INTO enum_exn_type VALUES (-1, 'Unspecified');
INSERT IGNORE INTO enum_exn_type VALUES (0, 'Other');
INSERT IGNORE INTO enum_exn_type VALUES (1, 'IRC 988(a)(1)(B)');

CREATE TABLE IF NOT EXISTS enum_spt_phase (id INT PRIMARY KEY NOT NULL UNIQUE, name VARCHAR(64));
INSERT IGNORE INTO enum_spt_phase VALUES (-1, 'Unspecified');
INSERT IGNORE INTO enum_spt_phase VALUES (0, 'Other');
INSERT IGNORE INTO enum_spt_phase VALUES (1, 'Entry');
INSERT IGNORE INTO enum_spt_phase VALUES (2, 'Exit');

CREATE TABLE IF NOT EXISTS enum_spt_subtype (id INT PRIMARY KEY NOT NULL UNIQUE, name VARCHAR(64));
INSERT IGNORE INTO enum_spt_subtype VALUES (-1, 'Unspecified');
INSERT IGNORE INTO enum_spt_subtype VALUES (0, 'Other');
INSERT IGNORE INTO enum_spt_subtype VALUES (1, 'Commission');
INSERT IGNORE INTO enum_spt_subtype VALUES (2, 'Swap');
INSERT IGNORE INTO enum_spt_subtype VALUES (3, 'Tax');
INSERT IGNORE INTO enum_spt_subtype VALUES (4, 'Deposit');
INSERT IGNORE INTO enum_spt_subtype VALUES (5, 'Withdrawal');
INSERT IGNORE INTO enum_spt_subtype VALUES (6, 'Expense');
INSERT IGNORE INTO enum_spt_subtype VALUES (7, 'Rebate');

CREATE TABLE IF NOT EXISTS enum_spt_type (id INT PRIMARY KEY NOT NULL UNIQUE, name VARCHAR(64));
INSERT IGNORE INTO enum_spt_type VALUES (-1, 'Unspecified');
INSERT IGNORE INTO enum_spt_type VALUES (0, 'Other');
INSERT IGNORE INTO enum_spt_type VALUES (1, 'Gross');
INSERT IGNORE INTO enum_spt_type VALUES (2, 'Fee');
INSERT IGNORE INTO enum_spt_type VALUES (3, 'Adjustment');

CREATE TABLE IF NOT EXISTS enum_txn_type (id INT PRIMARY KEY NOT NULL UNIQUE, name VARCHAR(64));
INSERT IGNORE INTO enum_txn_type VALUES (-1, 'Unspecified');
INSERT IGNORE INTO enum_txn_type VALUES (0, 'Other');
INSERT IGNORE INTO enum_txn_type VALUES (1, 'Short');
INSERT IGNORE INTO enum_txn_type VALUES (2, 'Long');
INSERT IGNORE INTO enum_txn_type VALUES (3, 'Balance');

CREATE TABLE IF NOT EXISTS enum_act_mode (id INT PRIMARY KEY UNIQUE NOT NULL, name VARCHAR(64));
INSERT IGNORE INTO enum_act_mode VALUES(-1, 'Unspecified');
INSERT IGNORE INTO enum_act_mode VALUES(0, 'Demo');
INSERT IGNORE INTO enum_act_mode VALUES(1, 'Contest');
INSERT IGNORE INTO enum_act_mode VALUES(2, 'Real');

CREATE TABLE IF NOT EXISTS currency (uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, name VARCHAR(12) NOT NULL, fraction DOUBLE NOT NULL DEFAULT (1));

CREATE TABLE IF NOT EXISTS accounts (uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, cny_uuid VARCHAR(36) NOT NULL, num INT NOT NULL, mode INT, name VARCHAR(64), server VARCHAR(64), company VARCHAR(64));

CREATE TABLE IF NOT EXISTS elections (uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, txn_uuid VARCHAR(36) NOT NULL, type INTEGER NOT NULL DEFAULT (- 1), active BOOLEAN NOT NULL DEFAULT false, made_datetime DATETIME NOT NULL, recorded_datetime DATETIME NOT NULL);

CREATE TABLE IF NOT EXISTS splits (uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, txn_uuid VARCHAR(36) NOT NULL, cny_uuid VARCHAR(36) NOT NULL, phase INTEGER NOT NULL DEFAULT (- 1), type INTEGER NOT NULL DEFAULT (- 1), subtype INTEGER NOT NULL DEFAULT (- 1), amount DOUBLE NOT NULL, comment VARCHAR);

CREATE TABLE IF NOT EXISTS transactions (uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, act_uuid VARCHAR(36) NOT NULL, type INTEGER NOT NULL DEFAULT (- 1), num INT NOT NULL, comment VARCHAR, magic INTEGER DEFAULT (- 1) NOT NULL, entry_datetime DATETIME NOT NULL);

CREATE TABLE IF NOT EXISTS txn_orders (txn_uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, symbol VARCHAR(12) NOT NULL, lots DOUBLE NOT NULL, exit_datetime DATETIME, entry_pips DOUBLE NOT NULL, exit_pips DOUBLE);

CREATE TABLE IF NOT EXISTS txn_orders_exit (txn_uuid VARCHAR(36) PRIMARY KEY UNIQUE NOT NULL, exit_datetime DATETIME NOT NULL, exit_pips DOUBLE NOT NULL);
