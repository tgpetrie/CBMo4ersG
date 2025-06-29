import { FaCrown } from 'react-icons/fa';
export default function DataTable({ items = [], type }) {
  const isGainer = type === 'gainer';
  const config = {
    title: isGainer ? "TOP GAINERS" : "TOP LOSERS",
    colorClass: isGainer ? 'text-primary-blue' : 'text-primary-pink',
    glowClass: isGainer ? 'gainer' : 'loser'
  };
  return (
    <div className="bg-glass-bg border border-glass-border rounded-xl backdrop-blur-md overflow-hidden transition-all duration-300 hover:border-primary-blue/50 hover:shadow-2xl hover:shadow-primary-blue/10 min-h-[300px]">
      <header className="flex justify-between items-center p-4 border-b border-glass-border">
        <div>
          <h2 className={`font-headline text-2xl ${config.colorClass}`}>{config.title}</h2>
          <p className="text-xs text-text-muted uppercase">3-Minute Performance</p>
        </div>
        <div className="bg-primary-orange/80 text-dark-bg font-bold text-xs px-3 py-1.5 rounded-full animate-pulseGlow">LIVE</div>
      </header>
      <div className="p-2">
        {items.length > 0 ? (
          <table className="w-full border-separate border-spacing-y-1">
            <thead>
              <tr>
                <th className="p-2 text-left text-xs text-text-muted">#</th>
                <th className="p-2 text-left text-xs text-text-muted">Symbol</th>
                <th className="p-2 text-right text-xs text-text-muted">Price</th>
                <th className="p-2 text-right text-xs text-text-muted">% Change</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.symbol} className={`table-row-glow ${config.glowClass} transition-transform duration-300 ease-bounce hover:-translate-y-1`}>
                  <td className="p-4 w-12 text-center">
                    <span className="flex items-center justify-center h-8 w-8 rounded-full bg-mid-bg border border-text-muted/20 font-bold text-text-white">
                      {item.rank === 1 ? <FaCrown className={config.colorClass} /> : item.rank}
                    </span>
                  </td>
                  <td className="p-4">
                    <div className="flex items-center">
                      <span className="font-bold text-text-white text-lg">{item.symbol}</span>
                      <span className={`ml-3 px-2 py-0.5 rounded text-xs uppercase font-bold ${item.tag === 'strong' ? 'bg-tag-strong text-dark-bg' : 'bg-tag-moderate text-text-muted'}`}>{item.tag}</span>
                    </div>
                  </td>
                  <td className="p-4 text-right font-mono text-base text-text-white">
                    ${parseFloat(item.price).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 6 })}
                  </td>
                  <td className={`p-4 text-right font-bold text-lg ${config.colorClass}`}>
                    {parseFloat(item.percent_change) > 0 ? '+' : ''}{item.percent_change}%
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="flex items-center justify-center h-48 text-text-muted">Calculating 3-min changes...</div>
        )}
      </div>
    </div>
  );
}
