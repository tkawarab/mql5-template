
string env_name;

enum ENV_TYPE
  {
   dev,
   stg,
   prd
  };
  
enum OPERATION_TYPE
  {
   OPERATION_TYPE_ALL,
   OPERATION_TYPE_CLOSE,
   OPERATION_TYPE_OPEN,
   OPERATION_TYPE_CLOSE_NOW
  };

enum OPEN_TYPE
  {
   OPEN_TYPE_LONG,
   OPEN_TYPE_SHORT,
   OPEN_TYPE_LONG_SHORT
  };
  
enum ORDER_METHOD
  {
   ORDER_METHOD_MARKET,
   ORDER_METHOD_LIMIT,
   ORDER_METHOD_STOP,
   ORDER_METHOD_STOPLIMIT
  };

enum CLOSE_TYPE
  {
   CLOSE_TYPE_NONE,
   CLOSE_TYPE_LOGIC_ONLY,
   CLOSE_TYPE_TP_ONLY,
   CLOSE_TYPE_LOGIC_AND_TP
  };
  
enum SL_TYPE
  {
   SL_TYPE_NONE,
   SL_TYPE_ATR,
   SL_TYPE_SAR,
   SL_TYPE_ZIGZAG,
   SL_TYPE_MA,
   SL_TYPE_BB,
   SL_TYPE_FIXED_POINTS,
   SL_TYPE_MINIMUM,
   SL_TYPE_STRATEGY
  };
  
enum TP_TYPE
  {
   TP_TYPE_RRR,
   TP_TYPE_FIXED_POINTS
  }; 
  
enum TRAIL_TYPE
  {
   TRAIL_TYPE_NONE,
   TRAIL_TYPE_ATR,
   TRAIL_TYPE_SAR,
   TRAIL_TYPE_ZIGZAG,
   TRAIL_TYPE_MA,
   TRAIL_TYPE_FIXED_POINTS,
   TRAIL_TYPE_PERCENT,
   TRAIL_TYPE_PREVBAR,
   TRAIL_TYPE_BREAKEVEN
  };
enum MONEY_TYPE
  {
   MONEY_TYPE_FIXED_RISK,
   MONEY_TYPE_SizeOptimized,
   MONEY_TYPE_MINIMUM,
   MONEY_TYPE_FIXED_LOT
  };

enum FILTER_TYPE
  {
   FILTER_TYPE_BLOCK,
   FILTER_TYPE_ALLOW_ONLY,
   FILTER_TYPE_OFF
  };
  
enum PORTFOLIO_MODE
  {
   PORTFOLIO_DISABLE,
   PORTFOLIO_SYMBOLS_PERIODS_FILE,
   PORTFOLIO_SETUP_FILE   
  };
  
enum LOG_LEVEL
  {
      LOG_LEVEL_NONE,
      LOG_LEVEL_ONLY_CRITICAL,
      LOG_LEVEL_MORE_THAN_ERROR,
      LOG_LEVEL_MORE_THAN_WARNING,
      LOG_LEVEL_ALL_INFOMATION,
      LOG_LEVEL_DEBUG
  };
 
enum NOTIFY_TYPE
  {
      DEBUG,
      INFO,
      WARN,
      ERR,
      CRITICAL
  };  
  
enum Week
  {
      WEEK_SUNDAY,
      WEEK_MONDAY,
      WEEK_TUESDAY,
      WEEK_WEDNESDAY,
      WEEK_THURSDAY,
      WEEK_FRIDAY,
      WEEK_SATADAY
  };

input group "◆基本設定"
input string ProjectName="EA";                              // プロジェクト名
input PORTFOLIO_MODE portfolio_mode=PORTFOLIO_DISABLE;      // ポートフォリオモード
input ENUM_TIMEFRAMES Base_Period=PERIOD_CURRENT;           // 基準時間足（PORTFOLIO_DISABLEのみ）
input int MagicNumber=1000000;                              // 識別番号(＋Period秒数＝マジックナンバー)
input bool  EveryTick=false;                                // ティック毎に動作
input bool  ReportEnable=true;                              // レポート出力の有効化
input bool  ReportAddwrite=true;                            // レポートを追加書き込み（バックテストの場合）
input OPERATION_TYPE OperationType=OPERATION_TYPE_ALL;      // 動作モード
input LOG_LEVEL   print_log_level=LOG_LEVEL_ALL_INFOMATION; // ログレベル
input bool  EnableSaveLoadMode=true;                        // セーブ/ロードモードの有効化
input bool  EnableNotify=false;                             // エントリー時に通知

