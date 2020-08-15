# AccountRecorder

This MetaTrader 4 plugin records the trading account state on an interval using a SQL database.
The purpose is to enable a platform-agnostic and auditable history of the account so that programs
outside of MetaTrader may reference it.

This plugin connects to a database via ODBC. It supports MySQL, PostgreSQL, and SQLite connections.

**[View this example SQLite database for an illustration of the data recorded](https://inloop.github.io/sqlite-viewer/?url=https://cdn.jsdelivr.net/gh/marcolovescode/AccountRecorder@master/AccountRecorderExample.sqlite)**

## Author's Notes

*(This document does not constitute legal advice. Please consult a licensed professional such as a
CPA, Enrolled Agent, or attorney.)*

I created this program in order to satisfy a U.S. tax procedure that allows for a FX trade to be taxed as a
capital gain instead of as ordinary income. This lowers the overall tax due.

The election is made by "clearly identifying [an elected transaction] on [the trader's] books and records on
the date the transaction is entered into." This program satisfies that requirement by promptly
recording a *IRC § 988(a)(1)(B)* election for each trade entered.

In addition, I aimed to bolster my bookkeeping and reporting efforts by utilizing the database. As I was
planning to use off-shore trading houses, I would be unable to receive a summary statement of my trades entered
per year. As a result, I would have needed to prepare a tax return that listed every individual trade.

## License

See LICENSE for the current license as to the files I authored. The following files may have different licenses:

* [/MQL4/Experts/MAR_AccountRecorder/MQ_QueryData/depends](https://github.com/marcolovescode/AccountRecorder/blob/master/MQL4/Experts/MAR_AccountRecorder/MQ_QueryData/depends) - SQLite and ODBC utility code. See files for authorship.
