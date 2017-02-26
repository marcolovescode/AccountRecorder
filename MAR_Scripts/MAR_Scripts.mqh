//+------------------------------------------------------------------+
//|                                                  MAR_Scripts.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

const string Account_Sqlite[] = 
{
"INSERT INTO accounts(uuid, num, name)",
"SELECT {uuid}, {accountNum}, '{accountNum}'",
"WHERE NOT EXISTS(",
"select num from accounts where num={accountNum}",
")",
";",
"",
"select uuid from accounts where num={accountNum};",
""
};

// todo: load string arrays into ResourceStore
// a pre-build script can write file contents to string arrays named by their filename,
// and also generate the loading procedure
// that loads to ResourceStore by the array name
