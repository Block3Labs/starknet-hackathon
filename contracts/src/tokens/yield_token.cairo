#[starknet::contract]
pub mod YieldToken {
    use core::num::traits::Zero;
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};
    use starknet_hackathon::components::scaled_balance_token::ScaledBalanceTokenComponent;
    use starknet_hackathon::components::scaled_balance_token::ScaledBalanceTokenComponent::InternalTrait as ScaledBalanceTokenInternalTrait;
    use starknet_hackathon::interfaces::market::{IMarketDispatcher, IMarketDispatcherTrait};
    use starknet_hackathon::interfaces::yield_token::IYieldToken;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(
        path: ScaledBalanceTokenComponent,
        storage: scaled_balance_token,
        event: ScaledBalanceTokenEvent,
    );

    #[abi(embed_v0)]
    impl ScaledBalanceTokenImpl =
        ScaledBalanceTokenComponent::ScaledBalanceTokenImpl<ContractState>;
    impl ScaledBalanceTokenInternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        market: IMarketDispatcher,
        #[substorage(v0)]
        scaled_balance_token: ScaledBalanceTokenComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ScaledBalanceTokenEvent: ScaledBalanceTokenComponent::Event,
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    mod Errors {
        pub const ZERO_ADDRESS_CALLER: felt252 = 'caller is the zero address';
        pub const NOT_MARKET: felt252 = 'caller is not the market';
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: ByteArray, symbol: ByteArray, decimals: u256) {
        self.erc20.initializer(name, symbol);
    }

    #[abi(embed_v0)]
    impl YieldToken of IYieldToken<ContractState> {
        fn underlying_asset_address(self: @ContractState) -> ContractAddress {
            IMarketDispatcher { contract_address: self.market.read().contract_address }
                .underlying_asset_address()
        }

        fn set_market_address(ref self: ContractState, market_address: ContractAddress) {
            self.market.write(IMarketDispatcher { contract_address: market_address });
        }

        fn mint(
            ref self: ContractState,
            caller: ContractAddress,
            on_behalf_of: ContractAddress,
            amount: u256,
            liquidity_index: u256,
        ) -> bool {
            self.assert_only_market();
            self.scaled_balance_token.mint_scaled(caller, on_behalf_of, amount, liquidity_index)
        }

        fn burn(
            ref self: ContractState,
            from: ContractAddress,
            receiver_of_underlying: ContractAddress,
            amount: u256,
            liquidity_index: u256,
        ) -> bool {
            self.assert_only_market();
            self
                .scaled_balance_token
                .burn_scaled(from, receiver_of_underlying, amount, liquidity_index)
        }

        fn transfer(ref self: ContractState) -> bool {
            self.assert_only_market();
            true
        }
    }

    #[generate_trait]
    pub impl Internal of InternalTrait {
        fn assert_only_market(self: @ContractState) {
            let caller = get_caller_address();
            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            assert(caller == self.market.read().contract_address, Errors::NOT_MARKET);
        }
    }
    // #[abi(embed_v0)]
// impl ERC20 of openzeppelin_token::erc20::interface::IERC20<ContractState> {
// }
}
