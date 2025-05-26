import { useState } from 'react'
import {
  useSwapUnderlyingForPT,
  useSwapYTForUnderlying,
  useRedeemPT,
  useRedeemYT,
  // usePreviewRedeemYT,  // Temporarily disabled
  // useTotalAssets,      // Temporarily disabled
} from '../hooks'

import { useAccount } from '@starknet-react/core'

export default function ContractPanel() {
  const [amount, setAmount] = useState('')
  const [marketAddress, setMarketAddress] = useState(import.meta.env.VITE_DEFAULT_MARKET || '')
  const { address } = useAccount()

  const { swap: swapPT } = useSwapUnderlyingForPT()
  const { swap: swapYT } = useSwapYTForUnderlying()
  const { redeem: redeemPT } = useRedeemPT()
  const { redeem: redeemYT } = useRedeemYT()

  // Temporarily disabled hooks
  // const { result: preview } = usePreviewRedeemYT(marketAddress, address || '')
  // const { result: tvl } = useTotalAssets(marketAddress)

  const execute = async (fn: () => Promise<any>) => {
    try {
      const res = await fn()
      alert('✅ Transaction sent!')
      console.log(res)
    } catch (err) {
      alert('❌ Transaction failed')
      console.error(err)
    }
  }

  return (
    <div className="space-y-6 text-white bg-[#111827] border border-gray-700 p-6 rounded-lg shadow-lg">
      <h2 className="text-lg font-bold mb-4">🧠 Smart Contract Panel</h2>

      <div className="space-y-4">
        <div>
          <label className="text-sm text-gray-400">Market Address</label>
          <input
            className="w-full bg-[#1f2937] text-white px-4 py-2 rounded border border-gray-600"
            value={marketAddress}
            onChange={(e) => setMarketAddress(e.target.value)}
            placeholder="0x..."
          />
        </div>
        <div>
          <label className="text-sm text-gray-400">Amount</label>
          <input
            type="number"
            className="w-full bg-[#1f2937] text-white px-4 py-2 rounded border border-gray-600"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="ex: 1000000000000000000"
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <button
            className="bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded text-sm font-semibold"
            onClick={() => execute(() => swapPT(marketAddress, amount))}
          >
            Create Order (swapUnderlyingForPT)
          </button>
          <button
            className="bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded text-sm font-semibold"
            onClick={() => execute(() => swapYT(marketAddress, amount))}
          >
            Buy Order (swapYTForUnderlying)
          </button>
          <button
            className="bg-green-600 hover:bg-green-700 px-4 py-2 rounded text-sm font-semibold"
            onClick={() => execute(() => redeemPT(amount))}
          >
            Redeem PT
          </button>
          <button
            className="bg-green-600 hover:bg-green-700 px-4 py-2 rounded text-sm font-semibold"
            onClick={() => execute(() => redeemYT(amount))}
          >
            Redeem YT
          </button>
        </div>
        {/* Temporarily disabled preview and TVL display
        <div className="pt-4 border-t border-gray-700 text-sm text-gray-300 space-y-1">
          <div>
            Preview Redeem YT:{' '}
            <span className="font-mono text-indigo-400">{preview && preview[0]?.toString()}</span>
          </div>
          <div>
            Total Value Locked (TVL):{' '}
            <span className="font-mono text-green-400">{tvl && tvl[0]?.toString()}</span>
          </div>
        </div>
        */}
      </div>
    </div>
  )
}
