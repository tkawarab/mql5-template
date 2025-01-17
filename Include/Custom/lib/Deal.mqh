#ifndef ExpertMain
#include <stdlib.mqh>
#include <Trade\DealInfo.mqh>
#endif


CDealInfo g_deal;

bool deal_ticket_to_positionid(ulong deal_ticket,ulong &ret_posid){
   // 約定チケットからPositionIDを返す
   HistorySelect(0,TimeCurrent());
   if(!HistoryDealGetInteger(deal_ticket,DEAL_POSITION_ID,ret_posid)) return false;
   return true;
}

bool deal_ticket_close_last(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,ulong &ret_ticket){
   // 最後に決済した約定チケットを返す
   ulong open_ticket;
   if(!deal_ticket_open_last(Magic,symbol,order_type,open_ticket)) return false;
   ulong close_ticket;
   if(!deal_ticket_open_to_close(open_ticket,close_ticket,Magic)) return false;
   ret_ticket = close_ticket;
   return true;
}

bool deal_ticket_close_first(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,ulong &ret_ticket){
   // 最初に決済した約定チケットを返す
   ulong open_ticket;
   if(!deal_ticket_open_first(Magic,symbol,order_type,open_ticket)) return false;
   ulong close_ticket;
   if(!deal_ticket_open_to_close(open_ticket,close_ticket,Magic)) return false;
   ret_ticket = close_ticket;
   return true;
}

bool deal_ticket_open_last(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,ulong &ret_ticket){
   // 最後にオープンした約定チケットを返す
   HistorySelect(0,TimeCurrent());
   int deal_total = HistoryDealsTotal();
   ulong ticket = 0;
   datetime pos_time;
   datetime prev_pos_time = 0;
   for(int i=deal_total-1; i>=0; i--){
      g_deal.SelectByIndex(i);
         if(!g_deal.Entry()==DEAL_ENTRY_IN) continue;
         if(g_deal.Symbol() == symbol && g_deal.Magic() == Magic){
            pos_time = g_deal.Time();
            if(pos_time<prev_pos_time) continue;
            prev_pos_time = pos_time;
            if(g_deal.DealType()==DEAL_TYPE_BUY&&order_type==ORDER_TYPE_BUY){
               ticket = g_deal.Ticket();
            } else if(g_deal.DealType()==DEAL_TYPE_SELL&&order_type==ORDER_TYPE_SELL){
               ticket = g_deal.Ticket();
            }
         }      
   }
   if(ticket==0) return false;
   ret_ticket = ticket;
   return true;
}

bool deal_ticket_open_first(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,ulong &ret_ticket){
   // 最初にオープンした約定チケットを返す
   HistorySelect(0,TimeCurrent());
   int deal_total = HistoryDealsTotal();
   ulong ticket = 0;
   datetime pos_time;
   datetime prev_pos_time = TimeCurrent();   
   for(int i=0; i<deal_total; i++){
      g_deal.SelectByIndex(i);
         if(!g_deal.Entry()==DEAL_ENTRY_IN) continue;
         if(g_deal.Symbol() == symbol && g_deal.Magic() == Magic){
            pos_time = g_deal.Time();
            if(pos_time>prev_pos_time) continue;
            prev_pos_time = pos_time;         
            if(g_deal.DealType()==DEAL_TYPE_BUY&&order_type==ORDER_TYPE_BUY){
               ticket = g_deal.Ticket();
            } else if(g_deal.DealType()==DEAL_TYPE_SELL&&order_type==ORDER_TYPE_SELL){
               ticket = g_deal.Ticket();
            }
         }      
   }
   if(ticket==0) return false;
   ret_ticket = ticket;
   return true;
}

double deal_profit(ulong ticket){
   HistorySelect(0,TimeCurrent());
   g_deal.Ticket(ticket);
   return g_deal.Profit();
}

bool deal_ticket_close_to_open(ulong close_deal_ticket,ulong &ret_dealticket,ulong arg_magic){ 
   // 決済チケットからオープンしたチケットを取得する
   
   // エントリーの約定情報を取得する
   CDealInfo open_deal;
   ulong open_ticket = 0;
   ulong position_id;
   if(!deal_ticket_to_positionid(close_deal_ticket,position_id)){
      Print(__FUNCTION__ + " " + "Failed to get PositionID");
      return false;
   }

   // 同じPosition IDを持つ履歴リストを取得
   if(!HistorySelectByPosition(position_id)){
      Print("Select Failed");
      return false;
   }

   datetime pos_time;
   datetime prev_pos_time = TimeCurrent();
   // オープンの約定を選択する
   for(int i=0; i<HistoryDealsTotal(); i++){
      HistoryDealGetTicket(i);
      open_deal.SelectByIndex(i);
      if(open_deal.Entry()!=DEAL_ENTRY_IN) continue;
      if(open_deal.Magic()!=arg_magic) continue;
      pos_time = open_deal.Time();
      if(pos_time>prev_pos_time) continue;
      prev_pos_time = pos_time;
      open_ticket = open_deal.Ticket();
   }
   if(open_ticket==0) return false;   
   ret_dealticket = open_ticket;
   return true;
}

