#ifndef ExpertMain
#include <tk\lib\Function.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#endif
CPositionInfo m_position;
COrderInfo m_order;
CTrade m_trade;

int order_count(ulong Magic,string symbol){
   int count = 0;
   for(int i=0; i<OrdersTotal(); i++){
      if(m_order.SelectByIndex(i)){
         if(m_order.Symbol() == symbol && m_order.Magic() == Magic){
            count++;
         }
      }
   }
   return count;
}

int order_count(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   int count = 0;
   for(int i=0; i<OrdersTotal(); i++){
      if(m_order.SelectByIndex(i)){
         if(m_order.Symbol() == symbol && m_order.Magic() == Magic){
            if(((m_order.OrderType()==ORDER_TYPE_BUY||
               m_order.OrderType()==ORDER_TYPE_BUY_LIMIT||
               m_order.OrderType()==ORDER_TYPE_BUY_STOP)&&order_type==ORDER_TYPE_BUY) || 
               ((m_order.OrderType()==ORDER_TYPE_SELL||
               m_order.OrderType()==ORDER_TYPE_SELL_LIMIT||
               m_order.OrderType()==ORDER_TYPE_SELL_STOP)&&order_type==ORDER_TYPE_SELL)){
               count++;
            }
         }
      }
   }
   return count;
}

bool order_check(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,double price){
   int count = 0;
   for(int i=0; i<OrdersTotal(); i++){
      if(m_order.SelectByIndex(i)){
         if(m_order.Symbol() == symbol && m_order.Magic() == Magic){
            if(((m_order.OrderType()==ORDER_TYPE_BUY||
               m_order.OrderType()==ORDER_TYPE_BUY_LIMIT||
               m_order.OrderType()==ORDER_TYPE_BUY_STOP)&&order_type==ORDER_TYPE_BUY) || 
               ((m_order.OrderType()==ORDER_TYPE_SELL||
               m_order.OrderType()==ORDER_TYPE_SELL_LIMIT||
               m_order.OrderType()==ORDER_TYPE_SELL_STOP)&&order_type==ORDER_TYPE_SELL)){
               if(m_order.PriceOpen()==price) return false;
            }
         }
      }
   }
   return true;
}

int position_count(ulong Magic,string symbol){
   int count = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            count++;
         }
      }
   }
   return count;
}

int position_count(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   int count = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if((m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY) || (m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL)){
               count++;
            }
         }
      }
   }
   return count;
}

// 保有中ポジションの合計損益を返す
double position_total_profit(ulong Magic,string symbol){
   double profit = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            profit+=m_position.Profit();
         }
      }
   }
   return profit;
}

// 保有中ポジションの合計損益を返す（オーダータイプを指定）
double position_total_profit(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   double profit = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_SELL){ continue; }
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               if(order_type==ORDER_TYPE_BUY){ continue; }
            }
            profit+=m_position.Profit();
         }
      }
   }
   return profit;
}

// 保有中ポジションの合計スワップ損益を返す
double position_total_swap(ulong Magic,string symbol){
   double swap = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            swap+=m_position.Swap();
         }
      }
   }
   return swap;
}

// 保有中ポジションの合計スワップ損益を返す（オーダータイプを指定）
double position_total_swap(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   double swap = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_SELL){ continue; }
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               if(order_type==ORDER_TYPE_BUY){ continue; }
            }
            swap+=m_position.Swap();
         }
      }
   }
   return swap;
}

// 保有中ポジションの合計損益を取引決済通貨単位で返す（オーダータイプを指定）　EURUSDならUSDで返す
double position_total_profit_trade_cur(ulong Magic,string symbol){
   double profit = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            double close_width_price = 0;
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               close_width_price = Bid(symbol) - m_position.PriceOpen();
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               close_width_price = m_position.PriceOpen() - Ask(symbol);
            }           
            profit+=calc_profit(m_position.Volume(),close_width_price,symbol);
         }
      }
   }
   return profit;
}

