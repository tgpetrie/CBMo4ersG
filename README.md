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
