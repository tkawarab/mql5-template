#ifndef ExpertMain
#include <tk\lib\Function.mqh>
#include <stdlib.mqh>
#include <tk\com\Input.mqh>
#include <tk\lib\Logger.mqh>
#endif

#include <tk\extlib\News.mqh>
class CCalendar{
   private:
      virtual  bool  GetValueHistorys(datetime s,datetime e);
      CNews    *news;
      int      news_total;
      string   m_target_countries[];
      string   m_target_currencies[];
      int      m_country_num;
      int      m_currency_num;
      CLogger  *m_logger;
      string   put_info_message(int i);
   protected:
      MqlCalendarValue  values[];
      MqlCalendarEvent  events[];
      string            countries[];
      string            currencies[];
      bool     CheckTargetCountry(string check_country_name);
      bool     CheckTargetCurrency(string check_currency_name);
   public:
      void  CCalendar();
      void  ~CCalendar();
      void  PutEventInfo(datetime target_date);
      bool  CheckEventHoliday(datetime target_date);
      bool  CheckEventLowImportance(datetime target_date);
      bool  CheckEventMidImportance(datetime target_date);
      bool  CheckEventHighImportance(datetime target_date);
      bool  CheckEventCritical(datetime target_date);
};

void  CCalendar::CCalendar(){ 
   ushort u_sep=StringGetCharacter(",",0); 
   m_country_num = StringSplit(TargetCountry,u_sep,m_target_countries);
   m_currency_num = StringSplit(TargetCurrency,u_sep,m_target_currencies);
   m_logger = new CLogger(print_log_level);
   //news.GMT_offset_winter=2;
   //news.GMT_offset_summer=3;
   if(MQLInfoInteger(MQL_TESTER)) {
      news = new CNews;
      news_total = news.LoadHistory(true); 
   }
}

void CCalendar::~CCalendar(){
   if(MQLInfoInteger(MQL_TESTER)) {
      delete news;
   }
   delete m_logger;
}

bool CCalendar::GetValueHistorys(datetime s,datetime e){
   //datetime s = StringToTime("2022/7/18");
   //datetime e = StringToTime("2022/7/19"); 
   ZeroMemory(values);
   ZeroMemory(events);
   ZeroMemory(countries);
   ZeroMemory(currencies);
   if(MQLInfoInteger(MQL_TESTER)){
      int i2=0;
      for(int i=0; i<news_total; i++){
         if(!(news.event[i].time>=s&&news.event[i].time<=e)) continue;

         ArrayResize(values,i2+1);
         ArrayResize(events,i2+1);
         ArrayResize(countries,i2+1);
         ArrayResize(currencies,i2+1);
         values[i2].actual_value = news.event[i].actual_value;
         values[i2].event_id = news.event[i].event_id;
         values[i2].forecast_value = news.event[i].forecast_value;
         values[i2].id = news.event[i].value_id;
         values[i2].impact_type = news.event[i].impact_type;
         values[i2].period = news.event[i].period;
         values[i2].prev_value = news.event[i].prev_value;
         values[i2].revised_prev_value = news.event[i].revised_prev_value;
         values[i2].revision = news.event[i].revision;
         values[i2].time = news.event[i].time;
         events[i2].country_id = news.event[i].country_id;
         events[i2].digits = news.event[i].digits;
         events[i2].frequency = news.event[i].frequency;
         events[i2].id = news.event[i].event_id;
         events[i2].importance = news.event[i].importance;
         events[i2].multiplier = news.event[i].multiplier;
         events[i2].name = news.eventname[i];
         events[i2].sector = news.event[i].sector;
         events[i2].time_mode = news.event[i].timemode;
         events[i2].type = news.event[i].event_type;
         events[i2].unit = news.event[i].unit;
         countries[i2] = news.countryname[i];
         currencies[i2] = news.currencyname[i];
         i2++;
      } 
   } else {
      MqlCalendarEvent event;
      if(!CalendarValueHistory(values,s,e,NULL,NULL)) return false;
      for(int i=0; i<ArraySize(values); i++){
         if(!CalendarEventById(values[i].event_id,event)){
            Print(ErrorDescription(GetLastError()));
            return false;
         }
         MqlCalendarCountry countrybuffer;
         CalendarCountryById(event.country_id,countrybuffer);
         ArrayResize(events,i+1);
         ArrayResize(countries,i+1);
         ArrayResize(currencies,i+1);
         events[i] = event;
         countries[i] = countrybuffer.name;
         currencies[i] = countrybuffer.currency;
      }
   }

   return true;
}

void  CCalendar::PutEventInfo(datetime target_date){
   datetime s = open_dt(target_date);
   datetime e = close_dt(target_date);
   if(!GetValueHistorys(s,e)) {
      m_logger.print(ERR,"Failed to get history");
      return;
   }
   for(int i=0; i<ArraySize(events); i++){
      m_logger.print(INFO,put_info_message(i));
   }
}

bool CCalendar::CheckTargetCountry(string check_country_name){
      if(m_country_num==0) return true;
      bool f = false;
      if(m_country_num>0){
         for(int i2=0; i2<ArraySize(m_target_countries); i2++){
            if(m_target_countries[i2]==check_country_name) f = true;
         }
      }   
      return f;
}

