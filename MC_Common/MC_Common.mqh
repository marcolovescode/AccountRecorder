//+------------------------------------------------------------------+
//|                                           MMT_Helper_Library.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

enum DataType {
    DataString,
    DataBool,
    DataInt,
    DataDouble
};

enum StringType {
    Type_Alphanumeric,
    Type_Uppercase,
    Type_Lowercase,
    Type_Alpha,
    Type_Numeric,
    Type_Symbol
};

class MC_Common {
    private:
    static string StringZeroArray[1];
    static bool BoolZeroArray[1];
    static int IntZeroArray[1];
    static double DoubleZeroArray[1];
    
    public:
    //array
    static int ArrayPushGeneric(string &stringArray[], int &intArray[], double &doubleArray[], bool &boolArray[], string stringUnit, int intUnit, double doubleUnit, bool boolUnit, DataType inputType);
    static int ArrayReserveGeneric(string &stringArray[], int &intArray[], double &doubleArray[], bool &boolArray[], DataType inputType, int reserveSize);
    static int ArrayPush(string &array[], int unit);
    static int ArrayPush(int &array[], int unit);
    static int ArrayPush(double &array[], int unit);
    static int ArrayPush(bool &array[], int unit);
    static int ArrayReserve(string &array[], int reserveSize);
    static int ArrayReserve(int &array[], int reserveSize);
    static int ArrayReserve(double &array[], int reserveSize);
    static int ArrayReserve(bool &array[], int reserveSize);
    
    // string
    static string StringTrim(string inputStr);
    static bool StrToBool(string inputStr);
    static bool IsAddrAbcValid (string addrAbc);
    static int AddrAbcToInt(string addrAbc, bool zeroBased=true);
    static string AddrIntToAbc(int addrInt, bool zeroBased=true);
    static string ConcatStringFromArray(string& strArray[], string delimiter = ";");
    static StringType GetStringType(string test);
    
    //uuid
    static string GetUuid();
};

string MC_Common::StringZeroArray[1];
bool MC_Common::BoolZeroArray[1];
int MC_Common::IntZeroArray[1];
double MC_Common::DoubleZeroArray[1];

int MC_Common::ArrayPushGeneric(string &stringArray[], int &intArray[], double &doubleArray[], bool &boolArray[], string stringUnit, int intUnit, double doubleUnit, bool boolUnit, DataType inputType) {
    int size;
    
    switch(inputType) {
        case DataInt: size = ArraySize(intArray); ArrayResize(intArray, size+1); intArray[size] = intUnit; break;
        case DataDouble: size = ArraySize(doubleArray); ArrayResize(doubleArray, size+1); doubleArray[size] = doubleUnit; break;
        case DataBool: size = ArraySize(boolArray); ArrayResize(boolArray, size+1); boolArray[size] = boolUnit; break;
        default: size = ArraySize(stringArray); ArrayResize(stringArray, size+1); stringArray[size] = stringUnit; break;
    }
    
    return size + 1;
}

int MC_Common::ArrayReserveGeneric(string &stringArray[], int &intArray[], double &doubleArray[], bool &boolArray[], DataType inputType, int reserveSize) {
    int size;
    
    switch(inputType) {
        case DataInt: size = ArraySize(intArray); ArrayResize(intArray, size, reserveSize); break;
        case DataDouble: size = ArraySize(doubleArray); ArrayResize(doubleArray, size, reserveSize); break;
        case DataBool: size = ArraySize(boolArray); ArrayResize(boolArray, size, reserveSize); break;
        default: size = ArraySize(stringArray); ArrayResize(stringArray, size, reserveSize); break;
    }
    
    return size + reserveSize;
}


int MC_Common::ArrayPush(string &array[], int unit) {
    return ArrayPushGeneric(array, IntZeroArray, DoubleZeroArray, BoolZeroArray, unit, NULL, NULL, NULL, DataString);
}

int MC_Common::ArrayPush(int &array[], int unit) {
    return ArrayPushGeneric(StringZeroArray, array, DoubleZeroArray, BoolZeroArray, NULL, unit, NULL, NULL, DataInt);
}


int MC_Common::ArrayPush(double &array[], int unit) {
    return ArrayPushGeneric(StringZeroArray, IntZeroArray, array, BoolZeroArray, NULL, NULL, unit, NULL, DataDouble);
}


int MC_Common::ArrayPush(bool &array[], int unit) {
    return ArrayPushGeneric(StringZeroArray, IntZeroArray, DoubleZeroArray, array, NULL, NULL, NULL, unit, DataBool);
}

int MC_Common::ArrayReserve(string &array[], int reserveSize) {
    return ArrayReserveGeneric(array, IntZeroArray, DoubleZeroArray, BoolZeroArray, DataString, reserveSize);
}

int MC_Common::ArrayReserve(int &array[], int reserveSize) {
    return ArrayReserveGeneric(StringZeroArray, array, DoubleZeroArray, BoolZeroArray, DataInt, reserveSize);
}

