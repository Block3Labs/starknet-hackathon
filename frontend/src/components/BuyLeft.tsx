import { useState } from 'react'
import { useSwapUnderlyingForPT, useSwapYTForUnderlying } from '../hooks'
import { useAccount, useConnect } from '@starknet-react/core'
import { usePrice } from '../context/PriceContext'
import { useOrders } from '../context/OrderContext'
import Notification from './Notification'

// Simulate Argent X wallet popup
const simulateArgentXPopup = () => {
  const popup = document.createElement('div')
  popup.style.position = 'fixed'
  popup.style.top = '50%'
  popup.style.left = '50%'
  popup.style.transform = 'translate(-50%, -50%)'
  popup.style.backgroundColor = '#1E1E1E'
  popup.style.padding = '24px'
  popup.style.borderRadius = '16px'
  popup.style.boxShadow = '0 0 0 100vmax rgba(0, 0, 0, 0.7)'
  popup.style.zIndex = '1000'
  popup.style.minWidth = '320px'
  popup.style.color = 'white'
  popup.style.fontFamily = 'system-ui'

  const content = `
    <div style="text-align: center;">
      <div style="margin-bottom: 16px;">
        <img src="https://www.argent.xyz/favicon.ico" alt="Argent X" style="width: 48px; height: 48px;" />
      </div>
      <h2 style="margin: 0 0 16px; font-size: 18px; color: white;">Confirm Transaction</h2>
      <div style="background: rgba(255, 255, 255, 0.1); padding: 16px; border-radius: 12px; margin-bottom: 20px; text-align: left;">
        <div style="margin-bottom: 8px; font-size: 14px; color: #999;">Network Fee</div>
        <div style="font-size: 16px;">~0.0001 ETH</div>
      </div>
      <button id="confirmBtn" style="background: #FF5B81; color: white; border: none; padding: 12px 24px; border-radius: 8px; width: 100%; font-size: 16px; cursor: pointer; margin-bottom: 8px;">Confirm</button>
      <button id="cancelBtn" style="background: transparent; color: #999; border: 1px solid #333; padding: 12px 24px; border-radius: 8px; width: 100%; font-size: 16px; cursor: pointer;">Cancel</button>
    </div>
  `

  popup.innerHTML = content
  document.body.appendChild(popup)

  return new Promise((resolve, reject) => {
    const confirmBtn = popup.querySelector('#confirmBtn')
    const cancelBtn = popup.querySelector('#cancelBtn')

    confirmBtn?.addEventListener('click', () => {
      document.body.removeChild(popup)
      resolve(true)
    })

    cancelBtn?.addEventListener('click', () => {
      document.body.removeChild(popup)
      reject(new Error('Transaction cancelled'))
    })
  })
}

export default function BuyLeft() {
  const [action, setAction] = useState<'BUY' | 'CREATE'>('BUY')
  const [amount, setAmount] = useState<string>('0')
  const [isProcessing, setIsProcessing] = useState(false)
  const [showNotification, setShowNotification] = useState(false)
  const [notificationMessage, setNotificationMessage] = useState('')
  const [notificationType, setNotificationType] = useState<'success' | 'error'>('success')
  
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { currentPrice } = usePrice()
  const { addPendingOrder, updateOrderStatus } = useOrders()

  const { swap: swapPT } = useSwapUnderlyingForPT()
  const { swap: swapYT } = useSwapYTForUnderlying()

  const calculateReceiveAmount = () => {
    if (!amount || Number(amount) === 0) return '0'
    const inputAmount = Number(amount)
    const receiveAmount = (inputAmount * currentPrice) / 100000
    return receiveAmount.toFixed(2)
  }

  const showTemporaryNotification = (message: string, type: 'success' | 'error', duration = 3000) => {
    setNotificationMessage(message)
    setNotificationType(type)
    setShowNotification(true)
    
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        setShowNotification(false)
        setTimeout(resolve, 300) // Wait for animation to complete
      }, duration)
    })
  }

  const handleSubmit = async () => {
    if (!isConnected) {
      const connector = connectors[0]
      if (connector) {
        try {
          await connect({ connector })
        } catch (error) {
          console.error('Failed to connect wallet:', error)
        }
      }
      return
    }

    if (isProcessing) return

    setIsProcessing(true)
    
    try {
      // Show pending notification for 5 seconds
      await showTemporaryNotification('Transaction pending...', 'success', 5000)
      
      // Show success notification
      await showTemporaryNotification('Transaction accepted', 'success', 3000)
      
      // Add to pending orders after success
      const orderId = Date.now()
      addPendingOrder(amount, action)
      
      // Update order status after a delay
      setTimeout(() => {
        updateOrderStatus(orderId, 'completed')
      }, 2000)

      setAmount('0')
    } catch (error) {
      console.error('Transaction failed:', error)
      await showTemporaryNotification('Transaction failed', 'error', 3000)
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex gap-2">
        <button
          onClick={() => setAction('BUY')}
          className={`flex-1 py-2 rounded-lg font-medium transition-all ${
            action === 'BUY'
              ? 'bg-[#ff9776] text-white'
              : 'bg-white/5 text-gray-300 hover:bg-white/10'
          }`}
          disabled={isProcessing}
        >
          BUY
        </button>
        <button
          onClick={() => setAction('CREATE')}
          className={`flex-1 py-2 rounded-lg font-medium transition-all ${
            action === 'CREATE'
              ? 'bg-[#40c9a2] text-white'
              : 'bg-white/5 text-gray-300 hover:bg-white/10'
          }`}
          disabled={isProcessing}
        >
          CREATE
        </button>
      </div>

      <div className="space-y-2">
        <label className="block text-sm text-gray-400">Amount</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full px-4 py-3 bg-white/5 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-[#40c9a2] transition-all"
          placeholder="0"
          disabled={!isConnected || isProcessing}
        />
      </div>

      <button
        onClick={handleSubmit}
        disabled={isProcessing}
        className={`w-full py-3 rounded-lg font-medium text-white transition-all ${
          isProcessing ? 'opacity-50 cursor-not-allowed' :
          !isConnected
            ? 'bg-[#ff9776] hover:bg-[#ff8561]'
            : action === 'BUY'
            ? 'bg-[#ff9776] hover:bg-[#ff8561]'
            : 'bg-[#40c9a2] hover:bg-[#35b892]'
        }`}
      >
        {isProcessing ? 'Processing...' : isConnected ? action : 'Connect Wallet'}
      </button>

      <div className="text-sm text-gray-400">
        Receive: <span className="text-white font-mono">{calculateReceiveAmount()} YT</span>
      </div>

      <Notification
        show={showNotification}
        message={notificationMessage}
        type={notificationType}
        onClose={() => setShowNotification(false)}
      />
    </div>
  )
}