bool CCalendar::CheckTargetCurrency(string check_currency_name){
      if(m_currency_num==0) return true;
      bool f = false;
      if(m_currency_num>0){
         for(int i2=0; i2<ArraySize(m_target_currencies); i2++){
            if(m_target_currencies[i2]==check_currency_name) f = true;
         }      
      }      
      return f;
}

bool CCalendar::CheckEventHoliday(datetime target_date){
   datetime s = open_dt(target_date);
   datetime e = close_dt(target_date);
   if(!GetValueHistorys(s,e)) return false;

   for(int i=0; i<ArraySize(events); i++){
      if(m_country_num==0&&m_currency_num==0) continue;
      bool f=true;
      if(m_country_num!=0){
         f = CheckTargetCountry(countries[i]);
      } else {
         f = false;
      }
      if(m_currency_num!=0){
         if(!f) {
            f = CheckTargetCurrency(currencies[i]);
         }
      } 
      if(!f) continue;
      if((ENUM_CALENDAR_EVENT_TYPE)events[i].type!=CALENDAR_TYPE_HOLIDAY) continue;

      m_logger.print(INFO,put_info_message(i),"OPEN",__FUNCTION__);
      return true;
   }
   return false;
}

bool CCalendar::CheckEventLowImportance(datetime target_date){
   datetime s = open_dt(target_date);
   datetime e = close_dt(target_date);
   if(!GetValueHistorys(s,e)) return false;
   
   for(int i=0; i<ArraySize(events); i++){
      if(m_country_num==0&&m_currency_num==0) continue;
      bool f=true;
      if(m_country_num!=0){
         f = CheckTargetCountry(countries[i]);
      } else {
         f = false;
      }
      if(m_currency_num!=0){
         if(!f) {
            f = CheckTargetCurrency(currencies[i]);
         }
      }
      if(!f) continue;
      if(events[i].importance<CALENDAR_IMPORTANCE_LOW) continue;
      m_logger.print(INFO,put_info_message(i),"OPEN",__FUNCTION__);
      return true;
   }
   return false;
}

bool CCalendar::CheckEventMidImportance(datetime target_date){
   datetime s = open_dt(target_date);
   datetime e = close_dt(target_date);
   if(!GetValueHistorys(s,e)) return false;
   
   for(int i=0; i<ArraySize(events); i++){
      if(m_country_num==0&&m_currency_num==0) continue;
      bool f=true;
      if(m_country_num!=0){
         f = CheckTargetCountry(countries[i]);
      } else {
         f = false;
      }
      if(m_currency_num!=0){
         if(!f) {
            f = CheckTargetCurrency(currencies[i]);
         }
      }
      if(!f) continue;
      if(events[i].importance<CALENDAR_IMPORTANCE_MODERATE) continue;
      m_logger.print(INFO,put_info_message(i),"OPEN",__FUNCTION__);
      return true;
   }
   return false;
}

bool CCalendar::CheckEventHighImportance(datetime target_date){
   datetime s = open_dt(target_date);
   datetime e = close_dt(target_date);
   if(!GetValueHistorys(s,e)) return false;
   
   for(int i=0; i<ArraySize(events); i++){
      if(m_country_num==0&&m_currency_num==0) continue;
      bool f=true;
      if(m_country_num!=0){
         f = CheckTargetCountry(countries[i]);
      } else {
         f = false;
      }
      if(m_currency_num!=0){
         if(!f) {
            f = CheckTargetCurrency(currencies[i]);
         }
      }
      if(!f) continue;
      if(events[i].importance<CALENDAR_IMPORTANCE_HIGH) continue;
      m_logger.print(INFO,put_info_message(i),"OPEN",__FUNCTION__);
      return true;
   }
   return false;
}

bool CCalendar::CheckEventCritical(datetime target_date){
   datetime s = open_dt(target_date);
   datetime e = close_dt(target_date);
   if(!GetValueHistorys(s,e)) return false;
   
   for(int i=0; i<ArraySize(events); i++){
      if(m_country_num==0&&m_currency_num==0) continue;
      bool f=true;
      if(m_country_num!=0){
         f = CheckTargetCountry(countries[i]);
      } else {
         f = false;
      }
      if(m_currency_num!=0){
         if(!f) {
            f = CheckTargetCurrency(currencies[i]);
         }
      }
      if(!f) continue;
      if(events[i].importance<CALENDAR_IMPORTANCE_HIGH) continue;
      f = false;
      if(StringFind(events[i].name,"雇用")>0) f = true;
      if(StringFind(events[i].name,"金利")>0) f = true;
      if(StringFind(events[i].name,"国内総生産")>0) f = true;
      if(StringFind(events[i].name,"小売売上高")>0) f = true;
      if(StringFind(events[i].name,"FOMC")>0) f = true;
      if(StringFind(events[i].name,"FRB")>0) f = true;
      if(StringFind(events[i].name,"IMF")>0) f = true;
      if(StringFind(events[i].name,"物価")>0) f = true;
      if(StringFind(events[i].name,"日銀黒田")>0) f = true;
      if(f){
         m_logger.print(INFO,put_info_message(i),"OPEN",__FUNCTION__);
         return true;
      }
   }
   return false;
}

string CCalendar::put_info_message(int i){
   string message = TimeToString(values[i].time) + " " + countries[i] + " " + EnumToString(events[i].sector) + " " + events[i].name + " " + EnumToString(values[i].impact_type) + " " + EnumToString(events[i].importance);
   return message;
}