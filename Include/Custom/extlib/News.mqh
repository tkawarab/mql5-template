//+------------------------------------------------------------------+
//|                                                         News.mqh |
//|                                                 username Chris70 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

// ___________________________________________________________________
//
// this is a workaround in order to be able to use Metaquotes' built-in Economic Event Calendar functions not only during live trading,
// but also in the Strategy Tester and even for genetic optimization
//
// HOW TO USE THIS FILE:
// 1. copy this file to your ../MQL5/include/ folder
// 2. global scope:
//    #include <News.mqh>
//    CNews news;
// 3. if(!) your broker isn't located in central Europe (or the same time zone, with daylight saving time):
//    adjust the GMT_OFFSET default value definitions (below) to the requirements of your country/region;
//    alternatively adjust the values in OnInit():
//    e.g.
//    news.server_offset_winter=2;
//    news.server_offset_summer=3;
//    why is this information necessary? because the event calendar seems to use GMT time for event dates/time,
//    however in the strategy tester TimeGMT() returns wrong values and then is the same as TimeCurrent() or TimeTradeServer(),
//    therefore in the tester GMT time needs to be simulated in order to match with the event data supplied by Metaquotes
// 4. keep the event array updated in your main event handler (OnTick(),OnStart(), OnCalculate()..) by calling
//    news.update();
//    by default the updates will be limited to once every 60 seconds, which is usually much more than enough
//    because most scheduled events are announced already with several days in advance, so that staying even more "current"
//    usually in reality doesn't change anything;
//    if a different update frequency is desired, just add this as a parameter, e.g.
//    news.update(900); for array updates every 15 minutes;
//    if detailed print log information is desired e.g. during debugging, set the second parameter to 'true' (false by default), e.g.:
//    news.update(60,true);
//    there is one exception with some strategies where instant updates are necessary: exactly around the time of the news event in those cases when we need instant access
//    to the 'actual value' (e.g. in order to compare it to the forecast), then
//    news.update(0);
//    is recommended
// 5. the total number of accessible historical, current and scheduled near future events is given by the return value of the update function, e.g.
//    int total_events=news.update();
//    this number (minus 1) also represents the highest possible index of the event array, so it's the same as ArraySize(news.event);
//    to access detailed information about any event, then just address it via its index:
//    news.event[index].value_id
//    news.event[index].event_id
//    news.event[index].time
//    news.event[index].period
//    news.event[index].revision
//    news.event[index].actual_value
//    news.event[index].prev_value
//    news.event[index].revised_prev_value
//    news.event[index].forecast_value
//    news.event[index].impact_type
//    news.event[index].event_type
//    news.event[index].sector
//    news.event[index].frequency
//    news.event[index].timemode
//    news.event[index].importance
//    news.event[index].multiplier
//    news.event[index].unit
//    news.event[index].digits
//    news.event[index].country_id
//    news.eventname[index]
//
//    in order to make sense of a country id (which is just a number) and get the currency (=as a 3 character string) of this country
//    just use the function news.CountryIdToCurrency()
//    accordingly, in order to get the country id for a given currency, use news.CurrencyToCountryId();
//
//    there is one thing to mention about the 'index': at the time I'm writing this about 90.000 historical events can be accessed from the Metaquotes servers,
//    however, this also means the index number can be pretty high and we probably don't want to go through the entire history of all past events until we have found the next upcoming event,
//    so in order to make this more convenient (/efficient), I added the function
//    news.next()
//    which returns the index number of the next upcoming event relative to a given index to start the search with, e.g..
//    news.next(last_event_index,"USD",true,0);
//    in order to find the next following event that affects the dollar pairs, starting the search with index 'last_event_index';
//    'true' and '0' in this case means that the event will be shown on the current chart as a vertical line with the name of the event attached
//
//    IMPORTANT: please note that this method works for both the strategy tester and live trading,
//    actually the main motivation for this 'workaround' was to be able to test news strategies before deploying them in live trading,
//    however, by default Metaquotes makes it impossible to directly access historical event data in the strategy tester, so that for testing this workaround
//    consists in ONCE storing historical data to the harddrive and access them then later offline from this file;
//    this means that in order to make this work, the EA has to be run at least ONCE in live mode; live mode doesn't mean trading; for example also just having called the news.update() functtion only once
//    in the "debugging with live data" mode already is enough to ensure that the event data file exists (as a .bin file in the common files folder);
//    for actual live trading on the other hand of course the news history file is irrelevant (because then we can also access the data directly, like intended by the built-in functions), but it also 'doesn't hurt';
//    as a consequence, there are no differences of how to use this code whether it's for testing or live; I think this makes dealing with events in an EA a lot easier
//
//    Happy news trading,
//
//    Chris
// ___________________________________________________________________
#property copyright  "username Chris70"
#property link       "https://www.mql5.com"
#define   GMT_OFFSET_WINTER_DEFAULT 2
#define   GMT_OFFSET_SUMMER_DEFAULT 3