bool deal_ticket_open_to_close(ulong open_deal_ticket,ulong &ret_dealticket,ulong arg_magic){ 
   // オープンチケットから決済したチケットを取得する
   // エントリーの約定情報を取得する
   CDealInfo close_deal;
   ulong close_ticket = 0;
   ulong position_id;
   if(!deal_ticket_to_positionid(open_deal_ticket,position_id)){
      Print(__FUNCTION__ + " " + "Failed to get PositionID");
      return false;
   }
   
   // 同じPosition IDを持つ履歴リストを取得
   if(!HistorySelectByPosition(position_id)){
      Print("Select Failed");
      return false;
   }

   datetime pos_time;
   datetime prev_pos_time = 0;
   // 決済の約定を選択する
   for(int i=0; i<HistoryDealsTotal(); i++){
      HistoryDealGetTicket(i);
      close_deal.SelectByIndex(i);
      if(close_deal.Entry()!=DEAL_ENTRY_OUT) continue;
      // 決済の履歴はマジックナンバーがない場合があるのでマジックナンバーのチェックをしない
      pos_time = close_deal.Time();
      if(pos_time<prev_pos_time) continue;
      prev_pos_time = pos_time;
      close_ticket = close_deal.Ticket();      
   }
   if(close_ticket==0) return false;
   ret_dealticket = close_ticket;
   return true;
}

bool get_dealticket_open(ulong close_deal_PositionId,ulong &ret_dealticket,ulong arg_magic){ 
   // エントリーの約定情報を取得する
   CDealInfo open_deal;
   //ulong open_ticket = m_deal.PositionId();
   ulong open_ticket = close_deal_PositionId;

   // 同じPosition IDを持つ履歴リストを取得
   if(!HistorySelectByPosition(open_ticket)){
      Print("Select Failed");
      return false;
   }

   // オープンの約定を選択する
   for(int i=0; i<HistoryDealsTotal(); i++){
      HistoryDealGetTicket(i);
      open_deal.SelectByIndex(i);
      if(open_deal.Entry()==DEAL_ENTRY_IN) break;
   }
   
   // open_deal.Ticket(open_ticket);
   open_ticket = open_deal.Ticket();
   datetime open_time = open_deal.Time();
   double open_price = open_deal.Price();
   ulong magic = open_deal.Magic();   

//   if(magic!=arg_magic) return false; // マジックナンバーが違う場合は処理しない
   ret_dealticket = open_ticket;
   return true;
}


int report_summary(double &res_array[],datetime s,datetime e,string symbol,ulong magic){
   int deal_count = 0;
   double total_PL = 0;
   double total_Profit = 0;
   double total_loss = 0;
   double pf = 0;
   double e_payoff = 0;
   double win_count = 0;
   double lose_count = 0;
   double win_per = 0;
   double lose_per = 0;
   double ave_win = 0;
   double ave_lose = 0;
   double rr = 0;

   HistorySelect(s,e);
   
   int deal_total = HistoryDealsTotal();
   ulong ticket = 0;

   for(int i=deal_total-1; i>=0; i--){
      g_deal.SelectByIndex(i);
      if(!g_deal.Entry()==DEAL_ENTRY_OUT) continue;
         ulong open_ticket;
         if(!get_dealticket_open(g_deal.PositionId(),open_ticket,magic)) return false; 

         HistorySelect(s,e);
         g_deal.SelectByIndex(i);
         
         if(g_deal.Time()<s||g_deal.Time()>e) continue;
         if(g_deal.Symbol() == symbol){
            deal_count++;
            double profit = g_deal.Profit();
            total_PL += profit;
            if(profit>0) {
               total_Profit += profit;
               win_count++;
            } else {
               total_loss += profit;
               lose_count++;
            }
         }      
   }
   
   pf = total_Profit / MathAbs(total_loss);
   win_per = win_count / (win_count+lose_count);
   lose_per = lose_count / (win_count+lose_count);
   ave_win = total_Profit / win_count;
   ave_lose = total_loss / lose_count;
   rr = ave_win / MathAbs(ave_lose);
   e_payoff = total_PL / (win_count+lose_count);
   
   ArrayResize(res_array,12);
   res_array[0] = total_PL;
   res_array[1] = total_Profit;
   res_array[2] = total_loss;
   res_array[3] = pf;
   res_array[4] = e_payoff;
   res_array[5] = win_count;
   res_array[6] = lose_count;
   res_array[7] = win_per;
   res_array[8] = lose_per;
   res_array[9] = ave_win;
   res_array[10] = ave_lose;
   res_array[11] = rr;
   
   return deal_count;

}


