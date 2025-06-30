import { BsArrowUpRight, BsArrowDownRight } from 'react-icons/bs';
export default function MarqueeBanner({ items = [], title }) {
  if (!items || items.length === 0) return null;
  const displayItems = [...items, ...items, ...items];
  return (
    <div className="w-[99vw] max-w-[1920px] left-1/2 -translate-x-1/2 relative bg-gradient-to-r from-transparent via-mid-bg/90 to-transparent rounded-full py-5 overflow-hidden backdrop-blur-md shadow-2xl mx-auto flex items-center" style={{boxShadow: '0 0 48px 12px rgba(0,0,0,0.32)'}}>
      <span className="marquee-fade left" />
      <span className="marquee-fade right" />
      {/* Move the label above the banner */}
      <div className="absolute -top-8 left-16 bg-dark-bg/95 px-8 py-2 rounded-full text-base md:text-xl font-headline text-text-white z-20 shadow-lg select-none border border-glass-border">
        {title}
      </div>
      <div className="flex animate-marquee pause-on-hover w-full pl-64 pr-16">
        {displayItems.map((item, idx) => {
          const isPositive = parseFloat(item.percent_change) >= 0;
          return (
            <div key={`${item.symbol}-${idx}`} className="flex items-baseline mx-16 flex-shrink-0">
              <span className="font-headline text-text-white text-3xl md:text-4xl drop-shadow-xl">{item.symbol}</span>
              <div className={`flex items-center ml-6 text-xl md:text-2xl ${isPositive ? 'text-primary-blue' : 'text-primary-pink'} drop-shadow-lg`}>
                {isPositive ? <BsArrowUpRight /> : <BsArrowDownRight />}
                <span className="ml-3 font-sans font-bold">{isPositive ? '+' : ''}{item.percent_change}%</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