enum ENUM_COUNTRY_ID
  {
   World=0,
   EU=999,
   USA=840,
   Canada=124,
   Australia=36,
   NewZealand=554,
   Japan=392,
   China=156,
   UK=826,
   Switzerland=756,
   Germany=276,
   France=250,
   Italy=380,
   Spain=724,
   Brazil=76,
   SouthKorea=410
  };

class CNews
  {
private:
   struct            EventStruct
                       {
                        ulong    value_id;
                        ulong    event_id;
                        datetime time;
                        datetime period;
                        int      revision;
                        long     actual_value;
                        long     prev_value;
                        long     revised_prev_value;
                        long     forecast_value;
                        ENUM_CALENDAR_EVENT_IMPACT impact_type;
                        ENUM_CALENDAR_EVENT_TYPE event_type;
                        ENUM_CALENDAR_EVENT_SECTOR sector;
                        ENUM_CALENDAR_EVENT_FREQUENCY frequency;
                        ENUM_CALENDAR_EVENT_TIMEMODE timemode;
                        ENUM_CALENDAR_EVENT_IMPORTANCE importance;
                        ENUM_CALENDAR_EVENT_MULTIPLIER multiplier;
                        ENUM_CALENDAR_EVENT_UNIT unit;
                        uint     digits;
                        ulong    country_id; // ISO 3166-1
                       };
   string            future_eventname[];
   string            future_countryname[];
   string            future_currency[];
   MqlDateTime       tm;
   datetime          servertime;
   datetime          GMT(ushort server_offset_winter,ushort server_offset_summer);   
public:
   EventStruct       event[];
   string            eventname[];
   string            countryname[];
   string            currencyname[];
   int               SaveHistory(bool printlog_info=false);
   int               LoadHistory(bool printlog_info=false);
   int               update(int interval_seconds,bool printlog_info=false);
   int               next(int pointer_start,string currency,bool show_on_chart,long chart_id);
   string            CountryIdToCurrency(ENUM_COUNTRY_ID c);
   int               CurrencyToCountryId(string currency);    
   datetime          last_update;
   ushort            GMT_offset_winter;
   ushort            GMT_offset_summer;    
                     CNews(void)
                       {
                        ArrayResize(event,1000000,0);ZeroMemory(event);
                        ArrayResize(eventname,1000000,0);ZeroMemory(eventname);
                        ArrayResize(future_eventname,1000000,0);ZeroMemory(future_eventname);
                        ArrayResize(countryname,1000000,0);ZeroMemory(countryname);
                        ArrayResize(future_countryname,1000000,0);ZeroMemory(future_countryname);
                        ArrayResize(currencyname,1000000,0);ZeroMemory(currencyname);
                        ArrayResize(future_currency,1000000,0);ZeroMemory(future_currency);
                        GMT_offset_winter=GMT_OFFSET_WINTER_DEFAULT;
                        GMT_offset_summer=GMT_OFFSET_SUMMER_DEFAULT;
                        last_update=0;
                        SaveHistory(true);
                        LoadHistory(true);
                       }
                    ~CNews(void){};
  };

//+------------------------------------------------------------------+
//| update news events (file and buffer arrays)                      |
//+------------------------------------------------------------------+
int CNews::update(int interval_seconds=60,bool printlog_info=false)
  {
   static datetime last_time=0;
   static int total_events=0;
   if (TimeCurrent()<last_time+interval_seconds){return total_events;}
   total_events = SaveHistory(printlog_info);
   //total_events=LoadHistory(printlog_info);
   last_time=TimeCurrent();
   return total_events;
  }