int MC_Common::ArrayReserve(double &array[], int reserveSize) {
    return ArrayReserveGeneric(StringZeroArray, IntZeroArray, array, BoolZeroArray, DataDouble, reserveSize);
}

int MC_Common::ArrayReserve(bool &array[], int reserveSize) {
    return ArrayReserveGeneric(StringZeroArray, IntZeroArray, DoubleZeroArray, array, DataBool, reserveSize);
}

string MC_Common::StringTrim(string inputStr) {
    return StringTrimLeft(StringTrimRight(inputStr));
}

bool MC_Common::StrToBool(string inputStr) {
    StringToLower(inputStr);
    string testStr = StringTrim(inputStr);
    
    if(StringCompare(testStr,"true") == 0) { return true; }
    else if(StringCompare(testStr,"false") == 0) { return false; }
    else return (bool)StrToInteger(testStr);
}

bool MC_Common::IsAddrAbcValid (string addrAbc) {
    return AddrAbcToInt(addrAbc) >= 0; // todo: this overflows eventually with zzzzzzz etc, how to check?
}

int MC_Common::AddrAbcToInt(string addrAbc, bool zeroBased=true) {
    // http://stackoverflow.com/questions/9905533/convert-excel-column-alphabet-e-g-aa-to-number-e-g-25
    
    StringToLower(addrAbc);
    int addrAbcLength = StringLen(addrAbc);
    
    string letters = "abcdefghijklmnopqrstuvwxyz";
    int lettersLength = StringLen(letters);
    
    int sum = 0;
    int j = 0;
    for (int i = addrAbcLength-1; i >= 0; i--) {
        sum += MathPow(lettersLength, j) * (StringFind(letters, StringSubstr(addrAbc, i, 1))+1);
        j++;
    }
    return sum - (int)zeroBased; //make 0-based, not 1-based
}

string MC_Common::AddrIntToAbc(int addrInt, bool zeroBased=true) {
    // http://stackoverflow.com/questions/181596/how-to-convert-a-column-number-eg-127-into-an-excel-column-eg-aa

    int dividend = addrInt + (int)zeroBased; // make 0 based, not 1 based
    string columnName ="";
    int modulo;

    while (dividend > 0)
    {
        modulo = (dividend - 1) % 26;
        columnName = CharToString((uchar)(97 + modulo)) + columnName;
        dividend = (int)((dividend - modulo) / 26);
    } 

    return columnName;
}

string MC_Common::ConcatStringFromArray(string& strArray[], string delimiter = ";") {
    int strCount = ArraySize(strArray);
    
    string finalString = "";
    for(int i = 0; i < strCount; i++) {
        finalString = StringConcatenate(finalString, strArray[i], delimiter);
    }
    
    return finalString;
}

StringType MC_Common::GetStringType(string test) {
    int len = StringLen(test);
    bool uppercase = false; bool lowercase = false; bool numeric = false;
    ushort code;
    
    for(int i= 0; i < len; i++) {
        code = StringGetChar(test, i);
        if(code >= 65 && code <= 90) { uppercase = true; }
        else if(code >= 97 && code <= 122) { lowercase = true; }
        else if(code >= 48 && code <= 57) { numeric = true; }
    }

    if((uppercase||lowercase)&&numeric){ return Type_Alphanumeric; }
    else if(uppercase||lowercase) { return Type_Alpha; }
    else if(numeric) { return Type_Numeric; }
    else return Type_Symbol;
}

// https://github.com/femtotrader/rabbit4mt4/blob/master/emit/MQL4/Include/uuid.mqh
//http://en.wikipedia.org/wiki/Universally_unique_identifier
//RFC 4122
//  A Universally Unique IDentifier (UUID) URN Namespace
//  http://tools.ietf.org/html/rfc4122.html

//+------------------------------------------------------------------+
//|UUID Version 4 (random)                                           |
//|Version 4 UUIDs use a scheme relying only on random numbers.      |
//|This algorithm sets the version number (4 bits) as well as two    |
//|reserved bits. All other bits (the remaining 122 bits) are set    |
//|using a random or pseudorandom data source. Version 4 UUIDs have  |
//|the form xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx                     |
//|where x is any hexadecimal digit and y is one of 8, 9, A, or B    |
//|(e.g., f47ac10b-58cc-4372-a567-0e02b2c3d479).                                                               |
//+------------------------------------------------------------------+
string MC_Common::GetUuid()
  {
   string alphabet_x="0123456789abcdef";
   string alphabet_y="89ab";
   string id="xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"; // 36 char = (8-4-4-4-12)
   ushort character;
   for(int i=0; i<36; i++)
     {
      if(i==8 || i==13 || i==18 || i==23)
        {
         character='-';
        }
      else if(i==14)
        {
         character='4';
        }
      else if(i==19)
        {
         character = (ushort) MathRand() % 4;
         character = StringGetChar(alphabet_y, character);
        }
      else
        {
         character = (ushort) MathRand() % 16;
         character = StringGetChar(alphabet_x, character);
        }
      id=StringSetChar(id,i,character);
     }
   return (id);
  }
//+------------------------------------------------------------------+