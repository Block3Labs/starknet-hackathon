import { useConnect, useDisconnect, useAccount } from '@starknet-react/core'
import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'

export default function ConnectWallet() {
  const { connect, connectors } = useConnect()
  const { disconnect } = useDisconnect()
  const { address, isConnected } = useAccount()

  const [isModalOpen, setIsModalOpen] = useState(false)

  if (isConnected) {
    return (
      <div className="flex items-center gap-2">
        <span className="text-sm font-mono text-gray-300 truncate max-w-[150px]">{address}</span>
        <button
          onClick={() => disconnect()}
          className="text-sm text-red-500 hover:underline"
        >
          Disconnect
        </button>
      </div>
    )
  }

  return (
    <div className="relative">
      {/* Button */}
      <button
        onClick={() => setIsModalOpen(true)}
        className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded text-sm font-semibold transition"
      >
        Connect Wallet
      </button>

      {/* Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.15 }}
            className="absolute right-0 mt-2 w-64 bg-[#1f2937] border border-gray-700 rounded shadow-lg z-50"
          >
            <div className="p-4 border-b border-gray-600 flex justify-between items-center">
              <span className="text-sm font-semibold text-white">Select Wallet</span>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>
            <div className="p-4 space-y-2">
              {connectors.map((connector) => (
                <button
                  key={connector.id}
                  onClick={() => {
                    connect({ connector })
                    setIsModalOpen(false)
                  }}
                  className="w-full text-left px-4 py-2 bg-[#111827] hover:bg-[#1c1f2b] border border-gray-700 rounded text-sm text-gray-300 transition"
                >
                  {connector.name}
                </button>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
