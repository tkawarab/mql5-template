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
//| Class=CMoneyFixedRisk                                            |
//| Page=                                                            |
//| Parameter=Percent,double,10.0,Risk percentage                    |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CMoneyFixedRisk.                                           |
//| Purpose: Class of money management with fixed percent risk.      |
//|              Derives from class CExpertMoney.                    |
//+------------------------------------------------------------------+
class CMoneyFixedRisk : public CExpertMoney
  {
private:
   bool              m_decrease_reset;
public:
                     CMoneyFixedRisk(void);
                    ~CMoneyFixedRisk(void);
   //---
   virtual double    CheckOpenLong(double price,double sl);
   virtual double    CheckOpenShort(double price,double sl);
   virtual double    CheckClose(CPositionInfo *position) { return(0.0); }
   void              DecreaseReset(bool enable){ m_decrease_reset = enable; }
protected:
   double            Optimize(double lots);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CMoneyFixedRisk::CMoneyFixedRisk(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CMoneyFixedRisk::~CMoneyFixedRisk(void)
  {
  }
//+------------------------------------------------------------------+
//| Getting lot size for open long position.                         |
//+------------------------------------------------------------------+
double CMoneyFixedRisk::CheckOpenLong(double price,double sl)
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
   return(lot);
  }
//+------------------------------------------------------------------+
//| Getting lot size for open short position.                        |
//+------------------------------------------------------------------+
double CMoneyFixedRisk::CheckOpenShort(double price,double sl)
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
   Optimize(lot);
   return(lot);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Optimizing lot size for open.                                    |
//+------------------------------------------------------------------+
double CMoneyFixedRisk::Optimize(double lots)
  {
   double lot=lots;
//--- calculate number of losses orders without a break

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
      if(profits>=1)  //
         return lot;
            
      if(losses>=1)  // 一敗目から減少するように演算子を変更
         if(m_decrease_reset){
            lot=m_symbol.LotsMin(); // 前回負けの場合は最小ロットにする
         }



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