input group "◆環境設定"
input char  AdjustedTimeOffset=0;                           // EA基準GMT調整オフセット（MT5時間からEA基準とするGMTに調整する値を入力）
                                                            // MT5時間がGMT+2で、日本時間を基準とする場合は6を入力する
                                                            // MT5時間をそのまま基準とする場合は0を入力する
input bool  AdjustSummerTime=false;                         // サマータイムオフセット調整の有効化（サマータイム中EA基準GMTオフセットを1時間ずらす）
                                                            // 標準GMT＋２、夏GMT＋３の場合、ONにすると日本時間がベース　例）ONにすると標準・夏関わらず日本時間9時に動作する
                                                            // GMT+0固定の場合、ONにするとサマータイムがベース　例）ONにすると日本時間9時は標準時0時、夏時間23時に動作する
//input int SummerTimeStartMonth=3;                           // サマータイム開始月
//input int SummerTimeStartDay=10;                            // サマータイム開始日（米国：3月第2日曜から） 
//input int SummerTimeEndMonth=11;                            // サマータイム終了月
//input int SummerTimeEndDay=3;                               // サマータイム終了日（米国：11月第1日曜まで） 
input string SummerTimeStartDate="0310";                           // サマータイム開始日MMDD形式（米国：3月第2日曜から） 
input string SummerTimeEndDate="1103";                            // サマータイム終了日MMDD形式（米国：11月第1日曜まで） 
input string i_SwapTime="0700";                                       // スワップ発生時間（標準時） ※EA基準GMT指定
input string i_SwapTimeSummer="0600";                                 // スワップ発生時間（夏時間） ※サマータイムオフセット調整しない場合・EA基準GMT指定
input Week  Weekend=WEEK_SATADAY;                            // 週末休場曜日　※EA基準GMT指定
input string i_WeekendTime="0700";                                   // 週末休場時間HHMM形式（標準時） ※EA基準GMT指定
input string i_WeekendTimeSummer="0600";                             // 週末休場時間HHMM形式（夏時間） ※サマータイムオフセット調整しない場合・EA基準GMT指定
//input int WeekendTime=22;                                   // 週末休場時間HHMM形式（標準時） ※EA基準GMT指定
//input int WeekendTimeSummer=21;                             // 週末休場時間HHMM形式（夏時間） ※サマータイムオフセット調整しない場合・EA基準GMT指定
input Week  Weekstart=WEEK_MONDAY;                          // 週明け開始曜日　※EA基準GMT指定
input int Spread_Limit_Points=0;                            // スプレッド制限（point）

