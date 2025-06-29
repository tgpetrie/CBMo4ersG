#!/bin/bash

# --- Configuration ---
TARGET_DIR="~/betacb3.11"
EVAL_TARGET_DIR=$(eval echo "$TARGET_DIR")

echo "Generating Final Project Using Your Proven Coinbase Logic in: ${EVAL_TARGET_DIR}"
echo "--------------------------------------------------------"
rm -rf "${EVAL_TARGET_DIR}"
echo "Removed old project directory to ensure a clean slate."
sleep 2

# Create the Vercel-optimized monorepo structure
mkdir -p "${EVAL_TARGET_DIR}/api"
mkdir -p "${EVAL_TARGET_DIR}/public"
mkdir -p "${EVAL_TARGET_DIR}/src/components"

# ==============================================================================
# === Backend: Your Logic Adapted for Vercel
# ==============================================================================
echo "Generating Serverless Backend in ${EVAL_TARGET_DIR}/api/..."

# --- /api/data.py ---
cat > "${EVAL_TARGET_DIR}/api/data.py" << 'EOF'
from flask import Flask, jsonify
from .cache_utils import ( get_gainers_3m, get_losers_3m, get_1h_price_change_banner, get_1h_volume_change_banner, update_cached_snapshots )
app = Flask(__name__)
@app.route('/', methods=['GET'])
def handler():
    try:
        update_cached_snapshots()
        data = { "gainers": get_gainers_3m(), "losers": get_losers_3m(), "price_banner": get_1h_price_change_banner(), "volume_banner": get_1h_volume_change_banner() }
        return jsonify(data)
    except Exception as e:
        print(f"FATAL ERROR in main handler: {e}")
        return jsonify({"error": "A critical error occurred while processing market data."}), 500
EOF

# --- /api/cache_utils.py (YOUR LOGIC, RE-ENGINEERED) ---
cat > "${EVAL_TARGET_DIR}/api/cache_utils.py" << 'EOF'
import time, json, os, requests
from concurrent.futures import ThreadPoolExecutor, as_completed

CACHE_TTL, THREE_MIN_SECONDS, ONE_HOUR_SECONDS = 45, 180, 3600
PRODUCTS_CACHE_TTL, TABLE_COUNT, BANNER_COUNT = 3600, 6, 25
CACHE_FILE_PATH = '/tmp/coinbase_cache.json'
COINBASE_API_URL = "https://api.exchange.coinbase.com"

def _read_cache():
    if not os.path.exists(CACHE_FILE_PATH): return {}
    try:
        with open(CACHE_FILE_PATH, 'r') as f: return json.load(f)
    except (IOError, json.JSONDecodeError) as e:
        print(f"CACHE READ ERROR: {e}. Self-healing."); return {}
def _write_cache(data):
    try:
        with open(CACHE_FILE_PATH, 'w') as f: json.dump(data, f)
    except IOError as e: print(f"CACHE WRITE ERROR: {e}")

def _fetch_products(cache):
    if time.time() - cache.get("products_last_updated", 0) > PRODUCTS_CACHE_TTL:
        try:
            res = requests.get(f"{COINBASE_API_URL}/products", timeout=10); res.raise_for_status()
            cache['products'] = [p['id'] for p in res.json() if p['id'].endswith('-USD') and p['status'] == 'online']
            cache['products_last_updated'] = time.time()
        except requests.RequestException as e: print(f"Error fetching Coinbase products: {e}")
    return cache.get('products', [])

def _fetch_tickers(product_ids):
    """THIS IS YOUR PROVEN LOGIC: Fetches tickers one by one, concurrently."""
    if not product_ids: return {}
    tickers = {}
    
    def fetch_one(product_id):
        try:
            ticker_url = f"{COINBASE_API_URL}/products/{product_id}/ticker"
            response = requests.get(ticker_url, timeout=2)
            if response.status_code == 200:
                return product_id, response.json()
        except requests.RequestException:
            return product_id, None
        return product_id, None

    with ThreadPoolExecutor(max_workers=20) as executor:
        future_to_id = {executor.submit(fetch_one, pid): pid for pid in product_ids}
        for future in as_completed(future_to_id):
            pid, ticker_data = future.result()
            if ticker_data:
                tickers[pid] = ticker_data
    
    print(f"Fetched {len(tickers)}/{len(product_ids)} tickers successfully.")
    return tickers

