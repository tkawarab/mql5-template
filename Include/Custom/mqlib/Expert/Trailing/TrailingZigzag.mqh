//+------------------------------------------------------------------+
//|                                         TrailingParabolicSAR.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Custom.mqh>
#include <tk\mqlib\Indicators\Zigzag.mqh>
#include <tk\lib\Function.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trailing Stop based on ZigZag                              |
//| Type=Trailing                                                    |
//| Name=Zigzag                                                      |
//| Class=CTrailingZigzag                                            |
//| Page=                                                            |
//| Parameter=Step,double,0.02,Speed increment                       |
//| Parameter=Maximum,double,0.2,Maximum rate                        |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CTrailingZigzag.                                             |
//| Appointment: Class traling stops with Parabolic SAR.             |
//| Derives from class CExpertTrailing.                              |
//+------------------------------------------------------------------+
class CTrailingZigzag : public CExpertTrailing
  {
private:
   double               zig_point(int num);
   int                  zig_bar(int num);
   int                  zig_bar_high(int num);
   double               zig_point_high(int num);
   double               zig_point_low(int num);
   int                  m_Depth;
   int                  m_Deviation;
   int                  m_Backstep;
   double               m_Addpoints;
protected:
   int                  m_zig_handle;
   double               m_zig_buf[];  
   CiZigZag             m_zg;
public:
                     CTrailingZigzag(void);
                    ~CTrailingZigzag(void);

   //--- method of creating the indicator and timeseries
   virtual bool      SetParam(int arg_Depth=12,int arg_Deviation=5,int arg_BackStep=3,double arg_Addpoints=0);
   virtual bool      InitIndicators(CIndicators *indicators);
   //---
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CTrailingZigzag::CTrailingZigzag(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CTrailingZigzag::~CTrailingZigzag(void)
  {
  }

bool CTrailingZigzag::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_zg)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_zg.Create(m_symbol.Name(),m_period,m_Depth,m_Deviation,m_Backstep))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CTrailingZigzag::SetParam(int arg_Depth=12,int arg_Deviation=5,int arg_BackStep=3,double arg_Addpoints=0)
  {

   //m_zig_handle = iCustom(m_symbol.Name(),m_period,"Examples\\ZigZag.ex5",arg_Depth,arg_Deviation,arg_BackStep);
   m_Depth = arg_Depth;
   m_Deviation = arg_Deviation;
   m_Backstep = arg_BackStep;
   m_Addpoints = arg_Addpoints;
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingZigzag::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---

   double level =NormalizeDouble(m_symbol.Bid()-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   //double new_sl=NormalizeDouble(zig_point(1),m_symbol.Digits());
   //double new_sl=NormalizeDouble(zig_point(1)-point2price(m_Addpoints,_Point),m_symbol.Digits());
   double new_sl=NormalizeDouble(zig_point_low(1)-point2price(m_Addpoints,_Point),m_symbol.Digits());
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl>base && new_sl<level) //&& new_sl>position.PriceOpen())
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTrailingZigzag::CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---
   double level =NormalizeDouble(m_symbol.Ask()+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   //double new_sl=NormalizeDouble(zig_point(1)+m_symbol.Spread()*m_symbol.Point(),m_symbol.Digits());
   //double new_sl=NormalizeDouble(zig_point(1)+point2price(m_Addpoints,_Point),m_symbol.Digits());
   double new_sl=NormalizeDouble(zig_point_high(1)+point2price(m_Addpoints,_Point),m_symbol.Digits());
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl<base && new_sl>level) //&& new_sl<position.PriceOpen())
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+

double CTrailingZigzag::zig_point(int num){
   /*
   int zig_cnt = 0;
   double zig_value = 0;
   for(int i=0; i<ArraySize(m_zig_buf); i++){
      if(m_zig_buf[i]!=0) {
         zig_cnt++;
         zig_value = m_zig_buf[i];
         if(zig_cnt==num+1) break;
      }
   } */
   
   int i=0;
   int zig_cnt = 0;
   double zig_value = 0;
   
   do{
      if(m_zg.ZigZag(i)!=0) {
         zig_cnt++;
         zig_value = m_zg.ZigZag(i);
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

int CTrailingZigzag::zig_bar(int num){
   /*
   int zig_cnt = 0;
   int zig_value = 0;
   for(int i=0; i<ArraySize(m_zig_buf); i++){
      if(m_zig_buf[i]!=0) {
         zig_cnt++;
         zig_value = i;
         if(zig_cnt==num+1) break;
      }
   } */

   int i=0;
   int zig_cnt = 0;
   int zig_value = 0;
   
   do{
      if(m_zg.ZigZag(i)!=0) {
         zig_cnt++;
         zig_value = i;
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

double CTrailingZigzag::zig_point_high(int num){
      
   int i=0;
   int zig_cnt = 0;
   double zig_value = 0;
   
   do{
      if(m_zg.High(i)!=0&&m_zg.High(i)==m_zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
      //if(m_zg.High(i)!=0) { 
         zig_cnt++;
         zig_value = m_zg.High(i);
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

int CTrailingZigzag::zig_bar_high(int num){
      
   int i=0;
   int zig_cnt = 0;
   int zig_value = 0;
   
   do{
      if(m_zg.High(i)!=0&&m_zg.High(i)==m_zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
      //if(m_zg.High(i)!=0) { 
         zig_cnt++;
         zig_value = i;
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}

double CTrailingZigzag::zig_point_low(int num){
      
   int i=0;
   int zig_cnt = 0;
   double zig_value = 0;
   
   do{
      if(m_zg.Low(i)!=0&&m_zg.Low(i)==m_zg.ZigZag(i)) {     // 2024.03.03 画面描画された確定値（Zigzag）を確認する
      //if(m_zg.Low(i)!=0) { 
         zig_cnt++;
         zig_value = m_zg.Low(i);
      }
      i++;
   } while(zig_cnt!=num+1);
   
   return zig_value;
}