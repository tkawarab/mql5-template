#ifndef ExpertMain
#include <tk\strategy\Template.mqh>
#include <tk\com\MyExpert.mqh>
#include <tk\com\Portfolio.mqh>
#include <tk\lib\File.mqh>
#endif 


string setup_txt, symbols_txt, periods_txt, tester_txt;
string error_symbols[];
CPortfolio portfolio(ProjectName);
CArrayString *array_setup;
CArrayString *array_symbols;
CArrayString *array_periods;
CArrayString *array_tester;

void PutFilePath(){
   setup_txt = "projects\\" + ProjectName + "\\" + env_name + "\\portfolio\\setup.txt";
   symbols_txt = "projects\\" + ProjectName + "\\" + env_name + "\\portfolio\\symbols.txt";  // --> Path=C:\Users\tkawa\AppData\Roaming\MetaQuotes\Terminal\Common\Files
   periods_txt = "projects\\" + ProjectName + "\\" + env_name + "\\portfolio\\periods.txt";
   tester_txt = "#tester.txt";
}

void LoadFile(){

   CDataFile *symbols_txt_file = new CDataFile(symbols_txt,false);
   array_symbols = symbols_txt_file.read();
   CDataFile *periods_txt_file = new CDataFile(periods_txt,false);
   array_periods = periods_txt_file.read();
   CDataFile *tester_txt_file = new CDataFile(tester_txt,false);
   array_tester = tester_txt_file.read();

   delete symbols_txt_file;
   delete periods_txt_file;
   delete tester_txt_file;
}

void CreatePortfolio(){

   string symbol;
   string period;

   // Load Symbols file
   for(int i=0; i<array_symbols.Total(); i++){
      symbol = array_symbols.At(i);
      if(portfolio.IsExistSymbol(symbol)) continue;
      if(StringSubstr(symbol,0,2)=="//") continue;
      // Load Periods file
      for(int i2=0; i2<array_periods.Total(); i2++){
         period = array_periods.At(i2);
         if(StringSubstr(period,0,2)=="//") continue;
            int bar_check = iBarShift(symbol,get_period(period),iTime(symbol,get_period(period),0),true);
            if(bar_check==-1) continue;                                 
            CMyExpert *expert = CreateExpert(symbol,get_period(period));

            // Load Tester file
            if(MQLInfoInteger(MQL_TESTER)){
               string col[2];
               string check_symbol;
               datetime tester_start;
               bool  find=false;
               for(int i3=0; i3<array_tester.Total(); i3++){
                  string rec = array_tester.At(i3);
                  StringSplit(rec,StringGetCharacter(",",0),col);
                  check_symbol = col[0];
                  if(check_symbol==symbol){
                     tester_start = StringToTime(col[1]);
                     expert.InitTester(tester_start);
                     find = true;
                  }
               }
               if(!find) {
                  int size = ArraySize(error_symbols);
                  expert.InitTester(StringToTime("3000/12/31"));
                  bool error_find = false;
                  for(int i4=0; i4<size; i4++){
                     if(error_symbols[i4]==symbol) error_find = true;
                  }
                  if(!error_find){
                     ArrayResize(error_symbols,size+1);
                     error_symbols[size] = symbol;
                  }
               }
            }  
                      
            SetPortfolio(expert);
      }
   }

   if(!MQLInfoInteger(MQL_TESTER)) {
      delete array_symbols;
      delete array_periods;
      delete array_tester;     
   }
}

CMyExpert* CreateExpert(string symbol,ENUM_TIMEFRAMES period){
   CMyExpert *expert = new CMyExpertStrategy;
   //init(expert,symbol,period);
   expert.Init(symbol,period);
   return expert;
}

void SetPortfolio(CMyExpert* expert){
   expert.InitReport(); 
   portfolio.AddExpert(expert);
}


void LoadFile_SetupTxt(){

   CDataFile *setup_txt_file = new CDataFile(setup_txt,false);
   array_setup = setup_txt_file.read();
   CDataFile *tester_txt_file = new CDataFile(tester_txt,false);
   array_tester = tester_txt_file.read();

   delete setup_txt_file;
   delete tester_txt_file;
}

