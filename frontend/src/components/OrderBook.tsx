export default function OrderBook() {
    const orderbook = {
      currentPrice: '3%',
      asks: [
        { strk: 100, yt: 10, rate: '3.5%' },
        { strk: 80, yt: 8, rate: '3.4%' },
        { strk: 50, yt: 5, rate: '3.2%' },
      ],
      bids: [
        { strk: 100, yt: 2, rate: '1.2%' },
        { strk: 75, yt: 1.5, rate: '1.0%' },
        { strk: 60, yt: 1, rate: '0.9%' },
      ],
      history: [
        'Executed 10 YT @ 3%',
        'Executed 2 YT @ 1.2%',
        'Created 25 YT pool',
      ],
    }
  
    return (
      <div className="text-white space-y-6">
        <div>
          <h2 className="text-xl font-semibold">Order Book</h2>
          <p className="text-sm text-gray-400">
            Current: <span className="font-mono">{orderbook.currentPrice}</span>
          </p>
        </div>
  
        <div>
          <h3 className="text-sm text-green-400 font-semibold mb-1">Asks (Sell YT)</h3>
          <ul className="space-y-1 text-sm font-mono text-green-300">
            {orderbook.asks.map((ask, i) => (
              <li key={i} className="flex justify-between border-b border-green-800/30 pb-1">
                <span>{ask.strk} STRK</span>
                <span>{ask.yt} YT</span>
                <span>{ask.rate}</span>
              </li>
            ))}
          </ul>
        </div>
  
        <div>
          <h3 className="text-sm text-red-400 font-semibold mb-1">Bids (Buy YT)</h3>
          <ul className="space-y-1 text-sm font-mono text-red-300">
            {orderbook.bids.map((bid, i) => (
              <li key={i} className="flex justify-between border-b border-red-800/30 pb-1">
                <span>{bid.strk} STRK</span>
                <span>{bid.yt} YT</span>
                <span>{bid.rate}</span>
              </li>
            ))}
          </ul>
        </div>
  
        <div>
          <h3 className="text-sm text-gray-300 font-semibold mb-1">History</h3>
          <ul className="space-y-1 text-sm text-gray-400 font-mono">
            {orderbook.history.map((item, index) => (
              <li key={index} className="border-b border-gray-700 pb-1">{item}</li>
            ))}
          </ul>
        </div>
      </div>
    )
  }
  