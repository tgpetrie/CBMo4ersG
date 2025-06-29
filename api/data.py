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
