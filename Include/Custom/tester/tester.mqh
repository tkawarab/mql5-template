#include <Math\Stat\Math.mqh>
enum TesterOptimize
  {
   PRR,
   PRR_RV,
   WinR
  };
//+------------------------------------------------------------------+
//| OnTester                                                         |
//+------------------------------------------------------------------+
input group    "◆最適化カスタム指標"
input TesterOptimize tester_optimize_type=PRR;
input bool Carry = true; // 最適化するときに計算結果に100をかける

double OnTesterCommon()
{
   double ret=0;
   if(tester_optimize_type==PRR){
      ret=OnTesterPRR();
   } else if(tester_optimize_type==PRR_RV){
      ret=OnTesterPRR_RV();
   } else if(tester_optimize_type==WinR){
      ret=OnTesterWINR();
   }
   return ret;
}

//+------------------------------------------------------------------+
//|  悲観的リターンレシオ(PRR)
//|  https://qiita.com/aisaki180507/items/a86e6f667d6e56bf17c9
//+------------------------------------------------------------------+
double OnTesterPRR()
{
  const int dig = 2;   // ←悲観的リターンレシオを小数点以下何桁まで表示するか
  double n, PF, PRR;

//--- プロフィットファクターと取引回数
  PF = TesterStatistics(STAT_PROFIT_FACTOR);
  n  = TesterStatistics(STAT_TRADES);

//--- 悲観的リターンレシオの計算
  PRR = PF / ((n + 1.96 * sqrt(n)) / (n - 1.96 * sqrt(n)));

//--- 桁数の設定
  PRR = MathRound(PRR, dig);
  
//--- 最適化のときにのみ結果に100をかける(MT5のバグ対策)
  if(Carry == true && MQLInfoInteger(MQL_OPTIMIZATION))
    PRR *= 100;

  return PRR;
}

//+------------------------------------------------------------------+
//|  ラルフビンスの悲観的リターンレシオ(PRR)
//|　　考え方は同じで上より少し楽観的な結果になる
//|  https://qiita.com/aisaki180507/items/a86e6f667d6e56bf17c9
//+------------------------------------------------------------------+
double OnTesterPRR_RV()
{
  const int dig = 2;   // ←悲観的リターンレシオを小数点以下何桁まで表示するか

  double PT = 0, LT = 0, PRR = 0;

//--- 勝トレード数と負トレード数
  PT = TesterStatistics(STAT_PROFIT_TRADES);
  LT = TesterStatistics(STAT_LOSS_TRADES);

//--- 悲観的リターンレシオの計算
  PT = (PT - sqrt(PT)) * (TesterStatistics(STAT_GROSS_PROFIT) / PT);
  LT = (LT + sqrt(LT)) * (-TesterStatistics(STAT_GROSS_LOSS) / LT);
  PRR = PT / LT;

//--- 桁数の設定
  PRR = MathRound(PRR, dig);

//--- 最適化のときにのみ結果に100をかける(MT5のバグ対策)
  if(Carry == true && MQLInfoInteger(MQL_OPTIMIZATION))
    PRR *= 100;

  return PRR;
}

double OnTesterWINR()
{
   double win_trade = TesterStatistics(STAT_PROFIT_TRADES);
   double total_trade = TesterStatistics(STAT_TRADES);
   return NormalizeDouble((win_trade / total_trade) * 100,2);
}