input group "◆オーダー設定"
input OPEN_TYPE i_OpenType=OPEN_TYPE_LONG_SHORT;            // エントリータイプ
input ORDER_METHOD i_OrderMethod=ORDER_METHOD_MARKET;       // 注文方式
input ENUM_ORDER_TYPE_TIME i_OrderTypeTime=ORDER_TIME_SPECIFIED; // 注文期限タイプ（指値/逆指値時）
input uint i_OrderTypeTimeSpec=10;                          // （ORDER_TIME_SPECIFIED）注文期限指定・現在時間足の経過バー数で指定
input double i_OrderLimitStopPrice=10;                      // 指値・逆指値point（現在価格から指値/逆指値をセットする距離）
input double i_OrderStopLimitPrice=10;                      // ストップリミットpoint（現在価格からストップリミット注文を発動する価格までの距離）
input bool  Trade_Reverse=false;                            // 逆張りでエントリーする（エントリータイプと反転のシグナルを使う）
input int Trade_Allow_Pos_num=1;                            // 許容最大ポジション数
input bool Trade_Allow_Cross_Order=false;                   // 両建てを許可する
input bool  i_Reverse_Order=false;                          // ドテン有効化
input ulong Trade_Deviation_InPoints=0;                     // 許容スリッページ
input uint sleep_bar_cnt_after_entry=1;                     // エントリー後からエントリーを抑止するバーカウント数
input uint sleep_bar_count=0;                               // 決済後からエントリーを抑止するバーカウント数
input string Trade_Allow_Days=NULL;                         // エントリー許可日（カンマ区切り）
input uint   Start_Entry_Day=1;                             // エントリー許可日（開始） 1-31
input int    End_Entry_Day=31;                              // エントリー許可日（終了） 1-31
input string Trade_Allow_Hour=NULL;                         // エントリー許可時間（カンマ区切り）　※EA基準GMT指定
input uint Start_Entry_Hour=0;                              // エントリー許可期間（開始時） 0-23h　※EA基準GMT指定
input int End_Entry_Hour=23;                                // エントリー許可期間（終了時） 0-23h　※EA基準GMT指定
input uint Start_Entry_Minute=0;                            // エントリー許可期間（開始分） 0-59m　※EA基準GMT指定
input int End_Entry_Minute=59;                              // エントリー許可期間（終了分） 0-59m　※EA基準GMT指定
input bool HL_line_Filter=false;                            // 水平線フィルタの有効化する
input double Upper_line_price1=0;                           // 水平線価格より高値ではショートトレードしない
input double Lower_line_price1=0;                           // 水平線価格より安値ではロングトレードしない
input bool  H_line_TP=false;                                 // TPが水平線より大きい場合水平線をTPとする
input bool  Trend_Filter=false;                             // トレンドフィルタを有効にする（価格がトレンド方向に沿っていない場合エントリーしない）
input double Trend_Filter_Price=0;                          // トレンドフィルタの初回開始価格を設定
input uint  Trend_Filter_Reset=300;                         // 一定バー数経過でトレンドフィルタ開始価格をリセットする（バー数経過時点の価格に設定）

input group "◆ストップ管理設定"
input SL_TYPE SlType=SL_TYPE_FIXED_POINTS;                  // ストップロスタイプ
input double sl_coefficient=1;                              // SL幅調整係数（全タイプ適用）
//input ENUM_TIMEFRAMES SL_Indicator_TF=PERIOD_CURRENT;     // IndicatorPeriod(Common)
input uint loss_points = 100;                               // SL_TYPE_FIXED_POINTS設定値（point）
input uint ATR_Period=14;                                   // SL_TYPE_ATR設定値（期間）
//input uint ATR_magnification=3;                           // SL_TYPE_ATR設定値（ATR倍率）
input double SAR_Step=0.02;                                 // SL_TYPE_SAR設定値（Step）
input double SAR_Maximum=0.02;                              // SL_TYPE_SAR設定値（Maximum）
input uint ZIGZAG_Depth=12;                                 // SL_TYPE_ZIGZAG設定値（Depth）
input uint ZIGZAG_Deviation=5;                              // SL_TYPE_ZIGZAG設定値（Deviation）
input uint ZIGZAG_Backstep=3;                               // SL_TYPE_ZIGZAG設定値（Backstep）
input uint MA_Period=120;                                   // SL_TYPE_MA設定値（Period）
input uint MA_Shift=0;                                      // SL_TYPE_MA設定値（Shift）
input ENUM_MA_METHOD MA_Method=MODE_SMA;                    // SL_TYPE_MA設定値（Method）
input ENUM_APPLIED_PRICE MA_AppliedPrice=PRICE_CLOSE;       // SL_TYPE_MA設定値（AppliedPrice）
input uint bb_Period=14;                                    // SL_TYPE_BB設定値（Period）
input uint bb_Deviation=3;                                  // SL_TYPE_BB設定値（Deviation）

