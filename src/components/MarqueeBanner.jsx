import { BsArrowUpRight, BsArrowDownRight } from 'react-icons/bs';
export default function MarqueeBanner({ items = [], title }) {
  if (!items || items.length === 0) return null;
  const displayItems = [...items, ...items, ...items];
  return (<div className="w-full bg-mid-bg border border-glass-border rounded-full py-3 relative overflow-hidden backdrop-blur-sm"><div className="absolute top-1/2 left-6 -translate-y-1/2 bg-dark-bg px-4 py-1.5 rounded-full text-xs font-headline text-text-white z-10 border border-glass-border">{title}</div><div className="flex animate-marquee pause-on-hover">{displayItems.map((item, idx) => { const isPositive = parseFloat(item.percent_change) >= 0; return (<div key={`${item.symbol}-${idx}`} className="flex items-baseline mx-8 flex-shrink-0"><span className="font-headline text-text-white text-lg">{item.symbol}</span><div className={`flex items-center ml-2 text-sm ${isPositive ? 'text-primary-blue' : 'text-primary-pink'}`}>{isPositive ? <BsArrowUpRight /> : <BsArrowDownRight />}<span className="ml-1 font-sans font-bold">{isPositive ? '+' : ''}{item.percent_change}%</span></div></div>); })}</div></div>);
}