// 保有中ポジションの合計損益を取引決済通貨単位で返す（オーダータイプを指定）　EURUSDならUSDで返す
double position_total_profit_trade_cur(ulong Magic,ENUM_ORDER_TYPE order_type,string symbol){
   double profit = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            double close_width_price;
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_SELL){ continue; }
               close_width_price = Bid(symbol) - m_position.PriceOpen();
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               if(order_type==ORDER_TYPE_BUY){ continue; }
               close_width_price = m_position.PriceOpen() - Ask(symbol);
            }           
            profit+=calc_profit(m_position.Volume(),close_width_price,symbol);
         }
      }
   }
   return profit;
}


// 保有中ポジションの合計期待利得を決済通貨の単位で返す（指定した利確幅(pips)に対して各ポジションのロット数に応じた期待値）
double position_total_expected_profit_trade_cur(ulong Magic,double close_width_point,string symbol){
   double profit = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            //profit+=calc_profit(OrderLots(),close_width_point) / Bid;
            profit+=calc_profit(m_position.Volume(),close_width_point,symbol) / Bid(symbol);
         }
      }
   }
   return profit;
}

// 保有中ポジションの合計期待利得を決済通貨の単位で返す（指定した利確幅(pips)に対して各ポジションのロット数に応じた期待値）
double position_total_expected_profit_trade_cur(ulong Magic,double close_width_point,ENUM_ORDER_TYPE order_type,string symbol){
   double profit = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_SELL){ continue; }
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               if(order_type==ORDER_TYPE_BUY){ continue; }
            }         
            //profit+=calc_profit(OrderLots(),close_width_point) / Bid;
            profit+=calc_profit(m_position.Volume(),close_width_point,symbol);
         }
      }
   }
   return profit;
}

// 取引ロット数と損益Price幅で現在の損益を返す
double calc_profit(double volume,double close_width_price,string symbol){
   double lot_size = (SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
   double currency_amount = volume * lot_size;
   return currency_amount * close_width_price;
}



// ポジション全決済
bool close_position_all(ulong Magic,string symbol,int slippage){
   bool ret = true;
   for(int i=PositionsTotal(); i>=0; i--){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               ret = close_position(m_position.Ticket(),Bid(symbol),m_position.Volume(),slippage);
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               ret = close_position(m_position.Ticket(),Ask(symbol),m_position.Volume(),slippage);
            }
         }
      }
   }
   return ret;   
}

bool close_position_all(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   bool ret = true;
   for(int i=PositionsTotal(); i>=0; i--){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY){
               m_trade.PositionClose(m_position.Ticket());
               //close_position(m_position.Ticket(),Bid(symbol),m_position.Volume(),slippage);
            } else if(m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL){
               m_trade.PositionClose(m_position.Ticket());
               //close_position(m_position.Ticket(),Ask(symbol),m_position.Volume(),slippage);
            }
            Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
            if(m_trade.ResultRetcode()!=10009) ret = false;
         }
      }
   }
   return ret;
}

bool close_position_all(ulong Magic,ENUM_ORDER_TYPE order_type,double partial_coefficient,CSymbolInfo *m_symbol){
   bool ret = true;
   m_symbol.RefreshRates();
   for(int i=PositionsTotal(); i>=0; i--){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == m_symbol.Name() && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY){
               double stepvol = m_symbol.LotsStep();
               double partial_vol = MathFloor(m_position.Volume() / partial_coefficient / stepvol) * stepvol;
               if(m_symbol.LotsMin()>partial_vol) continue;
               m_trade.PositionClosePartial(m_position.Ticket(),partial_vol);
            } else if(m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL){
               double stepvol = m_symbol.LotsStep();
               double partial_vol = MathFloor(m_position.Volume() / partial_coefficient / stepvol) * stepvol;
               if(m_symbol.LotsMin()>partial_vol) continue;
               m_trade.PositionClosePartial(m_position.Ticket(),partial_vol);
            }
            Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
            if(m_trade.ResultRetcode()!=10009) ret = false;
         }
      }
   }
   return ret;
}

