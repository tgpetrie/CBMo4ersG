import { FaCrown } from 'react-icons/fa';
export default function DataTable({ items = [], type }) {
  const isGainer = type === 'gainer';
  const config = {
    title: isGainer ? "TOP GAINERS" : "TOP LOSERS",
    colorClass: isGainer ? 'text-primary-blue' : 'text-primary-pink',
    glowClass: isGainer ? 'gainer' : 'loser'
  };
  return (
    <div className="bg-glass-bg rounded-2xl shadow-xl shadow-primary-blue/10 backdrop-blur-md overflow-hidden transition-all duration-300 hover:shadow-2xl hover:shadow-primary-blue/20 min-h-[300px]">
      <div className="p-4">
        {items.length > 0 ? (
          <table className="w-full border-separate border-spacing-y-2">
            <thead>
              <tr>
                <th className="p-2 text-left text-sm md:text-base text-text-muted font-semibold">#</th>
                <th className="p-2 text-left text-sm md:text-base text-text-muted font-semibold">Symbol</th>
                <th className="p-2 text-right text-sm md:text-base text-text-muted font-semibold">Price</th>
                <th className="p-2 text-right text-sm md:text-base text-text-muted font-semibold">% Change</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.symbol} className={`table-row-glow ${config.glowClass} transition-transform duration-300 ease-bounce hover:-translate-y-1 bg-dark-bg/80 rounded-xl shadow-md`}>
                  <td className="p-4 w-14 text-center">
                    <span className="flex items-center justify-center h-10 w-10 rounded-full bg-mid-bg font-bold text-text-white text-lg md:text-xl shadow-sm">
                      {item.rank === 1 ? <FaCrown className={config.colorClass} /> : item.rank}
                    </span>
                  </td>
                  <td className="p-4">
                    <div className="flex items-center">
                      <span className="font-bold text-text-white text-xl md:text-2xl tracking-wide">{item.symbol}</span>
                      <span className={`ml-3 px-2 py-1 rounded text-xs md:text-sm uppercase font-bold ${item.tag === 'strong' ? 'bg-tag-strong text-dark-bg' : 'bg-tag-moderate text-text-muted'}`}>{item.tag}</span>
                    </div>
                  </td>
                  <td className="p-4 text-right font-mono text-lg md:text-xl text-text-white">
                    ${parseFloat(item.price).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 6 })}
                  </td>
                  <td className={`p-4 text-right font-bold text-xl md:text-2xl ${config.colorClass}`}> 
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
