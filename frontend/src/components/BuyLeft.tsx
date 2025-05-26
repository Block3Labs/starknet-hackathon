import { useState } from 'react'
import { useSwapUnderlyingForPT, useSwapYTForUnderlying } from '../hooks'
import { useAccount, useConnect } from '@starknet-react/core'
import { usePrice } from '../context/PriceContext'

export default function BuyLeft() {
  const [action, setAction] = useState<'BUY' | 'CREATE'>('BUY')
  const [amount, setAmount] = useState<string>('0')
  
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { currentPrice } = usePrice()

  const { swap: swapPT } = useSwapUnderlyingForPT()
  const { swap: swapYT } = useSwapYTForUnderlying()

  const calculateReceiveAmount = () => {
    if (!amount || Number(amount) === 0) return '0'
    const inputAmount = Number(amount)
    // Simple calculation based on current price
    // You might want to adjust this formula based on your actual tokenomics
    const receiveAmount = (inputAmount * currentPrice) / 100000
    return receiveAmount.toFixed(2)
  }

  const handleSubmit = async () => {
    if (!isConnected) {
      // Connect first available wallet
      const connector = connectors[0]
      if (connector) {
        connect({ connector })
      }
      return
    }

    try {
      const amountStr = (Number(amount) * 1e18).toString()
      if (action === 'CREATE') {
        await swapPT(import.meta.env.VITE_DEFAULT_MARKET || '', amountStr)
        alert('Order created successfully ✅')
      } else {
        await swapYT(import.meta.env.VITE_DEFAULT_MARKET || '', amountStr)
        alert('Order executed successfully ✅')
      }
    } catch (err) {
      alert('Transaction failed ❌')
      console.error(err)
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
          disabled={!isConnected}
        />
      </div>

      <button
        onClick={handleSubmit}
        className={`w-full py-3 rounded-lg font-medium text-white transition-all ${
          !isConnected
            ? 'bg-[#ff9776] hover:bg-[#ff8561]'
            : action === 'BUY'
            ? 'bg-[#ff9776] hover:bg-[#ff8561]'
            : 'bg-[#40c9a2] hover:bg-[#35b892]'
        }`}
      >
        {isConnected ? action : 'Connect Wallet'}
      </button>

      <div className="text-sm text-gray-400">
        Receive: <span className="text-white font-mono">{calculateReceiveAmount()} YT</span>
      </div>
    </div>
  )
}
