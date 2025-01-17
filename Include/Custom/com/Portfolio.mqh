#property version   "1.00"
#ifndef ExpertMain
#include <tk\com\MyExpert.mqh>
#include <tk\com\Input.mqh>
#endif

#include <Arrays\ArrayObj.mqh>
class CPortfolio
  {
private:
   CArrayObj         m_experts;
   int    file_handle;
   string            m_project_name;
public:
                     CPortfolio(string project_name);
                    ~CPortfolio();
   bool              AddExpert(CMyExpert *expert);
   int               Total(){ return m_experts.Total(); }
   void              PrintDescription();
   void              OnTick();
   void              OnDeinit();
   void              OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& request,const MqlTradeResult& result);
   bool              IsExistSymbol(string arg_Symbol);
   bool              IsExistSymbolPeriod(string arg_Symbol,ENUM_TIMEFRAMES arg_Period);
   bool              IsExistSymbolPeriodOpentype(string arg_Symbol,ENUM_TIMEFRAMES arg_Period,OPEN_TYPE arg_OpenType);      
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPortfolio::CPortfolio(string arg_ProjectName)
  {
   m_project_name = arg_ProjectName;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPortfolio::~CPortfolio()
  {
  }
//+------------------------------------------------------------------+

bool CPortfolio::AddExpert(CMyExpert *expert){
//--- check pointer
   if(expert==NULL)
      return(false);
   
//--- add the filter to the array of filters
   if(!m_experts.Add(expert))
      return(false);
//--- succeed
   return(true);

}


void CPortfolio::OnTick(){
   int total = m_experts.Total();
   
   for(int i=0; i<total; i++){
      CMyExpert *expert=m_experts.At(i);
      expert.OnTick();
   }
}

void CPortfolio::OnDeinit(){
   int total = m_experts.Total();
   for(int i=total-1; i>=0; i--){
      CMyExpert *expert=m_experts.At(i);      
      string magic = IntegerToString(expert.Magic());
      string symbol = expert.Symbol();
      string period = EnumToString(expert.Period());
      string opentype = EnumToString((OPEN_TYPE)expert.OpenType());
      Print(magic + " " + symbol + " " + period + " " + opentype + "# Delete portfolio");
      m_experts.Delete(i);
   }
   m_experts.Shutdown();
}

void CPortfolio::OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result){
   int total = m_experts.Total();
   for(int i=0; i<total; i++){
      CMyExpert *expert=m_experts.At(i);
      expert.OnTradeTransaction(trans,request,result);
   }
   
}

void CPortfolio::PrintDescription(void){
   int total = m_experts.Total();
   
   for(int i=0; i<total; i++){
      CMyExpert *expert=m_experts.At(i);
      Print("Portfolio#" + IntegerToString(i+1) + " Symbol:" + expert.Symbol() + " Period:" + EnumToString(expert.Period()));
   }

}


bool CPortfolio::IsExistSymbol(string arg_Symbol){
   int total = m_experts.Total();
   for(int i=0; i<total; i++){
      CMyExpert *expert=m_experts.At(i);
      if(arg_Symbol==expert.Symbol()) return true;
   }
   return false;
}

bool CPortfolio::IsExistSymbolPeriod(string arg_Symbol,ENUM_TIMEFRAMES arg_Period){
   int total = m_experts.Total();
   for(int i=0; i<total; i++){
      CMyExpert *expert=m_experts.At(i);
      if(arg_Symbol==expert.Symbol()) {
         if(arg_Period==expert.Period()) return true;
      }
   }
   return false;
}

bool CPortfolio::IsExistSymbolPeriodOpentype(string arg_Symbol,ENUM_TIMEFRAMES arg_Period,OPEN_TYPE arg_OpenType){
   int total = m_experts.Total();
   for(int i=0; i<total; i++){
      CMyExpert *expert=m_experts.At(i);
      if(arg_Symbol==expert.Symbol()) {
         if(arg_Period==expert.Period()) {
            if(arg_OpenType==expert.OpenType()) return true;
            if(arg_OpenType==OPEN_TYPE_LONG){
               if(expert.OpenType()==OPEN_TYPE_LONG||expert.OpenType()==OPEN_TYPE_LONG_SHORT){
                  Print(arg_Symbol + " " + EnumToString(arg_Period) + " " + EnumToString(arg_OpenType) + "# already exists order type. pre-set order type:" + EnumToString(expert.OpenType()));
                  return true;
               }
            } else if(arg_OpenType==OPEN_TYPE_SHORT){
               if(expert.OpenType()==OPEN_TYPE_SHORT||expert.OpenType()==OPEN_TYPE_LONG_SHORT){
                  Print(arg_Symbol + " " + EnumToString(arg_Period) + " " + EnumToString(arg_OpenType) + "# already exists order type. pre-set order type:" + EnumToString(expert.OpenType()));
                  return true;
               }            
            } else if(arg_OpenType==OPEN_TYPE_LONG_SHORT){
               if(expert.OpenType()==OPEN_TYPE_LONG||expert.OpenType()==OPEN_TYPE_SHORT){
                  Print(arg_Symbol + " " + EnumToString(arg_Period) + " " + EnumToString(arg_OpenType) + "# already exists order type. pre-set order type:" + EnumToString(expert.OpenType()));
                  return true;
               }            
            }
         }
      }
   }
   return false;
}
