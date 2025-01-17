
#define SUNDAY 0
#define MONDAY 1
#define TUESDAY 2
#define WEDNESDAY 3
#define THURSDAY 4
#define FRIDAY 5
#define SATURDAY 6
#define DATETIME_DAY 86400
#define DATETIME_HOUR 3600
#define DATETIME_MINUTE 60
#define DATETIME_SECOUND 1

double Ask(string symbol){
   MqlTick last_tick;
   SymbolInfoTick(symbol,last_tick);
   return last_tick.ask;
}

double Bid(string symbol){
   MqlTick last_tick;
   SymbolInfoTick(symbol,last_tick);
   return last_tick.bid;
}

// 3桁5桁業者か判断し、pips変換のための値（10）を返す
int digits_adjust(int digits){
   return (digits==3 || digits==5) ? 10 : 1;
}

// adjusted pointを返す（5桁なら0.0001）
double adjusted_point(double point,int digits){
   return point*digits_adjust(digits);
}

double pips2point(double value,int digits){
   return value * digits_adjust(digits);
}

double point2pips(double value,int digits){
   return value / digits_adjust(digits);
}

double pips2price(double value,double point,int digits){
   return value * adjusted_point(point,digits);
}

double price2pips(double value,double point,int digits){
   return value / adjusted_point(point,digits);
}

double point2price(double value,double point){
   return value * point;
}

double price2point(double value,double point){
   return value / point;
}

int lot_digits(string symbol){
   return (int)MathAbs(MathLog10(SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP))); 
}

int account_digits(){
   // 口座通貨の小数点以下の桁数
   return (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS);
}

double reverse_price(string symbol,double sl_price,double open_price=0,double coefficient=1){
   double distance;
   double r;
   
   if(coefficient==0) return 0;
   
   if(open_price==0){
      if(Bid(symbol)<sl_price&&Ask(symbol)<sl_price){     // ショートの時 
         distance = sl_price-Bid(symbol);                 
         r = Bid(symbol)-(distance*coefficient);          // エントリー価格からのTP距離（トレーダーが指定したTP値が利益になるようスプレッド分の差し引きは含めないことにする）
      } else if(Bid(symbol)>sl_price&&Ask(symbol)>sl_price){   // ロングの時
         distance = Ask(symbol)-sl_price; 
         r = Ask(symbol)+(distance*coefficient);          // エントリー価格からのTP距離（トレーダーが指定したTP値が利益になるようスプレッド分の差し引きは含めないことにする）
      } else {
         r = 0;
      }
   } else {
      if(open_price<sl_price){
         distance = sl_price-open_price;
         r = open_price-(distance*coefficient);
      } else if(open_price>sl_price){
         distance = open_price-sl_price;
         r = open_price+(distance*coefficient);
      } else {
         r = 0;
      }   
   
   }
   return r;
}

ENUM_ORDER_TYPE reverse_order_type(ENUM_ORDER_TYPE order_type){
   if(order_type==ORDER_TYPE_BUY){
      return ORDER_TYPE_SELL;
   } else {
      return ORDER_TYPE_BUY;
   }
   return 0;
}

double calc_pips2sl(string symbol,ENUM_ORDER_TYPE order_type,double sl_pips,double point,int digits){
   if(order_type==ORDER_TYPE_BUY){
      return Ask(symbol) - pips2price(sl_pips,point,digits);
   } else if(order_type==ORDER_TYPE_SELL){
      return Bid(symbol) + pips2price(sl_pips,point,digits);
   }
   return 0;
}

double calc_pips2tp(string symbol,ENUM_ORDER_TYPE order_type,double tp_pips,double point,int digits){
   if(order_type==ORDER_TYPE_BUY){
      return Ask(symbol) + pips2price(tp_pips,point,digits);
   } else if(order_type==ORDER_TYPE_SELL){
      return Bid(symbol) - pips2price(tp_pips,point,digits);
   }
   return 0;
}

// pips変換後のspreadを返す
double spread_pips(string symbol,int digits){
   return (double)SymbolInfoInteger(symbol,SYMBOL_SPREAD) / digits_adjust(digits);
}



// 新規生成されたバーかチェックする

bool IsNewBar(string symbol, ENUM_TIMEFRAMES tf)
{
   // If new bar return true
   // On same tick return true
   static datetime bartime = 0;
   static long ticktime = 0;
   MqlTick tick;
   SymbolInfoTick(symbol, tick);
   if(iTime(symbol, tf, 0) != bartime)
   {
      bartime = iTime(symbol, tf, 0);
      ticktime = tick.time_msc;
      return true;
   }
   else if(ticktime == tick.time_msc) return true;
   return false;
}


void get_dt_period_now_month(datetime &start,datetime &end){
   // 当月の期間（yyyy.mm.01 ~ yyyy.mm.dd）を返す
   end = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt); 

   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;

   start = StructToTime(dt);
}

void get_dt_period_prev_month(int prev_month_count,int period_month_count,datetime &start,datetime &end){
   // 指定した月を遡り、そこから指定した期間（yyyy.mm.01 ~ yyyy.mm.dd）を返す
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt); 
   
   for(int i=0; i<prev_month_count; i++){
      if(dt.mon==1){
         dt.year = dt.year - 1;
         dt.mon = 12;
      } else {
         dt.mon = dt.mon - 1;
      }   
   }

   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   start = StructToTime(dt);
   
   for(int i=0; i<period_month_count; i++){
      if(dt.mon==12){
         dt.year = dt.year + 1;
         dt.mon = 1;
      } else {
         dt.mon = dt.mon + 1;
      }   
   }   

   end = StructToTime(dt) - 1;
     
}