void close_position_partial(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,double close_vol){
   double remaining_vol=close_vol;
   for(int i=PositionsTotal(); i>=0; i--){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY){
               if(m_position.Volume()>=remaining_vol){
                  m_trade.PositionClosePartial(m_position.Ticket(),remaining_vol);
                  break;
               } else {
                  remaining_vol-=m_position.Volume();
                  m_trade.PositionClose(m_position.Ticket());
               }
            } else if(m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL){
               if(m_position.Volume()>=remaining_vol){
                  m_trade.PositionClosePartial(m_position.Ticket(),remaining_vol);
                  break;
               } else {
                  remaining_vol-=m_position.Volume();
                  m_trade.PositionClose(m_position.Ticket());
               }
            }
         }
      }
   }
}

void close_position_partial_coefficient(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,double partial_coefficient,CSymbolInfo *m_symbol){
   double stepvol = m_symbol.LotsStep();
   double partial_vol = MathFloor(m_position.Volume() / partial_coefficient / stepvol) * stepvol;
   if(m_symbol.LotsMin()>partial_vol) return;
   m_trade.PositionClosePartial(m_position.Ticket(),partial_vol);
}

bool modify_position_all(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,double sl,double tp){
   bool ret = true;
   for(int i=PositionsTotal(); i>=0; i--){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY){
               m_trade.PositionModify(m_position.Ticket(),sl,tp);
            } else if(m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL){
               m_trade.PositionModify(m_position.Ticket(),sl,tp);
            }
            Print(IntegerToString(Magic) + "_" + symbol +"_" + EnumToString(order_type) + "# " + __FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
            if(m_trade.ResultRetcode()!=10009) ret = false;
         }
      }
   }
   return ret;
}

void modify_order_all(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type,double price,double sl,double tp,ENUM_ORDER_TYPE_TIME order_exp_type,datetime order_exp_dt,double stoplimit){
   for(int i=0; i<OrdersTotal(); i++){
      if(m_order.SelectByIndex(i)){
         if(m_order.Symbol() == symbol && m_order.Magic() == Magic){
            if(((m_order.OrderType()==ORDER_TYPE_BUY||
               m_order.OrderType()==ORDER_TYPE_BUY_LIMIT||
               m_order.OrderType()==ORDER_TYPE_BUY_STOP)&&order_type==ORDER_TYPE_BUY) || 
               ((m_order.OrderType()==ORDER_TYPE_SELL||
               m_order.OrderType()==ORDER_TYPE_SELL_LIMIT||
               m_order.OrderType()==ORDER_TYPE_SELL_STOP)&&order_type==ORDER_TYPE_SELL)){
                  m_trade.OrderModify(m_order.Ticket(),price,sl,tp,order_exp_type,order_exp_dt,stoplimit);
            }
         }
      }
   }
}

void delete_order_all(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   for(int i=0; i<OrdersTotal(); i++){
      if(m_order.SelectByIndex(i)){
         if(m_order.Symbol() == symbol && m_order.Magic() == Magic){
            if(((m_order.OrderType()==ORDER_TYPE_BUY||
               m_order.OrderType()==ORDER_TYPE_BUY_LIMIT||
               m_order.OrderType()==ORDER_TYPE_BUY_STOP)&&order_type==ORDER_TYPE_BUY) || 
               ((m_order.OrderType()==ORDER_TYPE_SELL||
               m_order.OrderType()==ORDER_TYPE_SELL_LIMIT||
               m_order.OrderType()==ORDER_TYPE_SELL_STOP)&&order_type==ORDER_TYPE_SELL)){
               m_trade.OrderDelete(m_order.Ticket());
            }
         }
      }
   }
}


