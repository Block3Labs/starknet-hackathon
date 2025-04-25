import { useAccount } from '@starknet-react/core'
import { CallData, uint256 } from 'starknet'

// Remplace par ton vrai router contract address
const ROUTER_ADDRESS = '0xROUTER_ADDRESS_HERE'

export function useSwapUnderlyingForPT() {
  const { account } = useAccount()

  async function swap(marketAddress: string, amount: string) {
    if (!account) throw new Error('Wallet not connected')
    const amountUint = uint256.bnToUint256(BigInt(amount))
    const calldata = CallData.compile({ market_address: marketAddress, amount: amountUint })

    return await account.execute({
      contractAddress: ROUTER_ADDRESS,
      entrypoint: 'swap_underlying_for_pt',
      calldata,
    })
  }

  return { swap }
}

export function useSwapYTForUnderlying() {
  const { account } = useAccount()

  async function swap(marketAddress: string, amount: string) {
    if (!account) throw new Error('Wallet not connected')
    const amountUint = uint256.bnToUint256(BigInt(amount))
    const calldata = CallData.compile({ market_address: marketAddress, amount: amountUint })

    return await account.execute({
      contractAddress: ROUTER_ADDRESS,
      entrypoint: 'swap_yt_for_underlying',
      calldata,
    })
  }

  return { swap }
}

export function useRedeemPT() {
  const { account } = useAccount()

  async function redeem(amount: string) {
    if (!account) throw new Error('Wallet not connected')
    const amountUint = uint256.bnToUint256(BigInt(amount))
    const calldata = CallData.compile({ amount: amountUint })

    return await account.execute({
      contractAddress: ROUTER_ADDRESS,
      entrypoint: 'redeem_pt',
      calldata,
    })
  }

  return { redeem }
}

export function useRedeemYT() {
  const { account } = useAccount()

  async function redeem(amount: string) {
    if (!account) throw new Error('Wallet not connected')
    const amountUint = uint256.bnToUint256(BigInt(amount))
    const calldata = CallData.compile({ amount: amountUint })

    return await account.execute({
      contractAddress: ROUTER_ADDRESS,
      entrypoint: 'redeem_yt',
      calldata,
    })
  }

  return { redeem }
}