def update_cached_snapshots():
    now = time.time()
    cache = _read_cache()
    if now - cache.get("latest", {}).get("timestamp", 0) > CACHE_TTL:
        product_ids = _fetch_products(cache)
        if now - cache.get("three_mins_ago", {}).get("timestamp", 0) > THREE_MIN_SECONDS:
            cache["three_mins_ago"] = cache.get("latest", {})
        if now - cache.get("one_hour_ago", {}).get("timestamp", 0) > ONE_HOUR_SECONDS:
            cache["one_hour_ago"] = cache.get("latest", {})
        new_tickers = _fetch_tickers(product_ids)
        if new_tickers: cache["latest"] = {"data": new_tickers, "timestamp": now}
        if "three_mins_ago" not in cache: cache["three_mins_ago"] = cache.get("latest", {})
        if "one_hour_ago" not in cache: cache["one_hour_ago"] = cache.get("latest", {})
        _write_cache(cache)

def _calculate_changes(time_period_key):
    cache = _read_cache()
    latest_tickers, past_tickers = cache.get("latest", {}).get("data", {}), cache.get(time_period_key, {}).get("data", {})
    changes = []
    if not latest_tickers or not past_tickers: return []
    for pid, latest in latest_tickers.items():
        past = past_tickers.get(pid)
        if past:
            try:
                price_now, price_then = float(latest['price']), float(past['price'])
                if price_then > 0:
                    pct = ((price_now - price_then) / price_then) * 100
                    changes.append({"symbol": pid.replace('-USD', ''), "price": f"{price_now:.4f}", "percent_change": pct, "volume_24h": float(latest.get('volume_24h', 0))})
            except (ValueError, KeyError): continue
    return changes

def get_gainers_3m():
    changes = _calculate_changes("three_mins_ago")
    sorted_gainers = sorted(changes, key=lambda x: x['percent_change'], reverse=True)
    return [{"rank": i + 1, "symbol": g['symbol'], "price": g['price'], "tag": "strong" if abs(g['percent_change']) > 0.5 else "moderate", "percent_change": f"{g['percent_change']:.2f}"} for i, g in enumerate(sorted_gainers[:TABLE_COUNT])]
def get_losers_3m():
    changes = _calculate_changes("three_mins_ago")
    sorted_losers = sorted(changes, key=lambda x: x['percent_change'])
    return [{"rank": i + 1, "symbol": l['symbol'], "price": l['price'], "tag": "strong" if abs(l['percent_change']) > 0.5 else "moderate", "percent_change": f"{l['percent_change']:.2f}"} for i, l in enumerate(sorted_losers[:TABLE_COUNT])]
def get_1h_price_change_banner():
    changes = _calculate_changes("one_hour_ago")
    return [{"symbol": c['symbol'], "percent_change": f"{c['percent_change']:.2f}"} for c in sorted(changes, key=lambda x: x['percent_change'], reverse=True)[:BANNER_COUNT]]
def get_1h_volume_change_banner():
    changes = _calculate_changes("one_hour_ago")
    return [{"symbol": c['symbol'], "percent_change": f"{c['percent_change']:.2f}"} for c in sorted(changes, key=lambda x: x['volume_24h'], reverse=True)[:BANNER_COUNT]]
EOF
cat > "${EVAL_TARGET_DIR}/api/requirements.txt" << 'EOF'
Flask==3.0.2
requests==2.31.0
EOF