int report_summary_all(double &res_array[],datetime s,datetime e){
   int deal_count = 0;
   double total_PL = 0;
   double total_Profit = 0;
   double total_loss = 0;
   double pf = 0;
   double e_payoff = 0;
   double win_count = 0;
   double lose_count = 0;
   double win_per = 0;
   double lose_per = 0;
   double ave_win = 0;
   double ave_lose = 0;
   double rr = 0;

   HistorySelect(s,e);
   
   int deal_total = HistoryDealsTotal();
   ulong ticket = 0;

   for(int i=deal_total-1; i>=0; i--){
      g_deal.SelectByIndex(i);
      if(!g_deal.Entry()==DEAL_ENTRY_OUT) continue;
            deal_count++;
            double profit = g_deal.Profit();
            total_PL += profit;
            if(profit>0) {
               total_Profit += profit;
               win_count++;
            } else {
               total_loss += profit;
               lose_count++;
            }   
   }
   
   pf = total_Profit / MathAbs(total_loss);
   win_per = win_count / (win_count+lose_count);
   lose_per = lose_count / (win_count+lose_count);
   ave_win = total_Profit / win_count;
   ave_lose = total_loss / lose_count;
   rr = ave_win / MathAbs(ave_lose);
   e_payoff = total_PL / (win_count+lose_count);
   
   ArrayResize(res_array,12);
   res_array[0] = total_PL;
   res_array[1] = total_Profit;
   res_array[2] = total_loss;
   res_array[3] = pf;
   res_array[4] = e_payoff;
   res_array[5] = win_count;
   res_array[6] = lose_count;
   res_array[7] = win_per;
   res_array[8] = lose_per;
   res_array[9] = ave_win;
   res_array[10] = ave_lose;
   res_array[11] = rr;
   
   return deal_count;

}

void print_report_summary(double &array[],datetime s,datetime e,string symbol,ulong magic){
   string log_txt = IntegerToString(magic) + " " + symbol + "#Report from:" + TimeToString(s) + " to:" + TimeToString(e);

   string to_pl = IntegerToString((int)NormalizeDouble(array[0],0));
   string to_profit = IntegerToString((int)NormalizeDouble(array[1],0));
   string to_loss = IntegerToString((int)NormalizeDouble(array[2],0));
   int p_factor_strlen = StringFind(DoubleToString(array[3]),".");
   string p_factor = StringSubstr(DoubleToString(array[3]),0,p_factor_strlen+3);
   string e_payoff = IntegerToString((int)NormalizeDouble(array[4],0));
   string win_count = IntegerToString((int)NormalizeDouble(array[5],0));
   string lose_count = IntegerToString((int)NormalizeDouble(array[6],0));
   int win_per_strlen = StringFind(DoubleToString(array[7]),".");
   string win_per = StringSubstr(DoubleToString(array[7]),0,win_per_strlen+3);
   int lose_per_strlen = StringFind(DoubleToString(array[8]),".");
   string lose_per = StringSubstr(DoubleToString(array[8]),0,lose_per_strlen+3);   
   string ave_win = IntegerToString((int)NormalizeDouble(array[9],0));
   string ave_lose = IntegerToString((int)NormalizeDouble(array[10],0));
   int rr_strlen = StringFind(DoubleToString(array[11]),".");
   string rr = StringSubstr(DoubleToString(array[11]),0,rr_strlen+3);
         
   log_txt += " to_pl:" + to_pl;
   log_txt += " to_profit:" + to_profit;
   log_txt += " to_loss:" + to_loss;
   log_txt += " p_factor:" + p_factor;
   log_txt += " e_payoff:" + e_payoff;
   log_txt += " rr:" + rr;
   log_txt += " win:" + win_count + "(" + win_per + "%)";
   log_txt += " lose:" + lose_count + "(" + lose_per + "%)";
   log_txt += " ave_win:" + ave_win;
   log_txt += " ave_lose:" + ave_lose;
   
   Print(log_txt);

}