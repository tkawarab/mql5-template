#property version   "1.10"

#include <stdlib.mqh>
#include <tk\com\Input.mqh>
#include <tk\lib\Logger.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <tk\mqlib\Indicators\Zigzag.mqh>
#include <tk\mqlib\Expert\Money\MoneyFixedRisk.mqh>
#include <tk\mqlib\Expert\Money\MoneySizeOptimizedRisk.mqh>
#include <tk\mqlib\Expert\Money\MoneyNone.mqh>
#include <tk\mqlib\Expert\Money\MoneyFixedLot.mqh>
#include <tk\lib\File.mqh>
#include <tk\lib\Function.mqh>
#include <tk\lib\Position.mqh>
#include <tk\lib\Deal.mqh>
#include <tk\extlib\inifile.mqh>
#include <tk\lib\Calendar.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingATR.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingMA.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingFixedPips.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingNone.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingParabolicSAR.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingZigzag.mqh>
#include <tk\mqlib\Expert\Trailing\TrailingPrevBar.mqh>


class CMyExpert : public CObject
  {
private:
   CDataFile             *report_csv;
   bool                 output_report();
   void                 output_report_summary();
   void                 Save();
   void                 Load();
   void                 Save_ini();
   void                 Load_ini();   
   void                 ExecNotify(string text);
   void                 DisplayMessage();   
   //CGlobalVariable      *g_val;   
   string               period_name() { return EnumToString(m_period); }
   string               m_direction_type; // LONG, SHORT, LONGSHORT
   bool                 m_init;
   int                  SummerTimeStartMonth;
   int                  SummerTimeStartDay;
   int                  SummerTimeEndMonth;
   int                  SummerTimeEndDay;
   int                  SwapTime;
   int                  SwapTimeMin;
   int                  SwapTimeSummer;
   int                  SwapTimeMinSummer;
   int                  WeekendTime;
   int                  WeekendTimeMin;
   int                  WeekendTimeSummer;
   int                  WeekendTimeMinSummer;
protected:
   CLogger  *m_logger;
   // Variables
   ulong                m_magic;
   string               m_symbol_name;
   ENUM_TIMEFRAMES      m_period;
   bool                 m_every_tick;
   string               m_project_name;
   string               m_env_name;
   bool                 m_summer_time;
   datetime             m_time_current;
   OPERATION_TYPE       m_operation_type;
   int                  m_max_spread_points;
   // Open
   OPEN_TYPE            m_open_type;
   uint                 m_sleep_bar_count;

   // Close
   CLOSE_TYPE           m_close_type;
   double               m_close_rrr;               // SLに対するTPの倍率を設定
   uint                 m_close_bar_count;         // 最初のポジションオープン後、指定バー数経過で全ポジションを強制決済する
     
   // Split Close
   bool                 m_close_split;
   double               m_split_rrr;               // 分割決済発動幅算出するための係数
   bool                 m_split_same_line;         // 複数ポジションがある時、分割決済発動するラインを最初のポジションと同一とするかどうか。しない場合は各ポジションごとに分割決済ラインを確認
   // Pyramid
   bool                 m_pyramiding_enable;
   uint                 m_pyramiding_max_counts;   // 最大ピラミッディング回数
   double               m_pyramiding_coefficient;  // ピラミッディング幅算出するための係数（SL幅＊係数）　オープン価格からラインを超えたらピラミッディングする
   bool                 m_pyramiding_close;        // ピラミッディング時に一つ前のポジションをクローズするかどうか
   bool                 m_pyramiding_same_money;   // ピラミッディング時最初のポジションと同じロットとするかどうか
   bool                 m_pyramiding_same_sl;      // ピラミッディング時最初のポジションと同じＳＬとするかどうか
   bool                 m_pyramiding_same_tp;      // ピラミッディング時最初のポジションと同じＴＰとするかどうか
   
   string               m_option_params[];         // Strategyに渡すパラメータ配列
   double               m_strategy_sl;             // Strategyで指定したSL値
   // Trade Standard Variables
   CAccountInfo         m_account;
   CSymbolInfo          m_symbol;
   COrderInfo           m_order;
   CHistoryOrderInfo    m_history;
   CPositionInfo        m_position;
   CDealInfo            m_deal;
   CTrade               m_trade;
   CTerminalInfo        m_terminal;
   // Indicator Variables
   CIndicators          m_indicators;                 // indicator collection to fast recalculations
   CiATR                m_atr;                        // SL計算用ATR
   CiSAR                m_sar;                        // SL計算用ParabolicSAR
   CiZigZag             m_zg;                         // SL計算用Zigzag
   CiMA                 m_ma;                         // SL計算用MA
   CiBands              m_bands;                      // SL用ボリンジャーバンド
   CiBands              m_bands_filter;               // フィルタ用ボリンジャーバンド
   CExpertMoney         *m_money;
   CCalendar            m_calendar;                   // 経済指標カレンダーを扱うクラス
   CExpertTrailing      *m_trail;

protected:
   // Strategy Use 
   double               m_order_ask;
   double               m_order_bid;
   double               m_order_lot;
   double               m_order_price;
   double               m_order_sl;
   double               m_order_tp;
   double               m_order_price_long;           // 最初のポジションのオープン価格（LONGポジション）
   double               m_order_stoplimit_price_long; // ストップリミット注文時、指値注文が出される価格
   ENUM_ORDER_TYPE_TIME m_order_time_long;            // 指値時注文期限タイプ（LONGポジション）
   datetime             m_order_time_spec_long;       // 注文期限の日時（LONGポジション）
   bool                 m_order_reset_long;           // 未決注文をキャンセルするフラグ（LONG）
   double               m_order_sl_long;              // 最初のポジションのＳＬ価格（LONGポジション）
   double               m_order_tp_long;              // 最初のポジションのＴＰ価格（LONGポジション）
   double               m_order_lot_long;             // 最初のポジションのロット数（LONGポジション）
   double               m_order_sl_width_long;        // 最初のポジションのＳＬ幅（LONGポジション）
   uint                 m_pyramiding_counts_long;     // ピラミッディングライン統一時のピラミッディングした回数（LONGポジション）
//   uint                 m_position_bar_count_long;    // 最初のポジションオープンからの経過バー数
   double               m_order_price_short;          // 最初のポジションのオープン価格（SHORTポジション） 
   double               m_order_stoplimit_price_short; // ストップリミット注文時、指値注文が出される価格
   ENUM_ORDER_TYPE_TIME m_order_time_short;            // 指値時注文期限タイプ（SHORTポジション）
   datetime             m_order_time_spec_short;       // 注文期限の日時（SHORTポジション）   
   bool                 m_order_reset_short;          // 未決注文をキャンセルするフラグ（LONG）
   double               m_order_sl_short;             // 最初のポジションのＳＬ価格（SHORTポジション）
   double               m_order_tp_short;             // 最初のポジションのＴＰ価格（SHORTポジション）
   double               m_order_lot_short;            // 最初のポジションのロット数（SHORTポジション）
   double               m_order_sl_width_short;       // 最初のポジションのＳＬ幅（SHORTポジション）
   uint                 m_pyramiding_counts_short;    // ピラミッディングライン統一時のピラミッディングした回数（SHORTポジション）  
//   uint                 m_position_bar_count_short;   // 最初のポジションオープンからの経過バー数
   double               m_position_manage_long[][4];  // [0] ticket, [1] sl_width, [2] trail_count, [3] split_count
   double               m_position_manage_short[][4]; // [0] ticket, [1] sl_width, [2] trail_count, [3] split_count
   uint                 m_sl_trail_count_long;        // トレイルライン統一時のトレイル回数（LONG）
   uint                 m_sl_trail_count_short;       // トレイルライン統一時のトレイル回数（SHORT）
   uint                 m_split_count_long;           // 分割決済ライン統一時のトレイル回数（LONG）
   uint                 m_split_count_short;          // 分割決済ライン統一時のトレイル回数（SHORT）
protected:
   // Methods
   
   virtual  void  InitIndicator(){ return; }
   virtual  void  RefreshIndicator(){ return; }
   
   virtual  void  Main(ENUM_ORDER_TYPE order_type);
   virtual  void  MainCheckOrder(ENUM_ORDER_TYPE order_type);
   virtual  bool  MainOpen(ENUM_ORDER_TYPE order_type);
   virtual  void  MainClose(ENUM_ORDER_TYPE order_type);
   
   virtual  bool  CheckOpenSleepTime(ENUM_ORDER_TYPE order_type);
   virtual  bool  CheckOpenEconomicIndicators(ENUM_ORDER_TYPE order_type);
   virtual  bool  CheckOpenFilter(ENUM_ORDER_TYPE order_type);
   virtual  bool  CheckOpenHline(ENUM_ORDER_TYPE order_type);
   virtual  bool  CheckOpenTrend(ENUM_ORDER_TYPE order_type);
   virtual  bool  CheckOpen(ENUM_ORDER_TYPE order_type){ return false; }
   virtual  bool  CheckPending(ENUM_ORDER_TYPE order_type){ return (order_count(m_magic,m_symbol_name,order_type)==0 ? true : false); } // 未決注文がある場合はスキップ
   virtual  bool  CheckPyramiding(ENUM_ORDER_TYPE order_type){ return true; }
   bool           CheckDateTime(void); 
   bool           CheckSpread(void);
   bool           CheckOpenCircuitBreaker(void);
   
   virtual  void  OrderOpen(ENUM_ORDER_TYPE order_type);

   virtual  bool  CheckClose(ENUM_ORDER_TYPE order_type){ return false; }
   virtual  void  OrderClose(ENUM_ORDER_TYPE order_type);
   
   virtual  bool  CheckTrail(ENUM_ORDER_TYPE order_type){ return true; }
   virtual  void  OrderTrail(ENUM_ORDER_TYPE order_type);

   virtual  bool  CheckCloseSplit(ENUM_ORDER_TYPE order_type);
   virtual  void  Refresh();
   
   virtual  double SL(ENUM_ORDER_TYPE order_type);
   virtual  double CalculateSL(ENUM_ORDER_TYPE order_type);
   virtual  double CalculateTP(ENUM_ORDER_TYPE order_type);
   virtual  double CalculateLOT(ENUM_ORDER_TYPE order_type);
   
   double               zig_point(int num,CiZigZag *zg);
   int                  zig_bar(int num,CiZigZag *zg);
   double               zig_point_high(int num,CiZigZag *zg);
   int                  zig_bar_high(int num,CiZigZag *zg);
   double               zig_point_low(int num,CiZigZag *zg);
   int                  zig_bar_low(int num,CiZigZag *zg);      
   bool                 ForceClose(ENUM_ORDER_TYPE order_type);
   bool                 LogicClose(ENUM_ORDER_TYPE order_type);
   void                 SplitClose(ENUM_ORDER_TYPE order_type);
   void                 Trail(ENUM_ORDER_TYPE order_type);
   void                 TrailingModel(ENUM_ORDER_TYPE order_type);
   bool                 Pyramiding(ENUM_ORDER_TYPE order_type);
  
protected:
   // Event Handler
   virtual  void  OnCloseAll() {}
   virtual  void  OnStoploss() {}
   virtual  void  OnTakeprofit() {}
   virtual  void  OnExpert() {}
protected:
   // Tester
   datetime       m_tester_start;
public:
                     CMyExpert();
                    ~CMyExpert();
   virtual  void  OnTick();
   virtual  void  OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& request,const MqlTradeResult& result);
   virtual  bool  Init(string symbol,ENUM_TIMEFRAMES period);
   virtual  void  InitClose(CLOSE_TYPE arg_CloseType,double arg_RiskRewordRatio,uint arg_CloseBarCount,bool arg_CloseWeekend);
   virtual  void  InitCloseSplit(bool arg_CloseSplit,double arg_SplitRiskRewordRatio,bool arg_SplitSameLine);
   virtual  void  InitPyramiding(bool arg_PyramidingEnable,uint arg_PyramidingMaxCounts=3,double arg_PyramidingCoefficient=0.5,bool arg_PyramidingClose=false,bool arg_PyramidingSameMoney=true,bool arg_PyramidingSameSL=false,bool arg_PyramidingSameTP=false);
   virtual  bool  InitMoney(MONEY_TYPE arg_MoneyType,double arg_Percent,double arg_DecreaseFactor,double arg_IncreaseFactor,bool arg_DecreaseByStepvol,bool arg_IncreaseByStepvol);
   virtual  bool  InitIndicators(CIndicators *indicators=NULL);   
   virtual  void  InitTester(datetime start){ m_tester_start = start; }
   virtual  void  InitOpen(OPEN_TYPE open_type,int arg_SpreadPoints,uint arg_SleepBarCount);
   virtual  void  InitOperationType(OPERATION_TYPE operation_type){ m_operation_type = operation_type; }
   virtual  void  InitOptionParams(string &ParamArray[]){ ArrayCopy(m_option_params,ParamArray); }
   virtual  void  InitMagic(ulong arg_Magic);
   virtual  void  InitReport();
   virtual  bool  InitTrail();

   string            Symbol(){ return m_symbol_name; }
   ENUM_TIMEFRAMES   Period(){ return m_period; }
   OPEN_TYPE         OpenType(){ return m_open_type; }
   ulong             Magic(){ return m_magic; }
   CMyExpert      *get_pointer(){ return GetPointer(this); }
  };
  
//+------------------------------------------------------------------+
//| Constructor/Deconstructor                                        |
//+------------------------------------------------------------------+
CMyExpert::CMyExpert(): m_magic(0),
                        m_symbol_name(_Symbol),
                        m_period(_Period),
                        m_every_tick(false),
                        m_operation_type(OPERATION_TYPE_ALL),
                        m_open_type(OPEN_TYPE_LONG_SHORT),
                        m_max_spread_points(0),                                              
                        m_close_type(CLOSE_TYPE_LOGIC_ONLY),
                        m_close_rrr(2),
                        m_close_bar_count(0),
                        m_close_split(false),                        
                        m_split_rrr(1),
                        m_order_price_long(0),
                        m_order_price_short(0),
                        m_order_stoplimit_price_long(0),
                        m_order_stoplimit_price_short(0),
                        m_order_time_long(ORDER_TIME_GTC),
                        m_order_time_short(ORDER_TIME_GTC),
                        m_order_time_spec_long(0),
                        m_order_time_spec_short(0),
                        m_pyramiding_enable(false),
                        m_pyramiding_max_counts(3),
                        m_pyramiding_counts_long(0),
                        m_pyramiding_counts_short(0),
                        m_sl_trail_count_long(0),
                        m_sl_trail_count_short(0),
                        m_init(false),
                        m_summer_time(false),
                        m_time_current(0)
  {

//---
   m_logger = new CLogger(print_log_level);
   DisplayMessage();

   return;
  }

