import { useState } from 'react'
import { useSwapUnderlyingForPT, useSwapYTForUnderlying } from '../hooks'

export default function BuyLeft() {
  const [action, setAction] = useState<'BUY' | 'CREATE'>('BUY')
  const [amount, setAmount] = useState<number>(0)

  const { swap: swapPT } = useSwapUnderlyingForPT()
  const { swap: swapYT } = useSwapYTForUnderlying()

  const marketAddress = '0xMARKET_ADDRESS_HERE'

  const handleSubmit = async () => {
    const amountStr = (amount * 1e18).toString()

    try {
      if (action === 'CREATE') {
        await swapPT(marketAddress, amountStr)
        alert('Order created successfully ✅')
      } else if (action === 'BUY') {
        await swapYT(marketAddress, amountStr)
        alert('Order executed successfully ✅')
      }
    } catch (err) {
      alert('Transaction failed ❌')
      console.error(err)
    }
  }

  const receiveAmount = (amount * 2).toFixed(2)

  return (
    <div className="space-y-6 text-white">
      <div className="flex gap-2">
        <button
          onClick={() => setAction('BUY')}
          className={`flex-1 py-2 text-sm rounded font-semibold transition ${
            action === 'BUY'
              ? 'bg-indigo-600 text-white'
              : 'bg-[#1f2937] hover:bg-[#2d3748] text-gray-300'
          }`}
        >
          BUY
        </button>
        <button
          onClick={() => setAction('CREATE')}
          className={`flex-1 py-2 text-sm rounded font-semibold transition ${
            action === 'CREATE'
              ? 'bg-indigo-600 text-white'
              : 'bg-[#1f2937] hover:bg-[#2d3748] text-gray-300'
          }`}
        >
          CREATE
        </button>
      </div>
      <div>
        <label className="text-sm text-gray-400 mb-1 block">Amount</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(Number(e.target.value))}
          placeholder="Enter amount"
          className="w-full px-4 py-2 rounded bg-[#1f2937] text-white border border-gray-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
      </div>
      <button
        onClick={handleSubmit}
        className="w-full py-2 bg-green-600 hover:bg-green-700 rounded font-semibold text-white transition"
      >
        {action}
      </button>
      <p className="text-sm text-gray-400">
        Receive: <span className="text-indigo-400 font-mono">{receiveAmount} YT</span>
      </p>
    </div>
  )
}