bool position_check_order_type(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_BUY){ return true; }
            } else {
               if(order_type==ORDER_TYPE_SELL){ return true; }
            }
         }
      }
   }
   return false;
}


// オープン中のポジションから最初にオープンしたポジションのチケット番号を返す
ulong position_ticket_first(ulong Magic,string symbol){
   datetime open_time = TimeCurrent();
   ulong ticket = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(open_time>m_position.Time()){
               open_time = m_position.Time();
               ticket = m_position.Ticket();
            }
         }
      }
   }
   return ticket;
}

// オープン中のポジションから最初にオープンしたポジションのチケット番号を返す(注文方向指定)
ulong position_ticket_first(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   datetime open_time = TimeCurrent();
   ulong ticket = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if((m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY) || (m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL)){
               if(open_time>m_position.Time()){
               //if(ticket<OrderTicket()){
                  open_time = m_position.Time();
                  ticket = m_position.Ticket();
               }
            }
         }
      }
   }
   return ticket;
}

// オープン中のポジションから最後にオープンしたポジションのチケット番号を返す
ulong position_ticket_last(ulong Magic,string symbol){
   datetime open_time = 0; // ＝1970.01.01 00:00:00
   ulong ticket = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(open_time<m_position.Time()){
               open_time = m_position.Time();
               ticket = m_position.Ticket();
            }
         }
      }
   }
   return ticket;
}

// オープン中のポジションから最後にオープンしたポジションのチケット番号を返す(注文方向指定)
ulong position_ticket_last(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   datetime open_time = 0; // ＝1970.01.01 00:00:00
   ulong ticket = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if((m_position.PositionType()==POSITION_TYPE_BUY&&order_type==ORDER_TYPE_BUY) || (m_position.PositionType()==POSITION_TYPE_SELL&&order_type==ORDER_TYPE_SELL)){
               if(open_time<m_position.Time()){
               //if(ticket<OrderTicket()){
                  open_time = m_position.Time();
                  ticket = m_position.Ticket();
               }
            }
         }
      }
   }
   return ticket;
}

#define OP_BUY 0           //Buy 
#define OP_SELL 1          //Sell
// オープン
int open_position(int cmd,double lot,double price,int slippage,double sl,double tp,string comment,ulong Magic,datetime expiration,string symbol){
   if(cmd==OP_BUY){
      return m_trade.Buy(lot,symbol,price,sl,tp,comment);
   } else if(cmd==OP_SELL){
      return m_trade.Sell(lot,symbol,price,sl,tp,comment);   
   }
   return -1;
}

// クローズ
bool close_position(ulong ticket,double price,double lot,int slippage){
   m_trade.PositionClosePartial(ticket,lot);
   Print(__FUNCTION__ + " ResultRet: " + IntegerToString(m_trade.ResultRetcode()) + "_" + m_trade.ResultRetcodeDescription());
   if(m_trade.ResultRetcode()!=10009) return false;
   return true;  
}


int market_order(ENUM_ORDER_TYPE order_type,double lot,int slippage,double sl,double tp,string comment,ulong Magic,string symbol){
   if(order_type==ORDER_TYPE_BUY){
      return open_position(POSITION_TYPE_BUY,lot,Ask(symbol),slippage,sl,tp,comment,Magic,0,symbol);
   } else if(order_type==ORDER_TYPE_SELL) {
      return open_position(POSITION_TYPE_SELL,lot,Bid(symbol),slippage,sl,tp,comment,Magic,0,symbol);
   }
   return 0;
}


