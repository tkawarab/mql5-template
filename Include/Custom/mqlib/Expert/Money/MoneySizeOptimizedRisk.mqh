//+------------------------------------------------------------------+
//|                                               MoneyFixedRisk.mqh |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <tk\mqlib\Expert\ExpertMoney.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trading with fixed risk                                    |
//| Type=Money                                                       |
//| Name=FixRisk                                                     |
//| Class=CMoneySizeOptimizedRisk                                            |
//| Page=                                                            |
//| Parameter=Percent,double,10.0,Risk percentage                    |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CMoneySizeOptimizedRisk.                                           |
//| Purpose: Class of money management with fixed percent risk.      |
//|              Derives from class CExpertMoney.                    |
//+------------------------------------------------------------------+
class CMoneySizeOptimizedRisk : public CExpertMoney
  {
protected:
   double            m_decrease_factor;  
   double            m_increase_factor;
   bool              m_decrease_by_stepvol;
   bool              m_increase_by_stepvol;
   bool              m_decrease_reset;
public:
                     CMoneySizeOptimizedRisk(void);
                    ~CMoneySizeOptimizedRisk(void);
   //---
   void              DecreaseFactor(double decrease_factor) { m_decrease_factor=decrease_factor; }   
   void              IncreaseFactor(double increase_factor) { m_increase_factor=increase_factor; }   
   void              DecreaseByStepvol(bool enable) { m_decrease_by_stepvol=enable; }   
   void              IncreaseByStepvol(bool enable) { m_increase_by_stepvol=enable; }   
   void              DecreaseReset(bool enable) { m_decrease_reset=enable; }
   virtual double    CheckOpenLong(double price,double sl);
   virtual double    CheckOpenShort(double price,double sl);
   virtual double    CheckClose(CPositionInfo *position) { return(0.0); }
protected:
   double            Optimize(double lots);   
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CMoneySizeOptimizedRisk::CMoneySizeOptimizedRisk(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CMoneySizeOptimizedRisk::~CMoneySizeOptimizedRisk(void)
  {
  }
//+------------------------------------------------------------------+
//| Getting lot size for open long position.                         |
//+------------------------------------------------------------------+
double CMoneySizeOptimizedRisk::CheckOpenLong(double price,double sl)
  {
   if(m_symbol==NULL)
      return(0.0);
//--- select lot size
   double lot;
   double minvol=m_symbol.LotsMin();
   if(sl==0.0)
      lot=minvol;
   else
     {
      double loss;
      if(price==0.0)
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_BUY,1.0,m_symbol.Ask(),sl);
      else
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_BUY,1.0,price,sl);
      double stepvol=m_symbol.LotsStep();
      lot=MathFloor((m_account.Balance())*m_percent/loss/100.0/stepvol)*stepvol;
     }
//---
   if(lot<minvol)
      lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(Optimize(lot));
  }
//+------------------------------------------------------------------+
//| Getting lot size for open short position.                        |
//+------------------------------------------------------------------+
double CMoneySizeOptimizedRisk::CheckOpenShort(double price,double sl)
  {
   if(m_symbol==NULL)
      return(0.0);
//--- select lot size
   double lot;
   double minvol=m_symbol.LotsMin();
   if(sl==0.0)
      lot=minvol;
   else
     {
      double loss;
      if(price==0.0)
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_SELL,1.0,m_symbol.Bid(),sl);
      else
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_SELL,1.0,price,sl);
      double stepvol=m_symbol.LotsStep();
      lot=MathFloor(m_account.Balance()*m_percent/loss/100.0/stepvol)*stepvol;
     }
//---
   if(lot<minvol)
      lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(Optimize(lot));
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Optimizing lot size for open.                                    |
//+------------------------------------------------------------------+
double CMoneySizeOptimizedRisk::Optimize(double lots)
  {
   double lot=lots;
//--- calculate number of losses orders without a break
//   if(m_decrease_factor>0)
//     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int       orders=HistoryDealsTotal();  // total history deals
      int       losses=0;                    // number of consequent losing orders
      int       profits=0;
      CDealInfo deal;
      //---
      for(int i=orders-1;i>=0;i--)
        {
         deal.Ticket(HistoryDealGetTicket(i));
         if(deal.Ticket()==0)
           {
            Print("CMoneySizeOptimized::Optimize: HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(deal.Symbol()!=m_symbol.Name())
            continue;
         //--- check profit
         double profit=deal.Profit();
         if(profit>0.0){
            if(losses>0) break;
            profits++;
         }
         if(profit<0.0){
            if(profits>0) break;
            losses++;
         }
        }
      //---
      if(losses>=1)  // 一敗目から減少するように演算子を変更
         if(m_decrease_reset){
            lot=m_symbol.LotsMin(); // 前回負けの場合は最小ロットにする
         } else {
            if(m_decrease_by_stepvol){
               lot=lot+(losses*m_symbol.LotsStep());
            } else {
               lot=NormalizeDouble(lot-lot*losses/m_decrease_factor,2);
            }
        }
      if(profits>=1)  //
         if(m_increase_by_stepvol){
            lot=lot+(profits*m_symbol.LotsStep());
         } else {
            lot=NormalizeDouble(lot+lot*profits/m_increase_factor,2);        
         }
//     }
//--- normalize and check limits
   double stepvol=m_symbol.LotsStep();
   lot=stepvol*NormalizeDouble(lot/stepvol,0);
//---
   double minvol=m_symbol.LotsMin();
   if(lot<minvol)
      lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//---
   return(lot);
  }
//+------------------------------------------------------------------+
