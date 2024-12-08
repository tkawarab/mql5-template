//+------------------------------------------------------------------+
//|                                            TrailingFixedPips.mqh |
//|                             Copyright 2000-2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
// wizard description start
//+----------------------------------------------------------------------+
//| Description of the class                                             |
//| Title=Trailing Stop based on fixed Stop Level                        |
//| Type=Trailing                                                        |
//| Name=FixedPips                                                       |
//| Class=CTrailingPrevBar                                             |
//| Page=                                                                |
//| Parameter=StopLevel,int,30,Stop Loss trailing level (in points)      |
//| Parameter=ProfitLevel,int,50,Take Profit trailing level (in points)  |
//+----------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CTrailingPrevBar.                                        |
//| Purpose: Class of trailing stops with fixed stop level in pips.  |
//|              Derives from class CExpertTrailing.                 |
//+------------------------------------------------------------------+
class CTrailingPrevBar : public CExpertTrailing
  {
protected:
   //--- input parameters
   int               m_prev_bar;

public:
                     CTrailingPrevBar(void);
                    ~CTrailingPrevBar(void);
   //--- methods of initialization of protected data
   void              PrevBar(int prev_bar)     { m_prev_bar=prev_bar;     }
   virtual bool      ValidationSettings(void);
   //---
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CTrailingPrevBar::CTrailingPrevBar(void) : m_prev_bar(10)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTrailingPrevBar::~CTrailingPrevBar(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CTrailingPrevBar::ValidationSettings(void)
  {

//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingPrevBar::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---
   double level =NormalizeDouble(m_symbol.Bid()-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   double new_sl=NormalizeDouble(iLow(_Symbol,PERIOD_CURRENT,m_prev_bar),m_symbol.Digits());
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl>base && new_sl<level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTrailingPrevBar::CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---
   double level =NormalizeDouble(m_symbol.Ask()+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   double new_sl=NormalizeDouble(iHigh(_Symbol,PERIOD_CURRENT,m_prev_bar),m_symbol.Digits());
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl<base && new_sl>level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