// 利益とロット数から価格（決済通貨）を計算
double OrderCalcPrice(string symbol,double volume,double profit){

    // EURUSDやEURCHF等の場合はUSDJPYやCHFJPYのレートを取得し、単位を円に変換
    if (SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT) != AccountInfoString(ACCOUNT_CURRENCY))
    {
        // 対応する通貨を取得
        //string cross_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT) + AccountCurrency();

        // 口座通貨で決済通貨の現在レートを取得（GBPUSDならUSDJPYのレートを取得）
        double rate = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
        if(rate==0){ return 0; }
        
        // 単位を円に変換
         return (profit /rate) / (volume * SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));

    } else {
       return profit / (volume * SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
    }
    return 0;
} 


// 保有中ポジションの損益分岐点を返す
double position_breakeven_point(ulong Magic,string symbol){
   double prices = 0;
   double lots = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            prices+=m_position.PriceOpen()*m_position.Volume();
            lots+=m_position.Volume();
         }
      }
   }
   return prices/lots;
}

// 保有中ポジションの損益分岐点を返す（オーダータイプを指定）
double position_breakeven_point(ulong Magic,string symbol,ENUM_ORDER_TYPE order_type){
   double prices = 0;
   double lots = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_SELL){ continue; }
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               if(order_type==ORDER_TYPE_BUY){ continue; }
            }
            prices+=m_position.PriceOpen()*m_position.Volume();
            lots+=m_position.Volume();
         }
      }
   }
   return prices/lots;
}

// 保有中ポジションの損益分岐点を返す（オーダータイプを指定）
double position_breakeven_point_include_swap(ulong Magic,ENUM_ORDER_TYPE order_type,string symbol){
   double prices = 0;
   double lots = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         if(m_position.Symbol() == symbol && m_position.Magic() == Magic){
            //double swap_price=OrderCalcPrice(_Symbol,OrderLots(),OrderSwap());
            double swap_price=OrderCalcPrice(symbol,m_position.Volume(),m_position.Swap());
            
            if(m_position.PositionType()==POSITION_TYPE_BUY){
               if(order_type==ORDER_TYPE_SELL){ continue; }
               prices+=(m_position.PriceOpen()-swap_price)*m_position.Volume();
            } else if(m_position.PositionType()==POSITION_TYPE_SELL){
               if(order_type==ORDER_TYPE_BUY){ continue; }
               prices+=(m_position.PriceOpen()+swap_price)*m_position.Volume();
            }
            lots+=m_position.Volume();
         }
      }
   }
   return prices/lots;
}


// 保有中ポジションが全損した場合の有効証拠金を計算し返す（証拠金維持率評価のため）
double positions_ttl_equity(ulong Magic,string symbol){
   double open_price = 0;
   double lot = 0;
   double sl = 0;
   double profit = 0;
   double ttl_profit = 0;
   ENUM_POSITION_TYPE pos_type;
   ENUM_ORDER_TYPE odr_type;
   for(int i=0; i<PositionsTotal(); i++){
      if(m_position.SelectByIndex(i)){
         sl = m_position.StopLoss();
         pos_type = m_position.PositionType();
         lot = m_position.Volume();
         open_price = m_position.PriceOpen();
         odr_type = (pos_type==POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL; // OrderCalcProfitのためにPositionTypeからOrderTypeへ変換
         //if(!OrderCalcProfit(odr_type,symbol,lot,open_price,sl,profit)) continue; // symbol誤りのため修正
         if(!OrderCalcProfit(odr_type,m_position.Symbol(),lot,open_price,sl,profit)) continue;
         ttl_profit+=profit;
      }
   }
     
   double balance = AccountInfoDouble(ACCOUNT_BALANCE); // 口座預金取得
   double enable_balance = balance + ttl_profit;   // 口座預金から含み損益を加算し有効証拠金を計算
   return enable_balance;
}


/*
// テイクプロフィット値を変更する
int ModTakeprofit(ulong ticket,double tp){
   return m_trade.PositionModify(ticket,m_position.StopLoss(),tp);
}

// ストップロス値を変更する
int ModStoploss(ulong ticket,double sl){
   return m_trade.PositionModify(ticket,sl,m_position.TakeProfit());
}
*/