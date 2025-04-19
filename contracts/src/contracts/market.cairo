/// liquidityRate - APR in RAY per seconde
/// liquidityIndex - This is a global index that reflects the accumulation of interest over time.
/// Starts at 1e27 (RAY), then increases over time using the formula :
/// liquidityIndex = liquidityIndex * (1 + rate * dt) → or in RAY : index = index * (RAY + rate *
/// dt) / RAY scaledBalance - This is a user's ‘frozen’ balance. It never changes.
///
///
/// Gérer la logique économique du protocole :
/// liquidityRate (taux par seconde)
/// liquidityIndex (croissance des intérêts)
/// lastUpdateTimestamp
/// Appeler régulièrement (ou à chaque action) la fonction
///
/// Répond aux appels deposit, withdraw
/// Calcule la part "scaled" de l’utilisateur (en divisant par le liquidityIndex)
// Interagit avec le YieldToken pour mint/burn les parts
#[starknet::contract]
pub mod Market {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet_hackathon::interfaces::market::IMarket;

    mod Errors {
        pub const NOT_MARKET: felt252 = 'Caller is not the market';
    }

    #[storage]
    pub struct Storage {
        underlying_asset: ContractAddress,
    }

    #[abi(embed_v0)]
    impl Market of IMarket<ContractState> {
        fn underlying_asset_address(self: @ContractState) -> ContractAddress {
            self.underlying_asset.read()
        }

        fn maturity_timestamp(self: @ContractState) -> u64 {
            0
        }

        fn get_liquidity_index(self: @ContractState) -> u256 {
            0
        }

        fn update_liquidity_index(ref self: ContractState) {}

        fn deposit(ref self: ContractState, amount: u256) { // has enough underlying asset amount
        // mint_yt()
        // mint_pt()
        // emit event
        }

        fn redeem_yt(ref self: ContractState) {}

        fn redeem_pt(ref self: ContractState) {}
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn assert_only_market(self: @ContractState) {
            assert(get_caller_address() == get_contract_address(), Errors::NOT_MARKET);
        }
    }
}