//+------------------------------------------------------------------+
//| grab news history and save it to disk                            |
//+------------------------------------------------------------------+
int CNews::SaveHistory(bool printlog_info=false)
  {
   datetime tm_gmt=GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;
   
   // create or open history file
   if (!FileIsExist("news\\newshistory.bin",FILE_COMMON))
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      if (filehandle!=INVALID_HANDLE){if(printlog_info){Print(__FUNCTION__,": creating new file common/files/news/newshistory.bin");}}
      else {if (printlog_info){Print(__FUNCTION__,"invalid filehandle, can't create news history file");}return 0;}
      FileSeek(filehandle,0,SEEK_SET);
      FileWriteLong(filehandle,(long)last_update);
     }
   else
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if (filehandle!=INVALID_HANDLE){if(printlog_info){Print(__FUNCTION__,": previous newshistory file found in common/files; history update starts from ",last_update," GMT");}}
      else {if(printlog_info){Print(__FUNCTION__,": invalid filehandle; can't open previous news history file");};return 0;}
      bool from_beginning=FileSeek(filehandle,0,SEEK_END);
      if(!from_beginning){Print(__FUNCTION__": unable to go to the file's beginning");}
     }
   if (last_update>tm_gmt)
     {
      if (printlog_info)
        {Print(__FUNCTION__,": time of last news update is in the future relative to timestamp of request; the existing data won't be overwritten/replaced,",
         "\nexecution of function therefore prohibited; only future events relative to this timestamp will be loaded");}
      return 0; //= number of new events since last update
     }
     
   // get entire event history from last update until now
   MqlCalendarValue eventvaluebuffer[];ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;ZeroMemory(eventbuffer);
   MqlCalendarCountry countrybuffer;ZeroMemory(countrybuffer);
   CalendarValueHistory(eventvaluebuffer,last_update,tm_gmt);
   
   int number_of_events=ArraySize(eventvaluebuffer);
   int saved_elements=0;
   if (number_of_events>=ArraySize(event)){ArrayResize(event,number_of_events,0);}
   for (int i=0;i<number_of_events;i++)
     {
      event[i].value_id          =  eventvaluebuffer[i].id;
      event[i].event_id          =  eventvaluebuffer[i].event_id;
      event[i].time              =  eventvaluebuffer[i].time;
      event[i].period            =  eventvaluebuffer[i].period;
      event[i].revision          =  eventvaluebuffer[i].revision;
      event[i].actual_value      =  eventvaluebuffer[i].actual_value;
      event[i].prev_value        =  eventvaluebuffer[i].prev_value;
      event[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      event[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      event[i].impact_type       =  eventvaluebuffer[i].impact_type;
      
      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);
      
      event[i].event_type        =  eventbuffer.type;
      event[i].sector            =  eventbuffer.sector;
      event[i].frequency         =  eventbuffer.frequency;
      event[i].timemode          =  eventbuffer.time_mode;
      event[i].importance        =  eventbuffer.importance;
      event[i].multiplier        =  eventbuffer.multiplier;
      event[i].unit              =  eventbuffer.unit;
      event[i].digits            =  eventbuffer.digits;
      event[i].country_id        =  eventbuffer.country_id;
      eventname[i]               =  eventbuffer.name;
      
      CalendarCountryById(eventbuffer.country_id,countrybuffer);         
      countryname[i]             =  countrybuffer.code;
      currencyname[i]            =  countrybuffer.currency;

      //if (event[i].event_type!=CALENDAR_TYPE_HOLIDAY &&           // ignore holiday events
      //   event[i].timemode==CALENDAR_TIMEMODE_DATETIME)           // only events with exactly published time
      //  {
         FileWriteStruct(filehandle,event[i]);
         int length=StringLen(eventbuffer.name);
         FileWriteInteger(filehandle,length,INT_VALUE);
         FileWriteString(filehandle,eventbuffer.name,length);
         
         length=StringLen(countrybuffer.code);
         FileWriteInteger(filehandle,length,INT_VALUE);
         FileWriteString(filehandle,countrybuffer.code,length);      
         
         length=StringLen(countrybuffer.currency);
         FileWriteInteger(filehandle,length,INT_VALUE);
         FileWriteString(filehandle,countrybuffer.currency,length); 
                     
         saved_elements++; 
     }
   // renew update time
   FileSeek(filehandle,0,SEEK_SET);
   FileWriteLong(filehandle,(long)tm_gmt);
   FileClose(filehandle);
   if (printlog_info)
      {Print(__FUNCTION__,": ",number_of_events," total events found, ",saved_elements,
      " events saved (holiday events and events without exact published time are ignored)");}
   return saved_elements; //= number of new events since last update
  }