input group "◆決済設定"
input CLOSE_TYPE CloseType=CLOSE_TYPE_TP_ONLY;              // 決済タイプ
input TP_TYPE TpType=TP_TYPE_FIXED_POINTS;                  // テイクプロフィットタイプ
input double rrr=2;                                         // TP_TYPE_RRR設定値（リスクリワードレシオ）
input uint profit_points = 100;                             // TP_TYPE_FIXED_POINTS設定値（point）
input int exit_bar_count=0;                                 // オープンからの経過バー数による強制決済（バー数を指定）
input bool exit_bar_count_profit=false;                     // 経過バー強制決済時に含み益がある場合のみ決済する
input bool exit_day=false;                                  // 当日強制決済の有効化
input bool exit_weekend=false;                              // 週末強制決済の有効化
input uint exit_shift_bar=1;                                // 当日/週末強制決済するシフトバー位置
input OPEN_TYPE force_exit_open_type=OPEN_TYPE_LONG_SHORT;  // 当日強制決済の対象とするオープンタイプ
input bool EarlyClose=false;                                // 早期決済の有効化
input int early_bar_count=0;                                // 早期決済を確認するバーカウント数
input double early_rrr=2;                                   // 早期決済するリスクリワードレシオ
input bool split_exit=false;                                // 分割決済の有効化
input double split_rrr=1;                                   // 分割決済のリスクリワードレシオ
input bool split_same_line=true;                            // 複数ポジション時分割ラインを統一

input group "◆資金管理設定"
input MONEY_TYPE MoneyType=MONEY_TYPE_MINIMUM;              // 資金管理タイプ
input double FixedLots=0.01;                                // MONEY_TYPE_FIXED_LOT設定値（固定ロット数）
input double risk=2;                                        // 資金率
input bool risk_check=false;                                // 資金率を超えた場合トレードしない
input bool DecreaseByStepvol=false;                         // MONEY_TYPE_SizeOptimized設定値（最小ロット数単位で減少）
input bool IncreaseByStepvol=false;                         // MONEY_TYPE_SizeOptimized設定値（最小ロット数単位で増加）
input bool DecreaseReset=false;                             // MONEY_TYPE_SizeOptimized設定値（負けたら最小ロット数に戻す）
input double DecreaseFactor=3;                              // MONEY_TYPE_SizeOptimized設定値（資金減少係数(除数)）
input double IncreaseFactor=3;                              // MONEY_TYPE_SizeOptimized設定値（資金増加係数（除数））

input group "◆フィルタ設定"
input bool  Trade_Allow_MONDAY=true;                        // 月曜日の取引を許可する
input bool  Trade_Allow_TUESDAY=true;                       // 火曜日の取引を許可する
input bool  Trade_Allow_WEDNESDAY=true;                     // 水曜日の取引を許可する
input bool  Trade_Allow_THURSDAY=true;                      // 木曜日の取引を許可する
input bool  Trade_Allow_FRIDAY=true;                        // 金曜日の取引を許可する
input bool  Trade_Allow_SATURDAY=false;                     // 土曜日の取引を許可する
input bool  Trade_Allow_SUNDAY=false;                       // 日曜日の取引を許可する
input bool  i_Trade_Allow_Open_WeekStart=false;              // 週明け指定時間まで取引をしない
input uint  i_Trade_Allow_Open_hour=8;                       // 週明けトレード抑制を行う時間を指定
input bool  Trade_Allow_Jan=true;                           // 1月の取引を許可する
input bool  Trade_Allow_Feb=true;                           // 2月の取引を許可する
input bool  Trade_Allow_Mar=true;                           // 3月の取引を許可する
input bool  Trade_Allow_Apr=true;                           // 4月の取引を許可する
input bool  Trade_Allow_May=true;                           // 5月の取引を許可する
input bool  Trade_Allow_Jun=true;                           // 6月の取引を許可する
input bool  Trade_Allow_Jul=true;                           // 7月の取引を許可する
input bool  Trade_Allow_Aug=true;                           // 8月の取引を許可する
input bool  Trade_Allow_Sep=true;                           // 9月の取引を許可する
input bool  Trade_Allow_Oct=true;                           // 10月の取引を許可する
input bool  Trade_Allow_Nov=true;                           // 11月の取引を許可する
input bool  Trade_Allow_Dec=true;                           // 12月の取引を許可する
input bool  Trade_Allow_End_Month=true;                     // 月末の取引を許可する
input bool  Trade_Allow_Start_Month=true;                   // 月初の取引を許可する
input bool  bb_filter=false;