# ==============================================================================
# === Frontend and Configs (No changes needed)
# ==============================================================================
echo "Generating Frontend and Config files..."
cat > "${EVAL_TARGET_DIR}/package.json" << 'EOF'
{ "name": "bhabit-cb4-vercel", "private": true, "version": "1.0.0", "type": "module", "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" }, "dependencies": { "react": "^18.2.0", "react-dom": "^18.2.0", "react-icons": "^5.0.1", "swr": "^2.2.5" }, "devDependencies": { "@vitejs/plugin-react": "^4.2.1", "autoprefixer": "^10.4.19", "postcss": "^8.4.38", "tailwindcss": "^3.4.1", "vite": "^5.2.0" } }
EOF
cat > "${EVAL_TARGET_DIR}/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'; import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()], server: { proxy: { '/api': { target: 'http://localhost:8001', changeOrigin: true, rewrite: (path) => path.replace(/^\/api\/data/, ''), }, }, },
});
EOF
cat > "${EVAL_TARGET_DIR}/tailwind.config.js" << 'EOF'
/** @type {import('tailwindcss').Config} */
export default { content: ["./index.html", "./src/**/*.{js,jsx}"], theme: { extend: { colors: { 'primary-orange': '#FF6B00', 'primary-blue': '#00BFFF', 'primary-pink': '#FF69B4', 'accent-purple': '#8A2BE2', 'dark-bg': '#000', 'mid-bg': '#111', 'light-bg': '#1a1a1a', 'glass-bg': 'rgba(0, 0, 0, 0.8)', 'glass-border': 'rgba(0, 191, 255, 0.3)', 'text-light': '#ccc', 'text-white': '#fff', 'text-muted': '#888', 'tag-strong': '#F5A623', 'tag-moderate': '#333', }, fontFamily: { display: ['Bebas Neue', 'sans-serif'], headline: ['Montserrat', 'sans-serif'], sans: ['Inter', 'sans-serif'], }, boxShadow: { 'glow-blue': '0 0 30px var(--primary-blue)', 'glow-pink': '0 0 30px var(--primary-pink)', 'glow-orange': '0 0 30px var(--primary-orange)', }, keyframes: { marquee: { '0%': { transform: 'translateX(0%)' }, '100%': { transform: 'translateX(-100%)' }, }, pulseGlow: { '0%, 100%': { opacity: 1, boxShadow: '0 0 10px var(--primary-orange)' }, '50%': { opacity: 0.7, boxShadow: '0 0 20px var(--primary-orange)' }, } }, animation: { marquee: 'marquee 60s linear infinite', pulseGlow: 'pulseGlow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite', }, }, }, plugins: [], };
EOF
cat > "${EVAL_TARGET_DIR}/postcss.config.js" << 'EOF'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } }
EOF
cat > "${EVAL_TARGET_DIR}/index.html" << 'EOF'
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8" /><link rel="icon" type="image/svg+xml" href="/rabbit-logo.svg" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;500;700&family=Montserrat:wght@700&display=swap" rel="stylesheet"><title>BHABIT | CB4</title></head><body class="bg-dark-bg text-text-light font-sans"><div id="root"></div><script type="module" src="/src/main.jsx"></script></body></html>
EOF
cat > "${EVAL_TARGET_DIR}/public/rabbit-logo.svg" << 'EOF'
<svg fill="#8A2BE2" width="64px" height="64px" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg"><path d="M716.4 92.4C696.2 46.9 646.2 12 585.2 12c-54.3 0-102.3 29.8-128.3 74.3-25.9-44.5-74-74.3-128.3-74.3-61 0-111 34.9-131.2 80.4C131.9 104.9 64 189.4 64 288c0 105.9 85.1 193.3 189.6 195.9-1.2-5.7-1.6-11.4-1.6-17.2 0-77.9 44.8-146.4 110.1-178.1 27.5-13.3 58.3-20.6 90.9-20.6s63.4 7.3 90.9 20.6c65.4 31.7 110.1 100.2 110.1 178.1 0 5.8-.4 11.5-1.6 17.2C874.9 481.3 960 393.9 960 288c0-98.6-67.9-183.1-133.5-195.6zM512 576c-112.9 0-210.7 85.2-221.1 195.8-1.5 16.1-2.2 32.3-2.2 48.5 0 27.6 4.4 54.3 12.9 79.9 26.5 79.9 104.1 135.8 193.2 135.8 91.1 0 168.3-57.9 192.3-139.7 10.6-35.8 16.1-73.3 16.1-112.5 0-21.9-2.3-43.4-6.8-64.3-13.4-59.5-62.8-107.5-121-125.7-16-5-32.9-7.8-50.4-7.8s-34.4 2.8-50.4 7.8c-3.1 1-6.1 2-9.1 3.1-6.9 2.4-13.7 5.1-20.2 8-11.2 5-21.9 10.6-32.1 16.7-19.1 11.3-36.4 25.1-51.2 40.7-18.9 19.8-32.9 43.8-40.7 70.1-2.7 9.1-4.8 18.3-6.4 27.6-3.8 22.8-5.7 46.1-5.7 69.5 0 13.9 1.2 27.7 3.5 41.2C399.7 706.8 451.3 640 512 640c59.9 0 111.2 65.5 121.2 150.9 1.4 12 2.1 24.2 2.1 36.4 0 35.8-6.9 70.1-20.2 101.8-19.1 31.7-48.5 56.1-82.6 68.3-28.9 10.2-59.7 15.6-91.4 15.6-70.6 0-134.2-38.3-166.8-98.3-11.8-21.9-20.6-45.5-25.9-70.1-6.4-30.2-9.7-61.2-9.7-92.7 0-21.4 2.3-42.6 6.8-63.1 12.5-56.7 58.3-102.3 114.7-116.2 22.8-5.7 46.6-8.7 71-8.7 30.7 0 60.3 4.5 87.8 13.4 20.2 6.6 39.1 15.5 56.1 26.4 21.1 13.4 39.4 30.1 54.1 49.3 15.8 20.7 27.7 44.1 35.2 69.5 3.3 11.2 5.9 22.8 7.8 34.6 2.7 16.5 4.1 33.3 4.1 50.4 0 14.1-1.3 28.1-3.9 41.8-10.4-86.4-82.1-152.9-166.8-152.9z"/></svg>
EOF
cat > "${EVAL_TARGET_DIR}/src/index.css" << 'EOF'
@tailwind base; @tailwind components; @tailwind utilities; .table-row-glow { @apply relative; } .table-row-glow::after { content: ''; position: absolute; bottom: 0; left: 0; right: 0; height: 2px; opacity: 0; transition: opacity 0.3s ease; } .table-row-glow.gainer:hover::after { background: linear-gradient(90deg, transparent, var(--primary-blue), transparent); opacity: 1; } .table-row-glow.loser:hover::after { background: linear-gradient(90deg, transparent, var(--primary-pink), transparent); opacity: 1; } .pause-on-hover:hover { animation-play-state: paused; }
EOF
cat > "${EVAL_TARGET_DIR}/src/main.jsx" << 'EOF'
import React from 'react'; import ReactDOM from 'react-dom/client'; import App from './App.jsx'; import './index.css'; ReactDOM.createRoot(document.getElementById('root')).render(<React.StrictMode><App /></React.StrictMode>);
EOF
cat > "${EVAL_TARGET_DIR}/src/App.jsx" << 'EOF'
import React from "react"; import useSWR from "swr"; import BHABITLogo from "./components/BHABITLogo.jsx"; import MarqueeBanner from "./components/MarqueeBanner.jsx"; import DataTable from "./components/DataTable.jsx";
const API_ENDPOINT = "/api/data";
const fetcher = async (url) => { const res = await fetch(url); if (!res.ok) { const e = new Error('An error occurred while fetching the data.'); e.info = await res.json().catch(() => ({ error: 'Could not parse error JSON.' })); e.status = res.status; throw e; } return res.json(); };
export default function App() {
  const { data, error, isLoading } = useSWR(API_ENDPOINT, fetcher, { refreshInterval: 45000, shouldRetryOnError: true });
  const renderContent = () => {
    if (error) return <div className="text-center py-20 text-primary-pink font-headline">Error: {error.info?.error || error.message}</div>;
    if (isLoading && !data) return <div className="text-center py-20 text-text-muted text-xl font-headline animate-pulse">Connecting to Real-Time Data Stream...</div>;
    return (<> <MarqueeBanner items={data?.price_banner} title="1H PRICE CHANGE" /> <div className="grid grid-cols-1 lg:grid-cols-2 gap-8"><DataTable items={data?.gainers} type="gainer" /><DataTable items={data?.losers} type="loser" /></div> <MarqueeBanner items={data?.volume_banner} title="1H VOLUME MOVERS" /> </>);
  };
  return (<main className="container mx-auto max-w-7xl px-4 py-8"><BHABITLogo /><div className="flex flex-col gap-12 mt-8">{renderContent()}</div></main>);
}
EOF
cat > "${EVAL_TARGET_DIR}/src/components/BHABITLogo.jsx" << 'EOF'
export default function BHABITLogo() { return (<header className="flex items-center justify-center"><h1 className="font-display text-7xl md:text-8xl text-text-white tracking-widest" style={{ textShadow: '2px 2px 15px rgba(138, 43, 226, 0.5)' }}>BHABIT</h1><img src="/rabbit-logo.svg" alt="Rabbit Logo" className="w-16 h-16 ml-4 -mt-2" /></header>); }
EOF
cat > "${EVAL_TARGET_DIR}/src/components/MarqueeBanner.jsx" << 'EOF'
import { BsArrowUpRight, BsArrowDownRight } from 'react-icons/bs';
export default function MarqueeBanner({ items = [], title }) {
  if (!items || items.length === 0) return null;
  const displayItems = [...items, ...items, ...items];
  return (<div className="w-full bg-mid-bg border border-glass-border rounded-full py-3 relative overflow-hidden backdrop-blur-sm"><div className="absolute top-1/2 left-6 -translate-y-1/2 bg-dark-bg px-4 py-1.5 rounded-full text-xs font-headline text-text-white z-10 border border-glass-border">{title}</div><div className="flex animate-marquee pause-on-hover">{displayItems.map((item, idx) => { const isPositive = parseFloat(item.percent_change) >= 0; return (<div key={`${item.symbol}-${idx}`} className="flex items-baseline mx-8 flex-shrink-0"><span className="font-headline text-text-white text-lg">{item.symbol}</span><div className={`flex items-center ml-2 text-sm ${isPositive ? 'text-primary-blue' : 'text-primary-pink'}`}>{isPositive ? <BsArrowUpRight /> : <BsArrowDownRight />}<span className="ml-1 font-sans font-bold">{isPositive ? '+' : ''}{item.percent_change}%</span></div></div>); })}</div></div>);
}
EOF
cat > "${EVAL_TARGET_DIR}/src/components/DataTable.jsx" << 'EOF'
import { FaCrown } from 'react-icons/fa';
export default function DataTable({ items = [], type }) {
  const isGainer = type === 'gainer';
  const config = { title: isGainer ? "TOP GAINERS" : "TOP LOSERS", colorClass: isGainer ? 'text-primary-blue' : 'text-primary-pink', glowClass: isGainer ? 'gainer' : 'loser' };
  return (<div className="bg-glass-bg border border-glass-border rounded-xl backdrop-blur-md overflow-hidden transition-all duration-300 hover:border-primary-blue/50 hover:shadow-2xl hover:shadow-primary-blue/10 min-h-[300px]"><header className="flex justify-between items-center p-4 border-b border-glass-border"><div><h2 className={`font-headline text-2xl ${config.colorClass}`}>{config.title}</h2><p className="text-xs text-text-muted uppercase">3-Minute Performance</p></div><div className="bg-primary-orange/80 text-dark-bg font-bold text-xs px-3 py-1.5 rounded-full animate-pulseGlow">LIVE</div></header><div className="p-2">{items.length > 0 ? (<table className="w-full border-separate border-spacing-y-1"><tbody>{items.map((item) => (<tr key={item.symbol} className={`table-row-glow ${config.glowClass} transition-transform duration-300 ease-bounce hover:-translate-y-1`}><td className="p-4 w-12 text-center"><span className="flex items-center justify-center h-8 w-8 rounded-full bg-mid-bg border border-text-muted/20 font-bold text-text-white">{item.rank === 1 ? <FaCrown className={config.colorClass} /> : item.rank}</span></td><td className="p-4"><div className="flex items-center"><span className="font-bold text-text-white text-lg">{item.symbol}</span><span className={`ml-3 px-2 py-0.5 rounded text-xs uppercase font-bold ${item.tag === 'strong' ? 'bg-tag-strong text-dark-bg' : 'bg-tag-moderate text-text-muted'}`}>{item.tag}</span></div></td><td className={`p-4 text-right font-bold text-lg ${config.colorClass}`}>{parseFloat(item.percent_change) > 0 ? '+' : ''}{item.percent_change}%</td></tr>))}</tbody></table>) : (<div className="flex items-center justify-center h-48 text-text-muted">Calculating 3-min changes...</div>)}</div></div>);
}
EOF

