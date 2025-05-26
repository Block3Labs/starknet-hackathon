import { useEffect } from 'react'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  ResponsiveContainer,
  Tooltip,
  CartesianGrid,
} from 'recharts'
import { usePrice } from '../context/PriceContext'

export default function ChartSection() {
  const { setCurrentPrice } = usePrice()
  
  const data = [
    { time: '10:00', value: 100000 },
    { time: '10:00', value: 100000 },
    { time: '11:00', value: 99000 },
    { time: '12:00', value: 100500 },
    { time: '13:00', value: 101000 },
    { time: '14:00', value: 101500 },
  ]

  // Update current price whenever the last data point changes
  useEffect(() => {
    const lastPrice = data[data.length - 1].value
    setCurrentPrice(lastPrice)
  }, [data, setCurrentPrice])

  const pendingOrders = [
    'Order #128 - 10 YT pending',
    'Order #127 - 25 YT pending',
    'Order #126 - 5 YT pending',
  ]

  return (
    <div className="space-y-6">
      <div className="bg-[#111827] border border-gray-800 rounded-lg p-6 shadow-lg">
        <div className="mb-4">
          <h2 className="text-sm font-medium text-gray-400 uppercase tracking-wider">
            Price Chart
          </h2>
        </div>
        
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data}>
              <defs>
                <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#40c9a2" stopOpacity={0.1}/>
                  <stop offset="95%" stopColor="#40c9a2" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid
                strokeDasharray="3 3"
                vertical={false}
                stroke="rgba(255,255,255,0.1)"
              />
              <XAxis
                dataKey="time"
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#9ca3af', fontSize: 12 }}
              />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#9ca3af', fontSize: 12 }}
                domain={['dataMin - 1000', 'dataMax + 1000']}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#1f2937',
                  border: 'none',
                  borderRadius: '0.5rem',
                  boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                }}
                itemStyle={{ color: '#40c9a2' }}
                labelStyle={{ color: '#9ca3af' }}
              />
              <Line
                type="monotone"
                dataKey="value"
                stroke="#40c9a2"
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4, fill: '#40c9a2' }}
                fillOpacity={1}
                fill="url(#colorValue)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="bg-[#111827] border border-gray-800 rounded-lg p-6 shadow-lg">
        <h2 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
          Pending Orders
        </h2>
        <div className="space-y-2">
          {pendingOrders.map((order, index) => (
            <div
              key={index}
              className="flex items-center px-4 py-3 bg-white/5 border border-gray-700/50 rounded-lg text-gray-300 text-sm"
            >
              {order}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
