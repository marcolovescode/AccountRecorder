SetWorkingDir, A_ScriptDir

Output =
(
//+------------------------------------------------------------------+
//|                                                  MAR_Scripts.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#include "../MC_Common/MC_Resource.mqh"
//+------------------------------------------------------------------+


)

Loop, Files, *.sql
{
    Output := Output . "const string " . SubStr(A_LoopFileName, 1, -4) . "[] =`n{`n"
    Loop, Read, %A_LoopFileName%
    {
        Output := Output . """" . StrReplace(A_LoopReadLine, """", "\""") . """,`n"
    }
    Output := Output . "};`n`n"
}

Output := Output . "void MAR_LoadScripts() {`n"

Loop, Files, *.sql
{
    Output := Output . "`tResourceMan.loadTextResource(""MAR_Scripts/" . A_LoopFileName . """, " . SubStr(A_LoopFileName, 1, -4) . ");`n"
}

Output := Output . "}`n"

FileDelete, MAR_Scripts.mqh
FileAppend, %Output%, MAR_Scripts.mqh
