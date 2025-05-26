import { AnimatePresence, motion } from 'framer-motion'

interface NotificationProps {
  show: boolean
  message: string
  type?: 'success' | 'error'
  onClose: () => void
}

export default function Notification({ show, message, type = 'success', onClose }: NotificationProps) {
  return (
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.2 }}
          className="fixed top-4 right-4 z-50"
        >
          <div className={`px-4 py-3 rounded-lg shadow-lg flex items-center gap-2 ${
            type === 'success' ? 'bg-[#40c9a2] text-white' : 'bg-red-500 text-white'
          }`}>
            <span>{message}</span>
            <button
              onClick={onClose}
              className="ml-2 text-white/80 hover:text-white"
            >
              ✕
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
} 