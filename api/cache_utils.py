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