void CreatePortfolio_SetupTxt(){

   string setup;
   string symbol;
   string period;
   OPEN_TYPE open_type;
   OPERATION_TYPE operation_type;

   // Load Setup file
   for(int i=0; i<array_setup.Total(); i++){
      setup = array_setup.At(i);
      string rec[];
      StringSplit(setup,StringGetCharacter(",",0),rec);
      if(ArraySize(rec)<3) {
         Print("Error: An empty value was found in setup.txt. line:" + IntegerToString(i));
         continue;
      }
      if(rec[0]=="") {
         Print("Error: An empty symbol name was found in setup.txt. line:" + IntegerToString(i));
         continue;      
      } else {
         symbol = rec[0];
      }
      if(rec[1]=="") {
         period = "PERIOD_CURRENT";
      } else {
         period = rec[1];
         int bar_check = iBarShift(symbol,get_period(period),iTime(symbol,get_period(period),0),true);
         if(bar_check==-1) continue;     
      }
           
      if(rec[2]=="OPEN_TYPE_LONG"){
         open_type = OPEN_TYPE_LONG;
      } else if(rec[2]=="OPEN_TYPE_SHORT"){
         open_type = OPEN_TYPE_SHORT;      
      } else if(rec[2]=="OPEN_TYPE_LONG_SHORT"){
         open_type = OPEN_TYPE_LONG_SHORT;
      } else {
         Print("Error: An empty open type was found in setup.txt. line:" + IntegerToString(i));
         continue;
      }
      
      if(rec[3]=="OPERATION_TYPE_ALL"){
         operation_type = OPERATION_TYPE_ALL;
      } else if(rec[3]=="OPERATION_TYPE_CLOSE"){
         operation_type = OPERATION_TYPE_CLOSE;     
      } else if(rec[3]=="OPERATION_TYPE_OPEN"){
         operation_type = OPERATION_TYPE_OPEN;
      } else if(rec[3]=="OPERATION_TYPE_CLOSE_NOW"){
         operation_type = OPERATION_TYPE_CLOSE_NOW;
      } else {
         Print("Error: An empty operation type was found in setup.txt. line:" + IntegerToString(i));
         continue;
      }
            
      double reinit_rrr,reinit_sl_coefficient;
      if(rec[4]==""){
         Print("Error: An empty sl coefficient value was found in setup.txt. line:" + IntegerToString(i));
         continue;         
      } else {
         reinit_sl_coefficient = StringToDouble(rec[4]);
      }
      
      if(rec[5]==""){
         Print("Error: An empty rrr value was found in setup.txt. line:" + IntegerToString(i));
         continue;         
      } else {
         reinit_rrr = StringToDouble(rec[5]);
      }      
      
      if(portfolio.IsExistSymbolPeriodOpentype(symbol,get_period(period),open_type)) continue;
      if(StringSubstr(symbol,0,2)=="//") continue;
      CMyExpert *expert = CreateExpert(symbol,get_period(period));
      expert.InitOpen(open_type,Spread_Limit_Points,sleep_bar_count);
      expert.InitMagic(MagicNumber);
      expert.InitOperationType(operation_type);
      expert.InitClose(CloseType,reinit_rrr,exit_bar_count,exit_weekend);
      //expert.InitSl(SlType,loss_points,reinit_sl_coefficient,trail_enable,trail_coefficient,trail_same_line);
      
      if(ArraySize(rec)>6){
         string params[];     
         ArrayResize(params,ArraySize(rec)-6);
         ArrayCopy(params,rec,0,6);
         expert.InitOptionParams(params);
      }

      // Load Tester file
      if(MQLInfoInteger(MQL_TESTER)){
         string col[2];
         string check_symbol;
         datetime tester_start;
         bool  find=false;
         for(int i3=0; i3<array_tester.Total(); i3++){
            string tester_rec = array_tester.At(i3);
            StringSplit(tester_rec,StringGetCharacter(",",0),col);
            check_symbol = col[0];
            if(check_symbol==symbol){
               tester_start = StringToTime(col[1]);
               expert.InitTester(tester_start);
               find = true;
            }
         }
         if(!find) {
            int size = ArraySize(error_symbols);
            expert.InitTester(StringToTime("3000/12/31"));
            bool error_find = false;
            for(int i4=0; i4<size; i4++){
               if(error_symbols[i4]==symbol) error_find = true;
            }
            if(!error_find){
               ArrayResize(error_symbols,size+1);
               error_symbols[size] = symbol;
            }
         }
      }  
      
      SetPortfolio(expert);   
   }

   if(!MQLInfoInteger(MQL_TESTER)) {
      delete array_setup;
      delete array_tester;     
   }
}


bool OnInitCommon(){
   if(MQLInfoInteger(MQL_TESTER)) {
      env_name = "dev";
   } else if((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO){
      env_name = "stg";
   } else if((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL){
      env_name = "prd";
   }
   Print("# ProjectName:" + ProjectName);
   Print("# Environment:" + env_name);
   PutFilePath();
     
   if(MQLInfoInteger(MQL_TESTER)) EventSetTimer(PeriodSeconds()); 

   if(portfolio_mode==PORTFOLIO_SYMBOLS_PERIODS_FILE){
      if(!(FileIsExist(symbols_txt,FILE_COMMON))) {
         Print(__FUNCTION__ + ": symbols.txt not found.");
         return false;
      }
      if(!(FileIsExist(periods_txt,FILE_COMMON))) {
         Print(__FUNCTION__ + ": periods.txt not found.");
         return false;
      }      
      LoadFile();
      CreatePortfolio();
   } else if(portfolio_mode==PORTFOLIO_SETUP_FILE){
      if(!(FileIsExist(setup_txt,FILE_COMMON))) {
         Print(__FUNCTION__ + ": setup.txt not found.");
         return false;
      }  
      LoadFile_SetupTxt();
      CreatePortfolio_SetupTxt();   
   } else if(portfolio_mode==PORTFOLIO_DISABLE) {
      //CMyExpert *expert = CreateExpert(_Symbol,_Period);      
      CMyExpert *expert = CreateExpert(_Symbol,Base_Period);      
      SetPortfolio(expert);
   }
   return true;
}

void OnDeinitCommon(){
   Print("## Portfolio num:",portfolio.Total());
   portfolio.PrintDescription();
   for(int i=0; i<ArraySize(error_symbols); i++){
      Print("## ErrorSymbol:",error_symbols[i]);
   }
   if(MQLInfoInteger(MQL_TESTER)) {
      delete array_symbols;
      delete array_periods;
      delete array_tester;     
      EventKillTimer();
   }
   portfolio.OnDeinit();

}