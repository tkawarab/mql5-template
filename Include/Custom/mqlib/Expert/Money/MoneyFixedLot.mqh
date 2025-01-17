//+------------------------------------------------------------------+
//|                                                MoneyFixedLot.mqh |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <tk\mqlib\Expert\ExpertMoney.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trading with fixed trade volume                            |
//| Type=Money                                                       |
//| Name=FixLot                                                      |
//| Class=CMoneyFixedLot                                             |
//| Page=                                                            |
//| Parameter=Percent,double,10.0,Percent                            |
//| Parameter=Lots,double,0.1,Fixed volume                           |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CMoneyFixedLot.                                            |
//| Purpose: Class of money management with fixed lot.               |
//|              Derives from class CExpertMoney.                    |
//+------------------------------------------------------------------+
class CMoneyFixedLot : public CExpertMoney
  {
protected:
   //--- input parameters
   double            m_lots;
   bool              m_decrease_by_stepvol;
   bool              m_increase_by_stepvol;
   bool              m_decrease_reset;
public:
                     CMoneyFixedLot(void);
                    ~CMoneyFixedLot(void);
   //---
   void              DecreaseByStepvol(bool enable) { m_decrease_by_stepvol=enable; }   
   void              IncreaseByStepvol(bool enable) { m_increase_by_stepvol=enable; }   
   void              DecreaseReset(bool enable) { m_decrease_reset=enable; }   
   void              Lots(double lots)                      { m_lots=lots; }
   virtual bool      ValidationSettings(void);
   //---
   virtual double    CheckOpenLong(double price,double sl)  { return(Optimize(m_lots)); }
   virtual double    CheckOpenShort(double price,double sl) { return(Optimize(m_lots)); }
protected:
   double            Optimize(double lots);    
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CMoneyFixedLot::CMoneyFixedLot(void) : m_lots(0.1)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CMoneyFixedLot::~CMoneyFixedLot(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CMoneyFixedLot::ValidationSettings(void)
  {
   if(!CExpertMoney::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_lots<m_symbol.LotsMin() || m_lots>m_symbol.LotsMax())
     {
      printf(__FUNCTION__+": lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
      return(false);
     }
   if(MathAbs(m_lots/m_symbol.LotsStep()-MathRound(m_lots/m_symbol.LotsStep()))>1.0E-10)
     {
      printf(__FUNCTION__+": lots amount is not corresponding with lot step %f",m_symbol.LotsStep());
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Optimizing lot size for open.                                    |
//+------------------------------------------------------------------+
double CMoneyFixedLot::Optimize(double lots)
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
      if(losses>=1)  // 一敗目から減少するように演算子を変更
         if(m_decrease_reset){
            lot=m_symbol.LotsMin(); // 前回負けの場合は最小ロットにする
         } else {
            if(m_decrease_by_stepvol){
               lot=lot+(losses*m_symbol.LotsStep());
            } 
        }
      if(profits>=1)  //
         if(m_increase_by_stepvol){
            lot=lot+(profits*m_symbol.LotsStep());
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
