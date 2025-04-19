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
    use core::num::traits::Zero;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use starknet_hackathon::interfaces::market::IMarket;
    use starknet_hackathon::utils::math::ray_wad::{RAY, ray_div, ray_mul};

    const MIN_MATURITY: u64 = 604_800;
    const SECONDS_PER_YEAR: u64 = 31_536_000;
    const BPS_DENOMINATOR: u256 = 10_000;

    #[storage]
    pub struct Storage {
        market_name: ByteArray,
        underlying_asset: ContractAddress,
        pt_token: ContractAddress,
        yt_token: ContractAddress,
        maturity_timestamp: u64,
        start_timestamp: u64,
        last_updated_timestamp: u64,
        liquidity_index: u256,
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct MarketCreated {
        #[key]
        market_address: ContractAddress,
        underlying_asset: ContractAddress,
        pt_token: ContractAddress,
        yt_token: ContractAddress,
        start_timestamp: u64,
        maturity_timestamp: u64,
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct LiquidityIndexUpdated {
        #[key]
        timestamp: u64,
        previous_index: u256,
        new_index: u256,
        liquidity_rate: u256,
        delta: u64,
    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        MarketCreated: MarketCreated,
        LiquidityIndexUpdated: LiquidityIndexUpdated,
    }

    mod Errors {
        pub const NOT_MARKET: felt252 = 'Caller is not the market';
        pub const ZERO_ADDRESS: felt252 = 'Zero address not allowed';
        pub const MATURITY_TOO_SOON: felt252 = 'Maturity must exceed 1 week';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        market_name: ByteArray,
        underlying_asset: ContractAddress,
        pt_token: ContractAddress,
        yt_token: ContractAddress,
        maturity_timestamp: u64,
    ) {
        let now = get_block_timestamp();

        assert(underlying_asset.is_non_zero(), Errors::ZERO_ADDRESS);
        assert(pt_token.is_non_zero(), Errors::ZERO_ADDRESS);
        assert(yt_token.is_non_zero(), Errors::ZERO_ADDRESS);
        assert(maturity_timestamp >= MIN_MATURITY, Errors::MATURITY_TOO_SOON);

        self.market_name.write(market_name);
        self.underlying_asset.write(underlying_asset);
        self.pt_token.write(pt_token);
        self.yt_token.write(yt_token);
        self.maturity_timestamp.write(maturity_timestamp);
        self.start_timestamp.write(now);
        self.liquidity_index.write(RAY);

        self
            .emit(
                MarketCreated {
                    market_address: get_contract_address(),
                    underlying_asset,
                    pt_token,
                    yt_token,
                    start_timestamp: now,
                    maturity_timestamp,
                },
            );
    }

    #[abi(embed_v0)]
    impl Market of IMarket<ContractState> {
        fn underlying_asset_address(self: @ContractState) -> ContractAddress {
            self.underlying_asset.read()
        }

        fn maturity_timestamp(self: @ContractState) -> u64 {
            self.maturity_timestamp.read()
        }

        fn is_mature(self: @ContractState) -> bool {
            get_block_timestamp() >= self.start_timestamp.read() + self.maturity_timestamp.read()
        }

        fn get_liquidity_index(self: @ContractState) -> u256 {
            self.liquidity_index.read()
        }

        fn preview_redeem_yt(self: @ContractState, user: ContractAddress) -> u256 {
            0
        }

        fn preview_yield(self: @ContractState, user: ContractAddress, future_time: u64) -> u256 {
            0
        }

        fn total_assets(self: @ContractState) -> u256 {
            0
        }

        // fn get_apr(self: @ContractState) -> u256;
        fn update_liquidity_index(ref self: ContractState, apr_bps: u256) {
            let now = get_block_timestamp();
            let last_update = self.last_updated_timestamp.read();
            let delta = now - last_update;

            if delta.is_zero() {
                return;
            }

            let liquidity_rate = ray_div(apr_bps, BPS_DENOMINATOR);
            let delta_ray = ray_div(delta.into(), SECONDS_PER_YEAR.into());
            let interest = ray_mul(liquidity_rate, delta_ray);
            let current_index = self.liquidity_index.read();
            let new_index = ray_mul(current_index, RAY + interest);

            self.liquidity_index.write(new_index);
            self.last_updated_timestamp.write(now);

            self
                .emit(
                    LiquidityIndexUpdated {
                        timestamp: now,
                        previous_index: current_index,
                        new_index,
                        liquidity_rate,
                        delta,
                    },
                );
        }

        fn deposit(
            ref self: ContractState, user: ContractAddress, amount: u256,
        ) { // read liquidity_index
        // has enough underlying asset amount
        // mint_yt() for caller
        // mint_pt() for contract
        // emit event
        }

        // Redeem YT
        fn claim_yield(ref self: ContractState) {}

        // Redeem PT
        fn claim_underlying(ref self: ContractState) {}
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn assert_only_market(self: @ContractState) {
            assert(get_caller_address() == get_contract_address(), Errors::NOT_MARKET);
        }

        fn mint_pt(ref self: ContractState, amount: u256) {}

        fn mint_yt(ref self: ContractState, amount: u256) {}

        fn redeem_yt(ref self: ContractState, amount: u256) {}

        fn redeem_pt(ref self: ContractState, amount: u256) {}
    }
}

