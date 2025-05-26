import { createContext, useContext, useState, ReactNode } from 'react'

interface PriceContextType {
  currentPrice: number
  setCurrentPrice: (price: number) => void
}

const PriceContext = createContext<PriceContextType | undefined>(undefined)

export function PriceProvider({ children }: { children: ReactNode }) {
  const [currentPrice, setCurrentPrice] = useState(100000) // Default value

  return (
    <PriceContext.Provider value={{ currentPrice, setCurrentPrice }}>
      {children}
    </PriceContext.Provider>
  )
}

export function usePrice() {
  const context = useContext(PriceContext)
  if (context === undefined) {
    throw new Error('usePrice must be used within a PriceProvider')
  }
  return context
} 