void get_dt_period_next_month(int next_month_count,int period_month_count,datetime &start,datetime &end){
   // 指定した月を進み、そこから指定した期間（yyyy.mm.01 ~ yyyy.mm.dd）を返す
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt); 
   
   for(int i=0; i<next_month_count; i++){
      if(dt.mon==12){
         dt.year = dt.year + 1;
         dt.mon = 1;
      } else {
         dt.mon = dt.mon + 1;
      }   
   }

   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   start = StructToTime(dt);
   
   for(int i=0; i<period_month_count; i++){
      if(dt.mon==12){
         dt.year = dt.year + 1;
         dt.mon = 1;
      } else {
         dt.mon = dt.mon + 1;
      }   
   }   

   end = StructToTime(dt) - 1;
     
}

datetime open_dt(datetime date){
   MqlDateTime dt;
   TimeToStruct(date,dt); 
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

datetime close_dt(datetime date){
   MqlDateTime dt;
   TimeToStruct(date,dt); 
   dt.hour = 23;
   dt.min = 59;
   dt.sec = 59;
   return StructToTime(dt);
}

ENUM_TIMEFRAMES get_period(string period_name){
   if(period_name=="PERIOD_D1") return PERIOD_D1;
   if(period_name=="PERIOD_H1") return PERIOD_H1;
   if(period_name=="PERIOD_H12") return PERIOD_H12;
   if(period_name=="PERIOD_H2") return PERIOD_H2;
   if(period_name=="PERIOD_H3") return PERIOD_H3;
   if(period_name=="PERIOD_H4") return PERIOD_H4;
   if(period_name=="PERIOD_H6") return PERIOD_H6;
   if(period_name=="PERIOD_H8") return PERIOD_H8;
   if(period_name=="PERIOD_M1") return PERIOD_M1;
   if(period_name=="PERIOD_M10") return PERIOD_M10;
   if(period_name=="PERIOD_M12") return PERIOD_M12;
   if(period_name=="PERIOD_M15") return PERIOD_M15;
   if(period_name=="PERIOD_M2") return PERIOD_M2;
   if(period_name=="PERIOD_M20") return PERIOD_M20;
   if(period_name=="PERIOD_M3") return PERIOD_M3;
   if(period_name=="PERIOD_M30") return PERIOD_M30;
   if(period_name=="PERIOD_M4") return PERIOD_M4;
   if(period_name=="PERIOD_M5") return PERIOD_M5;
   if(period_name=="PERIOD_M6") return PERIOD_M6;
   if(period_name=="PERIOD_MN1") return PERIOD_MN1;
   if(period_name=="PERIOD_W1") return PERIOD_W1;
   return PERIOD_CURRENT;
}

//bool CheckSummerTime(ushort arg_servertime_offset,ushort arg_summertime_offset){
//   datetime now_gmt = GMT(arg_servertime_offset,arg_summertime_offset);
//   ulong now_offset = ((ulong)TimeCurrent() - (ulong)now_gmt) / 3600;
//   if(now_offset==arg_summertime_offset) return true;
//   if(now_offset!=arg_servertime_offset) {
//      Print(__FUNCTION__ + "Incorrect Offset. offset=" + IntegerToString(now_offset));
//   }  
//   return false;
//}

//datetime GMT(ushort server_offset_winter,ushort server_offset_summer)
//  {
//   // CASE 1: LIVE ACCOUNT
//   if (!MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_TESTER)){return TimeGMT();}
//   
//   // CASE 2: TESTER or OPTIMIZER
//   MqlDateTime tm;
//   datetime servertime=TimeCurrent(); //=should be the same as TimeTradeServer() in tester mode, however, the latter sometimes leads to performance issues
//   TimeToStruct(servertime,tm);
//
//   bool summertime=true;
//   // make a rough guess
//
//      if (tm.mon<=2 || (tm.mon==3 && tm.day<7)) {summertime=false;}
//      if ((tm.mon==11 && tm.day>=8) || tm.mon==12) {summertime=false;}
//
//   if (summertime){return servertime-server_offset_summer*3600;}
//   else {return servertime-server_offset_winter*3600;}
//  }
  
bool CheckEndOfMonth(datetime target_date){
   MqlDateTime dt;
   TimeToStruct(target_date,dt);
   int d = dt.day;

   datetime s,e;
   get_dt_period_next_month(1,1,s,e);
   TimeToStruct(s-1,dt);
   if(d==dt.day) return true;
   return false;
}

bool CheckStartOfMonth(datetime target_date){
   MqlDateTime dt;
   TimeToStruct(target_date,dt);
   int d = dt.day;

   datetime s,e;
   get_dt_period_now_month(s,e);
   TimeToStruct(s,dt);
   if(d==dt.day) return true;
   return false;
}

bool CheckSummerTime(int StartMonth,int StartDay,int EndMonth,int EndDay){
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   int mon = dt.mon;
   int day = dt.day;
   
   if(StartMonth>mon) return false; // サマータイム開始月より前の月の場合は標準時間
   if(EndMonth<mon) return false; // サマータイム終了月より後の月の場合は標準時間
   if(StartMonth==mon){
      if(StartDay>day) return false; // サマータイム開始月で開始日より前の場合は標準時間
   }
   if(EndMonth==mon){
      if(EndDay<day) return false; // サマータイム終了月で終了日より後の場合は標準時間
   }

   return true;   // 上記に一致しない場合サマータイムである
}

// 基準時間を調整して返す
datetime AdjustedTimeCurrent(bool isSummerTime,char adjusted_offset){
   datetime adjusted_time;
   if(isSummerTime) {
      adjusted_offset++;   // サマータイムの時1時間進める
   }
   adjusted_time = TimeCurrent() + (adjusted_offset * DATETIME_HOUR);

   return adjusted_time;
}