CMyExpert::~CMyExpert()
  {
   if(m_money!=NULL)
      delete m_money;  
   if(m_trail!=NULL)
      delete m_trail;     
   if(report_csv!=NULL)
      if(MQLInfoInteger(MQL_TESTER)) report_csv.write_array_value(",");
      delete report_csv;
   delete m_logger;
   ObjectDelete(0,"ExpertMessage1");
   ObjectDelete(0,"ExpertMessage2");   
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+

bool CMyExpert::Init(string arg_Symbol,ENUM_TIMEFRAMES arg_Period)
  { 
  
   // 取引口座チェック
   if(!m_account.TradeAllowed()) {
      Alert("ブローカーにより、現在の取引口座での取引操作が無効状態になっています");
      return false;
   }
   if(!m_account.TradeExpert()) {
      Alert("ブローカーにより、現在の取引口座での自動売買が無効状態になっています。");
      return false;
   }
   // クライアント状態チェック
   if(!m_terminal.IsTradeAllowed()) {
      Alert("MT5設定により、自動売買が無効状態になっています");
      return false;
   }      
   // クライアント状態チェック
   if(!m_terminal.IsConnected()) {
      Alert("取引サーバーへの接続が切断状態です");
      return false;
   }         
   //　入力パラメータチェック
   if(!(Start_Entry_Day>=1&&Start_Entry_Day<=31)){ Alert("ParameterError: Hour should be set between 0 and 23"); return false; } 
   if(!(End_Entry_Day>=-1&&End_Entry_Day<=31)){ Alert("ParameterError: Hour should be set between -1 and 23"); return false; }    
   if(!(Start_Entry_Hour>=0&&Start_Entry_Hour<=23)){ Alert("ParameterError: Hour should be set between 0 and 23"); return false; } 
   if(!(End_Entry_Hour>=-1&&End_Entry_Hour<=23)){ Alert("ParameterError: Hour should be set between -1 and 23"); return false; } 
   
   if(StringLen(SummerTimeStartDate)!=4){ Alert("ParameterError: SummerTime param should be MMDD format"); return false; } 
   if(StringLen(SummerTimeEndDate)!=4){ Alert("ParameterError: SummerTime param should be MMDD format"); return false; } 
   if(StringLen(i_SwapTime)!=4){ Alert("ParameterError: SwapTime param should be MMDD format"); return false; } 
   if(StringLen(i_SwapTimeSummer)!=4){ Alert("ParameterError: SwapTime param should be MMDD format"); return false; } 
   if(StringLen(i_WeekendTime)!=4){ Alert("ParameterError: WeekendTime param should be MMDD format"); return false; } 
   if(StringLen(i_WeekendTimeSummer)!=4){ Alert("ParameterError: WeekendTime param should be MMDD format"); return false; }    

   SummerTimeStartMonth = (int)StringSubstr(SummerTimeStartDate,0,2);
   SummerTimeStartDay = (int)StringSubstr(SummerTimeStartDate,2,2);
   SummerTimeEndMonth = (int)StringSubstr(SummerTimeEndDate,0,2);
   SummerTimeEndDay = (int)StringSubstr(SummerTimeEndDate,2,2);
   SwapTime = (int)StringSubstr(i_SwapTime,0,2);
   SwapTimeMin = (int)StringSubstr(i_SwapTime,2,2);
   SwapTimeSummer = (int)StringSubstr(i_SwapTimeSummer,0,2);
   SwapTimeMinSummer = (int)StringSubstr(i_SwapTimeSummer,2,2);
   WeekendTime = (int)StringSubstr(i_WeekendTime,0,2);
   WeekendTimeMin = (int)StringSubstr(i_WeekendTime,2,2);
   WeekendTimeSummer = (int)StringSubstr(i_WeekendTimeSummer,0,2);
   WeekendTimeMinSummer = (int)StringSubstr(i_WeekendTimeSummer,2,2);   

//   SetIndicatorATR(ATR_Period);
//   SetIndicatorSAR(SAR_Step,SAR_Maximum);
//   SetIndicatorZIGZAG(ZIGZAG_Depth,ZIGZAG_Deviation,ZIGZAG_Backstep);
//   SetIndicatorMA(MA_Period,MA_Method,MA_AppliedPrice);
     
   m_trade.LogLevel(LOG_LEVEL_ALL);
   m_trade.SetDeviationInPoints(Trade_Deviation_InPoints);
   m_trade.SetMarginMode();
   m_symbol_name = arg_Symbol;
   m_symbol.Name(arg_Symbol);
   m_period    =arg_Period;
   m_every_tick=EveryTick;
//   m_magic     =arg_Magic+(PeriodSeconds(arg_Period)/60);
   m_operation_type =OperationType;
   m_project_name   =ProjectName;
   m_env_name = env_name;
   m_order_time_long = i_OrderTypeTime;
   m_order_time_short = i_OrderTypeTime;
   

   InitOpen(i_OpenType,Spread_Limit_Points,sleep_bar_count);
   InitMagic(MagicNumber);
   InitClose(CloseType,rrr,exit_bar_count,exit_weekend);
   InitCloseSplit(split_exit,split_rrr,split_same_line);
   if(!InitMoney(MoneyType,risk,DecreaseFactor,IncreaseFactor,DecreaseByStepvol,IncreaseByStepvol)) return false;
   if(!InitTrail()) return false;
   InitPyramiding(pyramid_enable,pyramid_max_counts,pyramid_coefficient,pyramid_close_enable,pyramid_same_money,pyramid_same_sl,pyramid_same_tp);

   InitIndicator(); // Strategyインジケーターの初期化 同じパラメータのインジケーターが非表示だとテスターで非表示になるためこの位置に設置

   TesterHideIndicators(true);
   if(GetPointer(m_zg)){
      m_zg.Clear();
      //m_zg.Create(m_symbol_name,m_period,12,5,3);
      m_zg.Create(m_symbol_name,m_period,ZIGZAG_Depth,ZIGZAG_Deviation,ZIGZAG_Backstep);
   }

   if(GetPointer(m_sar)){
      m_sar.Clear();
      //m_sar.Create(m_symbol_name,m_period,0.02,0.02);
      m_sar.Create(m_symbol_name,m_period,SAR_Step,SAR_Maximum);
   }
   if(GetPointer(m_atr)){
      m_atr.Clear();
      //m_atr.Create(m_symbol_name,m_period,14);
      m_atr.Create(m_symbol_name,m_period,ATR_Period);
   }
   if(GetPointer(m_ma)){
      m_ma.Clear();
      //m_ma.Create(m_symbol_name,SL_Indicator_TF,MA_Period,0,MA_Method,MA_AppliedPrice);
      m_ma.Create(m_symbol_name,m_period,MA_Period,0,MA_Method,MA_AppliedPrice);
   }
   if(GetPointer(m_bands)){
      m_bands.Clear();
      //m_bands.Create(m_symbol_name,SL_Indicator_TF,bb_Period,0,bb_Deviation,PRICE_CLOSE);
      m_bands.Create(m_symbol_name,m_period,bb_Period,0,bb_Deviation,PRICE_CLOSE);
   }
   if(GetPointer(m_bands_filter)){
      m_bands_filter.Clear();
      m_bands_filter.Create(m_symbol_name,m_period,20,0,3.0,PRICE_CLOSE);
   }   
   TesterHideIndicators(false);

   InitIndicators(); // m_money m_trail オブジェクトのインジケーター初期化

   Load();   
   

   
   return true;
}

void CMyExpert::InitOpen(OPEN_TYPE open_type,int arg_SpreadPoints,uint arg_SleepBarCount){
   m_open_type = open_type;
   m_max_spread_points = arg_SpreadPoints;
   m_sleep_bar_count = arg_SleepBarCount;
   if(m_open_type==OPEN_TYPE_LONG){
      m_direction_type = "LONG";
   } else if(m_open_type==OPEN_TYPE_SHORT){
      m_direction_type = "SHORT";
   } else if(m_open_type==OPEN_TYPE_LONG_SHORT){
      m_direction_type = "LONGSHORT";
   }
}

void CMyExpert::InitClose(CLOSE_TYPE arg_CloseType,double arg_RiskRewordRatio,uint arg_CloseBarCount,bool arg_CloseWeekend) { 
   m_close_type = arg_CloseType; 
   m_close_rrr = arg_RiskRewordRatio; 
   m_close_bar_count = arg_CloseBarCount;
}

void CMyExpert::InitCloseSplit(bool arg_CloseSplit,double arg_SplitRiskRewordRatio,bool arg_SplitSameLine) { 
   m_close_split = arg_CloseSplit; 
   m_split_rrr = arg_SplitRiskRewordRatio; 
   m_split_same_line = arg_SplitSameLine; 
}

void CMyExpert::InitMagic(ulong arg_Magic){
   uint p = PeriodSeconds(m_period)/60;   // 1 ~ 43,200
   uint o = 0;  // 0 , 100,000 , 200,000
   if(m_open_type==OPEN_TYPE_LONG){
      o = 0;
   } else if(m_open_type==OPEN_TYPE_SHORT){
      o = 100000;
   } else if(m_open_type==OPEN_TYPE_LONG_SHORT){
      o = 200000;
   }
   m_magic = arg_Magic + o + p;

   if(GetPointer(m_trade)!=NULL)
      m_trade.SetExpertMagicNumber(m_magic);
   if(GetPointer(m_money)!=NULL)
      m_money.Magic(m_magic);
}


bool CMyExpert::InitMoney(MONEY_TYPE arg_MoneyType,double arg_Percent,double arg_DecreaseFactor,double arg_IncreaseFactor,bool arg_DecreaseByStepvol,bool arg_IncreaseByStepvol){
   if(m_money!=NULL)
      delete m_money;
   if(arg_MoneyType==MONEY_TYPE_FIXED_RISK){
      CMoneyFixedRisk *m_money_tmp = new CMoneyFixedRisk();
      m_money_tmp.DecreaseReset(DecreaseReset);
      m_money = m_money_tmp;
      //m_money = new CMoneyFixedRisk();
      
   } else if(arg_MoneyType==MONEY_TYPE_SizeOptimized){
      CMoneySizeOptimizedRisk *m_money_tmp = new CMoneySizeOptimizedRisk();
      m_money_tmp.DecreaseFactor(arg_DecreaseFactor);
      m_money_tmp.IncreaseFactor(arg_IncreaseFactor);
      m_money_tmp.DecreaseByStepvol(arg_DecreaseByStepvol);
      m_money_tmp.IncreaseByStepvol(arg_IncreaseByStepvol);
      m_money_tmp.DecreaseReset(DecreaseReset);
      m_money = m_money_tmp;
   } else if(arg_MoneyType==MONEY_TYPE_MINIMUM){
      m_money = new CMoneyNone();
   } else if(arg_MoneyType==MONEY_TYPE_FIXED_LOT){
      CMoneyFixedLot *m_money_tmp = new CMoneyFixedLot();
      m_money_tmp.Lots(FixedLots);
      m_money_tmp.DecreaseByStepvol(DecreaseByStepvol);
      m_money_tmp.IncreaseByStepvol(IncreaseByStepvol);
      m_money_tmp.DecreaseReset(DecreaseReset);      
      m_money = m_money_tmp;      
   }

   m_money.Magic(m_magic);
   m_money.Percent(arg_Percent);
   if(!m_money.Init(GetPointer(m_symbol),m_period,m_symbol.Point())){
      Print(__FUNCTION__ + ": money object initilazation failed.");
      return false;
   }
   return true;
}

bool CMyExpert::InitIndicators(CIndicators *indicators)
  {
//--- NULL always comes as the parameter, but here it's not significant for us
   CIndicators *indicators_ptr=GetPointer(m_indicators);

   if(!m_trail.InitIndicators(indicators_ptr))
     {
      Print(__FUNCTION__+": error initialization indicators of trailing object");
      return(false);
     }

   if(!m_money.InitIndicators(indicators_ptr))
     {
      Print(__FUNCTION__+": error initialization indicators of money object");
      return(false);
     }
//--- ok
   return(true);
  }
  
void CMyExpert::InitPyramiding(bool arg_PyramidingEnable,uint arg_PyramidingMaxCounts=3,double arg_PyramidingCoefficient=0.5,bool arg_PyramidingClose=false,bool arg_PyramidingSameMoney=true,bool arg_PyramidingSameSL=false,bool arg_PyramidingSameTP=false) {
    m_pyramiding_enable = arg_PyramidingEnable; 
    m_pyramiding_max_counts = arg_PyramidingMaxCounts; 
    m_pyramiding_coefficient = arg_PyramidingCoefficient;
    m_pyramiding_close = arg_PyramidingClose;
    m_pyramiding_same_money = arg_PyramidingSameMoney;
    m_pyramiding_same_sl = arg_PyramidingSameSL;
    m_pyramiding_same_tp = arg_PyramidingSameTP; 
}

void CMyExpert::InitReport(){
   if(!ReportEnable) return;
//   if(!(MQLInfoInteger(MQL_TESTER)&&m_env_name=="dev")) return;  // バックテスト時は環境がdevモードの場合のみレポート出力する

   if(!(FileIsExist("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv",FILE_COMMON))) {
      // report csvが存在しない場合
      report_csv = new CDataFile("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv",false);
      report_csv.reset_array_value();
      report_csv.append_array_value("Ticket");
      report_csv.append_array_value("OpenTime");
      report_csv.append_array_value("CloseTime");
      report_csv.append_array_value("Symbol");
      report_csv.append_array_value("Action");
      report_csv.append_array_value("Size");
      report_csv.append_array_value("OpenPrice");
      report_csv.append_array_value("ClosePrice");
      report_csv.append_array_value("CommSwap");
      report_csv.append_array_value("PL");
      report_csv.append_array_value("Comment");
      report_csv.append_array_value("MagicNumber");
      report_csv.append_array_value("Win/Lose");
      report_csv.append_array_value("Reason");
      report_csv.append_array_value("PosBarNum");     
      report_csv.append_array_value("PosHighBarNum"); 
      report_csv.append_array_value("PosHigh"); 
      report_csv.append_array_value("PosLowBarNum"); 
      report_csv.append_array_value("PosLow");   
      if(MQLInfoInteger(MQL_TESTER)){
         // バックテストの場合開きっぱなしで改行しておく  
         report_csv.append_array_value("\r\n");
      } else {
         // デモ・本番ならCSVを保存し閉じる
         report_csv.write_array_value(",");   
         delete(report_csv);
      }
   } else {
      // report csvが存在する場合
      // TESTER 用に開く
      if(MQLInfoInteger(MQL_TESTER)){
         if(ReportAddwrite){
            report_csv = new CDataFile("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv",false);
            report_csv.reset_array_value();           
         } else {
            report_csv = new CDataFile("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv",true);
            report_csv.reset_array_value();
            report_csv.append_array_value("Ticket");
            report_csv.append_array_value("OpenTime");
            report_csv.append_array_value("CloseTime");
            report_csv.append_array_value("Symbol");
            report_csv.append_array_value("Action");
            report_csv.append_array_value("Size");
            report_csv.append_array_value("OpenPrice");
            report_csv.append_array_value("ClosePrice");
            report_csv.append_array_value("CommSwap");
            report_csv.append_array_value("PL");
            report_csv.append_array_value("Comment");
            report_csv.append_array_value("MagicNumber");
            report_csv.append_array_value("Win/Lose");
            report_csv.append_array_value("Reason");
            report_csv.append_array_value("PosBarNum");     
            report_csv.append_array_value("PosHighBarNum"); 
            report_csv.append_array_value("PosHigh"); 
            report_csv.append_array_value("PosLowBarNum"); 
            report_csv.append_array_value("PosLow");               
            report_csv.append_array_value("\r\n");       
         }
      }
      if(!MQLInfoInteger(MQL_TESTER)){
         report_csv = new CDataFile("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv",false);
         report_csv.reset_array_value();
         delete(report_csv);
      }
   }
}

bool CMyExpert::InitTrail(){
   
   if(trail_type==TRAIL_TYPE_ATR){
      CTrailingATR *m_trail_tmp = new CTrailingATR();
      m_trail_tmp.SetParam(trail_ATR_Period);
      m_trail = m_trail_tmp;
   } else if(trail_type==TRAIL_TYPE_FIXED_POINTS){
      CTrailingFixedPips *m_trail_tmp = new CTrailingFixedPips();
      m_trail_tmp.StopLevel(trail_loss_points);
      if(m_close_type==CLOSE_TYPE_LOGIC_AND_TP||m_close_type==CLOSE_TYPE_TP_ONLY){
         m_trail_tmp.ProfitLevel(trail_profit_points);
      } else {
         m_trail_tmp.ProfitLevel(0);
      }
      m_trail = m_trail_tmp;
   } else if(trail_type==TRAIL_TYPE_MA){
      CTrailingMA *m_trail_tmp = new CTrailingMA();
      m_trail_tmp.Period(trail_MA_Period);
      m_trail_tmp.Shift(trail_MA_Shift);
      m_trail_tmp.Method(trail_MA_Method);
      m_trail_tmp.Applied(trail_MA_AppliedPrice);
      m_trail = m_trail_tmp;
   } else if(trail_type==TRAIL_TYPE_NONE){
      m_trail = new CTrailingNone();
      
   } else if(trail_type==TRAIL_TYPE_PERCENT){
      m_trail = new CTrailingNone();
   } else if(trail_type==TRAIL_TYPE_SAR){
      CTrailingPSAR *m_trail_tmp = new CTrailingPSAR();
      m_trail_tmp.Maximum(trail_SAR_Maximum);
      m_trail_tmp.Step(trail_SAR_Step);
      m_trail = m_trail_tmp;
   } else if(trail_type==TRAIL_TYPE_ZIGZAG){
      CTrailingZigzag *m_trail_tmp = new CTrailingZigzag();
      m_trail_tmp.SetParam(trail_ZIGZAG_Depth,trail_ZIGZAG_Deviation,trail_ZIGZAG_Backstep,trail_addpoints);
      m_trail = m_trail_tmp;
   } else if(trail_type==TRAIL_TYPE_PREVBAR){
      CTrailingPrevBar *m_trail_tmp = new CTrailingPrevBar();
      m_trail_tmp.PrevBar(trail_prevbar);
      m_trail = m_trail_tmp;
   } else if(trail_type==TRAIL_TYPE_BREAKEVEN){
      m_trail = new CTrailingNone();
   }

   m_trail.EveryTick(EveryTick);
   m_trail.Magic(MagicNumber);
   if(!m_trail.Init(GetPointer(m_symbol),m_period,m_symbol.Point())){
      Print(__FUNCTION__ + ": trailing object initilazation failed.");
      return false;
   }
   return true;
}
  
//+------------------------------------------------------------------+
//| Process                                                          |
//+------------------------------------------------------------------+
  
void CMyExpert::OnTick()
  {

      // 取引口座チェック
      if(!m_account.TradeAllowed()) {
         m_logger.print(CRITICAL,"ブローカーにより、現在の取引口座での取引操作が無効状態になっています");
         return;
      }
      if(!m_account.TradeExpert()) {
         m_logger.print(CRITICAL,"ブローカーにより、現在の取引口座での自動売買が無効状態になっています。");
         return;
      }
      // クライアント状態チェック
      if(!m_terminal.IsTradeAllowed()) {
         m_logger.print(CRITICAL,"MT5設定により、自動売買が無効状態になっています");
         return;
      }      
      // クライアント状態チェック
      if(!m_terminal.IsConnected()) {
         m_logger.print(ERR,"取引サーバーへの接続が切断状態です");
         return;
      }            
      
      // サマータイム期間確認
      if(CheckSummerTime(SummerTimeStartMonth,SummerTimeStartDay,SummerTimeEndMonth,SummerTimeEndDay)) {
         m_summer_time = true;
      } else {
         m_summer_time = false;
      }
      
      // 基準時間調整
      if(AdjustSummerTime){
         m_time_current = AdjustedTimeCurrent(m_summer_time,AdjustedTimeOffset);
      } else {
         m_time_current = AdjustedTimeCurrent(false,AdjustedTimeOffset);
      }

      if(MQLInfoInteger(MQL_TESTER)) {
         if(TimeCurrent() < m_tester_start) return;
      }
      if(!(m_every_tick)){
         if(!(IsNewBar(_Symbol,m_period))) return;    // EAがセットされたチャートシンボルのティックを基準とする
         m_logger.print(DEBUG,"OnTick",IntegerToString(m_magic));
         m_logger.print(DEBUG,"Margin:",DoubleToString(m_account.Margin()));
      }
      Refresh();      
      if(m_open_type==OPEN_TYPE_LONG){
         Main(ORDER_TYPE_BUY);
      } else if(m_open_type==OPEN_TYPE_SHORT){
         Main(ORDER_TYPE_SELL);
      } else if(m_open_type==OPEN_TYPE_LONG_SHORT){
         Main(ORDER_TYPE_BUY);
         Main(ORDER_TYPE_SELL);
      }       
  }
  
  
void CMyExpert::Refresh(){
   m_symbol.RefreshRates();
   m_indicators.Refresh();
   m_atr.Refresh();
   m_sar.Refresh();
   m_zg.Refresh();
   m_ma.Refresh();
   m_bands.Refresh();
   m_bands_filter.Refresh();
   RefreshIndicator();  // ストラテジー（子クラス）用インジケーターの更新
}

void CMyExpert::Main(ENUM_ORDER_TYPE order_type){
      if(m_operation_type==OPERATION_TYPE_ALL){
         // 注文・決済を確認し執行する
         MainCheckOrder(order_type);
         //MainOpen(order_type);
         if(MainOpen(order_type)) OrderOpen(order_type);
         MainClose(order_type);  
      } else if(m_operation_type==OPERATION_TYPE_CLOSE){
         // 決済のみ確認しシグナル検知で執行する
         MainCheckOrder(order_type);
         MainClose(order_type); 
      } else if(m_operation_type==OPERATION_TYPE_OPEN){
         // 注文のみ確認しシグナル検知で執行する
         MainCheckOrder(order_type);
         if(MainOpen(order_type)) OrderOpen(order_type);
      } else if(m_operation_type==OPERATION_TYPE_CLOSE_NOW){
         // ポジションがあれば今すぐ決済する
         MainCheckOrder(order_type);
         if(position_count(m_magic,m_symbol_name,order_type)>0){
            close_position_all(m_magic,m_symbol_name,order_type);
         }
      }   
}

void CMyExpert::MainCheckOrder(ENUM_ORDER_TYPE order_type){
      if(order_count(m_magic,m_symbol_name,order_type)!=0){ 
         if(order_type==ORDER_TYPE_BUY){        
            if(m_order_reset_long) {
               delete_order_all(m_magic,m_symbol_name,order_type);
               m_order_reset_long = false;  
               Save(); 
               return;            
            }
            if(CheckOpen(order_type)) {
               //modify_order_all(m_magic,m_symbol_name,order_type)
            }
         } else if(order_type==ORDER_TYPE_SELL){
            if(m_order_reset_short) {
               m_trade.OrderDelete(m_trade.ResultOrder());
               delete_order_all(m_magic,m_symbol_name,order_type);
               m_order_reset_short = false;
               Save();
               return;
            }         
            if(CheckOpen(order_type)) {
            
            }            
         }
      }
}

bool CMyExpert::MainOpen(ENUM_ORDER_TYPE order_type){
      //if(position_count(m_magic,m_symbol_name,order_type)==0){
      // ポジション数と未決オーダー数がトレード許容数未満であることを確認しオーダーシグナル確認をする
      if(position_count(m_magic,m_symbol_name,order_type)<Trade_Allow_Pos_num&&order_count(m_magic,m_symbol_name,order_type)<Trade_Allow_Pos_num){
         // 両建て禁止の場合
         if(!Trade_Allow_Cross_Order){
            // 両建て禁止かつポジション数または未決オーダー数がトレード許容数以上である場合はトレード拒否
            if(position_count(m_magic,m_symbol_name)>=Trade_Allow_Pos_num||order_count(m_magic,m_symbol_name)>=Trade_Allow_Pos_num) return false;
         }
         if(!CheckDateTime()) return false;
         if(!CheckOpenSleepTime(order_type)) return false;
         if(!CheckOpenEconomicIndicators(order_type)) return false;
         if(!CheckOpenFilter(order_type)) return false;
         if(!CheckOpenHline(order_type)) return false;
         if(!CheckOpenTrend(order_type)) return false;
         if(!CheckOpen(order_type)) {
            m_logger.print(INFO,"オープンチェック結果＝シグナルなし","OPEN",__FUNCTION__);
            return false;
         } else {
            m_logger.print(INFO,"オープンチェック結果＝シグナル検知","OPEN",__FUNCTION__);
         }
         if(!CheckPending(order_type)) {
            m_logger.print(INFO,"未決注文が存在するためオープンスキップ","OPEN",__FUNCTION__);
            return false;         
         }
         if(!CheckSpread()) return false;
         //if(!CheckOpenCircuitBreaker) return;         
         //OrderOpen(order_type);
         return true;
      } else {
         m_logger.print(INFO,"保有ポジション数が上限を越えているためオープンスキップ","OPEN",__FUNCTION__);      
      }
     return false;   
}


bool CMyExpert::CheckSpread(void){

   if(m_max_spread_points>0 && m_max_spread_points<m_symbol.Spread()) {
      m_logger.print(INFO,"スプレッド制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);
      return false;
   }
   return true;
}

bool CMyExpert::CheckDateTime(void){
  
   MqlDateTime NowDT;
   TimeToStruct(m_time_current,NowDT);
   
   uint NowHour = NowDT.hour; //TimeHour(NowTime);
   
   //if(AdjustSummerTime&&CheckSummerTime(ServerTimeOffset,SummerTimeOffset)){
   //if(AdjustSummerTime&&CheckSummerTime(SummerTimeStartMonth,SummerTimeStartDay,SummerTimeEndMonth,SummerTimeEndDay)){
   //   // サマータイムの時1時間遅らせる
   //   if(NowHour==0){
   //      NowHour = 23;
   //   } else {
   //      NowHour--;
   //   }
   //}
   uint NowMinute = NowDT.min; //TimeMinute(NowTime);
   ENUM_DAY_OF_WEEK NowWeek = (ENUM_DAY_OF_WEEK)NowDT.day_of_week;

   uint NowDay = NowDT.day;

   // トレード許可日チェック（カンマ指定）   
   if(Trade_Allow_Days!=""){
      string days[];
      bool match_flg = false;
      int num = StringSplit(Trade_Allow_Days,StringGetCharacter(",",0),days);
      if(num>0){
         for(int i=0; i<ArraySize(days); i++){
            if(NowDay==StringToInteger(days[i])) match_flg = true;
         }
      }
      if(!match_flg) {
         m_logger.print(INFO,"トレード許可日ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;     
      }
   }


   // 開始日・終了日チェック（期間指定）
   uint end_entry_day = Start_Entry_Day;
   if(End_Entry_Day>=1){
      end_entry_day = End_Entry_Day;
   }
   if(Start_Entry_Day<=end_entry_day) { // 終了時間が0時を跨がない場合
      if(!(Start_Entry_Day <= NowDay && NowDay <= end_entry_day)) {
         m_logger.print(INFO,"トレード許可期間ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false; // 現在時間が開始時間～終了時間内ではない場合FALSE
      }
   }    
   
   
   // 開始時間・終了時間チェック（期間指定）
   uint end_entry_hour = Start_Entry_Hour;
   if(End_Entry_Hour>=0){
      end_entry_hour = End_Entry_Hour;
   }   

   if(Start_Entry_Hour<=end_entry_hour) { // 終了時間が0時を跨がない場合
      if(!(Start_Entry_Hour <= NowHour && NowHour <= end_entry_hour)) {
         m_logger.print(INFO,"トレード許可時間ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false; // 現在時間が開始時間～終了時間内ではない場合FALSE
      }
   } else if(Start_Entry_Hour>end_entry_hour) { // 終了時間が0時を跨ぐ場合
      if( !( (Start_Entry_Hour<=NowHour && NowHour<=23) ||
             (0<=NowHour && NowHour<=end_entry_hour)  // 現在時間が開始時間～0時または0時～終了時間内ではない場合FALSE
           )
        ) {
         m_logger.print(INFO,"トレード許可時間ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
       }
   }       
   // 開始時間・終了時間チェック（カンマ指定）   
   if(Trade_Allow_Hour!=""){
      string times[];
      bool match_flg = false;
      int num = StringSplit(Trade_Allow_Hour,StringGetCharacter(",",0),times);
      if(num>0){
         for(int i=0; i<ArraySize(times); i++){
            if(NowHour==StringToInteger(times[i])) match_flg = true;
         }
      }
      if(!match_flg) {
         m_logger.print(INFO,"トレード許可時間ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;     
      }
   }


   // 開始分・終了分時間チェック（期間指定）
   uint end_entry_minute = Start_Entry_Minute;
   if(End_Entry_Minute>=0){
      end_entry_minute = End_Entry_Minute;
   } 
   
   if(Start_Entry_Minute<=end_entry_minute) {
      if(!(Start_Entry_Minute <= NowMinute && NowMinute <= end_entry_minute)) {
         m_logger.print(INFO,"トレード許可時間ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      }
   } else if(Start_Entry_Minute>end_entry_minute) {
      if( !( (Start_Entry_Minute<=NowMinute && NowMinute<=59) ||
             (0<=NowMinute && NowMinute<=end_entry_minute)
           )
        ) {
         m_logger.print(INFO,"トレード許可時間ではないためオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
       }
   }

   if(!Trade_Allow_End_Month&&CheckEndOfMonth(m_time_current)) {
      m_logger.print(INFO,"月末トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);
      return false;
   }
   if(!Trade_Allow_Start_Month&&CheckStartOfMonth(m_time_current)) {
      m_logger.print(INFO,"月初トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);
      return false;
   }
   if(!Trade_Allow_MONDAY&&NowWeek==MONDAY) {
      m_logger.print(INFO,"月曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);
      return false;
   }
   if(!Trade_Allow_TUESDAY&&NowWeek==TUESDAY) {
      m_logger.print(INFO,"火曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);   
      return false;
   }
   if(!Trade_Allow_WEDNESDAY&&NowWeek==WEDNESDAY) {
      m_logger.print(INFO,"水曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__); 
      return false;
   }
   if(!Trade_Allow_THURSDAY&&NowWeek==THURSDAY) {
      m_logger.print(INFO,"木曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);   
      return false;
   }
   if(!Trade_Allow_FRIDAY&&NowWeek==FRIDAY) {
      m_logger.print(INFO,"金曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);   
      return false;
   }
   if(!Trade_Allow_SATURDAY&&NowWeek==SATURDAY) {
      m_logger.print(INFO,"土曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);   
      return false;
   }
   if(!Trade_Allow_SUNDAY&&NowWeek==SUNDAY) {
      m_logger.print(INFO,"日曜日トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }
   
   
   uint NowMon = NowDT.mon;
   if(!Trade_Allow_Jan&&NowMon==1) {
      m_logger.print(INFO,"1月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }   
   if(!Trade_Allow_Feb&&NowMon==2) {
      m_logger.print(INFO,"2月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }      
   if(!Trade_Allow_Mar&&NowMon==3) {
      m_logger.print(INFO,"3月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }        
   if(!Trade_Allow_Apr&&NowMon==4) {
      m_logger.print(INFO,"4月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }      
   if(!Trade_Allow_May&&NowMon==5) {
      m_logger.print(INFO,"5月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }             
   if(!Trade_Allow_Jun&&NowMon==6) {
      m_logger.print(INFO,"6月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }      
   if(!Trade_Allow_Jul&&NowMon==7) {
      m_logger.print(INFO,"7月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }         
   if(!Trade_Allow_Aug&&NowMon==8) {
      m_logger.print(INFO,"8月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }      
   if(!Trade_Allow_Sep&&NowMon==9) {
      m_logger.print(INFO,"9月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }       
   if(!Trade_Allow_Oct&&NowMon==10) {
      m_logger.print(INFO,"10月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }            
   if(!Trade_Allow_Nov&&NowMon==11) {
      m_logger.print(INFO,"11月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }         
   if(!Trade_Allow_Dec&&NowMon==12) {
      m_logger.print(INFO,"12月トレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);    
      return false;
   }         
   
   if(i_Trade_Allow_Open_WeekStart){   
      if(NowWeek<=(int)Weekstart){
         if(NowWeek==(int)Weekstart) {
            if((uint)NowDT.hour<=i_Trade_Allow_Open_hour){
               m_logger.print(INFO,"週明け指定時間によるトレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);  
               return false;
            }
         } else {
            m_logger.print(INFO,"週明け指定時間によるトレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);  
            return false;
         }
      }
   }


   MqlDateTime dt_calc;
   TimeToStruct(m_time_current,dt_calc);
   uint swap_time,weekend_time,trade_stop_time,swap_time_min,weekend_time_min;
   if(m_summer_time){
      if(AdjustSummerTime){
         swap_time = SwapTime;
         swap_time_min = SwapTimeMin;
         weekend_time = WeekendTime;
         weekend_time_min = WeekendTimeMin;
      } else {
         swap_time = SwapTimeSummer;
         swap_time_min = SwapTimeMinSummer;
         weekend_time = WeekendTimeSummer;
         weekend_time_min = WeekendTimeMinSummer;
      }
   } else {
      swap_time = SwapTime;
      swap_time_min = SwapTimeMin;
      weekend_time = WeekendTime;
      weekend_time_min = WeekendTimeMin;
   }
   if(NowWeek==(int)Weekend){
      dt_calc.hour = (int)weekend_time;
      dt_calc.min = (int)weekend_time_min;
      if(weekend_time==0) {
         trade_stop_time = 24;
      } else {
         trade_stop_time = weekend_time;
      }
   } else {
      dt_calc.hour = (int)swap_time;
      dt_calc.min = (int)swap_time_min;
      if(swap_time==0) {
         trade_stop_time = 24;
      } else {
         trade_stop_time = swap_time;
      }
   }
   //dt_calc.min = 0;
   datetime datetime_calc = StructToTime(dt_calc);
   datetime_calc = datetime_calc - (PeriodSeconds(_Period) * exit_shift_bar);
   TimeToStruct(datetime_calc,dt_calc);
   uint exit_hour = dt_calc.hour;
   uint exit_min = dt_calc.min;
   
      
   // 当日決済の場合はオープンしない
   if(exit_day){
      if(NowHour>=exit_hour&&NowHour<=trade_stop_time) {
         if(NowHour==exit_hour&&NowMinute>=exit_min){
            m_logger.print(INFO,"当日決済によるトレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);  
            return false;
         }
      }
   } 
          
   // 週末決済の場合はオープンしない
   if(exit_weekend){
      if(NowWeek==(int)Weekend) {
         if(NowHour>=exit_hour&&NowHour<=trade_stop_time) {
            if(NowHour==exit_hour&&NowMinute>=exit_min){         
               m_logger.print(INFO,"週末決済によるトレード制限によりオープンチェックをスキップしました","OPEN",__FUNCTION__);  
               return false;
            }
         }
      }
   }   

   return true;
}

bool CMyExpert::CheckOpenCircuitBreaker(void){
   // trueならオープン確認に進む、falseならオープン確認しない
   if(!MQLInfoInteger(MQL_TESTER)) return true;
   // bars
   double   m_high;
   double   m_low;
   double   m_open;
   double   m_close;   

   m_close = iClose(_Symbol,PERIOD_CURRENT,0);
   m_open = iOpen(_Symbol,PERIOD_CURRENT,0);
   m_high = iHigh(_Symbol,PERIOD_CURRENT,0);
   m_low = iLow(_Symbol,PERIOD_CURRENT,0);     
   
   if(m_close==m_open&&m_close==m_high&&m_close==m_low) {
      m_logger.print(INFO,"サーキットブレーカーのためスキップしました（バックテストのみ）","OPEN",__FUNCTION__); 
      return false;
   }
   return true;
}

void CMyExpert::OrderOpen(ENUM_ORDER_TYPE order_type){

      // ORDER_TIME_SPECIFIED（注文期限日時指定）の場合、期限日時を算出する
      if(i_OrderTypeTime==ORDER_TIME_SPECIFIED||i_OrderTypeTime==ORDER_TIME_SPECIFIED_DAY){
         m_order_time_spec_long = TimeCurrent() + (PeriodSeconds(_Period) * i_OrderTypeTimeSpec);
         m_order_time_spec_short = TimeCurrent() + (PeriodSeconds(_Period) * i_OrderTypeTimeSpec);
      }
      
      string request="";
      // 指値・逆指値注文の価格を算出
      if(i_OrderMethod==ORDER_METHOD_MARKET){
         request = "Market";
      
      } else if(i_OrderMethod==ORDER_METHOD_LIMIT){
         request = "Limit";
         if(order_type==ORDER_TYPE_BUY){
            m_order_price_long = m_symbol.Ask() - point2price(i_OrderLimitStopPrice,_Point);
            if(m_symbol.Ask()-point2price(m_symbol.StopsLevel(),m_symbol.Point())<m_order_price_long){
               m_logger.print(ERR,"long指値価格がストップレベルにかかっています");
            }            
         } else if(order_type==ORDER_TYPE_SELL){
            m_order_price_short = m_symbol.Bid() + point2price(i_OrderLimitStopPrice,_Point);
            if(m_symbol.Bid()+point2price(m_symbol.StopsLevel(),m_symbol.Point())>m_order_price_short){
               m_logger.print(ERR,"short指値価格がストップレベルにかかっています");
            }             
         }
      } else if(i_OrderMethod==ORDER_METHOD_STOP){
         request = "Stop";
         if(order_type==ORDER_TYPE_BUY){
            m_order_price_long = m_symbol.Ask() + point2price(i_OrderLimitStopPrice,_Point);
            if(m_symbol.Ask()+point2price(m_symbol.StopsLevel(),m_symbol.Point())>m_order_price_long){
               m_logger.print(ERR,"long逆指値価格がストップレベルにかかっています");
            }                        
         } else if(order_type==ORDER_TYPE_SELL){
            m_order_price_short = m_symbol.Bid() - point2price(i_OrderLimitStopPrice,_Point);
            if(m_symbol.Bid()-point2price(m_symbol.StopsLevel(),m_symbol.Point())<m_order_price_short){
               m_logger.print(ERR,"short逆指値価格がストップレベルにかかっています");
            }                 
         }      
      } else if(i_OrderMethod==ORDER_METHOD_STOPLIMIT){
         request = "Stop-Limit";
         if(order_type==ORDER_TYPE_BUY){
            m_order_stoplimit_price_long  = m_symbol.Ask() + point2price(i_OrderStopLimitPrice,_Point);
            m_order_price_long = m_order_stoplimit_price_long - point2price(i_OrderLimitStopPrice,_Point);           
         } else if(order_type==ORDER_TYPE_SELL){
            m_order_stoplimit_price_short = m_symbol.Bid() - point2price(i_OrderStopLimitPrice,_Point);
            m_order_price_short = m_order_stoplimit_price_short + point2price(i_OrderLimitStopPrice,_Point);
         } 
      }

      //string request="";
      //// Check Request Type
      //if(order_type==ORDER_TYPE_BUY){
      //   if(m_order_price_long==0){
      //      request = "Market";
      //   } else if(m_symbol.Ask()>m_order_price_long) {
      //      if(m_symbol.Ask()+point2price(m_symbol.StopsLevel(),m_symbol.Point())>m_order_price_long){
      //         request = "Limit";
      //      } else {
      //         m_logger.print(ERR,"指値価格がストップレベルにかかっています");
      //      }
      //   } else if((m_symbol.Ask()+point2price(m_symbol.StopsLevel(),m_symbol.Point()))<m_order_price_long) {
      //      request = "Stop";
      //   } else {
      //      request = "Market";
      //   }
      //   m_order_price = m_order_price_long;
      //} else if(order_type==ORDER_TYPE_SELL){
      //   if(m_order_price_short==0){
      //      request = "Market";
      //   } else if((m_symbol.Bid()+point2price(m_symbol.StopsLevel(),m_symbol.Point()))<m_order_price_short) {
      //      request = "Limit";
      //   } else if((m_symbol.Bid()+point2price(m_symbol.StopsLevel(),m_symbol.Point()))>m_order_price_short) {
      //      request = "Stop";
      //   } else {
      //      request = "Market";
      //   }
      //   m_order_price = m_order_price_short;     
      //}     

      // 各種パラメータを計算
      double loss = 0;
      double free_margin = -1;
      double margin = m_account.Balance();
      if(order_type==ORDER_TYPE_BUY){
         m_order_price = m_order_price_long;
         m_order_sl_long = CalculateSL(order_type);
         m_order_sl = m_order_sl_long;
         if(m_order_sl_long==EMPTY_VALUE) {
            m_logger.print(WARN,"SL値が無効なためオープンスキップしました","OPEN",__FUNCTION__);  
            return;    // SL値が無効ならスキップ
         }
         m_order_tp_long = CalculateTP(order_type);
         m_order_tp = m_order_tp_long;
         if(m_order_tp_long==EMPTY_VALUE) {
            m_logger.print(WARN,"TP値が無効なためオープンスキップしました","OPEN",__FUNCTION__);  
            return;     // TP値が無効ならスキップ
         }
         m_order_lot_long = CalculateLOT(order_type);
         m_order_lot = m_order_lot_long;
         m_pyramiding_counts_long = 0;                // ピラミッディング用カウンターを初期化
         //m_position_bar_count_long = 0;               // 強制決済バーカウンターを初期化
         ArrayInitialize(m_position_manage_long,DBL_MIN);
         ArrayFree(m_position_manage_long);
         m_sl_trail_count_long = 0;                   // トレイルカウンターを初期化
         m_split_count_long = 0;                      // 分割決済カウンターを初期化
         loss = m_account.OrderProfitCheck(m_symbol_name,order_type,m_order_lot_long,m_order_sl_long,m_symbol.Ask()); // エントリー価格（ASK）からSLまでの損失額
         if(request=="Market"){
            margin = m_account.MarginCheck(m_symbol_name,order_type,m_order_lot_long,m_symbol.Ask());
            free_margin = m_account.FreeMarginCheck(m_symbol_name,order_type,m_order_lot_long,m_symbol.Ask());         
         } else {
            margin = m_account.MarginCheck(m_symbol_name,order_type,m_order_lot_long,m_order_price_long);
            free_margin = m_account.FreeMarginCheck(m_symbol_name,order_type,m_order_lot_long,m_order_price_long);
         }
      } else if(order_type==ORDER_TYPE_SELL){
         m_order_price = m_order_price_short; 
         m_order_sl_short = CalculateSL(order_type);
         m_order_sl = m_order_sl_short;
         if(m_order_sl_short==EMPTY_VALUE) {
            m_logger.print(WARN,"SL値が無効なためオープンスキップしました","OPEN",__FUNCTION__); 
            return;    // SL値が無効ならスキップ
         }
         m_order_tp_short = CalculateTP(order_type);
         m_order_tp = m_order_tp_short;
         if(m_order_tp_short==EMPTY_VALUE) {
            m_logger.print(WARN,"TP値が無効なためオープンスキップしました","OPEN",__FUNCTION__);  
            return;     // TP値が無効ならスキップ
         }
         m_order_lot_short = CalculateLOT(order_type);
         m_order_lot = m_order_lot_short;
         m_pyramiding_counts_short = 0;                // ピラミッディング用カウンターを初期化  
         //m_position_bar_count_short = 0;               // 強制決済バーカウンターを初期化
         ArrayInitialize(m_position_manage_short,DBL_MIN);
         ArrayFree(m_position_manage_short);    
         m_sl_trail_count_short = 0;                   // トレイルカウンターを初期化
         m_split_count_short = 0;                      // 分割決済カウンターを初期化
         loss = m_account.OrderProfitCheck(m_symbol_name,order_type,m_order_lot_short,m_order_sl_short,m_symbol.Bid()); // エントリー価格（BID）からSLまでの損失額
         if(request=="Market"){
            margin = m_account.MarginCheck(m_symbol_name,order_type,m_order_lot_short,m_symbol.Bid());
            free_margin = m_account.FreeMarginCheck(m_symbol_name,order_type,m_order_lot_short,m_symbol.Bid());         
         } else {
            margin = m_account.MarginCheck(m_symbol_name,order_type,m_order_lot_short,m_order_price_short);
            free_margin = m_account.FreeMarginCheck(m_symbol_name,order_type,m_order_lot_short,m_order_price_short);
         }         
      } 
      m_order_ask = m_symbol.Ask();
      m_order_bid = m_symbol.Bid();
      
      // 証拠金チェック
      double margin_level = (m_account.Balance() / margin) * 100;      
      if(margin_level<100) {
         m_logger.print(ERR,"証拠金維持率が100%を下回ったため注文キャンセルしました:" + DoubleToString(margin_level),"OPEN",__FUNCTION__);
         return;
      }
      if(free_margin<0.0) {
         m_logger.print(ERR,"注文後の余剰証拠金が0を下回るため注文キャンセルしました:" + DoubleToString(free_margin),"OPEN",__FUNCTION__);
         return;
      }
      // 複数ポジションの損失考慮した証拠金チェック
      double ttl_equity = positions_ttl_equity(m_magic,m_symbol_name);
      double loss_profit = 0;
      m_logger.print(INFO,"TTL有効証拠金:" + DoubleToString(ttl_equity),"OPEN",__FUNCTION__);
   
         // 今回想定の損失額を算出し有効証拠金に反映する
      if(m_order_price==0){
         if(order_type==ORDER_TYPE_BUY){
            if(!OrderCalcProfit(order_type,m_symbol_name,m_order_lot,m_order_ask,m_order_sl,loss_profit)) loss_profit = EMPTY_VALUE;
         } else if(order_type==ORDER_TYPE_SELL) {
            if(!OrderCalcProfit(order_type,m_symbol_name,m_order_lot,m_order_bid,m_order_sl,loss_profit)) loss_profit = EMPTY_VALUE;
         }
      } else {
         if(!OrderCalcProfit(order_type,m_symbol_name,m_order_lot,m_order_price,m_order_sl,loss_profit)) loss_profit = EMPTY_VALUE;
      }      
      if(loss_profit==EMPTY_VALUE){
         m_logger.print(ERR,"証拠金計算に失敗しました:" + ErrorDescription(GetLastError()),"OPEN",__FUNCTION__);
         return;
      }
      ttl_equity+=loss_profit;
      
      
      m_logger.print(INFO,"TTL有効証拠金予定込み:" + DoubleToString(ttl_equity),"OPEN",__FUNCTION__);
      m_logger.print(INFO,"必要証拠金:" + DoubleToString(margin),"OPEN",__FUNCTION__);
      margin_level = (ttl_equity / (margin + m_account.Margin())) * 100;      
      m_logger.print(INFO,"証拠金Level:" + DoubleToString(margin_level),"OPEN",__FUNCTION__);
      m_logger.print(INFO,"ストップアウトLevel:" + DoubleToString(m_account.MarginStopOut()),"OPEN",__FUNCTION__);
      if(margin_level<100) {
         m_logger.print(ERR,"保有ポジショントータルでロスカットの可能性があるため注文をキャンセルしました:" + DoubleToString(margin_level),"OPEN",__FUNCTION__);
         return;
      }      
      
      double m_risk = NormalizeDouble((loss / m_account.Balance()) * 100,2);
      if(risk_check){
         if(m_risk>(m_money.Percent()*1.1)) {
            m_logger.print(WARN,"想定損失額が許容値（" + DoubleToString(m_money.Percent()) + "％）を上回ったため注文キャンセルしました:" + DoubleToString(m_risk),"OPEN",__FUNCTION__);
            return;   // 許容リスク(＋10%)を上回る場合はオーダーしない
         }
      } else {
         m_logger.print(INFO,"想定損失額：" +  DoubleToString(m_risk) + "％",__FUNCTION__);
      }   
      
      
      /* ロット数と許容リスクに合わせてSL値を計算。結果はいまいちだった
      if(m_risk>(m_money.Percent())){ //return;
         double allowed_loss = m_account.Balance() * (m_money.Percent()/100);
         double new_sl_width=0;
         if(order_type==ORDER_TYPE_BUY){
            new_sl_width = (allowed_loss / m_order_lot_long) * m_symbol.ContractSize();
            m_order_sl_long = m_symbol.Ask() - new_sl_width;
            loss = m_account.OrderProfitCheck(m_symbol_name,order_type,m_order_lot_long,m_order_sl_long,m_symbol.Ask());
         } else if(order_type==ORDER_TYPE_SELL){
            new_sl_width = (allowed_loss / m_order_lot_short) * m_symbol.ContractSize();
            m_order_sl_short = m_symbol.Bid() + new_sl_width;
            loss = m_account.OrderProfitCheck(m_symbol_name,order_type,m_order_lot_short,m_order_sl_short,m_symbol.Bid());
         }
         m_risk = NormalizeDouble((loss / m_account.Balance()) * 100,2);
         if(new_sl_width<m_atr.Main(1)*(sl_coefficient*0.8)) return;
      }
      */
      
      string period_short_name = StringSubstr(period_name(),7,StringLen(period_name()));
      if(order_type==ORDER_TYPE_BUY){
         if(request=="Market"){
            m_trade.Buy(m_order_lot_long,m_symbol.Name(),m_symbol.Ask(),m_order_sl_long,m_order_tp_long,m_project_name+"_Mkt_" + period_short_name + "_r=" + (string)m_risk);
         } else if(request=="Limit") {
            m_trade.BuyLimit(m_order_lot_long,m_order_price_long,m_symbol.Name(),m_order_sl_long,m_order_tp_long,m_order_time_long,m_order_time_spec_long,m_project_name+"_Lmt_" + period_short_name + "_r=" + (string)m_risk);
         } else if(request=="Stop") {
            m_trade.BuyStop(m_order_lot_long,m_order_price_long,m_symbol.Name(),m_order_sl_long,m_order_tp_long,m_order_time_long,m_order_time_spec_long,m_project_name+"_Stp_" + period_short_name + "_r=" + (string)m_risk);
         } else if(request=="Stop-Limit"){
            //m_trade.OrderOpen(m_symbol_name,ORDER_TYPE_BUY_STOP_LIMIT,m_order_lot_long,m_order_stoplimit_price_long,m_order_price_long,m_order_sl_long,m_order_tp_long,m_order_time_long,m_order_time_spec_long,m_project_name+"_StpLmt_" + period_short_name + "_r=" + (string)m_risk);
            m_trade.OrderOpen(m_symbol_name,ORDER_TYPE_BUY_STOP_LIMIT,m_order_lot_long,m_order_price_long,m_order_stoplimit_price_long,m_order_sl_long,m_order_tp_long,m_order_time_long,m_order_time_spec_long,m_project_name+"_StpLmt_" + period_short_name + "_r=" + (string)m_risk);
         }
      } else if(order_type==ORDER_TYPE_SELL){
         if(request=="Market"){
            m_trade.Sell(m_order_lot_short,m_symbol.Name(),m_symbol.Bid(),m_order_sl_short,m_order_tp_short,m_project_name+"_Mkt_" + period_short_name + "_r=" + (string)m_risk);
         } else if(request=="Limit") {
            m_trade.SellLimit(m_order_lot_short,m_order_price_short,m_symbol.Name(),m_order_sl_short,m_order_tp_short,m_order_time_short,m_order_time_spec_short,m_project_name+"_Lmt_" + period_short_name + "_r=" + (string)m_risk);
         } else if(request=="Stop") {
            m_trade.SellStop(m_order_lot_short,m_order_price_short,m_symbol.Name(),m_order_sl_short,m_order_tp_short,m_order_time_short,m_order_time_spec_short,m_project_name+"_Stp_" + period_short_name + "_r=" + (string)m_risk);
         } else if(request=="Stop-Limit") {
            //m_trade.OrderOpen(m_symbol_name,ORDER_TYPE_SELL_STOP_LIMIT,m_order_lot_short,m_order_stoplimit_price_short,m_order_price_short,m_order_sl_short,m_order_tp_short,m_order_time_short,m_order_time_spec_short,m_project_name+"_StpLmt_" + period_short_name + "_r=" + (string)m_risk);
            m_trade.OrderOpen(m_symbol_name,ORDER_TYPE_SELL_STOP_LIMIT,m_order_lot_short,m_order_price_short,m_order_stoplimit_price_short,m_order_sl_short,m_order_tp_short,m_order_time_short,m_order_time_spec_short,m_project_name+"_StpLmt_" + period_short_name + "_r=" + (string)m_risk);            
         }
      } 
      if(m_trade.ResultRetcode()!=10009) {
         m_logger.print(CRITICAL,"注文が失敗しました 理由:" + m_trade.ResultRetcodeDescription(),"OPEN",__FUNCTION__);
      }
      
      ExecNotify("エントリー実行");
}

bool CMyExpert::CheckOpenSleepTime(ENUM_ORDER_TYPE order_type){
      ulong close_ticket_last;
      if(!deal_ticket_close_last(m_magic,m_symbol_name,order_type,close_ticket_last)) return true; // 取引がない場合はエントリー許可
      m_deal.Ticket(close_ticket_last);
      uint sleep_bar_shift = iBarShift(m_symbol_name,m_period,m_deal.Time());

      if(m_sleep_bar_count>0 && m_sleep_bar_count>=sleep_bar_shift) {
         m_logger.print(INFO,"決済後スリープ期間中のためオープンチェックをスキップしました 経過バー数：" + IntegerToString(sleep_bar_shift),"OPEN",__FUNCTION__);
         return false; // Sleep期間内（エントリー拒否）
      }
      
      // エントリー後からエントリー抑止する期間
      ulong open_ticket_last;
      if(deal_ticket_open_last(m_magic,m_symbol_name,order_type,open_ticket_last)) return true; // 取引がない場合はエントリー許可
      m_deal.Ticket(open_ticket_last);
      sleep_bar_shift = iBarShift(m_symbol_name,m_period,m_deal.Time());
      if(sleep_bar_cnt_after_entry>0 && sleep_bar_cnt_after_entry>=sleep_bar_shift) {
         m_logger.print(INFO,"エントリー後スリープ期間中のためオープンチェックをスキップしました 経過バー数：" + IntegerToString(sleep_bar_shift),"OPEN",__FUNCTION__);
         return false; // Sleep期間内（エントリー拒否）
      } 
      
      return true; // Sleep期間外（エントリー許可）
}

bool CMyExpert::CheckOpenEconomicIndicators(ENUM_ORDER_TYPE order_type){
      bool eco_holiday,eco_low,eco_mid,eco_high,eco_cri;
      bool gotobi=false;
      if(FilterHoliday!=FILTER_TYPE_OFF) eco_holiday = m_calendar.CheckEventHoliday(m_time_current);
      if(FilterLow!=FILTER_TYPE_OFF) eco_low = m_calendar.CheckEventLowImportance(m_time_current);
      if(FilterMid!=FILTER_TYPE_OFF) eco_mid = m_calendar.CheckEventMidImportance(m_time_current);
      if(FilterHigh!=FILTER_TYPE_OFF) eco_high = m_calendar.CheckEventHighImportance(m_time_current);
      if(FilterCri!=FILTER_TYPE_OFF) eco_cri = m_calendar.CheckEventCritical(m_time_current);
      MqlDateTime dt;
      TimeToStruct(m_time_current,dt);
      if(dt.day==5||dt.day==10||dt.day==15||dt.day==20||dt.day==25||dt.day==30) gotobi = true;

      // ゴトー日ロジック
      if(FilterGotobi==FILTER_TYPE_ALLOW_ONLY){
         if(gotobi) {
            return true;
         } else {
            m_logger.print(INFO,"ゴトー日指定取引のためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }
      if(FilterGotobi==FILTER_TYPE_BLOCK){
         if(gotobi) {
            m_logger.print(INFO,"ゴトー日フィルタのためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }

      // 祝日ロジック
      if(FilterHoliday==FILTER_TYPE_ALLOW_ONLY){
         if(eco_holiday) {
            return true;
         } else {
            m_logger.print(INFO,"祝日指定取引のためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;            
         }
      }
      if(FilterHoliday==FILTER_TYPE_BLOCK){
         
         if(eco_holiday) {
            m_logger.print(INFO,"祝日フィルタのためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }

      // 重要度低ロジック
      if(FilterLow==FILTER_TYPE_ALLOW_ONLY){
         if(eco_low) {
            return true;
         } else {
            m_logger.print(INFO,"イベント低指定取引のためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }
      if(FilterLow==FILTER_TYPE_BLOCK){
         if(eco_low) {
            m_logger.print(INFO,"イベント低フィルタのためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }

      // 重要度中ロジック
      if(FilterMid==FILTER_TYPE_ALLOW_ONLY){
         if(eco_mid) {
            return true;
         } else {
            m_logger.print(INFO,"イベント中指定取引のためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }
      if(FilterMid==FILTER_TYPE_BLOCK){
         if(eco_mid) {
            m_logger.print(INFO,"イベント中フィルタのためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }

      // 重要度大ロジック
      if(FilterHigh==FILTER_TYPE_ALLOW_ONLY){
         if(eco_high) {
            return true;
         } else {
            m_logger.print(INFO,"イベント大指定取引のためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }
      if(FilterHigh==FILTER_TYPE_BLOCK){
         if(eco_high) {
            m_logger.print(INFO,"イベント大フィルタのためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }      
      
      // 重要度大ロジック
      if(FilterCri==FILTER_TYPE_ALLOW_ONLY){
         if(eco_cri) {
            return true;
         } else {
            m_logger.print(INFO,"致命イベント指定取引のためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }      
      if(FilterCri==FILTER_TYPE_BLOCK){
         if(eco_cri) {
            m_logger.print(INFO,"致命イベントフィルタのためオープンチェックをスキップしました","OPEN",__FUNCTION__);
            return false;
         }
      }
         
      return true;
}

bool CMyExpert::CheckOpenFilter(ENUM_ORDER_TYPE order_type) {
   if(!bb_filter) return true;
   double c = iClose(m_symbol_name,m_period,1);
   if(order_type==ORDER_TYPE_BUY){
      if(c>m_bands_filter.Upper(1)) {
         m_logger.print(INFO,"トレンドフィルタによりオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      }
      if(c>m_bands_filter.Upper(0)) {
         m_logger.print(INFO,"トレンドフィルタによりオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      } 
   } else if(order_type==ORDER_TYPE_SELL){
      if(c<m_bands_filter.Lower(1)) {
         m_logger.print(INFO,"トレンドフィルタによりオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      }
      if(c<m_bands_filter.Lower(0)) {
         m_logger.print(INFO,"トレンドフィルタによりオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      }      
   }
   
   return true;
}

bool CMyExpert::CheckOpenHline(ENUM_ORDER_TYPE order_type) {
   if(!HL_line_Filter) return true;

   if(order_type==ORDER_TYPE_BUY){
      if(Lower_line_price1>0&&m_symbol.Ask()<Lower_line_price1) {
         m_logger.print(INFO,"水平線フィルタによりオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      }
      //if(Upper_line_price1>0&&m_symbol.Ask()>Upper_line_price1) return false;
   } else if(order_type==ORDER_TYPE_SELL){
      //if(Lower_line_price1>0&&m_symbol.Bid()<Lower_line_price1) return false;
      if(Upper_line_price1>0&&m_symbol.Bid()>Upper_line_price1) {
         m_logger.print(INFO,"水平線フィルタによりオープンチェックをスキップしました","OPEN",__FUNCTION__);
         return false;
      }
   }
   return true;
}

// 前回エントリー価格からトレンド方向出ない場合はフィルタする
bool CMyExpert::CheckOpenTrend(ENUM_ORDER_TYPE order_type) {
   if(!Trend_Filter) return true;
   
   // 最後にオープンした決済チケットを取得
//   HistorySelect(0,TimeCurrent());
   ulong open_ticket_last;
   if(!deal_ticket_open_last(m_magic,m_symbol_name,order_type,open_ticket_last)) return true; // 取引がない場合はエントリー許可
   m_deal.Ticket(open_ticket_last);
   
   Print("test");
   Print(m_deal.Price());

//   // 最後の決済から経過バー数を取得
//   uint trend_reset_bar_shift = iBarShift(m_symbol_name,m_period,m_deal.Time());
//   double trend_check_base_price=0;
//      if(Trend_Filter_Reset>0 && Trend_Filter_Reset<trend_reset_bar_shift) {
//         trend_check_base_price = m_symbol.Ask()         
//      } else {
//      
//      }
   
   if(order_type==ORDER_TYPE_BUY){
      if(m_symbol.Ask()<m_deal.Price()) return false;
   } else {
      if(m_symbol.Bid()>m_deal.Price()) return false;
   }

   return true;
}


double CMyExpert::CalculateSL(ENUM_ORDER_TYPE order_type){

   // SL幅算出
   double sl_width=EMPTY_VALUE;
   if(SlType==SL_TYPE_ZIGZAG){
      if(order_type==ORDER_TYPE_BUY){
         sl_width = Bid(m_symbol_name) - zig_point_low(1);
         Print(zig_point_low(1));
      } else if(order_type==ORDER_TYPE_SELL){
         sl_width = zig_point_high(1) - Ask(m_symbol_name);
      }
   } else if(SlType==SL_TYPE_SAR) {
      if(order_type==ORDER_TYPE_BUY){
         sl_width = Bid(m_symbol_name) - m_sar.Main(1);
      } else if(order_type==ORDER_TYPE_SELL){
         sl_width = m_sar.Main(1) - Ask(m_symbol_name);
      }   
   } else if(SlType==SL_TYPE_ATR) {
      sl_width = m_atr.Main(1);
   } else if(SlType==SL_TYPE_FIXED_POINTS){
      sl_width = point2price(loss_points,m_symbol.Point());
   } else if(SlType==SL_TYPE_NONE){
      sl_width = 0;
   } else if(SlType==SL_TYPE_MA){
      if(order_type==ORDER_TYPE_BUY){
         sl_width = Bid(m_symbol_name) - m_ma.Main(1);
      } else if(order_type==ORDER_TYPE_SELL){
         sl_width = m_ma.Main(1) - Ask(m_symbol_name);
      }
   } else if(SlType==SL_TYPE_BB){
      if(order_type==ORDER_TYPE_BUY){
         sl_width = Bid(m_symbol_name) - m_bands.Lower(1);
      } else if(order_type==ORDER_TYPE_SELL){
         sl_width = m_bands.Upper(1) - Ask(m_symbol_name);
      }      
   } else if(SlType==SL_TYPE_MINIMUM){
         //sl_width = (m_symbol.StopsLevel()*m_symbol.Point()) + (point2price(1,m_symbol.Point()));
         sl_width = m_symbol.StopsLevel()*m_symbol.Point();
   } else if(SlType==SL_TYPE_STRATEGY){
      if(order_type==ORDER_TYPE_BUY){
         sl_width = Bid(m_symbol_name) - m_strategy_sl;
      } else if(order_type==ORDER_TYPE_SELL){
         sl_width = m_strategy_sl - Ask(m_symbol_name);
      }   
   }

   //sl_width = MathAbs(sl_width);
   // MAなどインジケーターが現在値と逆転している場合はSLが0になる場合がある
   // その場合フォロー時はオープンをスキップとするが逆張り時には絶対値で計算しオープン続行する
   if(Trade_Reverse) sl_width = MathAbs(sl_width);
   if(sl_width<0) {
      m_logger.print(WARN,"計算されたSL値が0を下回りました","OPEN",__FUNCTION__);
      return EMPTY_VALUE;
   }

   // ストップレベル確認
   // 計算されたSLがストップレベルにかかっているかどうかをチェックする
   double sl_value=0;   
   double stop_level=0;
   double order_price = 0;
   double stop_level_base_price = 0;
   
   // 成行・買いの場合はASKを基準にSLを計算する・ストップレベルはBIDが基準となる
   // 成行・売りの場合はBIDを基準にSLを計算する・ストップレベルはASKが基準となる
   // 指値・逆指値の場合は指値を基準にSLを計算する・ストップレベルは指値からスプレッド分調整した価格が基準となる
   if(order_type==ORDER_TYPE_BUY){
      if(m_order_price_long==0){
         order_price = Ask(m_symbol_name);
         stop_level_base_price = Bid(m_symbol_name);
      } else {
         order_price = m_order_price_long;
         stop_level_base_price = m_order_price_long - point2price(m_symbol.Spread(),_Point);
      }
   } else if(order_type==ORDER_TYPE_SELL){
      if(m_order_price_short==0){
         order_price = Bid(m_symbol_name);
         stop_level_base_price = Ask(m_symbol_name);
      } else {
         order_price = m_order_price_short;
         stop_level_base_price = m_order_price_short + point2price(m_symbol.Spread(),_Point);
      }
   }
   
   // SL値計算
   if(order_type==ORDER_TYPE_BUY){
      stop_level =NormalizeDouble(stop_level_base_price-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits()); // Stoplevelは決済価格が基準となるためBIDが基準となる（ロングの場合）
      sl_value = NormalizeDouble(order_price - (sl_width * sl_coefficient),m_symbol.Digits()); // エントリー（ASK）価格からSL算出（トレーダーが指定したSL値が損失になるようスプレッド分を含むASKから算出（BIDだとSL＋スプレッド分が損失になる）
      //sl_value = NormalizeDouble(Bid(m_symbol_name) - (sl_width * sl_coefficient),m_symbol.Digits()); //20240118 変更
      if(sl_value>stop_level) {
         m_logger.print(ERR,"SLがストップレベルにかかっています","OPEN",__FUNCTION__);
         return EMPTY_VALUE;
      }
      m_order_sl_width_long = sl_width * sl_coefficient;
   } else if(order_type==ORDER_TYPE_SELL) {
      stop_level =NormalizeDouble(stop_level_base_price+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits()); // Stoplevelは決済価格が基準となるためASKが基準となる（ショートの場合）
      sl_value = NormalizeDouble(order_price + (sl_width * sl_coefficient),m_symbol.Digits()); // エントリー（BID）価格からSL算出（トレーダーが指定したSL値が損失になるようスプレッド分を含むBIDから算出（ASKだとSL＋スプレッド分が損失になる）
      //sl_value = NormalizeDouble(Ask(m_symbol_name) + (sl_width * sl_coefficient),m_symbol.Digits()); //20240118 変更
      if(sl_value<stop_level) {
         m_logger.print(ERR,"SLがストップレベルにかかっています","OPEN",__FUNCTION__);
         return EMPTY_VALUE;
      }
      m_order_sl_width_short = sl_width * sl_coefficient;
   }   
   
   
   return NormalizeDouble(sl_value,m_symbol.Digits());
}

double CMyExpert::CalculateTP(ENUM_ORDER_TYPE order_type){

   double ret_tp=0;
   double order_price = 0;
   double stop_level_base_price = 0;   
   // 成行・買いの場合はASKを基準にSLを計算する・ストップレベルはBIDが基準となる
   // 成行・売りの場合はBIDを基準にSLを計算する・ストップレベルはASKが基準となる
   // 指値・逆指値の場合は指値を基準にSLを計算する・ストップレベルは指値からスプレッド分調整した価格が基準となる
   if(order_type==ORDER_TYPE_BUY){
      if(m_order_price_long==0){
         order_price = Ask(m_symbol_name);
         stop_level_base_price = Bid(m_symbol_name);
      } else {
         order_price = m_order_price_long;
         stop_level_base_price = m_order_price_long - point2price(m_symbol.Spread(),_Point);
      }
   } else if(order_type==ORDER_TYPE_SELL){
      if(m_order_price_short==0){
         order_price = Bid(m_symbol_name);
         stop_level_base_price = Ask(m_symbol_name);
      } else {
         order_price = m_order_price_short;
         stop_level_base_price = m_order_price_short + point2price(m_symbol.Spread(),_Point);
      }
   }
      
   // TP値計算
   if(order_type==ORDER_TYPE_BUY){
      if(m_close_type==CLOSE_TYPE_LOGIC_ONLY){
         ret_tp = 0;
      } else if(m_close_type==CLOSE_TYPE_NONE){
         ret_tp = 0;
      } else if(m_close_type==CLOSE_TYPE_TP_ONLY){
         if(TpType==TP_TYPE_RRR){
            ret_tp = reverse_price(m_symbol_name,m_order_sl_long,m_order_price_long,m_close_rrr);
         } else if(TpType==TP_TYPE_FIXED_POINTS){
            ret_tp = order_price + point2price(profit_points,m_symbol.Point());
         }
      } else if(m_close_type==CLOSE_TYPE_LOGIC_AND_TP){
         if(TpType==TP_TYPE_RRR){
            ret_tp = reverse_price(m_symbol_name,m_order_sl_long,m_order_price_long,m_close_rrr);
         } else if(TpType==TP_TYPE_FIXED_POINTS){
            ret_tp = order_price + point2price(profit_points,m_symbol.Point());
         }         
      }
   } else if(order_type==ORDER_TYPE_SELL){
      if(m_close_type==CLOSE_TYPE_LOGIC_ONLY){
         ret_tp = 0;
      } else if(m_close_type==CLOSE_TYPE_NONE){
         ret_tp = 0;
      } else if(m_close_type==CLOSE_TYPE_TP_ONLY){
         if(TpType==TP_TYPE_RRR){
            ret_tp = reverse_price(m_symbol_name,m_order_sl_short,m_order_price_short,m_close_rrr);
         } else if(TpType==TP_TYPE_FIXED_POINTS){
            ret_tp = order_price - point2price(profit_points,m_symbol.Point());
         }            
      } else if(m_close_type==CLOSE_TYPE_LOGIC_AND_TP){
         if(TpType==TP_TYPE_RRR){
            ret_tp = reverse_price(m_symbol_name,m_order_sl_short,m_order_price_short,m_close_rrr);
         } else if(TpType==TP_TYPE_FIXED_POINTS){
            ret_tp = order_price - point2price(profit_points,m_symbol.Point());
         }                
      }   
   }

   // 水平線
   if(H_line_TP){
      if(order_type==ORDER_TYPE_BUY){
         if(Upper_line_price1>m_symbol.Ask()){
            if(Upper_line_price1>0){
               if(ret_tp>Upper_line_price1||ret_tp==0) ret_tp = Upper_line_price1; // TPが水平線より高い場合は水平線をTPに適用する
            }
         }
      } else if(order_type==ORDER_TYPE_SELL){
         if(Lower_line_price1<m_symbol.Bid()){
            if(Lower_line_price1>0){
               if(ret_tp<Lower_line_price1||ret_tp==0) ret_tp = Lower_line_price1; // TPが水平線より低い場合は水平線をTPに適用する
            }
         }
      }
   }

   // ストップレベル確認
   // 計算されたTPがストップレベルにかかっているかどうかをチェックする
   double stop_level=0;
   if(ret_tp!=0){
      if(order_type==ORDER_TYPE_BUY){
         stop_level =NormalizeDouble(stop_level_base_price+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
         if(ret_tp<stop_level) {
            m_logger.print(ERR,"TPがストップレベルにかかっています","OPEN",__FUNCTION__);
            return EMPTY_VALUE;
         }
      } else if(order_type==ORDER_TYPE_SELL) {
         stop_level =NormalizeDouble(stop_level_base_price-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
         if(ret_tp>stop_level) {
            m_logger.print(ERR,"TPがストップレベルにかかっています","OPEN",__FUNCTION__);
            return EMPTY_VALUE;
         }
      }   
   }      
      
   return ret_tp;
}

double CMyExpert::CalculateLOT(ENUM_ORDER_TYPE order_type){
   double ret_lot=0;
   if(order_type==ORDER_TYPE_BUY){
      ret_lot = m_money.CheckOpenLong(m_order_price_long,m_order_sl_long);
   } else if(order_type==ORDER_TYPE_SELL){
      ret_lot = m_money.CheckOpenShort(m_order_price_short,m_order_sl_short);
   }  
   return ret_lot; 
}


void CMyExpert::MainClose(ENUM_ORDER_TYPE order_type){
      // 全ポジション一括操作
      if(position_count(m_magic,m_symbol_name,order_type)>0){
         if(LogicClose(order_type)) {
            return;
         }
         // ドテンロジック
         if(i_Reverse_Order){   
            if(i_OpenType==OPEN_TYPE_LONG_SHORT) {
               if(MainOpen(reverse_order_type(order_type))){
                  if(close_position_all(m_magic,m_symbol_name,order_type)) {
                     m_logger.print(INFO,"ドテンのため決済執行","CLOSE",__FUNCTION__);
                  }   
                  OrderOpen(reverse_order_type(order_type));  // 反対方向でエントリー
                  return;          
               }
            }
         }
      } else {
         return; // ポジションがない場合は後続スキップ
      }
      
      // ポジション個別操作
      for(int i=PositionsTotal(); i>=0; i--){
         if(!m_position.SelectByIndex(i)) continue; // ポジション選択
         if(m_position.Symbol() != m_symbol.Name()) continue; // シンボル確認
         if(m_position.Magic() != m_magic) continue;     // マジックナンバー確認
         if(!((m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY) ||
              (m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL)
          )) continue;      // ポジション方向確認
            if(ForceClose(order_type)) continue;
            SplitClose(order_type);   
            Trail(order_type);
            Pyramiding(order_type);
      }
}


bool CMyExpert::LogicClose(ENUM_ORDER_TYPE order_type){

   MqlDateTime dt,dt_calc;
   TimeToStruct(m_time_current,dt);
   TimeToStruct(m_time_current,dt_calc);
   int swap_time,weekend_time,trade_stop_time,swap_time_min,weekend_time_min;
   if(m_summer_time){
      if(AdjustSummerTime){
         swap_time = SwapTime;
         swap_time_min = SwapTimeMin;
         weekend_time = WeekendTime;
         weekend_time_min = WeekendTimeMin;
      } else {
         swap_time = SwapTimeSummer;
         swap_time_min = SwapTimeMinSummer;
         weekend_time = WeekendTimeSummer;
         weekend_time_min = WeekendTimeMinSummer;
      }
   } else {
      swap_time = SwapTime;
      swap_time_min = SwapTimeMin;
      weekend_time = WeekendTime;
      weekend_time_min = WeekendTimeMin;
   }
   if(dt.day_of_week==Weekend){
      dt_calc.hour = (int)weekend_time;
      dt_calc.min = (int)weekend_time_min;
      if(weekend_time==0) {
         trade_stop_time = 24;
      } else {
         trade_stop_time = weekend_time;
      }
   } else {
      dt_calc.hour = (int)swap_time;
      dt_calc.min = (int)swap_time_min;
      if(swap_time==0) {
         trade_stop_time = 24;
      } else {
         trade_stop_time = swap_time;
      }
   }
   //dt_calc.min = 0;
   
   datetime datetime_calc = StructToTime(dt_calc);
   datetime_calc = datetime_calc - (PeriodSeconds(_Period) * exit_shift_bar);
   TimeToStruct(datetime_calc,dt_calc);
   int exit_hour = dt_calc.hour;
   int exit_min = dt_calc.min;

      // 当日強制決済または週末強制決済が有効の場合
      if(exit_day){ 
         bool next_flg = false;
         if(force_exit_open_type==(OPEN_TYPE)OPEN_TYPE_LONG_SHORT) next_flg = true;
         if(force_exit_open_type==(OPEN_TYPE)OPEN_TYPE_LONG&&order_type==ORDER_TYPE_BUY) next_flg = true;  // 当日強制決済対象がロングのみの場合でオーダータイプが売りの場合はスキップ
         if(force_exit_open_type==(OPEN_TYPE)OPEN_TYPE_SHORT&&order_type==ORDER_TYPE_SELL) next_flg = true;  // 当日強制決済対象がショートのみの場合でオーダータイプが買いの場合はスキップ

         if(next_flg){
            if(dt.hour>=exit_hour&&dt.hour<=trade_stop_time){   // 時間（HH）が強制退出の時間内であるか（パラメータ指定の日付変更時間と強制退出するシフトバー数前の時間）
               if(dt.hour==exit_hour&&dt.min>=exit_min) {      // 強制退出の時間内である場合、分を確認する
                  if(close_position_all(m_magic,m_symbol_name,order_type)) {
                     m_logger.print(INFO,"当日強制決済の執行","CLOSE",__FUNCTION__);
                     return true;
                  }
               }
            }
         }
      }
      // 週末強制決済が有効の場合
      if(exit_weekend){ 
         if(dt.day_of_week==Weekend) { //　週末強制決済のみの場合は週末曜日であるか確認
            if(dt.hour>=exit_hour&&dt.hour<=trade_stop_time){
               if(dt.hour==exit_hour&&dt.min>=exit_min) {
                  if(close_position_all(m_magic,m_symbol_name,order_type)) {
                     m_logger.print(INFO,"週末強制決済の執行","CLOSE",__FUNCTION__);
                     return true;
                  }
               }
            }
         }
      }      
           
      // シグナル決済
      if(m_close_type==CLOSE_TYPE_TP_ONLY) return false;
      if(m_close_type==CLOSE_TYPE_NONE) return false;
      if(!CheckClose(order_type)) {
         m_logger.print(INFO,"ロジック決済シグナルなし","CLOSE",__FUNCTION__);
         return false;
      }
      if(close_position_all(m_magic,m_symbol_name,order_type)) {
         m_logger.print(INFO,"ロジック決済の執行","CLOSE",__FUNCTION__);
         return true;
      }
      return false;
}


bool CMyExpert::ForceClose(ENUM_ORDER_TYPE order_type){
      
      // 経過バー数決済
      int open_bar_shift = iBarShift(m_symbol_name,m_period,m_position.Time());  // ポジションオープンからの経過バー数を取得
      m_logger.print(DEBUG,"Elapsed bars:" + IntegerToString(open_bar_shift),"",__FUNCTION__);

      if(m_close_bar_count>0 && (int)m_close_bar_count<=open_bar_shift) {
         if(exit_bar_count_profit){
            if(m_position.Profit()>0) {
               close_position(m_position.Ticket(),0,m_position.Volume(),0);
               m_logger.print(INFO,"バーカウント強制決済の執行(含み益)","CLOSE",__FUNCTION__);
               return true;            
            }
         } else {
            close_position(m_position.Ticket(),0,m_position.Volume(),0);
            m_logger.print(INFO,"バーカウント強制決済の執行","CLOSE",__FUNCTION__);
            return true;
         }
      }
       
      // 早期決済
      if(EarlyClose){
         if(early_bar_count>=open_bar_shift){
            //m_position.SelectByTicket(position_ticket_first(m_magic,m_symbol_name,order_type));                 
            double close_level=0;
            if(order_type==ORDER_TYPE_BUY){
               close_level = m_position.PriceOpen() + (m_order_sl_width_long * early_rrr);      
               if(close_level<m_position.PriceCurrent()) {
                  m_logger.print(INFO,"早期決済の執行","CLOSE",__FUNCTION__);
                  //close_position_all(m_magic,order_type,2,GetPointer(m_symbol)); 
                  close_position_partial_coefficient(m_magic,m_symbol_name,order_type,2,GetPointer(m_symbol)); 
                  return true;
               }
            } else if(order_type==ORDER_TYPE_SELL){
               close_level = m_position.PriceOpen() - (m_order_sl_width_short * early_rrr);
               if(close_level>m_position.PriceCurrent()) {
                  m_logger.print(INFO,"早期決済の執行","CLOSE",__FUNCTION__);
                  //close_position_all(m_magic,order_type,2,GetPointer(m_symbol));  
                  close_position_partial_coefficient(m_magic,m_symbol_name,order_type,2,GetPointer(m_symbol)); 
                  return true;
               }
            }         
         }
      }
      return false;
      
}



void CMyExpert::SplitClose(ENUM_ORDER_TYPE order_type){
      if(!m_close_split) return;

      if(m_split_same_line){
         m_position.SelectByTicket(position_ticket_first(m_magic,m_symbol_name,order_type));                 
         double split_level=0;
         if(order_type==ORDER_TYPE_BUY){
            split_level = m_position.PriceOpen() + (m_order_sl_width_long * m_split_rrr * (m_split_count_long+1));      
            if(split_level>m_position.PriceCurrent()) return;
         } else if(order_type==ORDER_TYPE_SELL){
            split_level = m_position.PriceOpen() - (m_order_sl_width_short * m_split_rrr * (m_split_count_short+1));
            if(split_level<m_position.PriceCurrent()) return;   
         }   
         
         if(order_type==ORDER_TYPE_BUY){
            m_split_count_long++;
         } else if(order_type==ORDER_TYPE_SELL){
            m_split_count_short++;
         }
         close_position_all(m_magic,order_type,2,GetPointer(m_symbol));
      } else { 
         double split_level=0;
         ulong pos_ticket;
         double pos_sl_width=0;
         uint pos_split_count;
         uint partial_coefficient = 2;
         if(order_type==ORDER_TYPE_BUY){
            for(int i=0; i<ArrayRange(m_position_manage_long,0); i++){
               pos_ticket = (ulong)m_position_manage_long[i][0];
               pos_sl_width = m_position_manage_long[i][1];
               pos_split_count = (uint)m_position_manage_long[i][3]+1; // 初回0を1になるように調整
               m_position.SelectByTicket(pos_ticket);            
               split_level = m_position.PriceOpen() + (pos_sl_width * m_split_rrr * pos_split_count);
               if(split_level>m_position.PriceCurrent()) continue;  
               double stepvol = m_symbol.LotsStep();
               double partial_vol = MathFloor(m_position.Volume() / partial_coefficient / stepvol) * stepvol;
               if(m_symbol.LotsMin()>partial_vol) continue;
               m_trade.PositionClosePartial(pos_ticket,partial_vol);
               Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
               if(m_trade.ResultRetcode()!=10009) return;
               m_position_manage_long[i][3] = pos_split_count;               
            }
         } else if(order_type==ORDER_TYPE_SELL){
            for(int i=0; i<ArrayRange(m_position_manage_short,0); i++){
               pos_ticket = (ulong)m_position_manage_short[i][0];
               pos_sl_width = m_position_manage_short[i][1];
               pos_split_count = (uint)m_position_manage_short[i][3]+1; // 初回0を1になるように調整
               m_position.SelectByTicket(pos_ticket);
               split_level = m_position.PriceOpen() - (pos_sl_width * m_split_rrr * pos_split_count);
               if(split_level<m_position.PriceCurrent()) continue; 
               double stepvol = m_symbol.LotsStep();
               double partial_vol = MathFloor(m_position.Volume() / partial_coefficient / stepvol) * stepvol;
               if(m_symbol.LotsMin()>partial_vol) continue;    
               m_trade.PositionClosePartial(pos_ticket,partial_vol);
               Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
               if(m_trade.ResultRetcode()!=10009) return;   
               m_position_manage_short[i][3] = pos_split_count;                             
            }
         } 
      }

      return;
}

void CMyExpert::Trail(ENUM_ORDER_TYPE order_type){
   if(!trail_enable) return;
   
   if(!CheckTrail(order_type)) return;
   
   // EveryTickの場合、ティックごとにトレイル発生するため新規足の1回だけトレイルするように変更
   if(!(IsNewBar(_Symbol,m_period))) return;
   
   if(trail_type==TRAIL_TYPE_BREAKEVEN){
   
      return;
   }
   
   // TRAIL_TYPE_PERCENT以外はMQL5標準クラスを利用する
   if(!(trail_type==(TRAIL_TYPE)TRAIL_TYPE_PERCENT)){
      TrailingModel(order_type);
      return;
   }
   
   // 以下TRAIL_TYPE_PERCENTの処理
   if(trail_same_line){
      //m_position.SelectByTicket(position_ticket_last(m_magic,order_type));
      m_position.SelectByTicket(position_ticket_first(m_magic,m_symbol_name,order_type));
                 
      double tp = 0;
      double trail_level=0;
      if(order_type==ORDER_TYPE_BUY){
         trail_level = m_position.PriceOpen() + (m_order_sl_width_long * trail_coefficient * (m_sl_trail_count_long+1));      
         if(trail_level>m_position.PriceCurrent()) return;
         tp = m_order_tp_long;  // 追加
      } else if(order_type==ORDER_TYPE_SELL){
         trail_level = m_position.PriceOpen() - (m_order_sl_width_short * trail_coefficient * (m_sl_trail_count_short+1));
         if(trail_level<m_position.PriceCurrent()) return;   
         tp = m_order_tp_short; // 追加
      }   
      
      double sl = CalculateSL(order_type);
      //double tp = CalculateTP(order_type);    // Trail中はTPの意味がなくなるためTPは変更しない
      
      if(sl==EMPTY_VALUE) return;
      //if(tp==EMPTY_VALUE) tp = 0;
      
      double pos_sl=m_position.StopLoss();   // 現在のSL
      double base  =(pos_sl==0.0) ? m_position.PriceOpen() : pos_sl;      

      // 新しいSLがネガティブな場合はトレイルしない
      if(order_type==ORDER_TYPE_BUY){
         if(sl<base) return;
      } else if(order_type==ORDER_TYPE_SELL){
         if(sl>base) return;
      }
      
      if(!modify_position_all(m_magic,m_symbol_name,order_type,sl,tp)){
         Print(__FUNCTION__ + ": modify position failed");
         return;
      }

      if(order_type==ORDER_TYPE_BUY){
         m_sl_trail_count_long++;
      } else if(order_type==ORDER_TYPE_SELL){
         m_sl_trail_count_short++;
      }
   } else { 
      double trail_level=0;
      ulong pos_ticket;
      double pos_sl_width=0;
      uint pos_trail_count;
      if(order_type==ORDER_TYPE_BUY){
         for(int i=0; i<ArrayRange(m_position_manage_long,0); i++){
            pos_ticket = (ulong)m_position_manage_long[i][0];
            //pos_sl_width = m_order_sl_width_long; //m_position_manage_long[i][1];
            pos_sl_width = m_position_manage_long[i][1];
            pos_trail_count = (uint)m_position_manage_long[i][2]+1; // 初回0を1になるように調整
            m_position.SelectByTicket(pos_ticket);            
            trail_level = m_position.PriceOpen() + (pos_sl_width * trail_coefficient * pos_trail_count);
            if(trail_level>m_position.PriceCurrent()) continue;  
            double pos_sl=m_position.StopLoss();   // 現在のSL
            double base  =(pos_sl==0.0) ? m_position.PriceOpen() : pos_sl;   
            double sl = CalculateSL(order_type);
            //double tp = CalculateTP(order_type);
            double tp = m_position.TakeProfit();
            if(sl==EMPTY_VALUE) continue;
            //if(tp==EMPTY_VALUE) tp = 0;
            if(sl<base) continue; // 新しいSLがネガティブな場合はトレイルしない
            m_trade.PositionModify(pos_ticket,sl,tp);
            Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
            if(m_trade.ResultRetcode()!=10009) {
               Print(__FUNCTION__ + ": modify position failed");
               return;            
            }
            m_position_manage_long[i][2] = pos_trail_count;            
         }
      } else if(order_type==ORDER_TYPE_SELL){
         for(int i=0; i<ArrayRange(m_position_manage_short,0); i++){
            pos_ticket = (ulong)m_position_manage_short[i][0];
            //pos_sl_width = m_order_sl_width_short; //m_position_manage_short[i][1];
            pos_sl_width = m_position_manage_short[i][1];
            pos_trail_count = (uint)m_position_manage_short[i][2]+1; // 初回0を1になるように調整
            m_position.SelectByTicket(pos_ticket);
            trail_level = m_position.PriceOpen() - (pos_sl_width * trail_coefficient * pos_trail_count);
            if(trail_level<m_position.PriceCurrent()) continue; 
            double pos_sl=m_position.StopLoss();   // 現在のSL
            double base  =(pos_sl==0.0) ? m_position.PriceOpen() : pos_sl;  
            double sl = CalculateSL(order_type);
            //double tp = CalculateTP(order_type);
            double tp = m_position.TakeProfit();
            if(sl==EMPTY_VALUE) continue;
            //if(tp==EMPTY_VALUE) tp = 0;                            
            if(sl>base) continue; // 新しいSLがネガティブな場合はトレイルしない
            m_trade.PositionModify(pos_ticket,sl,tp);
            Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
            if(m_trade.ResultRetcode()!=10009) {
               Print(__FUNCTION__ + ": modify position failed");
               return;            
            }
            m_position_manage_short[i][2] = pos_trail_count;                        
         }
      } 
   }
   return;
}

void CMyExpert::TrailingModel(ENUM_ORDER_TYPE order_type){
   double sl=EMPTY_VALUE;
   double tp=EMPTY_VALUE;
   
   if(order_type==ORDER_TYPE_BUY){
      if(!m_trail.CheckTrailingStopLong(GetPointer(m_position),sl,tp)) return;
      double sl_width = m_symbol.Bid() - sl;
      sl = m_symbol.Bid() - (sl_width * trail_coefficient); 
      if(trail_allow_openprice&&sl<m_position.PriceOpen()) return;   // 係数調整されたSLがオープンよりも低い場合はトレイルしない
      if(trail_allow_stoploss&&sl<m_position.StopLoss()) return;   // 係数調整されたSLが現在のSLよりも低い場合はトレイルしない
   } else if(order_type==ORDER_TYPE_SELL){
      if(!m_trail.CheckTrailingStopShort(GetPointer(m_position),sl,tp)) return;
      double sl_width = sl - m_symbol.Ask();
      sl = m_symbol.Ask() + (sl_width * trail_coefficient);
      if(trail_allow_openprice&&sl>m_position.PriceOpen()) return;   // 係数調整されたSLがオープンよりも低い場合はトレイルしない
      if(trail_allow_stoploss&&sl>m_position.StopLoss()) return;   // 係数調整されたSLが現在のSLよりも高い場合はトレイルしない
   }
   



   double position_sl=m_position.StopLoss();
   double position_tp=m_position.TakeProfit();
   if(sl==EMPTY_VALUE)
      sl=position_sl;
   else
      sl=m_symbol.NormalizePrice(sl);
   if(tp==EMPTY_VALUE)
      tp=position_tp;
   else
      tp=m_symbol.NormalizePrice(tp);
   if(sl==position_sl && tp==position_tp)
      //return(false);
      return;


   ulong pos_ticket = m_position.Ticket();
   m_trade.PositionModify(pos_ticket,sl,tp);
   Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
   if(m_trade.ResultRetcode()!=10009) {
      Print(__FUNCTION__ + ": modify position failed");
      return;            
   }

}

bool CMyExpert::Pyramiding(ENUM_ORDER_TYPE order_type){
   if(!m_pyramiding_enable) return false;
   if(!CheckPyramiding(order_type)) return false;

   m_position.SelectByTicket(position_ticket_last(m_magic,m_symbol_name,order_type)); 
   double pyramiding_level=0;
   if(order_type==ORDER_TYPE_BUY){
      if(m_pyramiding_counts_long>=m_pyramiding_max_counts) return false;
      pyramiding_level = m_position.PriceOpen() + m_order_sl_width_long * m_pyramiding_coefficient;
      if(pyramiding_level>m_position.PriceCurrent()) return false;
      if(m_pyramiding_close){
         close_position_all(m_magic,m_symbol_name,order_type);
      }
      double pyramiding_lot,pyramiding_sl,pyramiding_tp;
      if(m_pyramiding_same_sl){
         pyramiding_sl = m_order_sl_long;
      } else {
         pyramiding_sl = CalculateSL(order_type);
      }
      if(m_pyramiding_same_tp){
         pyramiding_tp = m_order_tp_long;
      } else {
         pyramiding_tp = CalculateTP(order_type);
      }
      if(m_pyramiding_same_money){
         pyramiding_lot = m_order_lot_long;
      } else {
         pyramiding_lot = m_money.CheckOpenLong(0,pyramiding_sl);
      }
      if(pyramiding_sl==EMPTY_VALUE) return false;

      double loss = m_account.OrderProfitCheck(m_symbol_name,order_type,pyramiding_lot,pyramiding_sl,m_symbol.Ask());
      double m_risk = NormalizeDouble((loss / m_account.Balance()) * 100,2);
      if(m_risk>(m_money.Percent()*1.1)) return false;  // 許容リスク(＋10%)を上回る場合はオーダーしない
            
      m_trade.PositionOpen(m_symbol.Name(),order_type,pyramiding_lot,0,pyramiding_sl,pyramiding_tp,m_project_name+"_add_"  + EnumToString(m_period) + "_" +IntegerToString(m_pyramiding_counts_long+1));
      Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
      if(m_trade.ResultRetcode()!=10009) {
         Print(__FUNCTION__ + ": modify position failed");
         return false;            
      }
      m_pyramiding_counts_long++;
   } else if(order_type==ORDER_TYPE_SELL){
      if(m_pyramiding_counts_short>=m_pyramiding_max_counts) return false;
      pyramiding_level = m_position.PriceOpen() - m_order_sl_width_short * m_pyramiding_coefficient;
      if(pyramiding_level<m_position.PriceCurrent()) return false;  
      if(m_pyramiding_close){
         close_position_all(m_magic,m_symbol_name,order_type);
      }
      double pyramiding_lot,pyramiding_sl,pyramiding_tp;
      if(m_pyramiding_same_sl){
         pyramiding_sl = m_order_sl_short;
      } else {
         pyramiding_sl = CalculateSL(order_type);
      }
      if(m_pyramiding_same_tp){
         pyramiding_tp = m_order_tp_short;
      } else {
         pyramiding_tp = CalculateTP(order_type);
      }      
      if(m_pyramiding_same_money){
         pyramiding_lot = m_order_lot_short;
      } else {
         pyramiding_lot = m_money.CheckOpenShort(0,pyramiding_sl);
      }
      if(pyramiding_sl==EMPTY_VALUE) return false;

      double loss = m_account.OrderProfitCheck(m_symbol_name,order_type,pyramiding_lot,pyramiding_sl,m_symbol.Bid());
      double m_risk = NormalizeDouble((loss / m_account.Balance()) * 100,2);
      if(m_risk>(m_money.Percent()*1.1)) return false;   // 許容リスク(＋10%)を上回る場合はオーダーしない
      
      m_trade.PositionOpen(m_symbol.Name(),order_type,pyramiding_lot,0,pyramiding_sl,pyramiding_tp,m_project_name+"_add_" + EnumToString(m_period) + "_" +IntegerToString(m_pyramiding_counts_short+1));
      Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
      if(m_trade.ResultRetcode()!=10009) {
         Print(__FUNCTION__ + ": modify position failed");
         return false;            
      }
      m_pyramiding_counts_short++;
   } 
   return true;
}


//+------------------------------------------------------------------+

void CMyExpert::OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {

   ulong deal_ticket = 0;
   // when deal (position open or close)
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD){ 
      deal_ticket = trans.deal;  // entry exit stoploss
   }
   if(deal_ticket == 0){ return; }

   // 取引履歴を取得
//   HistoryDealSelect(deal_ticket);  

   HistorySelect(0,TimeCurrent());
   m_deal.Ticket(deal_ticket); 

   //if(m_deal.Magic()!=m_magic) return;  // 決済時はm_deal.Magic()が０になるため注文時のdealで確認する。
   if(m_deal.Symbol()!=m_symbol_name) return;


   if(m_deal.Entry()==DEAL_ENTRY_IN){
      // when open position
      if(m_deal.Magic()!=m_magic) return; 
      
      m_position.SelectByTicket(m_deal.PositionId());
      
      if(m_position.PositionType()==POSITION_TYPE_BUY){
         if(m_open_type==OPEN_TYPE_SHORT) return; // オーダータイプが一致しない場合はスキップ
         int new_size = ArrayRange(m_position_manage_long,0)+1;
         ArrayResize(m_position_manage_long,new_size);         
         m_position_manage_long[new_size-1][0] = (double)m_position.Ticket(); 
         m_position_manage_long[new_size-1][1] = m_position.PriceOpen() - m_position.StopLoss();
         m_position_manage_long[new_size-1][2] = 0;
         m_position_manage_long[new_size-1][3] = 0;
      } else if(m_position.PositionType()==POSITION_TYPE_SELL){
         if(m_open_type==OPEN_TYPE_LONG) return; // オーダータイプが一致しない場合はスキップ
         int new_size = ArrayRange(m_position_manage_short,0)+1;
         ArrayResize(m_position_manage_short,ArrayRange(m_position_manage_short,0)+1);  
         m_position_manage_short[new_size-1][0] = (double)m_position.Ticket(); 
         m_position_manage_short[new_size-1][1] = m_position.StopLoss() - m_position.PriceOpen();
         m_position_manage_short[new_size-1][2] = 0;  
         m_position_manage_short[new_size-1][3] = 0;       
      }
      long reason;
      if(m_deal.InfoInteger(DEAL_REASON,reason)){
         string trade_action = EnumToString((ENUM_TRADE_REQUEST_ACTIONS)request.action);
         string ret_code = IntegerToString(result.retcode);
         string ret_code_ext = IntegerToString(result.retcode_external);
         Print(IntegerToString(m_magic) + " " + m_symbol_name + " " + period_name() + " " + EnumToString(m_deal.DealType())  + "#Entry " + EnumToString((ENUM_DEAL_REASON)reason) + " " + trade_action + " ret:" + ret_code + " retex:" + ret_code_ext);
      }      

   } else if(m_deal.Entry()==DEAL_ENTRY_OUT){
      if(!output_report()) return;  // Falseの場合＝magic numberが一致しなかったとき、OPENTYPEが一致しないとき
      OnCloseAll();
      long reason;

      if(m_deal.InfoInteger(DEAL_REASON,reason)){
         string trade_action = EnumToString((ENUM_TRADE_REQUEST_ACTIONS)request.action);
         string ret_code = IntegerToString(result.retcode);
         string ret_code_ext = IntegerToString(result.retcode_external);
         Print(IntegerToString(m_magic) + " " + m_symbol_name + " " + period_name() + " " + EnumToString(m_deal.DealType())  + "#Exit " + EnumToString((ENUM_DEAL_REASON)reason) + " " + trade_action + " ret:" + ret_code + " retex:" + ret_code_ext);
      }
      if(reason==DEAL_REASON_SL) {
         OnStoploss();
      } else if(reason==DEAL_REASON_TP){
         OnTakeprofit();
      } else if(reason==DEAL_REASON_EXPERT){
         OnExpert();
      }
      
      output_report_summary();
      // when close position
   }   
   Save();
  }



double CMyExpert::zig_point(int num,CiZigZag *zg=NULL){
   if(zg==NULL)
      zg=GetPointer(m_zg);  

   int i=0;
   int zig_cnt = 0;
   double zig_value = 0;
   
   do{
      if(zg.ZigZag(i)!=0) {
         zig_cnt++;
         zig_value = zg.ZigZag(i);
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

int CMyExpert::zig_bar(int num,CiZigZag *zg=NULL){
   if(zg==NULL)
      zg=GetPointer(m_zg);  
      
   int i=0;
   int zig_cnt = 0;
   int zig_value = 0;
   
   do{
      if(zg.ZigZag(i)!=0) {
         zig_cnt++;
         zig_value = i;
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

double CMyExpert::zig_point_high(int num,CiZigZag *zg=NULL){
   if(zg==NULL)
      zg=GetPointer(m_zg);  
      
   int i=0;
   int zig_cnt = 0;
   double zig_value = 0;
   
   do{
      if(zg.High(i)!=0&&zg.High(i)==zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
      //if(zg.High(i)!=0) {  
         zig_cnt++;
         zig_value = zg.High(i);
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

int CMyExpert::zig_bar_high(int num,CiZigZag *zg=NULL){
   if(zg==NULL)
      zg=GetPointer(m_zg);  
      
   int i=0;
   int zig_cnt = 0;
   int zig_value = 0;
   
   do{
      if(zg.High(i)!=0&&zg.High(i)==zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
      //if(zg.High(i)!=0) {  
         zig_cnt++;
         zig_value = i;
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

double CMyExpert::zig_point_low(int num,CiZigZag *zg=NULL){
   if(zg==NULL)
      zg=GetPointer(m_zg);  
      
   int i=0;
   int zig_cnt = 0;
   double zig_value = 0;
   
   do{
      if(zg.Low(i)!=0&&zg.Low(i)==zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
         zig_cnt++;
         zig_value = zg.Low(i);
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

int CMyExpert::zig_bar_low(int num,CiZigZag *zg=NULL){
   if(zg==NULL)
      zg=GetPointer(m_zg);  
      
   int i=0;
   int zig_cnt = 0;
   int zig_value = 0;
   
   do{
      if(zg.Low(i)!=0&&zg.Low(i)==zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
         zig_cnt++;
         zig_value = i;
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

void CMyExpert::output_report_summary(){
   if(!MQLInfoInteger(MQL_TESTER)){
      datetime s,e;
      get_dt_period_now_month(s,e);

      double res[];
      if(report_summary(res,s,e,m_symbol_name,m_magic)>0){     
         print_report_summary(res,s,e,m_symbol_name,m_magic);
      } else {
         Print(IntegerToString(m_magic) + " " + m_symbol_name + "from:" + TimeToString(s) + " to:" + TimeToString(e) + " No deal");
      }
      
      get_dt_period_prev_month(3,3,s,e);
      if(report_summary(res,s,e,m_symbol_name,m_magic)>0){
         print_report_summary(res,s,e,m_symbol_name,m_magic);
      } else {
         Print(IntegerToString(m_magic) + " " + m_symbol_name + "from:" + TimeToString(s) + " to:" + TimeToString(e) + " No deal");
      }
   }   
}

bool CMyExpert::output_report(){

   ulong ticket = m_deal.Ticket();
   datetime close_time = m_deal.Time();
   double size = m_deal.Volume();
   double close_price = m_deal.Price();
   double commswap = m_deal.Commission() + m_deal.Swap();
   double pl = m_deal.Profit();
   string comment = EnumToString(m_period);
   string action;
   int close_bar_num = iBarShift(m_symbol_name,PERIOD_CURRENT,close_time,true); // クローズのバー取得
   long deal_reason;
   m_deal.InfoInteger(DEAL_REASON,deal_reason);
   string reason = EnumToString((ENUM_DEAL_REASON)deal_reason);
   
   // エントリーの約定情報を取得する
   CDealInfo open_deal;
   ulong open_ticket = m_deal.PositionId();
   //HistoryDealSelect(open_ticket);  

   // 同じPosition IDを持つ履歴リストを取得
   if(!HistorySelectByPosition(open_ticket)){
      Print("Select Failed");
   }

   // オープンの約定を選択する
   for(int i=0; i<HistoryDealsTotal(); i++){
      HistoryDealGetTicket(i);
      open_deal.SelectByIndex(i);
      if(open_deal.Entry()==DEAL_ENTRY_IN) break;
   }
   
   // open_deal.Ticket(open_ticket);
   open_ticket = open_deal.Ticket();
   datetime open_time = open_deal.Time();
   double open_price = open_deal.Price();
   ulong magic = open_deal.Magic();   
   int open_bar_num = iBarShift(m_symbol_name,PERIOD_CURRENT,open_time,true); // オープンのバー取得
   int pos_bar_num = Bars(m_symbol_name,PERIOD_CURRENT,open_time,close_time); // ポジション保有期間のバー数取得
   int pos_high_bar_num = iHighest(m_symbol_name,PERIOD_CURRENT,MODE_HIGH,pos_bar_num,close_bar_num);
   double pos_high = iHigh(m_symbol_name,PERIOD_CURRENT,pos_high_bar_num);
   int pos_low_bar_num = iLowest(m_symbol_name,PERIOD_CURRENT,MODE_LOW,pos_bar_num,close_bar_num);
   double pos_low = iLow(m_symbol_name,PERIOD_CURRENT,pos_low_bar_num);
   pos_high_bar_num = pos_bar_num - pos_high_bar_num; // 終点からのカウント数を始点からのカウント数に変換
   pos_low_bar_num = pos_bar_num - pos_low_bar_num; // 終点からのカウント数を始点からのカウント数に変換


   if(magic!=m_magic) return false; // マジックナンバーが違う場合は処理しない
   
   if(open_deal.DealType()==DEAL_TYPE_BUY){
      if(!(m_open_type==OPEN_TYPE_LONG||m_open_type==OPEN_TYPE_LONG_SHORT)) return false; // 方向が違う場合は処理しない
      if(m_order_price_long==0){
         action = "buy";
      } else if(m_order_price_long<m_order_ask){
         action = "buy limit";
      } else if(m_order_price_long>m_order_ask){
         action = "buy stop";
      }
   } else if(open_deal.DealType()==DEAL_TYPE_SELL){
      if(!(m_open_type==OPEN_TYPE_SHORT||m_open_type==OPEN_TYPE_LONG_SHORT)) return false; // 方向が違う場合は処理しない
      if(m_order_price_short==0){
         action = "sell";
      } else if(m_order_price_short>m_order_bid){
         action = "sell limit";
      } else if(m_order_price_short<m_order_bid){
         action = "sell stop";
      }
   }

   if(!ReportEnable) return true;

   //if(!(MQLInfoInteger(MQL_TESTER)&&m_env_name=="dev")) return true;  // バックテスト時は環境がdevモードの場合のみレポート出力する
   
   if(!MQLInfoInteger(MQL_TESTER)) {
      //report_csv = new CDataFile("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + ".csv",false);
      report_csv = new CDataFile("projects\\" + m_project_name + "\\" + m_env_name + "\\reports\\" + m_project_name + "_" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv",false);
      report_csv.reset_array_value();
   } else {
      // バックテストの場合常にファイルが開いているためここで改行する
      static bool initial_open = true;
      if(initial_open){
         initial_open = false;
      } else {
         report_csv.append_array_value("\r\n");
      }
   }
   report_csv.append_array_value(IntegerToString(ticket));
   report_csv.append_array_value(TimeToString(open_time));
   report_csv.append_array_value(TimeToString(close_time));
   report_csv.append_array_value(m_symbol_name);
   report_csv.append_array_value(action);
   report_csv.append_array_value(DoubleToString(size,lot_digits(m_symbol_name)));
   report_csv.append_array_value(DoubleToString(open_price,m_symbol.Digits()));
   report_csv.append_array_value(DoubleToString(close_price,m_symbol.Digits()));
//   report_csv.append_array_value(DoubleToString(commswap,0));
//   report_csv.append_array_value(DoubleToString(pl,0));
   report_csv.append_array_value(DoubleToString(commswap,account_digits()));
   report_csv.append_array_value(DoubleToString(pl,account_digits()));
   report_csv.append_array_value(comment);
   report_csv.append_array_value(IntegerToString(magic));
   int w = 0;
   if(pl>0) w = 1;
   report_csv.append_array_value(IntegerToString(w));
   report_csv.append_array_value(reason);
   report_csv.append_array_value(IntegerToString(pos_bar_num));
   report_csv.append_array_value(IntegerToString(pos_high_bar_num));
   report_csv.append_array_value(DoubleToString(pos_high,m_symbol.Digits()));
   report_csv.append_array_value(IntegerToString(pos_low_bar_num));
   report_csv.append_array_value(DoubleToString(pos_low,m_symbol.Digits()));
   
   if(MQLInfoInteger(MQL_TESTER)){
//      report_csv.append_array_value("\r\n");
   } else {
      report_csv.write_array_value(",");
      delete(report_csv);
   }
   
   return true;
}

void CMyExpert::Save(){
   if(!EnableSaveLoadMode) return;
   if(MQLInfoInteger(MQL_TESTER)) return;

   string save_file_path = "projects\\" + m_project_name + "\\" + m_env_name + "\\save\\" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv";
   //Print("Save:"+ save_file_path);
   CDataFile save_file(save_file_path,true);
   save_file.reset_array_value();
   save_file.append_array_value((string)m_order_ask);
   save_file.append_array_value((string)m_order_bid);
   save_file.append_array_value((string)m_order_price_long);
   save_file.append_array_value((string)m_order_reset_long);
   save_file.append_array_value((string)m_order_sl_long);
   save_file.append_array_value((string)m_order_tp_long);
   save_file.append_array_value((string)m_order_lot_long); 
   save_file.append_array_value((string)m_order_sl_width_long);
   save_file.append_array_value((string)m_pyramiding_counts_long); 
//   save_file.append_array_value((string)m_position_bar_count_long);
   save_file.append_array_value("N/A");
   save_file.append_array_value((string)m_order_price_short);
   save_file.append_array_value((string)m_order_reset_short); 
   save_file.append_array_value((string)m_order_sl_short);
   save_file.append_array_value((string)m_order_tp_short); 
   save_file.append_array_value((string)m_order_lot_short);
   save_file.append_array_value((string)m_order_sl_width_short); 
   save_file.append_array_value((string)m_pyramiding_counts_short); 
//   save_file.append_array_value((string)m_position_bar_count_short); 
   save_file.append_array_value("N/A");
   save_file.append_array_value((string)m_sl_trail_count_long);
   save_file.append_array_value((string)m_sl_trail_count_short); 
   save_file.append_array_value((string)m_split_count_long); 
   save_file.append_array_value((string)m_split_count_short); 
   string col;
   for(int i=0; i<ArrayRange(m_position_manage_long,0); i++){
         col = (string)m_position_manage_long[i][0] + ";" + (string)m_position_manage_long[i][1] + ";" + (string)m_position_manage_long[i][2] + ";" + (string)m_position_manage_long[i][3] + "_";
   }
   save_file.append_array_value(col);
   
   for(int i=0; i<ArrayRange(m_position_manage_short,0); i++){
         col = (string)m_position_manage_short[i][0] + ";" + (string)m_position_manage_short[i][1] + ";" + (string)m_position_manage_short[i][2] + ";" + (string)m_position_manage_short[i][3] + "_";
   }  
   save_file.append_array_value(col);  
   save_file.write_array_value(",");
   //Print("Save Complete");
   Save_ini();  // セーブした変数の値を確認用のINIファイルに出力する
}

void CMyExpert::Load(){
   if(!EnableSaveLoadMode) return;
   if(MQLInfoInteger(MQL_TESTER)) return;
   string load_file_path = "projects\\" + m_project_name + "\\" + m_env_name + "\\save\\" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".csv";
   Print("Load:" + load_file_path);
   if(!(FileIsExist(load_file_path,FILE_COMMON))) return;
   //Print("Load");
   CDataFile load_file(load_file_path,false);
   CArrayString *load_line = load_file.read();
   string load_rec[];
   ushort u_sep=StringGetCharacter(",",0); 
   StringSplit(load_line.At(0),u_sep,load_rec);

   m_order_ask = StringToDouble(load_rec[0]);
   m_order_bid = StringToDouble(load_rec[1]);
   m_order_price_long = StringToDouble(load_rec[2]);
   m_order_reset_long = StringToInteger(load_rec[3]);
   m_order_sl_long = StringToDouble(load_rec[4]);
   m_order_tp_long = StringToDouble(load_rec[5]);
   m_order_lot_long = StringToDouble(load_rec[6]); 
   m_order_sl_width_long = StringToDouble(load_rec[7]);
   m_pyramiding_counts_long = (uint)StringToInteger(load_rec[8]); 
//   m_position_bar_count_long = (uint)StringToInteger(load_rec[9]);
   m_order_price_short = StringToDouble(load_rec[10]);
   m_order_reset_short = StringToInteger(load_rec[11]); 
   m_order_sl_short = StringToDouble(load_rec[12]);
   m_order_tp_short = StringToDouble(load_rec[13]); 
   m_order_lot_short = StringToDouble(load_rec[14]);
   m_order_sl_width_short = StringToDouble(load_rec[15]); 
   m_pyramiding_counts_short = (uint)StringToInteger(load_rec[16]); 
//   m_position_bar_count_short = (uint)StringToInteger(load_rec[17]); 

   m_sl_trail_count_long = (int)StringToInteger(load_rec[18]);
   m_sl_trail_count_short = (int)StringToInteger(load_rec[19]); 
   m_split_count_long = (int)StringToInteger(load_rec[20]); 
   m_split_count_short = (int)StringToInteger(load_rec[21]);  

   string load_rec_pos[];
   u_sep=StringGetCharacter("_",0); 
   
   StringSplit(load_rec[22],u_sep,load_rec_pos);
   for(int i=0; i<ArraySize(load_rec_pos); i++){
      string load_col[];
      u_sep=StringGetCharacter(";",0); 
      StringSplit(load_rec_pos[i],u_sep,load_col);   
      if(ArraySize(load_col)<4) continue;
      for(int i2=0; i2<ArraySize(load_col); i2++){
         int new_size = ArrayRange(m_position_manage_long,0)+1;
         ArrayResize(m_position_manage_long,new_size);             
         m_position_manage_long[i][i2] = StringToDouble(load_col[i2]);
      }
   }
   
   u_sep=StringGetCharacter("_",0); 
   ArrayResize(load_rec_pos,0);
   StringSplit(load_rec[23],u_sep,load_rec_pos);
   for(int i=0; i<ArraySize(load_rec_pos); i++){
      string load_col[];
      u_sep=StringGetCharacter(";",0); 
      StringSplit(load_rec_pos[i],u_sep,load_col); 
      if(ArraySize(load_col)<4) continue;        
      for(int i2=0; i2<ArraySize(load_col); i2++){
         int new_size = ArrayRange(m_position_manage_short,0)+1;
         ArrayResize(m_position_manage_short,new_size);          
         m_position_manage_short[i][i2] = StringToDouble(load_col[i2]);
      }
   }      
  Load_ini();  // ロードした変数を確認用のINIファイルに出力する
  Print("Load Complete");
  if(load_line!=NULL)
      delete load_line;   
}



void CMyExpert::Save_ini(){
   // セーブした変数をINIファイルに書き出す。確認用のためでEA動作に影響しない
   if(MQLInfoInteger(MQL_TESTER)) return;
   string save_file_path = "projects\\" + m_project_name + "\\" + m_env_name + "\\save\\" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".ini";
   string ini_file_path = m_terminal.CommonDataPath() + "\\Files\\" + save_file_path;

   string section_name = "SAVE_COMMON";
   SetIniKey(ini_file_path,section_name,"m_order_ask",(string)m_order_ask);
   SetIniKey(ini_file_path,section_name,"m_order_bid",(string)m_order_bid);

   section_name = "SAVE_LONG";
   SetIniKey(ini_file_path,section_name,"order_price",(string)m_order_price_long);
   SetIniKey(ini_file_path,section_name,"order_reset_flag",(string)m_order_reset_long);
   SetIniKey(ini_file_path,section_name,"order_sl",(string)m_order_sl_long);
   SetIniKey(ini_file_path,section_name,"order_tp",(string)m_order_tp_long);
   SetIniKey(ini_file_path,section_name,"order_lot",(string)m_order_lot_long); 
   SetIniKey(ini_file_path,section_name,"order_sl_width",(string)m_order_sl_width_long);
   SetIniKey(ini_file_path,section_name,"pyramiding_counts",(string)m_pyramiding_counts_long); 
//   SetIniKey(ini_file_path,section_name,"position_bar_count",(string)m_position_bar_count_long);
   SetIniKey(ini_file_path,section_name,"sl_trail_count",(string)m_sl_trail_count_long);
   SetIniKey(ini_file_path,section_name,"split_count",(string)m_split_count_long); 
   string col;
   for(int i=0; i<ArrayRange(m_position_manage_long,0); i++){
         col = (string)m_position_manage_long[i][0] + ";" + (string)m_position_manage_long[i][1] + ";" + (string)m_position_manage_long[i][2] + ";" + (string)m_position_manage_long[i][3] + "_";
   }
   SetIniKey(ini_file_path,section_name,"position_manage",(string)col); 

   section_name = "SAVE_SHORT";
   SetIniKey(ini_file_path,section_name,"order_price",(string)m_order_price_short);
   SetIniKey(ini_file_path,section_name,"order_reset_flag",(string)m_order_reset_short); 
   SetIniKey(ini_file_path,section_name,"order_sl",(string)m_order_sl_short);
   SetIniKey(ini_file_path,section_name,"order_tp",(string)m_order_tp_short); 
   SetIniKey(ini_file_path,section_name,"order_lot",(string)m_order_lot_short);
   SetIniKey(ini_file_path,section_name,"order_sl_width",(string)m_order_sl_width_short); 
   SetIniKey(ini_file_path,section_name,"pyramiding_counts",(string)m_pyramiding_counts_short); 
//   SetIniKey(ini_file_path,section_name,"position_bar_count",(string)m_position_bar_count_short); 
   SetIniKey(ini_file_path,section_name,"sl_trail_count",(string)m_sl_trail_count_short); 
   SetIniKey(ini_file_path,section_name,"split_count",(string)m_split_count_short); 

   for(int i=0; i<ArrayRange(m_position_manage_short,0); i++){
         col = (string)m_position_manage_short[i][0] + ";" + (string)m_position_manage_short[i][1] + ";" + (string)m_position_manage_short[i][2] + ";" + (string)m_position_manage_short[i][3] + "_";
   }  
   SetIniKey(ini_file_path,section_name,"position_manage",(string)col); 

}

void CMyExpert::Load_ini(){
   // ロードした変数をINIファイルに書き出す。確認用のためでEA動作に影響しない
   if(MQLInfoInteger(MQL_TESTER)) return;
   string save_file_path = "projects\\" + m_project_name + "\\" + m_env_name + "\\save\\" + m_symbol_name + "_" + EnumToString(m_period) + "_" + m_direction_type + ".ini";
   string ini_file_path = m_terminal.CommonDataPath() + "\\Files\\" + save_file_path;

   string section_name = "LOAD_COMMON";
   SetIniKey(ini_file_path,section_name,"m_order_ask",(string)m_order_ask);
   SetIniKey(ini_file_path,section_name,"m_order_bid",(string)m_order_bid);

   section_name = "LOAD_LONG";
   SetIniKey(ini_file_path,section_name,"order_price",(string)m_order_price_long);
   SetIniKey(ini_file_path,section_name,"order_reset_flag",(string)m_order_reset_long);
   SetIniKey(ini_file_path,section_name,"order_sl",(string)m_order_sl_long);
   SetIniKey(ini_file_path,section_name,"order_tp",(string)m_order_tp_long);
   SetIniKey(ini_file_path,section_name,"order_lot",(string)m_order_lot_long); 
   SetIniKey(ini_file_path,section_name,"order_sl_width",(string)m_order_sl_width_long);
   SetIniKey(ini_file_path,section_name,"pyramiding_counts",(string)m_pyramiding_counts_long); 
//   SetIniKey(ini_file_path,section_name,"position_bar_count",(string)m_position_bar_count_long);
   SetIniKey(ini_file_path,section_name,"sl_trail_count",(string)m_sl_trail_count_long);
   SetIniKey(ini_file_path,section_name,"split_count",(string)m_split_count_long); 
   string col;
   for(int i=0; i<ArrayRange(m_position_manage_long,0); i++){
         col = (string)m_position_manage_long[i][0] + ";" + (string)m_position_manage_long[i][1] + ";" + (string)m_position_manage_long[i][2] + ";" + (string)m_position_manage_long[i][3] + "_";
   }
   SetIniKey(ini_file_path,section_name,"position_manage",(string)col); 

   section_name = "LOAD_SHORT";
   SetIniKey(ini_file_path,section_name,"order_price",(string)m_order_price_short);
   SetIniKey(ini_file_path,section_name,"order_reset_flag",(string)m_order_reset_short); 
   SetIniKey(ini_file_path,section_name,"order_sl",(string)m_order_sl_short);
   SetIniKey(ini_file_path,section_name,"order_tp",(string)m_order_tp_short); 
   SetIniKey(ini_file_path,section_name,"order_lot",(string)m_order_lot_short);
   SetIniKey(ini_file_path,section_name,"order_sl_width",(string)m_order_sl_width_short); 
   SetIniKey(ini_file_path,section_name,"pyramiding_counts",(string)m_pyramiding_counts_short); 
//   SetIniKey(ini_file_path,section_name,"position_bar_count",(string)m_position_bar_count_short); 
   SetIniKey(ini_file_path,section_name,"sl_trail_count",(string)m_sl_trail_count_short); 
   SetIniKey(ini_file_path,section_name,"split_count",(string)m_split_count_short); 

   for(int i=0; i<ArrayRange(m_position_manage_short,0); i++){
         col = (string)m_position_manage_short[i][0] + ";" + (string)m_position_manage_short[i][1] + ";" + (string)m_position_manage_short[i][2] + ";" + (string)m_position_manage_short[i][3] + "_";
   }  
   SetIniKey(ini_file_path,section_name,"position_manage",(string)col); 
}

void CMyExpert::ExecNotify(string text){
   if(!EnableNotify) return;
   SendNotification(text);
}


void CMyExpert::DisplayMessage(){
   color                   font_color           = (color)ChartGetInteger(0,CHART_COLOR_FOREGROUND,0);
   int                     font_size            = 8;
   string                  font_face            = "Arial";
   ENUM_ANCHOR_POINT       anchor               = ANCHOR_RIGHT_UPPER;
   ENUM_BASE_CORNER        corner               = CORNER_RIGHT_UPPER;
   int                     distance_x    = 10;
   int                     distance_y    = 20;
   string                  obj_label1 = "ExpertMessage1";
   ObjectCreate(0,obj_label1,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,obj_label1,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,obj_label1,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,obj_label1,OBJPROP_XDISTANCE,distance_x);
   ObjectSetInteger(0,obj_label1,OBJPROP_YDISTANCE,distance_y);
   ObjectSetString(0,obj_label1,OBJPROP_TEXT,EnumToString((OPERATION_TYPE)OperationType));
   ObjectSetString(0,obj_label1,OBJPROP_FONT,font_face);
   ObjectSetInteger(0,obj_label1,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,obj_label1,OBJPROP_COLOR,font_color);

   string                  obj_label2 = "ExpertMessage2";   
   int                     distance_y2    = 35;  
   ObjectCreate(0,obj_label2,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,obj_label2,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,obj_label2,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,obj_label2,OBJPROP_XDISTANCE,distance_x);
   ObjectSetInteger(0,obj_label2,OBJPROP_YDISTANCE,distance_y2);
   ObjectSetString(0,obj_label2,OBJPROP_TEXT,EnumToString((OPEN_TYPE)i_OpenType));
   ObjectSetString(0,obj_label2,OBJPROP_FONT,font_face);
   ObjectSetInteger(0,obj_label2,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,obj_label2,OBJPROP_COLOR,font_color);   
   
   
   
   
   
}