// Vercel serverless function: /api/data.js
// This function fetches data from Coinbase and returns gainers, losers, and banners.
// You can expand the logic as needed to match your Python backend.

import fetch from 'node-fetch';

const COINBASE_API_URL = 'https://api.exchange.coinbase.com';
const TABLE_COUNT = 6;
const BANNER_COUNT = 25;

async function fetchProducts() {
  const res = await fetch(`${COINBASE_API_URL}/products`);
  const products = await res.json();
  return products.filter(p => p.id.endsWith('-USD') && p.status === 'online').map(p => p.id);
}

async function fetchTickers(productIds) {
  // Fetch tickers in parallel (limit concurrency if needed)
  const results = await Promise.all(productIds.map(async (id) => {
    try {
      const res = await fetch(`${COINBASE_API_URL}/products/${id}/ticker`);
      if (!res.ok) return null;
      const data = await res.json();
      return { id, ...data };
    } catch {
      return null;
    }
  }));
  return results.filter(Boolean);
}

function calculateChanges(latest, past) {
  // This is a stub. In production, you would persist and compare snapshots.
  // Here, we just return the latest as a placeholder.
  return latest.map((t, i) => ({
    symbol: t.id.replace('-USD', ''),
    price: t.price,
    percent_change: (Math.random() * 10 - 5).toFixed(2), // Fake change for demo
    volume_24h: t.volume || 0,
    rank: i + 1,
    tag: Math.abs(Math.random()) > 0.5 ? 'strong' : 'moderate',
  }));
}

export default async function handler(req, res) {
  try {
    const productIds = await fetchProducts();
    const tickers = await fetchTickers(productIds);
    // In a real app, you would compare with cached/past data for real percent_change
    const gainers = calculateChanges(tickers, []);
    const losers = [...gainers].sort((a, b) => a.percent_change - b.percent_change);
    const price_banner = gainers.slice(0, BANNER_COUNT);
    const volume_banner = gainers.slice(0, BANNER_COUNT);
    res.status(200).json({ gainers: gainers.slice(0, TABLE_COUNT), losers: losers.slice(0, TABLE_COUNT), price_banner, volume_banner });
  } catch (e) {
    res.status(500).json({ error: 'A critical error occurred while processing market data.' });
  }
}
