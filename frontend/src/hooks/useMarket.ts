import { useContract } from '@starknet-react/core'

export function useUnderlyingAssetAddress(marketAddress: string) {
  return useContract({
    functionName: 'underlying_asset_address',
    contractAddress: marketAddress,
    args: [],
    watch: true,
  })
}

export function useMaturityTimestamp(marketAddress: string) {
  return useContract({
    functionName: 'maturity_timestamp',
    contractAddress: marketAddress,
    args: [],
    watch: true,
  })
}

export function usePreviewRedeemYT(marketAddress: string, userAddress: string) {
  return useContract({
    functionName: 'preview_redeem_yt',
    contractAddress: marketAddress,
    args: [userAddress],
    watch: true,
  })
}

export function usePreviewYield(marketAddress: string, userAddress: string, futureTime: string) {
  return useContract({
    functionName: 'preview_yield',
    contractAddress: marketAddress,
    args: [userAddress, futureTime],
    watch: false,
  })
}

export function useTotalAssets(marketAddress: string) {
  return useContract({
    functionName: 'total_assets',
    contractAddress: marketAddress,
    args: [],
    watch: true,
  })
}
