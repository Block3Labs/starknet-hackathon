#[starknet::contract]
pub mod Market {
    use core::num::traits::Zero;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{
        ClassHash, ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
    };
    use starknet_hackathon::interfaces::market::IMarket;
    use starknet_hackathon::interfaces::yield_token::{
        IYieldTokenDispatcher, IYieldTokenDispatcherTrait,
    };
    use starknet_hackathon::utils::math::ray_wad::{RAY, ray_div, ray_mul};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

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
        last_applied_apr: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
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
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        MarketCreated: MarketCreated,
        LiquidityIndexUpdated: LiquidityIndexUpdated,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    mod Errors {
        pub const NOT_MARKET: felt252 = 'Caller is not the market';
        pub const ZERO_ADDRESS: felt252 = 'Zero address not allowed';
        pub const MATURITY_TOO_SOON: felt252 = 'Maturity must exceed 1 week';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
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

        self.ownable.initializer(owner);
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
        fn update_liquidity_index(ref self: ContractState, apr: u256) {
            self.ownable.assert_only_owner();
            let now = get_block_timestamp();
            let last_update = self.last_updated_timestamp.read();
            let delta = now - last_update;

            if delta.is_zero() {
                return;
            }

            let liquidity_rate = ray_div(apr, BPS_DENOMINATOR);
            let delta_ray = ray_div(delta.into(), SECONDS_PER_YEAR.into());
            let interest = ray_mul(liquidity_rate, delta_ray);
            let current_index = self.liquidity_index.read();
            let new_index = ray_mul(current_index, RAY + interest);

            self.liquidity_index.write(new_index);
            self.last_updated_timestamp.write(now);
            self.last_applied_apr.write(apr);

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

        fn deposit(ref self: ContractState, account: ContractAddress, amount: u256) {
            // let apr = get_apr(underlying_address);
            let apr = 350; // 3.5%
            if self.last_applied_apr.read() != apr {
                self.update_liquidity_index(apr);
            }
            self.mint_pt(account, amount);
            self.mint_yt(account, amount);
        }

        // Redeem YT
        fn claim_yield(ref self: ContractState) {}

        // Redeem PT
        fn claim_underlying(ref self: ContractState) {}
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn assert_only_market(self: @ContractState) {
            assert(get_caller_address() == get_contract_address(), Errors::NOT_MARKET);
        }

        fn mint_pt(ref self: ContractState, account: ContractAddress, amount: u256) {}

        fn mint_yt(ref self: ContractState, account: ContractAddress, amount: u256) {
            let contract_address = get_contract_address();
            let liqudity_index = self.liquidity_index.read();
            IYieldTokenDispatcher { contract_address: self.underlying_asset.read() }
                .mint(account, contract_address, amount, liqudity_index);
        }

        fn redeem_yt(ref self: ContractState, amount: u256) {}

        fn redeem_pt(ref self: ContractState, amount: u256) {}
    }
}

