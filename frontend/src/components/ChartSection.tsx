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
import { usePrice } from '../context/PriceContext'
import { useOrders } from '../context/OrderContext'

type TimeUnit = '1m' | '1H' | '1D' | '1W'

interface ChartData {
  time: string
  price: number
}

// Fonction pour générer un prix basé sur le précédent avec une tendance
const generateNextPrice = (prevPrice: number, trend: number = 0): number => {
  const volatility = 0.005 // 0.5% de volatilité
  const change = (Math.random() - 0.5) * volatility + trend
  return prevPrice * (1 + change)
}

// Générer un historique de prix sur 30 jours
const generateHistoricalPrices = () => {
  const baseYield = 8 // Yield de base de 8%
  const prices: number[] = [baseYield]
  
  // Générer 30 jours de prix avec une légère tendance
  for (let i = 1; i < 30; i++) {
    prices.push(generateNextPrice(prices[i - 1], 0.0001)) // Très légère tendance
  }
  
  return prices
}

// Cache des prix historiques
const historicalPrices = generateHistoricalPrices()

const generateDataForTimeUnit = (unit: TimeUnit): ChartData[] => {
  const now = new Date()
  const data: ChartData[] = []
  
  switch (unit) {
    case '1m':
      // 60 points, un par minute
      for (let i = 59; i >= 0; i--) {
        const time = new Date(now.getTime() - i * 60000) // 60000ms = 1 minute
        data.push({
          time: time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          price: generateNextPrice(historicalPrices[historicalPrices.length - 1], 0)
        })
      }
      break
      
    case '1H':
      // 24 points, un par heure
      for (let i = 23; i >= 0; i--) {
        const time = new Date(now.getTime() - i * 3600000) // 3600000ms = 1 heure
        data.push({
          time: time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          price: generateNextPrice(historicalPrices[historicalPrices.length - 1], 0)
        })
      }
      break
      
    case '1D':
      // 30 points, un par jour
      for (let i = 29; i >= 0; i--) {
        const time = new Date(now.getTime() - i * 86400000) // 86400000ms = 1 jour
        data.push({
          time: time.toLocaleDateString([], { month: 'short', day: 'numeric' }),
          price: historicalPrices[historicalPrices.length - 1 - i]
        })
      }
      break
      
    case '1W':
      // 52 points, un par semaine
      for (let i = 51; i >= 0; i--) {
        const time = new Date(now.getTime() - i * 7 * 86400000)
        data.push({
          time: time.toLocaleDateString([], { month: 'short', day: 'numeric' }),
          price: generateNextPrice(
            i === 51 ? 100 : data[data.length - 1].price,
            0.002
          )
        })
      }
      break
  }
  
  return data
}

// Calculer la variation de prix sur une période
const calculatePriceChange = (data: ChartData[]): { percentage: string, weekPercentage: string } => {
  if (data.length < 2) return { percentage: '+0.00%', weekPercentage: '+0.00%' }
  
  const latest = data[data.length - 1].price
  const first = data[0].price
  const weekPrice = data[Math.max(0, data.length - 8)].price
  
  const change = ((latest - first) / first) * 100
  const weekChange = ((latest - weekPrice) / weekPrice) * 100
  
  return {
    percentage: `${change >= 0 ? '+' : ''}${change.toFixed(2)}%`,
    weekPercentage: `${weekChange >= 0 ? '+' : ''}${weekChange.toFixed(2)}%`
  }
}