//+------------------------------------------------------------------+
//| load history                                                     |
//+------------------------------------------------------------------+
int CNews::LoadHistory(bool printlog_info=false)
  {
   datetime dt_gmt=GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;
   int number_of_events=0;
   
   // open history file
   if (FileIsExist("news\\newshistory.bin",FILE_COMMON))
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if (filehandle!=INVALID_HANDLE){if (printlog_info){Print (__FUNCTION__,": previous news history file found; last update was on ",last_update," (GMT)");}}
      else {if (printlog_info){Print(__FUNCTION__,": can't open previous news history file; invalid file handle");}return 0;}
      
      ZeroMemory(event);
      // read all stored events
      int i=0;
      while (!FileIsEnding(filehandle) && !IsStopped())
        {
         if (ArraySize(event)<i+1){ArrayResize(event,i+1000);}
         FileReadStruct(filehandle,event[i]);
         int length=FileReadInteger(filehandle,INT_VALUE);
         eventname[i]=FileReadString(filehandle,length);
         length=FileReadInteger(filehandle,INT_VALUE);
         countryname[i]=FileReadString(filehandle,length);
         length=FileReadInteger(filehandle,INT_VALUE);
         currencyname[i]=FileReadString(filehandle,length);
         i++;
        }
      number_of_events=i;
      // FileClose(filehandle);
      if (printlog_info)
        {Print(__FUNCTION__,": loading of event history completed (",number_of_events," events), continuing with events after ",last_update," (GMT) ...");}
     }
   else
     {
      if (printlog_info)
        {Print(__FUNCTION__,": no newshistory file found, only upcoming events will be loaded");}
      last_update=dt_gmt;
     }
   
   return number_of_events;
   // get future events
   MqlCalendarValue eventvaluebuffer[];ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;ZeroMemory(eventbuffer);
   MqlCalendarCountry countrybuffer;ZeroMemory(countrybuffer);
   CalendarValueHistory(eventvaluebuffer,last_update,0);
   int future_events=ArraySize(eventvaluebuffer);
   if (printlog_info)
     {Print(__FUNCTION__,": ",future_events," new events found (holiday events and events without published exact time will be ignored)");}
   EventStruct future[];ArrayResize(future,future_events,0);ZeroMemory(future);
   ArrayResize(event,number_of_events+future_events);
   ArrayResize(eventname,number_of_events+future_events);
   ArrayResize(countryname,number_of_events+future_events);
   ArrayResize(currencyname,number_of_events+future_events);
   for (int i=0;i<future_events;i++)
     {

      future[i].value_id          =  eventvaluebuffer[i].id;
      future[i].event_id          =  eventvaluebuffer[i].event_id;
      future[i].time              =  eventvaluebuffer[i].time;
      future[i].period            =  eventvaluebuffer[i].period;
      future[i].revision          =  eventvaluebuffer[i].revision;
      future[i].actual_value      =  eventvaluebuffer[i].actual_value;
      future[i].prev_value        =  eventvaluebuffer[i].prev_value;
      future[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      future[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      future[i].impact_type       =  eventvaluebuffer[i].impact_type;
      
      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);
      
      future[i].event_type        =  eventbuffer.type;
      future[i].sector            =  eventbuffer.sector;
      future[i].frequency         =  eventbuffer.frequency;
      future[i].timemode          =  eventbuffer.time_mode;
      future[i].importance        =  eventbuffer.importance;
      future[i].multiplier        =  eventbuffer.multiplier;
      future[i].unit              =  eventbuffer.unit;
      future[i].digits            =  eventbuffer.digits;
      future[i].country_id        =  eventbuffer.country_id;
      future_eventname[i]         =  eventbuffer.name;
      
      CalendarCountryById(eventbuffer.country_id,countrybuffer);  
      future_countryname[i]         =  countrybuffer.code;
      future_currency[i]            =  countrybuffer.currency;    
      //future[i].country_name      =  countrybuffer.name;
      //future[i].currency          =  countrybuffer.currency;
            
      //if (future[i].event_type!=CALENDAR_TYPE_HOLIDAY &&           // ignore holiday events
      //   future[i].timemode==CALENDAR_TIMEMODE_DATETIME)           // only events with exactly published time
      //  {
         number_of_events++;
         event[number_of_events]=future[i];
         eventname[number_of_events]=future_eventname[i];
         countryname[number_of_events]=future_countryname[i];
         currencyname[number_of_events]=future_currency[i];

     }
   if (printlog_info)
     {Print(__FUNCTION__,": loading of news history completed, ",number_of_events," events in memory");}
   last_update=dt_gmt;
   return number_of_events;
  }

