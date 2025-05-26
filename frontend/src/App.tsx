import React from 'react'
import BuyLeft from './components/BuyLeft'
import ChartSection from './components/ChartSection'
import OrderBook from './components/OrderBook'
import Header from './components/Header'
import { PriceProvider } from './context/PriceContext'
import { OrderProvider } from './context/OrderContext'

export default function App() {
  return (
    <PriceProvider>
      <OrderProvider>
        <div className="min-h-screen bg-[#0a0b0f]">
          <Header />
          <main className="max-w-screen-xl mx-auto">
            <div className="grid grid-cols-12 gap-6 px-4 py-6">
              <div className="col-span-3 -ml-16 bg-[#111827] border border-gray-800 rounded-lg p-6 shadow-lg">
                <BuyLeft />
              </div>
              <div className="col-span-6 col-start-4">
                <ChartSection />
              </div>
              <div className="col-span-3 -mr-16 bg-[#111827] border border-gray-800 rounded-lg p-6 shadow-lg">
                <OrderBook />
              </div>
            </div>
          </main>
        </div>
      </OrderProvider>
    </PriceProvider>
  )
}
