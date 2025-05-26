import { AnimatePresence, motion } from 'framer-motion'

interface TransactionModalProps {
  isOpen: boolean
  onConfirm: () => void
  onCancel: () => void
}

export default function TransactionModal({ isOpen, onConfirm, onCancel }: TransactionModalProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/70"
        >
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.15 }}
            className="w-[320px] bg-[#1f2937] border border-gray-700 rounded-xl shadow-lg overflow-hidden"
          >
            <div className="p-4 border-b border-gray-600 flex justify-between items-center">
              <span className="text-sm font-semibold text-white">Confirm Transaction</span>
              <button
                onClick={onCancel}
                className="text-gray-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <div className="p-4 space-y-4">
              <div className="flex justify-center">
                <img
                  src="https://www.argent.xyz/favicon.ico"
                  alt="Argent X"
                  className="w-12 h-12"
                />
              </div>

              <div className="bg-white/5 p-4 rounded-lg space-y-1">
                <div className="text-sm text-gray-400">Network Fee</div>
                <div className="text-white font-mono">~0.0001 ETH</div>
              </div>

              <button
                onClick={onConfirm}
                className="w-full py-3 bg-[#ff9776] hover:bg-[#ff8561] text-white rounded-lg font-medium transition-all"
              >
                Confirm
              </button>

              <button
                onClick={onCancel}
                className="w-full py-3 bg-white/5 hover:bg-white/10 text-gray-300 rounded-lg font-medium transition-all"
              >
                Cancel
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
} 