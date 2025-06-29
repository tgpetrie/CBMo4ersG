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