export default function ChartSection() {
  const [selectedTimeUnit, setSelectedTimeUnit] = useState<TimeUnit>('1D')
  const [chartData, setChartData] = useState<ChartData[]>(generateDataForTimeUnit('1D'))
  const [priceChanges, setPriceChanges] = useState({ percentage: '+0.00%', weekPercentage: '+0.00%' })
  const { pendingOrders } = useOrders()

  const timeUnits: TimeUnit[] = ['1m', '1H', '1D', '1W']

  useEffect(() => {
    const newData = generateDataForTimeUnit(selectedTimeUnit)
    setChartData(newData)
    setPriceChanges(calculatePriceChange(newData))

    let interval: NodeJS.Timeout | null = null
    
    if (selectedTimeUnit === '1m') {
      interval = setInterval(() => {
        const updatedData = generateDataForTimeUnit('1m')
        setChartData(updatedData)
        setPriceChanges(calculatePriceChange(updatedData))
      }, 60000) // Mise à jour chaque minute
    }

    return () => {
      if (interval) clearInterval(interval)
    }
  }, [selectedTimeUnit])

  const formatTooltip = (value: number) => {
    return `${value.toFixed(2)} PT-VESU-STRK-SEP2025`
  }

  // Formater l'axe X en fonction de l'unité de temps
  const formatXAxis = (value: string) => {
    switch (selectedTimeUnit) {
      case '1m':
        return value.split(':')[1] // Afficher uniquement les minutes
      case '1H':
        return value.split(':')[0] + 'h' // Afficher l'heure avec 'h'
      default:
        return value
    }
  }

  return (
    <div className="space-y-6">
      <div style={{ 
        backgroundColor: '#111827', 
        border: '1px solid #1f2937',
        borderRadius: '0.5rem',
        padding: '1.5rem',
        minHeight: '400px'
      }}>
        <div style={{ marginBottom: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <h2 style={{ 
                fontSize: '0.875rem',
                fontWeight: '500',
                color: '#9ca3af',
                textTransform: 'uppercase',
                letterSpacing: '0.025em'
              }}>
                Yield Chart
              </h2>
              <div style={{
                marginTop: '0.5rem',
                fontSize: '1.5rem',
                fontWeight: '600',
                color: '#ffffff'
              }}>
                {chartData.length > 0 ? `${chartData[chartData.length - 1].price.toFixed(2)}%` : '8.00%'} PT-VESU-STRK-SEP2025
              </div>
              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.5rem' }}>
                <span style={{ 
                  color: priceChanges.percentage.startsWith('+') ? '#40c9a2' : '#ff4444',
                  fontSize: '0.875rem'
                }}>
                  {priceChanges.percentage}
                </span>
                <span style={{ 
                  color: priceChanges.weekPercentage.startsWith('+') ? '#40c9a2' : '#ff4444',
                  fontSize: '0.875rem'
                }}>
                  {priceChanges.weekPercentage} (Past 7d)
                </span>
              </div>
            </div>
            <div style={{ 
              display: 'flex', 
              gap: '0.5rem', 
              backgroundColor: '#1f2937',
              padding: '0.25rem',
              borderRadius: '0.375rem'
            }}>
              {timeUnits.map((unit) => (
                <button
                  key={unit}
                  onClick={() => setSelectedTimeUnit(unit)}
                  style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.25rem',
                    fontSize: '0.875rem',
                    backgroundColor: selectedTimeUnit === unit ? '#374151' : 'transparent',
                    color: selectedTimeUnit === unit ? '#ffffff' : '#9ca3af',
                    border: 'none',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                >
                  {unit}
                </button>
              ))}
            </div>
          </div>
        </div>
        
        <div style={{ width: '100%', height: '300px', position: 'relative' }}>
          <ResponsiveContainer>
            <LineChart
              data={chartData}
              margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
            >
              <CartesianGrid stroke="#1f2937" />
              <XAxis 
                dataKey="time"
                stroke="#9ca3af"
                tick={{ fill: '#9ca3af', fontSize: 12 }}
                tickFormatter={formatXAxis}
                interval={selectedTimeUnit === '1W' ? 3 : 'preserveStartEnd'}
              />
              <YAxis
                stroke="#9ca3af"
                tick={{ fill: '#9ca3af', fontSize: 12 }}
                domain={[7, 9]} // Limiter l'affichage entre 7% et 9%
                tickFormatter={(value) => `${value}%`}
              />
              <Tooltip 
                contentStyle={{
                  backgroundColor: '#1f2937',
                  border: 'none',
                  borderRadius: '0.5rem',
                  padding: '0.5rem'
                }}
                formatter={(value: number) => [`${value.toFixed(2)}% PT-VESU-STRK-SEP2025`]}
                labelFormatter={(label) => `Time: ${label}`}
              />
              <Line 
                type="monotone" 
                dataKey="price" 
                stroke="#40c9a2" 
                strokeWidth={2}
                isAnimationActive={false}
                dot={false}
                activeDot={{ r: 4, fill: '#40c9a2' }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div style={{ 
        backgroundColor: '#111827', 
        border: '1px solid #1f2937',
        borderRadius: '0.5rem',
        padding: '1.5rem'
      }}>
        <h2 style={{ 
          fontSize: '0.875rem',
          fontWeight: '500',
          color: '#9ca3af',
          textTransform: 'uppercase',
          letterSpacing: '0.025em',
          marginBottom: '1rem'
        }}>
          Pending Orders
        </h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {pendingOrders.map((order) => (
            <div
              key={order.id}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '0.75rem 1rem',
                backgroundColor: 'rgba(255, 255, 255, 0.05)',
                border: '1px solid rgba(107, 114, 128, 0.3)',
                borderRadius: '0.5rem',
                color: order.status === 'completed' ? '#40c9a2' : 
                      order.status === 'failed' ? '#ff4444' : 
                      '#9ca3af'
              }}
            >
              <span>
                Order #{order.id.toString().slice(-3)} - {order.amount} PT-VESU-STRK-SEP2025 {order.type.toLowerCase()}
              </span>
              <span style={{ fontSize: '0.875rem' }}>
                {order.status === 'pending' ? '⏳' : 
                 order.status === 'completed' ? '✅' : 
                 '❌'}
              </span>
            </div>
          ))}
          {pendingOrders.length === 0 && (
            <div style={{
              textAlign: 'center',
              color: '#6b7280',
              fontSize: '0.875rem',
              padding: '1rem'
            }}>
              No pending orders
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
