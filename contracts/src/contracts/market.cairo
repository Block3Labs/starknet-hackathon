#[starknet::contract]
pub mod Market {
    use core::num::traits::Zero;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
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
        orderbook_address: ContractAddress,
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
        pub const NOT_MATURED: felt252 = 'Market not matured yet';
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

        fn orderbook_address(self: @ContractState) -> ContractAddress {
            self.orderbook_address.read()
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

        fn deposit(ref self: ContractState, caller: ContractAddress, amount: u256) {
            // let apr = get_apr(underlying_address);
            let apr = 350; // 3.5% => 350, 4% => 400, 3.7% => 370
            self.update_liquidity_index(apr);
            self.mint_pt(caller, amount);
            self.mint_yt(caller, amount);
        }

        fn buy_yield(
            ref self: ContractState, buyer: ContractAddress, seller: ContractAddress, amount: u256,
        ) { // transfer_yt()
        }

        // Redeem YT
        fn claim_yield(ref self: ContractState, user: ContractAddress) -> u256 {
            assert(self.is_mature(), Errors::NOT_MATURED);
            let router_addr = get_caller_address();

            //check yt balance & check cb d'underlying asset ont doit lui donner
            let yt_token = IERC20Dispatcher {
                contract_address: self.yt_token.read(),
            }; //==> scaled_balance real YT-Token value with interest - claimable value at maturity
            let amount_to_redeem = yt_token.balance_of(user);

            assert(yt_token.balance_of(user) > 0, 'Wrong balance');

            //CheckRedeemAmount = (scaledBal * TVL_at_maturity) / scaled_total_supply;<==
            //sanitycheck, À Confirmer ou verifié
            self.preview_redeem_yt(user);

            self.burn_yt(user, yt_token.balance_of(user));

            IERC20Dispatcher { contract_address: self.underlying_asset.read() }
                .approve(router_addr, amount_to_redeem);

            amount_to_redeem
            //==> routeur transfer assets to caller
        }

        // Redeem PT
        fn claim_underlying(ref self: ContractState, user: ContractAddress, amount: u256) -> u256 {
            assert(self.is_mature(), Errors::NOT_MATURED);

            assert(self.is_mature(), Errors::NOT_MATURED);
            let router_addr = get_caller_address();

            //check cb d'underlying asset ont doit lui donner / normalement 1:1 underlying::pt
            let pt_token = IERC20Dispatcher { contract_address: self.pt_token.read() };
            let amount_to_redeem = pt_token.balance_of(user);
            assert(pt_token.balance_of(user) < amount, 'INVALID AMOUNT');
            self.burn_pt(user, amount);

            return amount_to_redeem;
            //==> routeur transfer underlying assets to caller  swap_pt_for_underlying()

        }
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

        fn mint_pt(
            ref self: ContractState, recipient: ContractAddress, amount: u256,
        ) { // mint pour recipient
        // IPrincipalTokenDispatcher { contract_address: self.pt_token.read() }.mint();
        }

        fn mint_yt(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let contract_address = get_contract_address();
            let liqudity_index = self.liquidity_index.read();
            IYieldTokenDispatcher { contract_address: self.yt_token.read() }
                .mint(contract_address, recipient, amount, liqudity_index);
        }

        fn burn_yt(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let contract_address = get_contract_address();
            let liqudity_index = self.liquidity_index.read();
            IYieldTokenDispatcher { contract_address: self.yt_token.read() }
                .burn(contract_address, recipient, amount, liqudity_index);
        }

        fn burn_pt(ref self: ContractState, recipient: ContractAddress, amount: u256) {}

        fn transfer_yt(
            ref self: ContractState, buyer: ContractAddress, amount: u256,
        ) { // Send YT from Market to buyer
        }

        fn redeem_yt(ref self: ContractState, amount: u256) {}

        fn redeem_pt(ref self: ContractState, amount: u256) {}
    }
}