# --- README.md ---
echo "Generating final README.md with the definitive instructions..."
cat > "${EVAL_TARGET_DIR}/README.md" << 'EOF'
# BHABIT | CB4 (Final Production Edition)

This project architecture is the definitive and most reliable setup for both local development and production deployment on Vercel. It adapts your original working logic to a robust, stateless serverless model.

## Core Logic
- **Backend:** A Python function at `api/data.py`.
- **Frontend:** A React/Vite application.
- **Data Source:** The backend uses the Coinbase API to calculate **3-minute change** for tables and **1-hour change** for banners, using a file-based cache in `/tmp` to store historical data.

---

## Final, Bulletproof Setup Guide

Follow these steps exactly. This two-terminal method bypasses all local Vercel/Volta conflicts.

### Step 1: Clean Slate & Setup
1.  **Navigate to the project directory**: `cd ~/betacb3.11`
2.  **Clean Up (HIGHLY Recommended)**: `rm -rf node_modules venv .vercel yarn.lock package-lock.json .pnp.* && rm -f /tmp/coinbase_cache.json`
3.  **Set up Python Virtual Environment**: `python3 -m venv venv` and then `source venv/bin/activate`
4.  **Install All Dependencies**: `pip install -r api/requirements.txt` and then `npm install`

### Step 2: Run the Application (Two Terminals)

**Open your FIRST terminal for the Backend.**
```bash
# In Terminal 1
cd ~/betacb3.11
source venv/bin/activate

# Set the FLASK_APP environment variable and run the pure Flask server
echo "Starting backend on http://localhost:8001..."
export FLASK_APP=api.data
python3 -m flask run --port=8001