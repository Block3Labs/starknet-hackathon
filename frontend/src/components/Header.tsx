import ConnectWallet from './ConnectWallet'

export default function Header() {
  return (
    <header className="w-full px-6 py-4 bg-[#111827] border-b border-gray-800 flex items-center justify-between shadow-sm">
      <h1 className="text-lg sm:text-xl font-bold text-white tracking-wide">
        Starknet DeFi App
      </h1>
      <ConnectWallet />
    </header>
  )
}