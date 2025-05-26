import { createContext, useContext, useState, ReactNode } from 'react'

interface PendingOrder {
  id: number
  amount: string
  type: 'BUY' | 'CREATE'
  timestamp: number
  status: 'pending' | 'completed' | 'failed'
}

interface OrderContextType {
  pendingOrders: PendingOrder[]
  addPendingOrder: (amount: string, type: 'BUY' | 'CREATE') => void
  updateOrderStatus: (id: number, status: 'completed' | 'failed') => void
}

const OrderContext = createContext<OrderContextType | undefined>(undefined)

export function OrderProvider({ children }: { children: ReactNode }) {
  const [pendingOrders, setPendingOrders] = useState<PendingOrder[]>([])

  const addPendingOrder = (amount: string, type: 'BUY' | 'CREATE') => {
    const newOrder: PendingOrder = {
      id: Date.now(),
      amount,
      type,
      timestamp: Date.now(),
      status: 'pending'
    }
    setPendingOrders(prev => [newOrder, ...prev])
  }

  const updateOrderStatus = (id: number, status: 'completed' | 'failed') => {
    setPendingOrders(prev =>
      prev.map(order =>
        order.id === id ? { ...order, status } : order
      )
    )
  }

  return (
    <OrderContext.Provider value={{ pendingOrders, addPendingOrder, updateOrderStatus }}>
      {children}
    </OrderContext.Provider>
  )
}

export function useOrders() {
  const context = useContext(OrderContext)
  if (context === undefined) {
    throw new Error('useOrders must be used within an OrderProvider')
  }
  return context
} 