// +------------------------------------------------------------------+
// | get pointer to next event for given currency                     |
// +------------------------------------------------------------------+
int CNews::next(int pointer_start,string currency,bool show_on_chart=true,long chart_id=0)
  {
   datetime dt_gmt=GMT(GMT_offset_winter,GMT_offset_summer);
   for (int p=pointer_start;p<ArraySize(event);p++)
     {
      if 
        (
         event[p].country_id==CurrencyToCountryId(currency) &&
         event[p].time>=dt_gmt
        )
        {
         if (pointer_start!=p && show_on_chart && MQLInfoInteger(MQL_VISUAL_MODE))
           {
            ObjectCreate(chart_id,"event "+IntegerToString(p),OBJ_VLINE,0,event[p].time+TimeTradeServer()-dt_gmt,0);
            ObjectSetInteger(chart_id,"event "+IntegerToString(p),OBJPROP_WIDTH,3);
            ObjectCreate(chart_id,"label "+IntegerToString(p),OBJ_TEXT,0,event[p].time+TimeTradeServer()-dt_gmt,SymbolInfoDouble(Symbol(),SYMBOL_BID));
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_YOFFSET,800);
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_BACK,true);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_FONT,"Arial");
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_FONTSIZE,10);
            ObjectSetDouble(chart_id,"label "+IntegerToString(p),OBJPROP_ANGLE,-90);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_TEXT,eventname[p]);
           }
         return p;         
        }
     }
   return pointer_start;
  }

//+------------------------------------------------------------------+
//| country id to currency                                           |
//+------------------------------------------------------------------+
string CNews::CountryIdToCurrency(ENUM_COUNTRY_ID c)
  {
   switch(c)
     {
      case 999:      return "EUR";     // EU
      case 840:      return "USD";     // USA
      case 36:       return "AUD";     // Australia
      case 554:      return "NZD";     // NewZealand
      case 156:      return "CYN";     // China
      case 826:      return "GBP";     // UK
      case 756:      return "CHF";     // Switzerland
      case 276:      return "EUR";     // Germany
      case 250:      return "EUR";     // France
      case 380:      return "EUR";     // Italy
      case 724:      return "EUR";     // Spain
      case 76:       return "BRL";     // Brazil
      case 410:      return "KRW";     // South Korea
      default:       return "";
     }
  }  
  
//+------------------------------------------------------------------+
//| currency to country id                                           |
//+------------------------------------------------------------------+
int CNews::CurrencyToCountryId(string currency)
  {
   if (currency=="EUR"){return 999;}
   if (currency=="USD"){return 840;}
   if (currency=="AUD"){return 36;}
   if (currency=="NZD"){return 554;}
   if (currency=="CYN"){return 156;}
   if (currency=="GBP"){return 826;}
   if (currency=="CHF"){return 756;}
   if (currency=="BRL"){return 76;}
   if (currency=="KRW"){return 410;}
   return 0;
  }

//+------------------------------------------------------------------+
//| convert server time to GMT                                       |
//| (=for correct GMT time during both testing and live trading)     |
//+------------------------------------------------------------------+
datetime CNews::GMT(ushort server_offset_winter,ushort server_offset_summer)
  {
   // CASE 1: LIVE ACCOUNT
   if (!MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_TESTER)){return TimeGMT();}
   
   // CASE 2: TESTER or OPTIMIZER
   servertime=TimeCurrent(); //=should be the same as TimeTradeServer() in tester mode, however, the latter sometimes leads to performance issues
   TimeToStruct(servertime,tm);
   static bool initialized=false;
   static bool summertime=true;
   // make a rough guess
   if (!initialized)
     {
      if (tm.mon<=2 || (tm.mon==3 && tm.day<=7)) {summertime=false;}
      if ((tm.mon==11 && tm.day>=8) || tm.mon==12) {summertime=false;}
      initialized=true;
     }
   // switch to summertime
   if (tm.mon==3 && tm.day>7 && tm.day_of_week==0 && tm.hour==7+server_offset_winter) // second sunday in march, 7h UTC New York=2h local winter time
     {
      summertime=true;
     }
   // switch to wintertime
   if (tm.mon==11 && tm.day<=7 && tm.day_of_week==0 && tm.hour==7+server_offset_summer) // first sunday in november, 7h UTC New York=2h local summer time
     {
      summertime=false;
     }
   if (summertime){return servertime-server_offset_summer*3600;}
   else {return servertime-server_offset_winter*3600;}
  }