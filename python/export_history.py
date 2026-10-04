"""Export bars and ticks from the MT5 terminal (Windows) to data/*.csv.

Usage:
    python python/export_history.py EURUSD --tf M5 --days 365
    python python/export_history.py EURUSD --ticks --days 14
"""
import argparse
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import MetaTrader5 as mt5
import pandas as pd
from dotenv import load_dotenv

TF = {n: getattr(mt5, f"TIMEFRAME_{n}") for n in
      ("M1", "M5", "M15", "M30", "H1", "H4", "D1")}
DATA = Path(__file__).resolve().parent.parent / "data"


def connect() -> None:
    load_dotenv()
    kwargs = {}
    if os.getenv("MT5_PATH"):
        kwargs["path"] = os.environ["MT5_PATH"]
    if os.getenv("MT5_LOGIN"):
        kwargs.update(login=int(os.environ["MT5_LOGIN"]),
                      password=os.environ.get("MT5_PASSWORD", ""),
                      server=os.environ.get("MT5_SERVER", ""))
    if not mt5.initialize(**kwargs):
        raise SystemExit(f"MT5 initialize failed: {mt5.last_error()}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("symbol")
    p.add_argument("--tf", default="M5", choices=TF)
    p.add_argument("--days", type=int, default=365)
    p.add_argument("--ticks", action="store_true")
    a = p.parse_args()

    connect()
    try:
        mt5.symbol_select(a.symbol, True)
        end = datetime.now(timezone.utc)
        start = end - timedelta(days=a.days)
        if a.ticks:
            raw = mt5.copy_ticks_range(a.symbol, start, end, mt5.COPY_TICKS_ALL)
            name = f"{a.symbol}_ticks.csv"
        else:
            raw = mt5.copy_rates_range(a.symbol, TF[a.tf], start, end)
            name = f"{a.symbol}_{a.tf}.csv"
        if raw is None or len(raw) == 0:
            raise SystemExit(f"No data returned: {mt5.last_error()}")
        df = pd.DataFrame(raw)
        df["time"] = pd.to_datetime(df["time"], unit="s", utc=True)
        DATA.mkdir(exist_ok=True)
        df.to_csv(DATA / name, index=False)
        print(f"Wrote {len(df)} rows to data/{name}")
    finally:
        mt5.shutdown()


if __name__ == "__main__":
    main()
