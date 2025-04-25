import { useEffect, useState } from 'react'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  ResponsiveContainer,
  Tooltip,
  CartesianGrid,
} from 'recharts'

export default function ChartSection() {
  const [orders, setOrders] = useState<string[]>([])

  useEffect(() => {
    setOrders([
      'Order #128 — 10 YT pending',
      'Order #129 — 25 YT pending',
      'Order #130 — 5 YT pending',
    ])
  }, [])

  const data = [
    { time: '10:00', price: 3.2 },
    { time: '10:15', price: 3.4 },
    { time: '10:30', price: 3.1 },
    { time: '10:45', price: 3.3 },
    { time: '11:00', price: 3.5 },
    { time: '11:15', price: 3.7 },
  ]

  return (
    <div className="space-y-8 text-white">
      <div className="rounded-xl overflow-hidden border border-indigo-500/30 bg-gradient-to-br from-[#1f1f2b] to-[#2c2c40] shadow-lg p-4">
        <div className="text-xs text-indigo-400 font-semibold uppercase tracking-wide mb-2">
          Price Chart
        </div>
        <ResponsiveContainer width="100%" height={200}>
          <LineChart data={data}>
            <XAxis dataKey="time" stroke="#8884d8" fontSize={12} />
            <YAxis stroke="#8884d8" fontSize={12} domain={['dataMin - 0.2', 'dataMax + 0.2']} />
            <CartesianGrid stroke="#444" strokeDasharray="3 3" />
            <Tooltip
              contentStyle={{
                backgroundColor: '#1a1b2f',
                border: 'none',
                borderRadius: '6px',
              }}
              labelStyle={{ color: '#ccc' }}
              itemStyle={{ color: '#fff' }}
            />
            <Line
              type="monotone"
              dataKey="price"
              stroke="#6366f1"
              strokeWidth={2}
              dot={{ r: 3 }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div>
        <h2 className="text-lg font-semibold text-gray-100 mb-3 tracking-wide">Pending Orders</h2>
        <ul className="space-y-2 text-sm text-gray-300 font-mono">
          {orders.map((order, index) => (
            <li
              key={index}
              className="px-4 py-2 border border-gray-700 rounded-lg bg-[#1a1b2f]/60 backdrop-blur-sm hover:bg-[#242540]/70 transition"
            >
              {order}
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
