import { useOrders } from '../context/OrderContext'
import { useEffect, useState } from 'react'

interface OrderBookEntry {
  amount: string
  yt: string
  rate: string
}

interface HistoryEntry {
  id: number
  message: string
  status: 'pending' | 'completed' | 'failed'
}

export default function OrderBook() {
  const { pendingOrders } = useOrders()
  const [asks, setAsks] = useState<OrderBookEntry[]>([
    { amount: '30 STRK', yt: '108 YT', rate: '9.8%' },
    { amount: '22 STRK', yt: '25 YT', rate: '9.2%' },
    { amount: '16 STRK', yt: '106 YT', rate: '8.7%' },
  ])
  const [bids, setBids] = useState<OrderBookEntry[]>([
    { amount: '149 STRK', yt: '104 YT', rate: '7.2%' },
    { amount: '7 STRK', yt: '7 YT', rate: '6.5%' },
    { amount: '58 STRK', yt: '102 YT', rate: '5.3%' },
  ])
  const [history, setHistory] = useState<HistoryEntry[]>([
    { id: 1, message: 'Executed 128 YT @ 109 STRK', status: 'completed' },
    { id: 2, message: 'Executed 27 YT @ 104 STRK', status: 'completed' },
    { id: 3, message: 'Cancelled 53 YT pool', status: 'failed' },
  ])

  useEffect(() => {
    // Update history and order book based on pending orders
    pendingOrders.forEach(order => {
      const ytAmount = Math.floor(Number(order.amount) * 1.2)
      const newEntry = {
        amount: `${order.amount} STRK`,
        yt: `${ytAmount} YT`,
        rate: '3%'
      }
      
      // Add to history if not already present
      setHistory(prev => {
        const existingEntry = prev.find(h => h.id === order.id)
        if (!existingEntry) {
          return [{
            id: order.id,
            message: `${order.type === 'BUY' ? 'Buying' : 'Creating'} ${ytAmount} YT @ ${order.amount} STRK`,
            status: order.status
          }, ...prev]
        }
        // Update status if entry exists
        return prev.map(h => 
          h.id === order.id 
            ? { ...h, status: order.status }
            : h
        )
      })

      // Add completed orders to the order book
      if (order.status === 'completed') {
        if (order.type === 'BUY') {
          setBids(prev => {
            if (!prev.some(bid => bid.amount === newEntry.amount)) {
              return [newEntry, ...prev]
            }
            return prev
          })
        } else {
          setAsks(prev => {
            if (!prev.some(ask => ask.amount === newEntry.amount)) {
              return [newEntry, ...prev]
            }
            return prev
          })
        }
      }
    })
  }, [pendingOrders])

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
            {asks.map((ask, i) => (
              <div
                key={i}
                className="flex items-center justify-between text-sm"
              >
                <span className="text-[#ff9776]">{ask.amount}</span>
                <span className="text-white">{ask.yt}</span>
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
            {bids.map((bid, i) => (
              <div
                key={i}
                className="flex items-center justify-between text-sm"
              >
                <span className="text-[#40c9a2]">{bid.amount}</span>
                <span className="text-white">{bid.yt}</span>
                <span className="text-[#ff9776]">{bid.rate}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="border-t border-gray-700/50 pt-4 mt-4">
          <h3 className="text-sm font-medium text-gray-400 mb-2">History</h3>
          <div className="space-y-2">
            {history.map((item) => (
              <div 
                key={item.id} 
                className={`text-sm ${
                  item.status === 'completed' ? 'text-[#40c9a2]' :
                  item.status === 'failed' ? 'text-[#ff9776]' :
                  'text-gray-300'
                }`}
              >
                {item.message}
                {item.status === 'pending' && ' (Pending...)'}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
