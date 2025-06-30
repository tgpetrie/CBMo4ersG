import React from "react"; import useSWR from "swr"; import BHABITLogo from "./components/BHABITLogo.jsx"; import MarqueeBanner from "./components/MarqueeBanner.jsx"; import DataTable from "./components/DataTable.jsx";
const API_ENDPOINT = "/api/data";
const fetcher = async (url) => { const res = await fetch(url); if (!res.ok) { const e = new Error('An error occurred while fetching the data.'); e.info = await res.json().catch(() => ({ error: 'Could not parse error JSON.' })); e.status = res.status; throw e; } return res.json(); };
export default function App() {
  const { data, error, isLoading } = useSWR(API_ENDPOINT, fetcher, { refreshInterval: 45000, shouldRetryOnError: true });
  const renderContent = () => {
    if (error) return <div className="text-center py-20 text-primary-pink font-headline">Error: {error.info?.error || error.message}</div>;
    if (isLoading && !data) return <div className="text-center py-20 text-text-muted text-xl font-headline animate-pulse">Connecting to Real-Time Data Stream...</div>;
    return (
      <>
        {/* Price Change Banner */}
        <div className="relative mb-8 mt-2">
          <div className="absolute -top-8 left-0 w-full flex justify-start z-30 pointer-events-none pl-2 md:pl-8">
            <span className="bg-dark-bg/95 px-8 py-2 rounded-full text-base md:text-xl font-headline text-text-white shadow-lg border border-glass-border select-none">1H PRICE CHANGE</span>
          </div>
          <MarqueeBanner items={data?.price_banner} title="" />
        </div>
        {/* Gainers/Losers Tables */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-20 mb-20">
          <div className="flex flex-col">
            <span className="mb-4 ml-2 md:ml-8 bg-dark-bg/95 px-8 py-2 rounded-full text-base md:text-xl font-headline text-text-white shadow-lg border border-glass-border select-none w-fit">TOP GAINERS (3MIN)</span>
            <DataTable items={data?.gainers} type="gainer" />
          </div>
          <div className="flex flex-col">
            <span className="mb-4 ml-2 md:ml-8 bg-dark-bg/95 px-8 py-2 rounded-full text-base md:text-xl font-headline text-text-white shadow-lg border border-glass-border select-none w-fit">TOP LOSERS (3MIN)</span>
            <DataTable items={data?.losers} type="loser" />
          </div>
        </div>
        {/* Volume Movers Banner */}
        <div className="relative mt-12 mb-4">
          <div className="absolute -top-8 left-0 w-full flex justify-start z-30 pointer-events-none pl-2 md:pl-8">
            <span className="bg-dark-bg/95 px-8 py-2 rounded-full text-base md:text-xl font-headline text-text-white shadow-lg border border-glass-border select-none">1H VOLUME MOVERS</span>
          </div>
          <MarqueeBanner items={data?.volume_banner} title="" />
        </div>
      </>
    );
  };
  return (<main className="container mx-auto max-w-7xl px-4 py-8"><BHABITLogo /><div className="flex flex-col gap-12 mt-8">{renderContent()}</div></main>);
}
