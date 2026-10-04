# AfterHoursTrading

MQL5 Expert Advisor + Python tooling to backtest, tune and forward-test an after-hours session strategy on MetaTrader 5 (XMGlobal-MT5 10). **Demo accounts only until forward tests prove out.**

## Setup (Windows)
1. Install MT5 and open a demo account; MetaEditor ships with it.
2. `winget install Git.Git OpenJS.NodeJS.LTS Python.Python.3.12 Microsoft.PowerShell`
3. `python -m venv .venv; .venv\Scripts\activate; pip install -r python\requirements.txt`
4. Copy `.env.example` to `.env` and fill in demo credentials (never commit `.env`).
5. Copy `mql5\Experts\AfterHoursEA.mq5` into the MT5 `MQL5\Experts` folder and compile in MetaEditor.

## Data
`python python\export_history.py EURUSD --tf M5 --days 365` writes `data/EURUSD_M5.csv` from your broker feed.
Add `--ticks` for tick data.

## Backtest
Edit `configs/tester_example.ini`, then run `terminal64.exe /config:configs\tester_example.ini`.

## Roadmap
- Walk-forward optimizer (`python/optimizer`) with in-sample / out-of-sample splits
- Session-window and news-filter sweeps
- Demo forward test before any live use
