#property version   "1.00"
#define  ExpertMain
#include <tk\com\MyExpert.mqh>
#include <tk\com\Portfolio.mqh>
#include <tk\com\Init.mqh>
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//                          Common 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("##### Initialize STARTED #####");
   OnInitCommon();
   Print("##### Initialize ENDED #####");
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   Print("##### Deinitialize STARTED #####");
   OnDeinitCommon();
   Print("##### Deinitialize ENDED #####");
  }
void OnTimer(){
   if(!MQLInfoInteger(MQL_TESTER)) return;
   if(portfolio_mode==PORTFOLIO_SYMBOLS_PERIODS_FILE) CreatePortfolio();
   if(portfolio_mode==PORTFOLIO_SETUP_FILE) CreatePortfolio_SetupTxt();
   portfolio.OnTick();
}
void OnTick()
  {
   if(MQLInfoInteger(MQL_TESTER)) return;
   portfolio.OnTick();
  }
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   portfolio.OnTradeTransaction(trans,request,result);
  }
double OnTester(){
   double win_trade = TesterStatistics(STAT_PROFIT_TRADES);
   double total_trade = TesterStatistics(STAT_TRADES);
   return NormalizeDouble((win_trade / total_trade) * 100,2);
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//                          Strategy 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

input group "◆ストラテジー設定"
input double min_distance_points_ma_fast_mid = 0;  // 短期-中期線間の最小距離
input double min_distance_points_ma_mid_slow = 0;  // 中期-長期線間の最小距離
input double min_distance_points_c_ma_slow = 0; // 終足-長期線間の最小距離
input double max_distance_points_c_ma_slow = 0; // 終足-長期線間の最大距離
input bool   rsi_check = false;                 // RSI
input uint   rsi_lower_thresold = 80;           // RSI下限値
input uint   rsi_upper_thresold = 20;           // RSI上限値

class CMyExpertStrategy : public CMyExpert{
   private:
      CiMA           fast_ma;
      CiMA           mid_ma;
      CiMA           slow_ma;
      CiRSI          rsi;
   protected:
      virtual  void  InitIndicator();
      virtual  void  RefreshIndicator();
      virtual  bool  CheckOpen(ENUM_ORDER_TYPE order_type);
      virtual  bool  CheckClose(ENUM_ORDER_TYPE order_type);
   protected:
      virtual  void  OnCloseAll();
      virtual  void  OnStoploss();
      virtual  void  OnTakeprofit();
      virtual  void  OnExpert();
};

bool CMyExpertStrategy::CheckOpen(ENUM_ORDER_TYPE order_type){
   // 逆張りエントリー時シグナルチェックの方向を反転させる
   if(Trade_Reverse){
      if(order_type==ORDER_TYPE_BUY){
         order_type = ORDER_TYPE_SELL;
      } else if(order_type==ORDER_TYPE_SELL){
         order_type = ORDER_TYPE_BUY;
      }
   }

   double c = iClose(m_symbol_name,m_period,1);

   double distance_points_ma_fast_mid = price2point(MathAbs(fast_ma.Main(1) - mid_ma.Main(1)),_Point);
   double distance_points_ma_mid_slow = price2point(MathAbs(mid_ma.Main(1) - slow_ma.Main(1)),_Point);
   double distance_points_c_ma_slow = price2point(MathAbs(c - slow_ma.Main(1)),_Point);

   if(distance_points_ma_fast_mid<min_distance_points_ma_fast_mid) return false;
   if(distance_points_ma_mid_slow<min_distance_points_ma_mid_slow) return false;

   if(distance_points_c_ma_slow<min_distance_points_c_ma_slow) return false;
   if(max_distance_points_c_ma_slow>0&&distance_points_c_ma_slow>max_distance_points_c_ma_slow) return false;
  
   if(order_type==ORDER_TYPE_BUY){

      if(!(c>mid_ma.Main(1))) return false;     
      if(!(fast_ma.Main(1)>mid_ma.Main(1))) return false;
      if(!(mid_ma.Main(1)>slow_ma.Main(1))) return false;   
      if(rsi_check&&rsi.Main(1)<rsi_lower_thresold) return false;

   } else if(order_type==ORDER_TYPE_SELL){
      if(!(c<mid_ma.Main(1))) return false;   
      if(!(fast_ma.Main(1)<mid_ma.Main(1))) return false;
      if(!(mid_ma.Main(1)<slow_ma.Main(1))) return false;
      if(rsi_check&&rsi.Main(1)>rsi_upper_thresold) return false;
   }

   return true;
}

bool CMyExpertStrategy::CheckClose(ENUM_ORDER_TYPE order_type){
   // 逆張りエントリー時シグナルチェックの方向を反転させる
   if(Trade_Reverse){
      if(order_type==ORDER_TYPE_BUY){
         order_type = ORDER_TYPE_SELL;
      } else if(order_type==ORDER_TYPE_SELL){
         order_type = ORDER_TYPE_BUY;
      }
   }
   
   double cl = iClose(m_symbol_name,m_period,1);
   bool flg = false;

      int bar = iBarShift(m_symbol_name,m_period,m_position.Time());
      if(bar<0) {
         Print("Close Logic Error");
      }
      
   if(order_type==ORDER_TYPE_BUY){
      if(cl<mid_ma.Main(1)) return true;
   } else if(order_type==ORDER_TYPE_SELL){
      if(cl>mid_ma.Main(1)) return true;
   }
   return false;
}

void  CMyExpertStrategy::OnCloseAll(void){}
void  CMyExpertStrategy::OnStoploss(void){}
void  CMyExpertStrategy::OnExpert(void){}
void  CMyExpertStrategy::OnTakeprofit(void){}

void  CMyExpertStrategy::InitIndicator(){
   TesterHideIndicators(true);
   TesterHideIndicators(false);
   fast_ma.Create(m_symbol_name,m_period,8,0,MODE_SMA,PRICE_CLOSE);
   mid_ma.Create(m_symbol_name,m_period,20,0,MODE_SMA,PRICE_CLOSE);
   slow_ma.Create(m_symbol_name,m_period,120,0,MODE_SMA,PRICE_CLOSE);
   rsi.Create(m_symbol_name,m_period,14,PRICE_CLOSE);
}

void CMyExpertStrategy::RefreshIndicator(){
   fast_ma.Refresh();
   mid_ma.Refresh();
   slow_ma.Refresh();
   rsi.Refresh();
}
