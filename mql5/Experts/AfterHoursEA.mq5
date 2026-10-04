//+------------------------------------------------------------------+
//| AfterHoursEA.mq5 - skeleton: session window + risk controls       |
//| Entry logic is a placeholder to be tuned via the Strategy Tester. |
//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

input int    InpStartHour     = 21;    // Session start (server time)
input int    InpEndHour       = 2;     // Session end (server time)
input double InpRiskPercent   = 0.5;   // Risk per trade, % of balance
input int    InpSLPoints      = 200;   // Stop loss, points
input int    InpTPPoints      = 300;   // Take profit, points
input int    InpMaxSpread     = 30;    // Skip if spread > points
input double InpMaxDailyLoss  = 2.0;   // Stop trading for day, % of balance
input int    InpMaPeriod      = 50;    // Placeholder signal: MA period
input long   InpMagic         = 240601;

CTrade trade;
int    maHandle;
double dayStartBalance;
int    lastDay = -1;

int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   maHandle = iMA(_Symbol, _Period, InpMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return maHandle == INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
}

bool InSession()
{
   MqlDateTime t; TimeToStruct(TimeCurrent(), t);
   if(InpStartHour <= InpEndHour) return t.hour >= InpStartHour && t.hour < InpEndHour;
   return t.hour >= InpStartHour || t.hour < InpEndHour;   // wraps midnight
}

bool DailyLossHit()
{
   MqlDateTime t; TimeToStruct(TimeCurrent(), t);
   if(t.day_of_year != lastDay) { lastDay = t.day_of_year; dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE); }
   return AccountInfoDouble(ACCOUNT_EQUITY) < dayStartBalance * (1.0 - InpMaxDailyLoss / 100.0);
}

bool HaveOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic) return true;
   return false;
}

double LotsForRisk()
{
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double perLot = InpSLPoints * _Point / tickSize * tickVal;
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double lots = MathFloor(risk / perLot / step) * step;
   return MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),
                  MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)));
}

void OnTick()
{
   if(DailyLossHit() || HaveOpenPosition() || !InSession()) return;
   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpread) return;

   double ma[]; if(CopyBuffer(maHandle, 0, 1, 1, ma) != 1) return;
   double close1 = iClose(_Symbol, _Period, 1);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(close1 > ma[0])
      trade.Buy(LotsForRisk(), _Symbol, ask, ask - InpSLPoints * _Point, ask + InpTPPoints * _Point);
   else if(close1 < ma[0])
      trade.Sell(LotsForRisk(), _Symbol, bid, bid + InpSLPoints * _Point, bid - InpTPPoints * _Point);
}
