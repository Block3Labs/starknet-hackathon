import { useContract } from '@starknet-react/core'

// NOTE: These hooks are currently disabled as they require proper ABI configuration
/*
export function useUnderlyingAssetAddress(marketAddress: string) {
  return useContract({
    entrypoint: 'underlying_asset_address',
    contractAddress: marketAddress,
    args: [],
    watch: true,
  })
}

export function useMaturityTimestamp(marketAddress: string) {
  return useContract({
    entrypoint: 'maturity_timestamp',
    contractAddress: marketAddress,
    args: [],
    watch: true,
  })
}

export function usePreviewRedeemYT(marketAddress: string, userAddress: string) {
  return useContract({
    entrypoint: 'preview_redeem_yt',
    contractAddress: marketAddress,
    args: [userAddress],
    watch: true,
  })
}

export function usePreviewYield(marketAddress: string, userAddress: string, futureTime: string) {
  return useContract({
    entrypoint: 'preview_yield',
    contractAddress: marketAddress,
    args: [userAddress, futureTime],
    watch: false,
  })
}

export function useTotalAssets(marketAddress: string) {
  return useContract({
    entrypoint: 'total_assets',
    contractAddress: marketAddress,
    args: [],
    watch: true,
  })
}
*/
