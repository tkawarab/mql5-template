#ifndef ExpertMain　
#include <stdlib.mqh>
#include <tk\com\Input.mqh>
#include <tk\lib\Function.mqh>
//enum LOG_LEVEL
//  {
//      LOG_LEVEL_NONE,
//      LOG_LEVEL_ONLY_CRITICAL,
//      LOG_LEVEL_MORE_THAN_ERROR,
//      LOG_LEVEL_MORE_THAN_WARNING,
//      LOG_LEVEL_ALL_INFOMATION,
//      LOG_LEVEL_DEBUG
//  };
//enum NOTIFY_TYPE
//  {
//      DEBUG,
//      INFO,
//      WARN,
//      ERR,
//      CRITICAL
//  };
#endif

class CLogger{
   private:
      LOG_LEVEL   m_print_level;
      LOG_LEVEL   m_alert_level;
      bool  m_enable_alert;
      string   m_delimiter;
      ulong       m_magic_number;
      string      m_symbol_name;
      string      m_period_name;
   public:
      void CLogger(LOG_LEVEL NotifyLevel,string Delims=",");
//      void ~CLogger() { delete slack; }
      virtual void print(NOTIFY_TYPE type,string message,string log_identifier=NULL,string function_name=NULL,int ret_code=NULL,bool print_only_newbar=true);
      void symbol(string arg_symbol){ m_symbol_name = arg_symbol; }
      void period(ENUM_TIMEFRAMES arg_period){ m_period_name = EnumToString(arg_period); }
      void magic(ulong arg_magic_number){ m_magic_number = arg_magic_number; }
};

void CLogger::CLogger(LOG_LEVEL PrintLevel=LOG_LEVEL_ALL_INFOMATION,string Delims=","){
      m_print_level = PrintLevel;
      m_delimiter = Delims;
   }
   
void CLogger::print(NOTIFY_TYPE type,string text,string log_identifier=NULL,string function_name=NULL,int ret_code=NULL,bool print_only_newbar=true){
   if(print_only_newbar) {
      if(!IsNewBar(_Symbol,PERIOD_CURRENT)) return;
   }

   if((NOTIFY_TYPE)type==DEBUG && (LOG_LEVEL)m_print_level<LOG_LEVEL_DEBUG){ return; }
   if((NOTIFY_TYPE)type==INFO && (LOG_LEVEL)m_print_level<LOG_LEVEL_ALL_INFOMATION){ return; }
   if((NOTIFY_TYPE)type==WARN && (LOG_LEVEL)m_print_level<LOG_LEVEL_MORE_THAN_WARNING){ return; }
   if((NOTIFY_TYPE)type==ERR && (LOG_LEVEL)m_print_level<LOG_LEVEL_MORE_THAN_ERROR){ return; }
   
   string message;
   if(ret_code!=NULL){
      message = EnumToString((NOTIFY_TYPE)type) + m_delimiter + log_identifier + m_delimiter + function_name + m_delimiter + text + m_delimiter + " (return code:" + IntegerToString(ret_code) + " description:" + ErrorDescription(ret_code) + ")";
   } else {
      message = EnumToString((NOTIFY_TYPE)type) + m_delimiter + log_identifier + m_delimiter + function_name + m_delimiter + text;
   }
   Print(message);

}

