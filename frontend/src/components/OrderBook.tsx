export default function OrderBook() {
  const orderbook = {
    asks: [
      { yt: '30 YT', amount: '108 YT', rate: '3%' },
      { yt: '22 YT', amount: '25 YT', rate: '3%' },
      { yt: '16 YT', amount: '106 YT', rate: '3%' },
    ],
    bids: [
      { yt: '149 YT', amount: '104 YT', rate: '3%' },
      { yt: '7 YT', amount: '7 YT', rate: '1%' },
      { yt: '58 YT', amount: '102 YT', rate: '1%' },
    ],
    history: [
      'Executed 128 YT @ 109 STRK',
      'Executed 27 YT @ 104 STRK',
      'Cancelled 53 YT pool',
    ],
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-white">Order Book</h2>
      </div>

      <div className="space-y-4">
        <div>
          <h3 className="text-sm font-medium text-[#40c9a2] mb-2">
            Asks (Sell YT)
          </h3>
          <div className="space-y-2">
            {orderbook.asks.map((ask, i) => (
              <div
                key={i}
                className="flex items-center justify-between text-sm"
              >
                <span className="text-[#ff9776]">{ask.yt}</span>
                <span className="text-white">{ask.amount}</span>
                <span className="text-[#40c9a2]">{ask.rate}</span>
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-sm font-medium text-[#ff9776] mb-2">
            Bids (Buy YT)
          </h3>
          <div className="space-y-2">
            {orderbook.bids.map((bid, i) => (
              <div
                key={i}
                className="flex items-center justify-between text-sm"
              >
                <span className="text-[#40c9a2]">{bid.yt}</span>
                <span className="text-white">{bid.amount}</span>
                <span className="text-[#ff9776]">{bid.rate}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="border-t border-gray-700/50 pt-4 mt-4">
          <h3 className="text-sm font-medium text-gray-400 mb-2">History</h3>
          <div className="space-y-2">
            {orderbook.history.map((item, i) => (
              <div key={i} className="text-sm text-gray-300">
                {item}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
