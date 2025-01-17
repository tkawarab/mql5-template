//+------------------------------------------------------------------+
//|                                                      IniFile.mqh |
//|                                        Copyright © 2018, Amr Ali |
//|                             https://www.mql5.com/en/users/amrali |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Amr Ali"
#property link      "https://www.mql5.com/en/users/amrali"
#property version   "1.200"
#property description "A library to provide simple storage mechanism for expert advisors and indicators."
#property strict


#ifndef INI_UNIQUE_HEADER_ID_H
#define INI_UNIQUE_HEADER_ID_H


/* Library Functions:

  //--- If the key is not found, the returned value is NULL.
  bool  GetIniKey          (string fileName, string section, string key, T &ReturnedValue)

  //--- add new or update an existing key.
  bool  SetIniKey          (string fileName, string section, string key, T value)

  int   GetIniSectionNames (string fileName, string &names[])
  int   GetIniKeyNames     (string fileName, string section, string &names[])

  bool  IniSectionExists   (string fileName, string section);
  bool  IniKeyExists       (string fileName, string section, string key);

  bool  DeleteIniSection   (string fileName, string section);
  bool  DeleteIniKey       (string fileName, string section, string key);
*/

#import "kernel32.dll"
int      GetPrivateProfileSectionNamesW(ushort &lpszReturnBuffer[],int nSize,string lpFileName);
int      GetPrivateProfileStringW(string lpSection,string lpKey,string lpDefault,ushort &lpReturnedString[],int nSize,string lpFileName);
bool     WritePrivateProfileStringW(string lpSection,string lpKey,string lpValue,string lpFileName);
#import
//+------------------------------------------------------------------+
//| GetIniKey                                                        |
//+------------------------------------------------------------------+
/**
* If the key is not found, the returned value is NULL.
*/

// string overload
bool GetIniKey(string fileName,string section,string key,string &ReturnedValue)
  {
   string result=GetRawIniString(fileName,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=result;
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }

// int overload
bool GetIniKey(string fileName,string section,string key,int &ReturnedValue)
  {
   string result=GetRawIniString(fileName,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(int) StringToInteger(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }

// long overload
bool GetIniKey(string fileName,string section,string key,long &ReturnedValue)
  {
   string result=GetRawIniString(fileName,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(long) StringToInteger(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }

// double overload
bool GetIniKey(string fileName,string section,string key,double &ReturnedValue)
  {
   string result=GetRawIniString(fileName,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(double) StringToDouble(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }

// datetime overload
bool GetIniKey(string fileName,string section,string key,datetime &ReturnedValue)
  {
   string result=GetRawIniString(fileName,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(datetime) StringToTime(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }

// bool overload
bool GetIniKey(string fileName,string section,string key,bool &ReturnedValue)
  {
   string result=GetRawIniString(fileName,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(bool)(result=="true");
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }
//+------------------------------------------------------------------+
//| SetIniKey                                                        |
//+------------------------------------------------------------------+
/**
* add new or update an existing key.
*/
template<typename T>
bool SetIniKey(string fileName,string section,string key,T value)
  {
   return (WritePrivateProfileStringW(section, key, (string)value, fileName));
  }
//+------------------------------------------------------------------+
//| DeleteIniSection                                                 |
//+------------------------------------------------------------------+
bool DeleteIniSection(string fileName,string section)
  {
   return (WritePrivateProfileStringW(section, NULL, NULL, fileName));
  }
//+------------------------------------------------------------------+
//| DeleteIniKey                                                     |
//+------------------------------------------------------------------+
bool DeleteIniKey(string fileName,string section,string key)
  {
   return (WritePrivateProfileStringW(section, key, NULL, fileName));
  }
//+------------------------------------------------------------------+
//| IniSectionExists                                                 |
//+------------------------------------------------------------------+
bool IniSectionExists(string fileName,string section)
  {
   string section_names[];
   int count=GetIniSectionNames(fileName,section_names);

   for(int i=0; i<count; i++)
     {
      if(section_names[i] == section)  return (true);
     }

   return (false);
  }
//+------------------------------------------------------------------+
//| IniKeyExists                                                     |
//+------------------------------------------------------------------+
bool IniKeyExists(string fileName,string section,string key)
  {
   string key_names[];
   int count=GetIniKeyNames(fileName,section,key_names);

   for(int i=0; i<count; i++)
     {
      if(key_names[i] == key)  return (true);
     }

   return (false);
  }
//+------------------------------------------------------------------+
//| GetIniSectionNames                                               |
//+------------------------------------------------------------------+

int GetIniSectionNames(string fileName,string &names[])
  {
   ushort buffer[8192];
   ArrayInitialize(buffer,0);

   int chars=GetPrivateProfileSectionNamesW(buffer,sizeof(buffer),fileName);

   return ExplodeStrings(buffer, names, chars);
  }
//+------------------------------------------------------------------+
//| GetIniKeyNames                                                   |
//+------------------------------------------------------------------+

int GetIniKeyNames(string fileName,string section,string &names[])
  {
   ushort buffer[8192];
   ArrayInitialize(buffer,0);

   int chars=GetPrivateProfileStringW(section,NULL,NULL,buffer,sizeof(buffer),fileName);

   return ExplodeStrings(buffer, names, chars);
  }
//+------------------------------------------------------------------+
//| Internal function                                                |
//+------------------------------------------------------------------+
string GetRawIniString(string fileName,string section,string key)
  {
   ushort buffer[255];
   ArrayInitialize(buffer,0);

   string defaultValue="";
   GetPrivateProfileStringW(section,key,defaultValue,buffer,sizeof(buffer),fileName);

   return ShortArrayToString(buffer);
  }
//+------------------------------------------------------------------+
//| Internal function                                                |
//+------------------------------------------------------------------+
int ExplodeStrings(ushort &buffer[],string &names[],int chars)
  {
   string value;
   int count=ArrayResize(names,0);

   int pos=0;
   int length;

   while(pos<chars && buffer[pos]!=0)
     {
      value  = ShortArrayToString(buffer, pos);
      length = StringLen(value);

      ArrayResize(names,++count,100);
      names[count-1]=value;

      pos+=length+1;
     }

   return (count);
  }

#endif // #ifndef INI_UNIQUE_HEADER_ID_H