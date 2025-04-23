import React from 'react'
import BuyLeft from './components/BuyLeft'
import ChartSection from './components/ChartSection'
import OrderBook from './components/OrderBook'
import Header from './components/Header'

export default function App() {
  return (
    <div className="h-screen flex flex-col bg-[#0e1015]">
      <Header />

      <main className="flex flex-1">
        {/* Left: Buy/Create */}
        <aside className="w-1/4 p-6 border-r border-gray-800 bg-[#111827]">
          <BuyLeft />
        </aside>

        {/* Center: Chart */}
        <section className="w-2/4 p-6">
          <ChartSection />
        </section>

        {/* Right: OrderBook */}
        <aside className="w-1/4 p-6 border-l border-gray-800 bg-[#111827]">
          <OrderBook />
        </aside>
      </main>
    </div>
  )
}