input group "◆経済指標設定"
input string TargetCountry="JP";                            // 国指定（カンマ区切り）　形式：ISO 3166-1 alpha-2
input string TargetCurrency="JPY";                          // 通貨指定（カンマ区切り）
input FILTER_TYPE FilterHoliday=FILTER_TYPE_OFF;            // 祝日フィルタタイプを指定
input FILTER_TYPE FilterLow=FILTER_TYPE_OFF;                // 重要度低のフィルタタイプを指定
input FILTER_TYPE FilterMid=FILTER_TYPE_OFF;                // 重要度中のフィルタタイプを指定
input FILTER_TYPE FilterHigh=FILTER_TYPE_OFF;               // 重要度高のフィルタタイプを指定
input FILTER_TYPE FilterCri=FILTER_TYPE_OFF;                // 重要度最高のフィルタタイプを指定
input FILTER_TYPE FilterGotobi=FILTER_TYPE_OFF;             // ゴトー日のフィルタタイプを指定

input group "◆トレイリングストップ設定"
input bool trail_enable=false;                              // トレイリングストップの有効化
input TRAIL_TYPE trail_type=TRAIL_TYPE_NONE;                // トレイリングストップタイプ
input double trail_coefficient=1;                           // トレイル利確幅係数
                                                            // トレイル幅算出するための係数（トレイル幅＝SL幅＊係数）　オープン価格からトレイル幅（ライン）を超えたらトレイルする
input bool trail_allow_openprice=false;                     // 算出されたSLがオープン価格を超えている場合のみトレイルする
input bool trail_allow_stoploss=false;                      // 算出されたSLが現状SLよりポジティブである場合のみトレイルする                                            
input double trail_addpoints=0;                             // トレイル幅に対してさらに距離を追加する（point）                                                            
input bool trail_same_line=true;                            // 複数ポジション時SLラインを統一
                                                            // 複数ポジションがある時、トレイル発動するラインを最初のポジションと同一とするかどうか。しない場合は各ポジションごとにトレイルラインを確認
//input ENUM_TIMEFRAMES SL_Indicator_TF=PERIOD_CURRENT;     // IndicatorPeriod(Common)
input uint trail_loss_points = 100;                         // TRAIL_TYPE_FIXED_POINTS設定値（StopLevelの固定幅（point）を指定）
input uint trail_profit_points = 100;                       // TRAIL_TYPE_FIXED_POINTS設定値（TPLevelの固定幅（point）を指定）
input uint trail_ATR_Period=14;                             // TRAIL_TYPE_ATR設定値（期間）
input double trail_SAR_Step=0.02;                           // TRAIL_TYPE_SAR設定値（Step）
input double trail_SAR_Maximum=0.02;                        // TRAIL_TYPE_SAR設定値（Maximum）
input uint trail_ZIGZAG_Depth=12;                           // TRAIL_TYPE_ZIGZAG設定値（Depth）
input uint trail_ZIGZAG_Deviation=5;                        // TRAIL_TYPE_ZIGZAG設定値（Deviation）
input uint trail_ZIGZAG_Backstep=3;                         // TRAIL_TYPE_ZIGZAG設定値（Backstep）
input uint trail_MA_Period=120;                             // TRAIL_TYPE_MA設定値（Period）
input uint trail_MA_Shift=0;                                // TRAIL_TYPE_MA設定値（Shift）
input ENUM_MA_METHOD trail_MA_Method=MODE_SMA;              // TRAIL_TYPE_MA設定値（Method）
input ENUM_APPLIED_PRICE trail_MA_AppliedPrice=PRICE_CLOSE; // TRAIL_TYPE_MA設定値（AppliedPrice）
input uint trail_bb_Period=14;                              // BollingerBand Period
input uint trail_bb_Deviation=3;                            // BollingerBnad Deviation
input uint trail_prevbar=10;                                // TRAIL_TYPE_PREVBAR設定値（バーシフト数）

input group "◆ピラミッディング設定"
input bool pyramid_enable=false;                            // ピラミッディングの有効化
input uint pyramid_max_counts=3;                            // 最大買い増し数
input double pyramid_coefficient=0.5;                       // ピラミッディング幅係数
input bool pyramid_close_enable=false;                      // ピラミッディング時にポジション決済
input bool pyramid_same_money=true;                         // 初期ロットでピラミッディング
input bool pyramid_same_sl=true;                            // 初期SLでピラミッディング
input bool pyramid_same_tp=true;                            // 初期TPでピラミッディング